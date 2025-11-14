// lib/models/activity_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType { challengeSent, challengeAccepted, challengeDeclined, battleCompleted }

class ActivityModel {
  final String id;
  final String battleId;
  final String challengerUid;
  final String opponentUid;
  final String? winnerUid;
  final int? challengerScore; // <-- ADDED
  final int? opponentScore;   // <-- ADDED
  final ActivityType type;
  final DateTime timestamp;

  ActivityModel({
    required this.id,
    required this.battleId,
    required this.challengerUid,
    required this.opponentUid,
    this.winnerUid,
    this.challengerScore, // <-- ADDED
    this.opponentScore,   // <-- ADDED
    required this.type,
    required this.timestamp,
  });

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'] ?? '',
      battleId: map['battleId'] ?? '',
      challengerUid: map['challengerUid'] ?? '',
      opponentUid: map['opponentUid'] ?? '',
      winnerUid: map['winnerUid'],
      challengerScore: map['challengerScore'], // <-- ADDED
      opponentScore: map['opponentScore'],     // <-- ADDED
      type: ActivityType.values.firstWhere(
          (e) => e.toString().split('.').last == map['type'],
          orElse: () => ActivityType.challengeSent),
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'battleId': battleId,
      'challengerUid': challengerUid,
      'opponentUid': opponentUid,
      'winnerUid': winnerUid,
      'challengerScore': challengerScore, // <-- ADDED
      'opponentScore': opponentScore,     // <-- ADDED
      'type': type.toString().split('.').last,
      'timestamp': timestamp,
    };
  }
}