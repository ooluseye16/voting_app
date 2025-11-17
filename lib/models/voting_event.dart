// lib/models/voting_event.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class VotingEvent {
  final String id;
  final String name;
  final String description;
  final String type;
  final String status;
  final DateTime createdAt;
  final DateTime? endDate;

  VotingEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    required this.createdAt,
    this.endDate,
  });

  factory VotingEvent.fromMap(String id, Map<String, dynamic> data) {
    return VotingEvent(
      id: id,
      name: data['name'] as String,
      description: data['description'] as String? ?? '',
      type: data['type'] as String? ?? 'general',
      status: data['status'] as String? ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    };
  }
}
