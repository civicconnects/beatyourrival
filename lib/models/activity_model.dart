// lib/models/activity_model.dart
// --- START COPY & PASTE HERE ---

import 'package:cloud_firestore/cloud_firestore.dart';

// Defines the types of activities we can log
enum ActivityType {
  challengeSent,
  challengeAccepted,
  challengeDeclined,
  challengeCanceled,
  battleCompleted,
  friendRequest,
  friendAccepted
}

class ActivityModel {
  final String id;
  final ActivityType type;
  final DateTime timestamp;
  // List of UIDs involved (e.g., [challenger, opponent])
  final List<String> participants; 
  final String actorUid; // The user who *performed* the action
  final String? targetUid; // The user who *received* the action (optional)
  final String? battleId; // The battle this is related to (optional)
  final int? challengerScore; // Optional
  final int? opponentScore; // Optional

  ActivityModel({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.participants,
    required this.actorUid,
    this.targetUid,
    this.battleId,
    this.challengerScore,
    this.opponentScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'participants': participants,
      'actorUid': actorUid,
      'targetUid': targetUid,
      'battleId': battleId,
      'challengerScore': challengerScore,
      'opponentScore': opponentScore,
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map, String id) {
    return ActivityModel(
      id: id,
      type: ActivityType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ActivityType.challengeSent,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      participants: List<String>.from(map['participants'] ?? []),
      actorUid: map['actorUid'] as String? ?? '',
      targetUid: map['targetUid'] as String?,
      battleId: map['battleId'] as String?,
      challengerScore: map['challengerScore'] as int?,
      opponentScore: map['opponentScore'] as int?,
    );
  }
}
// --- END COPY & PASTE HERE ---