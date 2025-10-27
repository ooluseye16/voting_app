import 'package:flutter/material.dart';
import 'package:voting_app/services/firebase_service.dart';

import '../../models/category.dart';
import '../../models/nominee.dart';
import '../../models/vote.dart';
import '../../widgets/category_card.dart';
import 'success_page.dart';

class VotingPage extends StatefulWidget {
  final String userCode;
  final String eventId;
  final String eventName;

  const VotingPage({
    super.key,
    required this.userCode,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<VotingPage> createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  List<Category>? _categories;
  List<Nominee>? _nominees;
  Map<String, Vote> _votes = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final categories = await FirebaseService.getCategoriesForEvent(
        widget.eventId,
      );
      final nominees = await FirebaseService.getNomineesForEvent(
        widget.eventId,
      );

      setState(() {
        _categories = categories;
        _nominees = nominees;
        _votes = {for (var c in categories) c.id: Vote(categoryId: c.id)};
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load voting data')),
        );
      }
    }
  }

  bool _canSubmit() {
    return _votes.values.every(
      (vote) => vote.first != null && vote.second != null && vote.third != null,
    );
  }

  int _getCompletedCount() {
    return _votes.values
        .where((v) => v.first != null && v.second != null && v.third != null)
        .length;
  }

  Future<void> _submitVotes() async {
    if (!_canSubmit()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please complete all categories'),
          backgroundColor: Colors.orange.shade600,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final success = await FirebaseService.submitVotes(
        widget.eventId,
        widget.userCode,
        _votes.values.toList(),
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const SuccessPage(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to submit votes')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_categories == null || _categories!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cast Your Votes')),
        body: const Center(child: Text('No categories available')),
      );
    }

    if (_nominees == null || _nominees!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cast Your Votes')),
        body: const Center(child: Text('No nominees available')),
      );
    }

    final total = _categories!.length;
    final completed = _getCompletedCount();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.how_to_vote_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.eventName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.userCode,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '$completed / $total completed',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: completed / total,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF6366F1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _categories!.length,
              itemBuilder: (_, index) {
                final category = _categories![index];
                return CategoryCard(
                  category: category,
                  nominees: _nominees!,
                  vote: _votes[category.id]!,
                  onVoteChanged: (v) {
                    setState(() => _votes[category.id] = v);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting || !_canSubmit()
                      ? null
                      : _submitVotes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Submit All Votes',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
