import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/access_code.dart';
import '../models/category.dart';
import '../models/event_statistics.dart';
import '../models/nominee.dart';
import '../models/vote.dart';
import '../models/vote_result.dart';
import '../models/voting_event.dart';

/// Lightweight DTO used when validating access codes
class AccessCodeData {
  final String code;
  final String eventId;
  final String eventName;
  final String generatedFor;

  AccessCodeData({
    required this.code,
    required this.eventId,
    required this.eventName,
    required this.generatedFor,
  });
}

class FirebaseService {
  static const String adminCode = 'ADMIN123';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =====================================================
  // EVENTS
  // =====================================================

  static Future<List<VotingEvent>> getAllEvents() async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => VotingEvent.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting events: $e');
      return [];
    }
  }

  static Future<String?> createEvent({
    required String name,
    required String description,
    String type = 'general',
    DateTime? endDate,
  }) async {
    try {
      final docRef = await _firestore.collection('events').add({
        'name': name,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'active': false,
        'type': type,
        'endDate': endDate,
      });
      print('✅ Event created: $name');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating event: $e');
      return null;
    }
  }

  static Future<bool> deleteEvent(String eventId) async {
    try {
      await _deleteSubcollections(eventId);
      await _firestore.collection('events').doc(eventId).delete();
      print('✅ Event deleted: $eventId');
      return true;
    } catch (e) {
      print('❌ Error deleting event: $e');
      return false;
    }
  }

  static Future<bool> resetEventData(String eventId) async {
    try {
      final batch = _firestore.batch();

      // 1️⃣ Delete all votes for this event
      final votes = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('votes')
          .get();
      for (final doc in votes.docs) {
        batch.delete(doc.reference);
      }

      // 2️⃣ Reset access codes (mark them as unused)
      final codes = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('access_codes')
          .get();
      for (final doc in codes.docs) {
        batch.update(doc.reference, {
          'used': false,
          'usedBy': null,
          'usedAt': null,
        });
      }

      // Commit all batched operations
      await batch.commit();
      return true;
    } catch (e) {
      print('🔥 Error resetting event data: $e');
      return false;
    }
  }

  static Future<bool> clearEventData(String eventId) async {
    try {
      await _deleteSubcollections(eventId);
      print('✅ Event data cleared: $eventId');
      return true;
    } catch (e) {
      print('❌ Error clearing event data: $e');
      return false;
    }
  }

  static Future<void> _deleteSubcollections(String eventId) async {
    for (final sub in ['nominees', 'categories', 'accessCodes', 'votes']) {
      final snapshot = await _firestore
          .collection('events/$eventId/$sub')
          .get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  }

  static Future<bool> archiveEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'archivedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Event archived: $eventId');
      return true;
    } catch (e) {
      print('❌ Error archiving event: $e');
      return false;
    }
  }

  static Future<String?> duplicateEvent(String eventId, String newName) async {
    try {
      final sourceEvent = await _firestore
          .collection('events')
          .doc(eventId)
          .get();
      if (!sourceEvent.exists) return null;
      final sourceData = sourceEvent.data()!;

      // Create new event
      final newEventRef = await _firestore.collection('events').add({
        'name': newName,
        'description': sourceData['description'] ?? '',
        'type': sourceData['type'] ?? 'general',
        'createdAt': FieldValue.serverTimestamp(),
        'active': false,
      });

      // Copy subcollections
      for (final sub in ['categories', 'nominees']) {
        final items = await _firestore.collection('events/$eventId/$sub').get();
        for (var item in items.docs) {
          await _firestore
              .collection('events/${newEventRef.id}/$sub')
              .add(item.data());
        }
      }

      print('✅ Event duplicated as $newName');
      return newEventRef.id;
    } catch (e) {
      print('❌ Error duplicating event: $e');
      return null;
    }
  }

  // =====================================================
  // ACCESS CODES
  // =====================================================

  static Future<String> generateAccessCodeForEvent({
    required String name,
    required String eventId,
    required String eventName,
  }) async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String code;

    while (true) {
      code = List.generate(
        8,
        (_) => chars[random.nextInt(chars.length)],
      ).join();
      final existing = await _firestore
          .collection('events/$eventId/accessCodes')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) break;
    }

    await _firestore.collection('events/$eventId/accessCodes').add({
      'code': code,
      'generatedFor': name,
      'eventId': eventId,
      'eventName': eventName,
      'generated': FieldValue.serverTimestamp(),
      'used': false,
    });

    print('✅ Access code generated: $code');
    return code;
  }

  static Future<List<AccessCode>> getAccessCodesForEvent(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('events/$eventId/accessCodes')
          .orderBy('generated', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => AccessCode(
              code: doc['code'] ?? '',
              generatedFor: doc['generatedFor'] ?? '',
              eventId: eventId,
              eventName: doc['eventName'] ?? '',
              generated: (doc['generated'] as Timestamp).toDate(),
              used: doc['used'] ?? false,
            ),
          )
          .toList();
    } catch (e) {
      print('❌ Error fetching access codes: $e');
      return [];
    }
  }

  static Future<AccessCodeData?> findAccessCode(String code) async {
    final events = await _firestore.collection('events').get();
    for (final eventDoc in events.docs) {
      final snapshot = await _firestore
          .collection('events/${eventDoc.id}/accessCodes')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        if (data['used'] == true) return null;
        return AccessCodeData(
          code: code,
          eventId: eventDoc.id,
          eventName: data['eventName'] ?? 'Unknown Event',
          generatedFor: data['generatedFor'] ?? '',
        );
      }
    }
    return null;
  }

  // =====================================================
  // CATEGORIES
  // =====================================================

  static Future<List<Category>> getCategoriesForEvent(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('events/$eventId/categories')
          .orderBy('createdAt')
          .get();
      return snapshot.docs
          .map((doc) => Category(id: doc.id, name: doc['name'] ?? ''))
          .toList();
    } catch (e) {
      print('❌ Error fetching categories: $e');
      return [];
    }
  }

  static Future<bool> addCategory(String eventId, String name) async {
    try {
      await _firestore.collection('events/$eventId/categories').add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Category added: $name');
      return true;
    } catch (e) {
      print('❌ Error adding category: $e');
      return false;
    }
  }

  static Future<bool> deleteCategory(String eventId, String id) async {
    try {
      await _firestore
          .collection('events/$eventId/categories')
          .doc(id)
          .delete();
      return true;
    } catch (e) {
      print('❌ Error deleting category: $e');
      return false;
    }
  }

  // =====================================================
  // NOMINEES
  // =====================================================

  static Future<List<Nominee>> getNomineesForEvent(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('events/$eventId/nominees')
          .orderBy('name')
          .get();
      return snapshot.docs
          .map((doc) => Nominee(id: doc.id, name: doc['name'] ?? ''))
          .toList();
    } catch (e) {
      print('❌ Error fetching nominees: $e');
      return [];
    }
  }

  static Future<bool> addNominee(String eventId, String name) async {
    try {
      await _firestore.collection('events/$eventId/nominees').add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Nominee added: $name');
      return true;
    } catch (e) {
      print('❌ Error adding nominee: $e');
      return false;
    }
  }

  static Future<bool> deleteNominee(String eventId, String id) async {
    try {
      await _firestore.collection('events/$eventId/nominees').doc(id).delete();
      return true;
    } catch (e) {
      print('❌ Error deleting nominee: $e');
      return false;
    }
  }

  // =====================================================
  // VOTES
  // =====================================================

  static Future<bool> submitVotes(
    String eventId,
    String code,
    List<Vote> votes,
  ) async {
    try {
      // Prevent double-voting
      final existing = await _firestore
          .collection('events/$eventId/votes')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return false;

      await _firestore.collection('events/$eventId/votes').add({
        'code': code,
        'submittedAt': FieldValue.serverTimestamp(),
        'votes': votes.map((v) => v.toJson()).toList(),
      });

      // Mark code as used
      final codeRef = await _firestore
          .collection('events/$eventId/accessCodes')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      if (codeRef.docs.isNotEmpty) {
        await codeRef.docs.first.reference.update({
          'used': true,
          'usedAt': FieldValue.serverTimestamp(),
        });
      }

      print('✅ Votes submitted for code: $code');
      return true;
    } catch (e) {
      print('❌ Error submitting votes: $e');
      return false;
    }
  }

  static Future<List<VoteResult>> getResultsForEvent(String eventId) async {
    try {
      final categories = await getCategoriesForEvent(eventId);
      final nominees = await getNomineesForEvent(eventId);
      final votesSnapshot = await _firestore
          .collection('events/$eventId/votes')
          .get();

      List<VoteResult> results = [];

      for (var category in categories) {
        Map<String, int> scores = {for (var n in nominees) n.name: 0};

        for (var voteDoc in votesSnapshot.docs) {
          final data = voteDoc.data();
          final votesList = data['votes'] as List<dynamic>? ?? [];
          for (var v in votesList) {
            if (v['categoryId'] == category.id) {
              if (v['first'] != null) {
                scores[v['first']] = (scores[v['first']] ?? 0) + 5;
              }
              if (v['second'] != null) {
                scores[v['second']] = (scores[v['second']] ?? 0) + 3;
              }
              if (v['third'] != null) {
                scores[v['third']] = (scores[v['third']] ?? 0) + 1;
              }
            }
          }
        }

        results.add(
          VoteResult(
            categoryId: category.id,
            categoryName: category.name,
            scores: scores,
          ),
        );
      }

      return results;
    } catch (e) {
      print('❌ Error getting results: $e');
      return [];
    }
  }

  // =====================================================
  // STATISTICS
  // =====================================================

  static Future<Map<String, dynamic>> getOverallStatistics() async {
    try {
      final eventsSnapshot = await _firestore.collection('events').get();
      List<EventStatistics> statsList = [];

      for (var eventDoc in eventsSnapshot.docs) {
        final eventId = eventDoc.id;
        final stats = await getEventStatistics(eventId);
        statsList.add(stats);
      }

      return {
        'totalNominees': statsList.fold(0, (sum, s) => sum + s.totalNominees),
        'totalCategories': statsList.fold(
          0,
          (sum, s) => sum + s.totalCategories,
        ),
        'totalEvents': statsList.length,
        'totalVotes': statsList.fold(0, (sum, s) => sum + s.totalVotes),
      };
    } catch (e) {
      print('❌ Error getting statistics: $e');
      return {};
    }
  }

  static Future<EventStatistics> getEventStatistics(String eventId) async {
    try {
      final results = await Future.wait([
        _firestore.collection('events/$eventId/nominees').get(),
        _firestore.collection('events/$eventId/categories').get(),
        _firestore.collection('events/$eventId/accessCodes').get(),
        _firestore.collection('events/$eventId/votes').get(),
      ]);

      final accessCodesSnapshot = results[2] as QuerySnapshot;
      final usedCodes = accessCodesSnapshot.docs
          .where((doc) => (doc.data() as Map)['used'] == true)
          .length;

      return EventStatistics(
        totalNominees: results[0].docs.length,
        totalCategories: results[1].docs.length,
        totalAccessCodes: accessCodesSnapshot.docs.length,
        usedCodes: usedCodes,
        totalVotes: results[3].docs.length,
      );
    } catch (e) {
      print('❌ Error getting event statistics: $e');
      return EventStatistics(
        totalNominees: 0,
        totalCategories: 0,
        totalAccessCodes: 0,
        usedCodes: 0,
        totalVotes: 0,
      );
    }
  }
}
