import 'package:cloud_firestore/cloud_firestore.dart';

class AccessCode {
  final String code;
  final String generatedFor;
  final String eventId;
  final String eventName;
  final DateTime generated;
  final bool used;

  AccessCode({
    required this.code,
    required this.generatedFor,
    required this.eventId,
    required this.eventName,
    required this.generated,
    this.used = false,
  });

  factory AccessCode.fromFirestore(Map<String, dynamic> data) {
    return AccessCode(
      code: data['code'] ?? 'UNKNOWN',
      generatedFor: data['generatedFor'] ?? 'Unknown',
      eventId: data['eventId'] ?? '',
      eventName: data['eventName'] ?? 'Unknown Event',
      generated: data['generated'] != null
          ? (data['generated'] as Timestamp).toDate()
          : DateTime.now(),
      used: data['used'] ?? false,
    );
  }
}