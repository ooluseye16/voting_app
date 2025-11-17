import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/access_code.dart';
import '../models/category.dart';
import '../models/event_statistics.dart';
import '../models/nominee.dart';
import '../models/vote.dart';
import '../models/vote_result.dart';
import '../models/voting_event.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static String? _currentOrgId; // Current organization/tenant ID
  static Map<String, String>? _adminCodeMap; // Cache of admin codes

  /// Load all admin codes and their corresponding org IDs from Firebase
  static Future<void> _loadAdminCodes() async {
    if (_adminCodeMap != null) return;

    try {
      final snapshot = await _firestore.collection('organizations').get();
      _adminCodeMap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final adminCode = data['adminCode'] as String?;
        if (adminCode != null && adminCode.isNotEmpty) {
          _adminCodeMap![adminCode] = doc.id; // Map code to org ID
        }
      }
    } catch (e) {
      print('Error loading admin codes: $e');
      _adminCodeMap = {};
    }
  }

  /// Validate admin code and set the current organization context
  /// Returns the organization ID if valid, null otherwise
  static Future<String?> validateAdminCode(String code) async {
    await _loadAdminCodes();

    final orgId = _adminCodeMap?[code];
    if (orgId != null) {
      _currentOrgId = orgId;
      return orgId;
    }
    return null;
  }

  /// Check if a code is an admin code (without setting context)
  static Future<bool> isAdminCode(String code) async {
    await _loadAdminCodes();
    return _adminCodeMap?.containsKey(code) ?? false;
  }

  /// Validate admin code and set context - returns true if valid
  static Future<bool> loginAsAdmin(String code) async {
    final orgId = await validateAdminCode(code);
    return orgId != null;
  }

  /// Get current organization ID
  static String? get currentOrgId => _currentOrgId;

  /// Set organization context (used after login)
  static void setOrganizationContext(String orgId) {
    _currentOrgId = orgId;
  }

  /// Clear organization context (logout)
  static void clearContext() {
    _currentOrgId = null;
  }

  /// Get organization-scoped collection reference
  static CollectionReference<Map<String, dynamic>> _getOrgCollection(
    String collectionName,
  ) {
    if (_currentOrgId == null) {
      throw Exception('No organization context set. Please login first.');
    }
    return _firestore
        .collection('organizations')
        .doc(_currentOrgId)
        .collection(collectionName);
  }

  // ==================== CATEGORIES ====================

  static Future<List<Category>> getCategories() async {
    try {
      final snapshot = await _getOrgCollection('categories').get();
      return snapshot.docs
          .map(
            (doc) => Category(id: doc.id, name: doc.data()['name'] as String),
          )
          .toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  /// Get categories for a specific event
  static Future<List<Category>> getCategoriesForEvent(String eventId) async {
    try {
      final snapshot = await _getOrgCollection(
        'events',
      ).doc(eventId).collection('categories').get();

      return snapshot.docs
          .map(
            (doc) => Category(id: doc.id, name: doc.data()['name'] as String),
          )
          .toList();
    } catch (e) {
      print('Error fetching event categories: $e');
      return [];
    }
  }

  static Future<bool> addCategory(String name) async {
    try {
      await _getOrgCollection(
        'categories',
      ).add({'name': name, 'createdAt': FieldValue.serverTimestamp()});
      return true;
    } catch (e) {
      print('Error adding category: $e');
      return false;
    }
  }

  /// Add category to a specific event
  static Future<bool> addCategoryToEvent(String eventId, String name) async {
    try {
      await _getOrgCollection('events')
          .doc(eventId)
          .collection('categories')
          .add({'name': name, 'createdAt': FieldValue.serverTimestamp()});
      return true;
    } catch (e) {
      print('Error adding event category: $e');
      return false;
    }
  }

  static Future<bool> deleteCategory(String id) async {
    try {
      await _getOrgCollection('categories').doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting category: $e');
      return false;
    }
  }

  /// Delete category from a specific event
  static Future<bool> deleteCategoryFromEvent(
    String eventId,
    String categoryId,
  ) async {
    try {
      await _getOrgCollection(
        'events',
      ).doc(eventId).collection('categories').doc(categoryId).delete();
      return true;
    } catch (e) {
      print('Error deleting event category: $e');
      return false;
    }
  }

  // ==================== NOMINEES ====================

  static Future<List<Nominee>> getNominees() async {
    try {
      final snapshot = await _getOrgCollection('nominees').get();
      return snapshot.docs
          .map((doc) => Nominee(id: doc.id, name: doc.data()['name'] as String))
          .toList();
    } catch (e) {
      print('Error fetching nominees: $e');
      return [];
    }
  }

  /// Get nominees for a specific event
  static Future<List<Nominee>> getNomineesForEvent(String eventId) async {
    try {
      final snapshot = await _getOrgCollection(
        'events',
      ).doc(eventId).collection('nominees').get();

      return snapshot.docs
          .map((doc) => Nominee(id: doc.id, name: doc.data()['name'] as String))
          .toList();
    } catch (e) {
      print('Error fetching event nominees: $e');
      return [];
    }
  }

  static Future<bool> addNominee(String name) async {
    try {
      await _getOrgCollection(
        'nominees',
      ).add({'name': name, 'createdAt': FieldValue.serverTimestamp()});
      return true;
    } catch (e) {
      print('Error adding nominee: $e');
      return false;
    }
  }

  /// Add nominee to a specific event
  static Future<bool> addNomineeToEvent(String eventId, String name) async {
    try {
      await _getOrgCollection('events').doc(eventId).collection('nominees').add(
        {'name': name, 'createdAt': FieldValue.serverTimestamp()},
      );
      return true;
    } catch (e) {
      print('Error adding event nominee: $e');
      return false;
    }
  }

  static Future<bool> deleteNominee(String id) async {
    try {
      await _getOrgCollection('nominees').doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting nominee: $e');
      return false;
    }
  }

  /// Delete nominee from a specific event
  static Future<bool> deleteNomineeFromEvent(
    String eventId,
    String nomineeId,
  ) async {
    try {
      await _getOrgCollection(
        'events',
      ).doc(eventId).collection('nominees').doc(nomineeId).delete();
      return true;
    } catch (e) {
      print('Error deleting event nominee: $e');
      return false;
    }
  }

  // ==================== EVENTS ====================

  /// Create a new event
  static Future<String?> createEvent({
    required String name,
    String? description,
    String type = 'general',
    DateTime? endDate,
  }) async {
    try {
      final docRef = await _getOrgCollection('events').add({
        'name': name,
        'description': description ?? '',
        'type': type,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
      });
      return docRef.id;
    } catch (e) {
      print('Error creating event: $e');
      return null;
    }
  }

  /// Get all events for the organization
  static Future<List<VotingEvent>> getAllEvents() async {
    try {
      final snapshot = await _getOrgCollection(
        'events',
      ).orderBy('createdAt', descending: true).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return VotingEvent(
          id: doc.id,
          name: data['name'] as String,
          description: data['description'] as String? ?? '',
          type: data['type'] as String? ?? 'general',
          status: data['status'] as String? ?? 'active',
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          endDate: (data['endDate'] as Timestamp?)?.toDate(),
        );
      }).toList();
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  /// Get all events (legacy method for compatibility)
  static Future<List<Map<String, dynamic>>> getEvents() async {
    try {
      final snapshot = await _getOrgCollection(
        'events',
      ).orderBy('createdAt', descending: true).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] as String,
          'description': data['description'] as String? ?? '',
          'type': data['type'] as String? ?? 'general',
          'status': data['status'] as String? ?? 'active',
          'createdAt': data['createdAt'],
          'endDate': data['endDate'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  /// Get a specific event
  static Future<Map<String, dynamic>?> getEvent(String eventId) async {
    try {
      final doc = await _getOrgCollection('events').doc(eventId).get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return {
        'id': doc.id,
        'name': data['name'] as String,
        'description': data['description'] as String? ?? '',
        'type': data['type'] as String? ?? 'general',
        'status': data['status'] as String? ?? 'active',
        'createdAt': data['createdAt'],
        'endDate': data['endDate'],
      };
    } catch (e) {
      print('Error fetching event: $e');
      return null;
    }
  }

  /// Archive an event (mark as archived instead of deleting)
  static Future<bool> archiveEvent(String eventId) async {
    try {
      await _getOrgCollection('events').doc(eventId).update({
        'status': 'archived',
        'archivedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error archiving event: $e');
      return false;
    }
  }

  /// Duplicate an event (copy categories and nominees, but not votes)
  static Future<String?> duplicateEvent(String eventId, String newName) async {
    try {
      // Get original event
      final originalEvent = await _getOrgCollection(
        'events',
      ).doc(eventId).get();
      if (!originalEvent.exists) return null;

      final originalData = originalEvent.data()!;

      // Create new event
      final newEventRef = await _getOrgCollection('events').add({
        'name': newName,
        'description': originalData['description'] ?? '',
        'type': originalData['type'] ?? 'general',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'endDate': originalData['endDate'],
      });

      final newEventId = newEventRef.id;

      // Copy categories
      final categoriesSnapshot = await _getOrgCollection(
        'events',
      ).doc(eventId).collection('categories').get();

      for (var catDoc in categoriesSnapshot.docs) {
        await _getOrgCollection('events')
            .doc(newEventId)
            .collection('categories')
            .doc(catDoc.id)
            .set(catDoc.data());
      }

      // Copy nominees
      final nomineesSnapshot = await _getOrgCollection(
        'events',
      ).doc(eventId).collection('nominees').get();

      for (var nomDoc in nomineesSnapshot.docs) {
        await _getOrgCollection('events')
            .doc(newEventId)
            .collection('nominees')
            .doc(nomDoc.id)
            .set(nomDoc.data());
      }

      return newEventId;
    } catch (e) {
      print('Error duplicating event: $e');
      return null;
    }
  }

  /// Delete an event and all its data
  static Future<bool> deleteEvent(String eventId) async {
    try {
      final eventRef = _getOrgCollection('events').doc(eventId);

      // Delete subcollections
      final batch = _firestore.batch();

      // Delete categories
      final categories = await eventRef.collection('categories').get();
      for (var doc in categories.docs) {
        batch.delete(doc.reference);
      }

      // Delete nominees
      final nominees = await eventRef.collection('nominees').get();
      for (var doc in nominees.docs) {
        batch.delete(doc.reference);
      }

      // Delete votes
      final votes = await eventRef.collection('votes').get();
      for (var doc in votes.docs) {
        batch.delete(doc.reference);
      }

      // Delete access codes
      final accessCodes = await eventRef.collection('accessCodes').get();
      for (var doc in accessCodes.docs) {
        batch.delete(doc.reference);
      }

      // Delete event document
      batch.delete(eventRef);

      await batch.commit();
      return true;
    } catch (e) {
      print('Error deleting event: $e');
      return false;
    }
  }

  /// Reset event votes (delete votes and reset access codes to unused)
  static Future<bool> resetEventData(String eventId) async {
    try {
      final eventRef = _getOrgCollection('events').doc(eventId);

      // Delete all votes
      final votesSnapshot = await eventRef.collection('votes').get();
      final batch = _firestore.batch();

      for (var doc in votesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Reset all access codes for this event to unused
      final accessCodesSnapshot = await eventRef
          .collection('accessCodes')
          .get();

      final resetBatch = _firestore.batch();
      for (var doc in accessCodesSnapshot.docs) {
        resetBatch.update(doc.reference, {
          'used': false,
          'usedAt': FieldValue.delete(),
        });
      }

      await resetBatch.commit();
      return true;
    } catch (e) {
      print('Error resetting event data: $e');
      return false;
    }
  }

  /// Clear all event data (categories, nominees, votes, and access codes)
  static Future<bool> clearEventData(String eventId) async {
    try {
      final eventRef = _getOrgCollection('events').doc(eventId);

      // Use batch to delete all subcollections
      final batch = _firestore.batch();

      // Delete categories
      final categories = await eventRef.collection('categories').get();
      for (var doc in categories.docs) {
        batch.delete(doc.reference);
      }

      // Delete nominees
      final nominees = await eventRef.collection('nominees').get();
      for (var doc in nominees.docs) {
        batch.delete(doc.reference);
      }

      // Delete votes
      final votes = await eventRef.collection('votes').get();
      for (var doc in votes.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Delete all access codes for this event
      final accessCodesSnapshot = await eventRef
          .collection('accessCodes')
          .get();

      final codesBatch = _firestore.batch();
      for (var doc in accessCodesSnapshot.docs) {
        codesBatch.delete(doc.reference);
      }

      await codesBatch.commit();
      return true;
    } catch (e) {
      print('Error clearing event data: $e');
      return false;
    }
  }

  // ==================== ACCESS CODES ====================

  static Future<String> generateAccessCode({
    required String name,
    required String eventId,
    required String eventName,
  }) async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String code;

    // Generate unique code
    do {
      code = List.generate(
        8,
        (index) => chars[random.nextInt(chars.length)],
      ).join();
    } while (await _codeExists(eventId, code));

    try {
      await _getOrgCollection(
        'events',
      ).doc(eventId).collection('accessCodes').doc(code).set({
        'eventId': eventId,
        'eventName': eventName,
        'generatedFor': name,
        'generated': FieldValue.serverTimestamp(),
        'used': false,
      });
      return code;
    } catch (e) {
      print('Error generating access code: $e');
      rethrow;
    }
  }

  static Future<bool> _codeExists(String eventId, String code) async {
    try {
      final doc = await _getOrgCollection(
        'events',
      ).doc(eventId).collection('accessCodes').doc(code).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Find access code across all events in all organizations (for user login)
  static Future<AccessCode?> findAccessCode(String code) async {
    try {
      // Search across all organizations
      final orgsSnapshot = await _firestore.collection('organizations').get();

      for (var orgDoc in orgsSnapshot.docs) {
        // Search across all events in this organization
        final eventsSnapshot = await orgDoc.reference
            .collection('events')
            .get();

        for (var eventDoc in eventsSnapshot.docs) {
          final codeDoc = await eventDoc.reference
              .collection('accessCodes')
              .doc(code)
              .get();

          if (codeDoc.exists) {
            final data = codeDoc.data()!;
            if (data['used'] != true) {
              // Set the organization context
              _currentOrgId = orgDoc.id;

              return AccessCode(
                eventId: data['eventId'] as String,
                eventName: data['eventName'] as String,
                code: code,
                generatedFor: data['generatedFor'] as String,
                generated: (data['generated'] as Timestamp).toDate(),
                used: false,
              );
            }
          }
        }
      }
      return null;
    } catch (e) {
      print('Error finding access code: $e');
      return null;
    }
  }

  /// Find access code within current organization and specific event
  static Future<AccessCode?> findAccessCodeInEvent(
    String eventId,
    String code,
  ) async {
    try {
      final doc = await _getOrgCollection(
        'events',
      ).doc(eventId).collection('accessCodes').doc(code).get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      if (data['used'] == true) return null;

      return AccessCode(
        eventId: data['eventId'] as String,
        eventName: data['eventName'] as String,
        code: code,
        generatedFor: data['generatedFor'] as String,
        generated: (data['generated'] as Timestamp).toDate(),
        used: false,
      );
    } catch (e) {
      print('Error finding access code: $e');
      return null;
    }
  }

  /// Get all access codes for a specific event
  static Future<List<AccessCode>> getAccessCodes(String eventId) async {
    try {
      final snapshot = await _getOrgCollection('events')
          .doc(eventId)
          .collection('accessCodes')
          .orderBy('generated', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AccessCode(
          eventId: data['eventId'] as String,
          eventName: data['eventName'] as String,
          code: doc.id,
          generatedFor: data['generatedFor'] as String,
          generated: (data['generated'] as Timestamp).toDate(),
          used: data['used'] as bool? ?? false,
        );
      }).toList();
    } catch (e) {
      print('Error fetching access codes: $e');
      return [];
    }
  }

  /// Get all access codes across all events (for admin dashboard)
  static Future<List<AccessCode>> getAllAccessCodes() async {
    try {
      final eventsSnapshot = await _getOrgCollection('events').get();
      List<AccessCode> allCodes = [];

      for (var eventDoc in eventsSnapshot.docs) {
        final codesSnapshot = await eventDoc.reference
            .collection('accessCodes')
            .orderBy('generated', descending: true)
            .get();

        for (var codeDoc in codesSnapshot.docs) {
          final data = codeDoc.data();
          allCodes.add(
            AccessCode(
              eventId: data['eventId'] as String,
              eventName: data['eventName'] as String,
              code: codeDoc.id,
              generatedFor: data['generatedFor'] as String,
              generated: (data['generated'] as Timestamp).toDate(),
              used: data['used'] as bool? ?? false,
            ),
          );
        }
      }

      return allCodes;
    } catch (e) {
      print('Error fetching all access codes: $e');
      return [];
    }
  }

  // ==================== VOTES ====================

  static Future<bool> checkIfAlreadyVoted(String code) async {
    try {
      final doc = await _getOrgCollection('votes').doc(code).get();
      return doc.exists;
    } catch (e) {
      print('Error checking vote status: $e');
      return false;
    }
  }

  /// Check if user has already voted for a specific event
  static Future<bool> checkIfAlreadyVotedForEvent(
    String eventId,
    String code,
  ) async {
    try {
      final doc = await _getOrgCollection(
        'events',
      ).doc(eventId).collection('votes').doc(code).get();
      return doc.exists;
    } catch (e) {
      print('Error checking event vote status: $e');
      return false;
    }
  }

  static Future<bool> submitVotes(
    String eventId,
    String code,
    List<Vote> votes,
  ) async {
    try {
      // Store votes under the event
      await _getOrgCollection(
        'events',
      ).doc(eventId).collection('votes').doc(code).set({
        'votes': votes
            .map(
              (v) => {
                'categoryId': v.categoryId,
                'first': v.first,
                'second': v.second,
                'third': v.third,
              },
            )
            .toList(),
        'submittedAt': FieldValue.serverTimestamp(),
      });

      // Mark access code as used (now under event)
      await _getOrgCollection('events')
          .doc(eventId)
          .collection('accessCodes')
          .doc(code)
          .update({'used': true, 'usedAt': FieldValue.serverTimestamp()});

      return true;
    } catch (e) {
      print('Error submitting votes: $e');
      return false;
    }
  }

  // ==================== STATISTICS ====================

  /// Get overall statistics across all events in the organization
  static Future<Map<String, dynamic>> getOverallStatistics() async {
    try {
      final eventsSnapshot = await _getOrgCollection('events').get();

      int totalEvents = eventsSnapshot.docs.length;
      int totalNominees = 0;
      int totalCategories = 0;
      int totalVotes = 0;
      int totalAccessCodes = 0;
      int usedAccessCodes = 0;

      // Count nominees, categories, votes, and access codes across all events
      for (var eventDoc in eventsSnapshot.docs) {
        final eventRef = eventDoc.reference;

        final nomineesSnapshot = await eventRef.collection('nominees').get();
        totalNominees += nomineesSnapshot.docs.length;

        final categoriesSnapshot = await eventRef
            .collection('categories')
            .get();
        totalCategories += categoriesSnapshot.docs.length;

        final votesSnapshot = await eventRef.collection('votes').get();
        totalVotes += votesSnapshot.docs.length;

        final accessCodesSnapshot = await eventRef
            .collection('accessCodes')
            .get();
        totalAccessCodes += accessCodesSnapshot.docs.length;
        usedAccessCodes += accessCodesSnapshot.docs
            .where((doc) => doc.data()['used'] == true)
            .length;
      }

      return {
        'totalEvents': totalEvents,
        'totalNominees': totalNominees,
        'totalCategories': totalCategories,
        'totalVotes': totalVotes,
        'totalAccessCodes': totalAccessCodes,
        'usedAccessCodes': usedAccessCodes,
      };
    } catch (e) {
      print('Error fetching overall statistics: $e');
      return {};
    }
  }

  /// Get statistics for a specific event
  static Future<EventStatistics> getEventStatistics(String eventId) async {
    try {
      final eventRef = _getOrgCollection('events').doc(eventId);

      final nomineesSnapshot = await eventRef.collection('nominees').get();
      final categoriesSnapshot = await eventRef.collection('categories').get();
      final votesSnapshot = await eventRef.collection('votes').get();

      // Count access codes for this event (now under event)
      final accessCodesSnapshot = await eventRef
          .collection('accessCodes')
          .get();

      final usedCodes = accessCodesSnapshot.docs
          .where((doc) => doc.data()['used'] == true)
          .length;

      return EventStatistics(
        totalNominees: nomineesSnapshot.docs.length,
        totalCategories: categoriesSnapshot.docs.length,
        totalAccessCodes: accessCodesSnapshot.docs.length,
        usedCodes: usedCodes,
        totalVotes: votesSnapshot.docs.length,
      );
    } catch (e) {
      print('Error fetching event statistics: $e');
      // Return empty statistics on error
      return EventStatistics(
        totalNominees: 0,
        totalCategories: 0,
        totalAccessCodes: 0,
        usedCodes: 0,
        totalVotes: 0,
      );
    }
  }

  static Future<List<VoteResult>> getResults() async {
    try {
      final categoriesSnapshot = await _getOrgCollection('categories').get();
      final nomineesSnapshot = await _getOrgCollection('nominees').get();
      final votesSnapshot = await _getOrgCollection('votes').get();

      List<VoteResult> results = [];

      for (var categoryDoc in categoriesSnapshot.docs) {
        Map<String, int> scores = {};

        // Initialize scores for all nominees
        for (var nomineeDoc in nomineesSnapshot.docs) {
          scores[nomineeDoc.data()['name'] as String] = 0;
        }

        // Calculate scores from all votes
        for (var voteDoc in votesSnapshot.docs) {
          final voteData = voteDoc.data();
          final votesList = voteData['votes'] as List<dynamic>;

          final categoryVote = votesList.firstWhere(
            (v) => v['categoryId'] == categoryDoc.id,
            orElse: () => null,
          );

          if (categoryVote != null) {
            final first = categoryVote['first'] as String?;
            final second = categoryVote['second'] as String?;
            final third = categoryVote['third'] as String?;

            if (first != null) scores[first] = (scores[first] ?? 0) + 5;
            if (second != null) scores[second] = (scores[second] ?? 0) + 3;
            if (third != null) scores[third] = (scores[third] ?? 0) + 1;
          }
        }

        results.add(
          VoteResult(
            categoryId: categoryDoc.id,
            categoryName: categoryDoc.data()['name'] as String,
            scores: scores,
          ),
        );
      }

      return results;
    } catch (e) {
      print('Error fetching results: $e');
      return [];
    }
  }

  /// Get results for a specific event
  static Future<List<VoteResult>> getResultsForEvent(String eventId) async {
    try {
      final categoriesSnapshot = await _getOrgCollection(
        'events',
      ).doc(eventId).collection('categories').get();

      final nomineesSnapshot = await _getOrgCollection(
        'events',
      ).doc(eventId).collection('nominees').get();

      final votesSnapshot = await _getOrgCollection(
        'events',
      ).doc(eventId).collection('votes').get();

      List<VoteResult> results = [];

      for (var categoryDoc in categoriesSnapshot.docs) {
        Map<String, int> scores = {};

        // Initialize scores for all nominees
        for (var nomineeDoc in nomineesSnapshot.docs) {
          scores[nomineeDoc.data()['name'] as String] = 0;
        }

        // Calculate scores from all votes
        for (var voteDoc in votesSnapshot.docs) {
          final voteData = voteDoc.data();
          final votesList = voteData['votes'] as List<dynamic>;

          final categoryVote = votesList.firstWhere(
            (v) => v['categoryId'] == categoryDoc.id,
            orElse: () => null,
          );

          if (categoryVote != null) {
            final first = categoryVote['first'] as String?;
            final second = categoryVote['second'] as String?;
            final third = categoryVote['third'] as String?;

            if (first != null) scores[first] = (scores[first] ?? 0) + 5;
            if (second != null) scores[second] = (scores[second] ?? 0) + 3;
            if (third != null) scores[third] = (scores[third] ?? 0) + 1;
          }
        }

        results.add(
          VoteResult(
            categoryId: categoryDoc.id,
            categoryName: categoryDoc.data()['name'] as String,
            scores: scores,
          ),
        );
      }

      return results;
    } catch (e) {
      print('Error fetching event results: $e');
      return [];
    }
  }
}
