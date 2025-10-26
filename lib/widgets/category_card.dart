
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/nominee.dart';
import '../models/vote.dart';
import 'vote_selector.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final List<Nominee> nominees;
  final Vote vote;
  final Function(Vote) onVoteChanged;

  const CategoryCard({
    Key? key,
    required this.category,
    required this.nominees,
    required this.vote,
    required this.onVoteChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isComplete = vote.first != null && vote.second != null && vote.third != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isComplete
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isComplete ? Icons.check_circle_rounded : Icons.star_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                if (isComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Complete',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Select 3 nominees: 1st (5pts) • 2nd (3pts) • 3rd (1pt)',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            VoteSelector(
              label: '1st Choice',
              points: 5,
              nominees: nominees,
              selectedNominee: vote.first,
              excludedNominees: [vote.second, vote.third].whereType<String>().toList(),
              onChanged: (nominee) {
                onVoteChanged(Vote(
                  categoryId: vote.categoryId,
                  first: nominee,
                  second: vote.second,
                  third: vote.third,
                ));
              },
            ),
            const SizedBox(height: 16),
            VoteSelector(
              label: '2nd Choice',
              points: 3,
              nominees: nominees,
              selectedNominee: vote.second,
              excludedNominees: [vote.first, vote.third].whereType<String>().toList(),
              onChanged: (nominee) {
                onVoteChanged(Vote(
                  categoryId: vote.categoryId,
                  first: vote.first,
                  second: nominee,
                  third: vote.third,
                ));
              },
            ),
            const SizedBox(height: 16),
            VoteSelector(
              label: '3rd Choice',
              points: 1,
              nominees: nominees,
              selectedNominee: vote.third,
              excludedNominees: [vote.first, vote.second].whereType<String>().toList(),
              onChanged: (nominee) {
                onVoteChanged(Vote(
                  categoryId: vote.categoryId,
                  first: vote.first,
                  second: vote.second,
                  third: nominee,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}