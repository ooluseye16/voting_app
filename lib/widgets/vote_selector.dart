import 'package:flutter/material.dart';

import '../models/nominee.dart';

class VoteSelector extends StatelessWidget {
  final String label;
  final int points;
  final List<Nominee> nominees;
  final String? selectedNominee;
  final List<String> excludedNominees;
  final Function(String?) onChanged;

  const VoteSelector({
    super.key,
    required this.label,
    required this.points,
    required this.nominees,
    required this.selectedNominee,
    required this.excludedNominees,
    required this.onChanged,
  });

  Color _getPointsColor() {
    switch (points) {
      case 5:
        return const Color(0xFFFFD700); // Gold
      case 3:
        return const Color(0xFFC0C0C0); // Silver
      case 1:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getPointsColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$points pts',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getPointsColor().withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: selectedNominee,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            prefixIcon: Icon(
              selectedNominee != null
                  ? Icons.person_rounded
                  : Icons.person_outline_rounded,
              color: selectedNominee != null
                  ? const Color(0xFF6366F1)
                  : Colors.grey,
            ),
          ),
          hint: const Text('Select nominee'),
          isExpanded: true,
          items: nominees
              .where((nominee) => !excludedNominees.contains(nominee.name))
              .map(
                (nominee) => DropdownMenuItem(
                  value: nominee.name,
                  child: Text(
                    nominee.name,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
