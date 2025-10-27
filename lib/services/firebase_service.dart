// File: lib/services/firebase_service.dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/access_code.dart';
import '../models/category.dart';
import '../models/nominee.dart';
import '../models/vote.dart';
import '../models/vote_result.dart';

class FirebaseService {
  static const String adminCode = 'ADMIN123';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============= Authentication =============

  static Future<String> validateCodeAndGetRole(String code) async {
    try {
      if (code == adminCode) return 'admin';

      final querySnapshot = await _firestore
          .collection('accessCodes')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return 'invalid';

      final codeData = querySnapshot.docs.first.data();
      if (codeData['used'] == true) return 'invalid';

      return 'user';
    } catch (e) {
      print('Error validating code: $e');
      return 'invalid';
    }
  }

  static Future<bool> checkIfAlreadyVoted(String code) async {
    try {
      final querySnapshot = await _firestore
          .collection('votes')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking vote status: $e');
      return false;
    }
  }

  // ============= Nominees =============

  static Future<List<Nominee>> getNominees() async {
    try {
      final querySnapshot = await _firestore
          .collection('nominees')
          .orderBy('name')
          .get();

      return querySnapshot.docs.map((doc) {
        return Nominee(id: doc.id, name: doc.data()['name'] ?? 'Unknown');
      }).toList();
    } catch (e) {
      print('Error getting nominees: $e');
      return [];
    }
  }

  static Future<bool> addNominee(String name) async {
    try {
      // Add nominee with temporary admin verification field
      final docRef = await _firestore.collection('nominees').add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'adminCode': adminCode,
      });

      // Remove the admin code after creation (keeps data clean)
      await docRef.update({'adminCode': FieldValue.delete()});

