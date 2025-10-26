import 'dart:math';
import '../models/nominee.dart';
import '../models/category.dart';
import '../models/vote.dart';
import '../models/access_code.dart';
import '../models/vote_result.dart';

class ApiService {
  static const String adminCode = 'ADMIN123';

  static List<Nominee> _nominees = [
    Nominee(id: '1', name: 'John Doe'),
    Nominee(id: '2', name: 'Jane Smith'),
    Nominee(id: '3', name: 'Bob Johnson'),
    Nominee(id: '4', name: 'Alice Williams'),
    Nominee(id: '5', name: 'Sarah Davis'),
  ];

  static List<Category> _categories = [
    Category(id: '1', name: 'Best Analyst'),
    Category(id: '2', name: 'Best Team Player'),
  ];

  static List<AccessCode> _accessCodes = [];
  static Map<String, List<Vote>> _submittedVotes = {};

  static Future<String> validateCodeAndGetRole(String code) async {
    await Future.delayed(const Duration(seconds: 1));
    if (code == adminCode) return 'admin';
    if (_accessCodes.any((ac) => ac.code == code && !ac.used)) return 'user';
    return 'invalid';
  }

  static Future<bool> checkIfAlreadyVoted(String code) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _submittedVotes.containsKey(code);
  }

  static Future<List<Category>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_categories);
  }

  static Future<List<Nominee>> getNominees() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_nominees);
  }

  static Future<bool> submitVotes(String code, List<Vote> votes) async {
    await Future.delayed(const Duration(seconds: 1));
    _submittedVotes[code] = votes;
    final codeIndex = _accessCodes.indexWhere((ac) => ac.code == code);
    if (codeIndex != -1) {
      _accessCodes[codeIndex] = AccessCode(
        code: _accessCodes[codeIndex].code,
        generatedFor: _accessCodes[codeIndex].generatedFor,
        generated: _accessCodes[codeIndex].generated,
        used: true,
      );
    }
    return true;
  }

  static Future<String> generateAccessCode(String name) async {
    await Future.delayed(const Duration(milliseconds: 500));
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String code;
    do {
      code = List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
    } while (_accessCodes.any((ac) => ac.code == code));

    _accessCodes.add(AccessCode(
      code: code,
      generatedFor: name,
      generated: DateTime.now(),
    ));
    return code;
  }

  static Future<List<AccessCode>> getAccessCodes() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_accessCodes);
  }

  static Future<bool> addCategory(String name) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final id = ((_categories.length) + 1).toString();
    _categories.add(Category(id: id, name: name));
    return true;
  }

  static Future<bool> deleteCategory(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _categories.removeWhere((cat) => cat.id == id);
    return true;
  }

  static Future<bool> addNominee(String name) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final id = ((_nominees.length) + 1).toString();
    _nominees.add(Nominee(id: id, name: name));
    return true;
  }

  static Future<bool> deleteNominee(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _nominees.removeWhere((nom) => nom.id == id);
    return true;
  }

  static Future<List<VoteResult>> getResults() async {
    await Future.delayed(const Duration(milliseconds: 500));
    List<VoteResult> results = [];

    for (var category in _categories) {
      Map<String, int> scores = {};
      
      for (var nominee in _nominees) {
        scores[nominee.name] = 0;
      }

      for (var votes in _submittedVotes.values) {
        final categoryVote = votes.firstWhere(
          (v) => v.categoryId == category.id,
          orElse: () => Vote(categoryId: category.id),
        );

        if (categoryVote.first != null) {
          scores[categoryVote.first!] = (scores[categoryVote.first!] ?? 0) + 5;
        }
        if (categoryVote.second != null) {
          scores[categoryVote.second!] = (scores[categoryVote.second!] ?? 0) + 3;
        }
        if (categoryVote.third != null) {
          scores[categoryVote.third!] = (scores[categoryVote.third!] ?? 0) + 1;
        }
      }

      results.add(VoteResult(
        categoryId: category.id,
        categoryName: category.name,
        scores: scores,
      ));
    }

    return results;
  }
}