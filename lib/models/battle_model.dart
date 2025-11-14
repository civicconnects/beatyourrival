// lib/models/battle_model.dart
// --- START COPY & PASTE HERE ---
import 'package:cloud_firestore/cloud_firestore.dart';
import 'move_model.dart'; 

enum BattleStatus { pending, active, completed, declined, rejected }

class BattleModel {
  final String? id;
  final String challengerUid;
  final String opponentUid;
  final String genre;
  final int maxRounds;
  final int currentRound;
  final String currentTurnUid;
  final BattleStatus status;
  final String? winnerUid; 
  
  // FIX: Added final score fields
  final int? challengerFinalScore;
  final int? opponentFinalScore;
  
  final DateTime createdAt;
  final DateTime? completedTimestamp;
  final List<MoveModel> moves; 

  BattleModel({
    this.id,
    required this.challengerUid,
    required this.opponentUid,
    required this.genre,
    required this.maxRounds,
    required this.currentRound,
    required this.currentTurnUid,
    required this.status,
    required this.createdAt, 
    required this.moves,     
    this.winnerUid,
    this.challengerFinalScore, // FIX: Added to constructor
    this.opponentFinalScore, // FIX: Added to constructor
    this.completedTimestamp,
  });

  factory BattleModel.fromMap(Map<String, dynamic> map, {String? id}) {
    BattleStatus parseStatus(String? statusStr) {
      if (statusStr == null) return BattleStatus.pending;
      return BattleStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => BattleStatus.pending,
      );
    }
    
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.parse(date);
      return DateTime.now(); 
    }

    return BattleModel(
      id: id,
      challengerUid: map['challengerUid'] as String? ?? 'unknown',
      opponentUid: map['opponentUid'] as String? ?? 'unknown',
      genre: map['genre'] as String? ?? 'Unknown',
      maxRounds: map['maxRounds'] as int? ?? 3,
      currentRound: map['currentRound'] as int? ?? 1,
      currentTurnUid: map['currentTurnUid'] as String? ?? '',
      status: parseStatus(map['status'] as String?),
      winnerUid: map['winnerUid'] as String?,
      // FIX: Added fromMap logic
      challengerFinalScore: map['challengerFinalScore'] as int?,
      opponentFinalScore: map['opponentFinalScore'] as int?,
      createdAt: parseDate(map['createdAt']),
      completedTimestamp: map['completedTimestamp'] != null ? parseDate(map['completedTimestamp']) : null,
      moves: const [], 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'challengerUid': challengerUid,
      'opponentUid': opponentUid,
      'genre': genre,
      'maxRounds': maxRounds,
      'currentRound': currentRound,
      'currentTurnUid': currentTurnUid,
      'status': status.name,
      'winnerUid': winnerUid,
      // FIX: Added toMap logic
      'challengerFinalScore': challengerFinalScore,
      'opponentFinalScore': opponentFinalScore,
      'createdAt': createdAt,
      'completedTimestamp': completedTimestamp,
    };
  }
}
// --- END COPY & PASTE HERE ---