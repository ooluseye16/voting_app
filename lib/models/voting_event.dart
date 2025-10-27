import 'package:cloud_firestore/cloud_firestore.dart';

class VotingEvent {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final bool active;
  final DateTime? endDate;
  final String type;

  VotingEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    this.active = true,
    this.endDate,
    this.type = 'general',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'createdAt': createdAt,
    'active': active,
    'endDate': endDate,
    'type': type,
  };

  factory VotingEvent.fromFirestore(String id, Map<String, dynamic> data) =>
      VotingEvent(
        id: id,
        name: data['name'] ?? 'Unnamed Event',
        description: data['description'] ?? '',
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        active: data['active'] ?? true,
        endDate: data['endDate'] != null
            ? (data['endDate'] as Timestamp).toDate()
            : null,
        type: data['type'] ?? 'general',
      );
}