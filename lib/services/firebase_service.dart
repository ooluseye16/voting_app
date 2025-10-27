import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/nominee.dart';
import '../models/category.dart';
import '../models/vote.dart';
import '../models/access_code.dart';
import '../models/vote_result.dart';

class FirebaseService {
  static const String adminCode = 'ADMIN123';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============= Authentication =============

  static Future<String> validateCodeAndGetRole(String code) async {
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
  }

  static Future<bool> checkIfAlreadyVoted(String code) async {
    final querySnapshot = await _firestore
        .collection('votes')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  // ============= Nominees =============

  static Future<List<Nominee>> getNominees() async {
    final querySnapshot =
        await _firestore.collection('nominees').orderBy('name').get();

    return querySnapshot.docs.map((doc) {
      return Nominee(
        id: doc.id,
        name: doc.data()['name'],
      );
    }).toList();
  }

  static Future<bool> addNominee(String name) async {
    try {
      final docRef = await _firestore.collection('nominees').add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'adminCode': adminCode, // required for rule verification
      });

      // Optional: remove adminCode after rule check
      await docRef.update({'adminCode': FieldValue.delete()});
      return true;
    } catch (e) {
      print('Error adding nominee: $e');
      return false;
    }
  }

  static Future<bool> deleteNominee(String id) async {
    try {
      await _firestore
          .collection('nominees')
          .doc(id)
          .delete(); // adminCode not needed for delete
      return true;
    } catch (e) {
      print('Error deleting nominee: $e');
      return false;
    }
  }

  // ============= Categories =============

  static Future<List<Category>> getCategories() async {
    final querySnapshot =
        await _firestore.collection('categories').orderBy('createdAt').get();

    return querySnapshot.docs.map((doc) {
      return Category(
        id: doc.id,
        name: doc.data()['name'],
      );
    }).toList();
  }

  static Future<bool> addCategory(String name) async {
    try {
      final docRef = await _firestore.collection('categories').add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'adminCode': adminCode,
      });

      await docRef.update({'adminCode': FieldValue.delete()});
      return true;
    } catch (e) {
      print('Error adding category: $e');
      return false;
    }
  }

  static Future<bool> deleteCategory(String id) async {
    try {
      await _firestore.collection('categories').doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting category: $e');
      return false;
    }
  }

  // ============= Access Codes =============

  static Future<String> generateAccessCode(String name) async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String code;

    // Generate unique code
    do {
      code = List.generate(8, (index) => chars[random.nextInt(chars.length)])
          .join();

      final existing = await _firestore
          .collection('accessCodes')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) break;
    } while (true);

    final docRef = await _firestore.collection('accessCodes').add({
      'code': code,
      'generatedFor': name,
      'generated': FieldValue.serverTimestamp(),
      'used': false,
      'adminCode': adminCode,
    });

    await docRef.update({'adminCode': FieldValue.delete()});
    return code;
  }

  static Future<List<AccessCode>> getAccessCodes() async {
    final querySnapshot = await _firestore
        .collection('accessCodes')
        .orderBy('generated', descending: true)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return AccessCode(
        code: data['code'],
        generatedFor: data['generatedFor'],
        generated: (data['generated'] as Timestamp).toDate(),
        used: data['used'] ?? false,
      );
    }).toList();
  }

  // ============= Votes =============

  static Future<bool> submitVotes(String code, List<Vote> votes) async {
    try {
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

      return true;
    } catch (e) {
      print('Error submitting votes: $e');
      return false;
    }
  }

  static Future<List<VoteResult>> getResults() async {
    try {
      // Get all categories
      final categories = await getCategories();

      // Get all nominees
      final nominees = await getNominees();

      // Get all votes
      final votesSnapshot = await _firestore.collection('votes').get();

      List<VoteResult> results = [];

      for (var category in categories) {
        Map<String, int> scores = {};

        // Initialize all nominees with 0 points
        for (var nominee in nominees) {
          scores[nominee.name] = 0;
        }

        // Calculate points from all votes
        for (var voteDoc in votesSnapshot.docs) {
          final voteData = voteDoc.data();
          final votesList = voteData['votes'] as List<dynamic>;

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

        results.add(VoteResult(
          categoryId: category.id,
          categoryName: category.name,
          scores: scores,
        ));
      }

      return results;
    } catch (e) {
      print('Error getting results: $e');
      return [];
    }
  }
}