      print('✅ Nominee added successfully: $name');
      return true;
    } catch (e) {
      print('❌ Error adding nominee: $e');
      return false;
    }
  }

  static Future<bool> deleteNominee(String id) async {
    try {
      await _firestore.collection('nominees').doc(id).delete();
      print('✅ Nominee deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting nominee: $e');
      return false;
    }
  }

  // ============= Categories =============

  static Future<List<Category>> getCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection('categories')
          .orderBy('createdAt')
          .get();

      return querySnapshot.docs.map((doc) {
        return Category(
          id: doc.id,
          name: doc.data()['name'] ?? 'Unknown Category',
        );
      }).toList();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  static Future<bool> addCategory(String name) async {
    try {
      final docRef = await _firestore.collection('categories').add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'adminCode': adminCode,
      });

      await docRef.update({'adminCode': FieldValue.delete()});

      print('✅ Category added successfully: $name');
      return true;
    } catch (e) {
      print('❌ Error adding category: $e');
      return false;
    }
  }

  static Future<bool> deleteCategory(String id) async {
    try {
      await _firestore.collection('categories').doc(id).delete();
      print('✅ Category deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting category: $e');
      return false;
    }
  }

  // ============= Access Codes =============

  static Future<String> generateAccessCode(String name) async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String code;
    int attempts = 0;
    const maxAttempts = 10;

    // Generate unique code with retry limit
    do {
      code = List.generate(
        8,
        (index) => chars[random.nextInt(chars.length)],
      ).join();

      final existing = await _firestore
          .collection('accessCodes')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) break;

      attempts++;
      if (attempts >= maxAttempts) {
        throw Exception(
          'Failed to generate unique code after $maxAttempts attempts',
        );
      }
    } while (true);

    try {
      final docRef = await _firestore.collection('accessCodes').add({
        'code': code,
        'generatedFor': name,
        'generated': FieldValue.serverTimestamp(),
        'used': false,
        'adminCode': adminCode,
      });

      await docRef.update({'adminCode': FieldValue.delete()});

      print('✅ Access code generated: $code for $name');
      return code;
    } catch (e) {
      print('❌ Error generating access code: $e');
      rethrow;
    }
  }

  static Future<List<AccessCode>> getAccessCodes() async {
    try {
      final querySnapshot = await _firestore
          .collection('accessCodes')
          .orderBy('generated', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return AccessCode(
          code: data['code'] ?? 'UNKNOWN',
          generatedFor: data['generatedFor'] ?? 'Unknown',
          generated: data['generated'] != null
              ? (data['generated'] as Timestamp).toDate()
              : DateTime.now(),
          used: data['used'] ?? false,
        );
      }).toList();
    } catch (e) {
      print('Error getting access codes: $e');
      return [];
    }
  }

  static Future<bool> deleteAccessCode(String code) async {
    try {
      final querySnapshot = await _firestore
          .collection('accessCodes')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
        print('✅ Access code deleted: $code');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error deleting access code: $e');
      return false;
    }
  }

  // ============= Votes =============

  static Future<bool> submitVotes(String code, List<Vote> votes) async {
    try {
      // Check if already voted
      final existingVote = await _firestore
          .collection('votes')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (existingVote.docs.isNotEmpty) {
        print('⚠️ Code has already been used to vote');
        return false;
      }

      // Add vote document
      await _firestore.collection('votes').add({
        'code': code,
        'submittedAt': FieldValue.serverTimestamp(),
        'votes': votes.map((v) => v.toJson()).toList(),
      });

      // Mark access code as used
      final codeQuery = await _firestore
          .collection('accessCodes')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (codeQuery.docs.isNotEmpty) {
        await codeQuery.docs.first.reference.update({
          'used': true,
          'usedAt': FieldValue.serverTimestamp(),
        });
      }

      print('✅ Votes submitted successfully for code: $code');
      return true;
    } catch (e) {
      print('❌ Error submitting votes: $e');
      return false;
    }
  }

  static Future<List<VoteResult>> getResults() async {
    try {
      // Get all data in parallel for better performance
      final results = await Future.wait([
        getCategories(),
        getNominees(),
        _firestore.collection('votes').get(),
      ]);

      final categories = results[0] as List<Category>;
      final nominees = results[1] as List<Nominee>;
      final votesSnapshot = results[2] as QuerySnapshot;

      List<VoteResult> voteResults = [];

      for (var category in categories) {
        Map<String, int> scores = {};

        // Initialize all nominees with 0 points
        for (var nominee in nominees) {
          scores[nominee.name] = 0;
        }

        // Calculate points from all votes
        for (var voteDoc in votesSnapshot.docs) {
          final voteData = voteDoc.data() as Map<String, dynamic>;
          final votesList = voteData['votes'] as List<dynamic>? ?? [];

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

        voteResults.add(
          VoteResult(
            categoryId: category.id,
            categoryName: category.name,
            scores: scores,
          ),
        );
      }

      print('✅ Results calculated for ${voteResults.length} categories');
      return voteResults;
    } catch (e) {
      print('❌ Error getting results: $e');
      return [];
    }
  }

  // ============= Statistics =============

  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final results = await Future.wait([
        _firestore.collection('nominees').get(),
        _firestore.collection('categories').get(),
        _firestore.collection('accessCodes').get(),
        _firestore.collection('votes').get(),
      ]);

      final nomineesCount = results[0].docs.length;
      final categoriesCount = results[1].docs.length;
      final accessCodesSnapshot = results[2] as QuerySnapshot;
      final votesCount = results[3].docs.length;

      final usedCodes = accessCodesSnapshot.docs
          .where((doc) => (doc.data() as Map)['used'] == true)
          .length;
      final unusedCodes = accessCodesSnapshot.docs.length - usedCodes;

      return {
        'totalNominees': nomineesCount,
        'totalCategories': categoriesCount,
        'totalAccessCodes': accessCodesSnapshot.docs.length,
        'usedCodes': usedCodes,
        'unusedCodes': unusedCodes,
        'totalVotes': votesCount,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {};
    }
  }

  // ============= Utility Methods =============

  static Future<bool> resetAllVotes() async {
    try {
      // Delete all votes
      final votesSnapshot = await _firestore.collection('votes').get();
      for (var doc in votesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Reset all access codes
      final codesSnapshot = await _firestore.collection('accessCodes').get();
      for (var doc in codesSnapshot.docs) {
        await doc.reference.update({
          'used': false,
          'usedAt': FieldValue.delete(),
        });
      }

      print('✅ All votes reset successfully');
      return true;
    } catch (e) {
      print('❌ Error resetting votes: $e');
      return false;
    }
  }

  static Future<bool> checkFirebaseConnection() async {
    try {
      await _firestore.collection('admin').doc('config').get();
      return true;
    } catch (e) {
      print('❌ Firebase connection error: $e');
      return false;
    }
  }
}
