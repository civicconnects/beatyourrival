import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/battle_model.dart';
import '../models/move_model.dart';
import 'auth_service.dart';

final battleServiceProvider = Provider<BattleService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return BattleService(FirebaseFirestore.instance, authService);
});

final battleStreamProvider = StreamProvider.family<BattleModel?, String>((ref, battleId) {
  return ref.watch(battleServiceProvider).streamBattle(battleId);
});

final userBattlesStreamProvider = StreamProvider<List<BattleModel>>((ref) {
  final user = ref.watch(authServiceProvider).currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(battleServiceProvider).streamUserBattles(user.uid);
});

final battleMovesStreamProvider = StreamProvider.family<List<MoveModel>, String>((ref, battleId) {
  return ref.watch(battleServiceProvider).streamBattleMoves(battleId);
});

final userActiveBattlesStreamProvider = StreamProvider.family<List<BattleModel>, String>((ref, userId) {
  return ref.watch(battleServiceProvider).streamUserActiveBattles(userId);
});

final userCompletedBattlesStreamProvider = StreamProvider.family<List<BattleModel>, String>((ref, userId) {
  return ref.watch(battleServiceProvider).streamUserCompletedBattles(userId);
});

final allActiveBattlesStreamProvider = StreamProvider<List<BattleModel>>((ref) {
  return ref.watch(battleServiceProvider).streamAllActiveBattles();
});

class BattleService {
  final FirebaseFirestore _firestore;
  final AuthService _authService;

  BattleService(this._firestore, this._authService);

  // Create a new battle challenge
  Future<String> createBattle({
    required String challengerUid,
    required String opponentUid,
    required String genre,
    required int maxRounds,
  }) async {
    final battleRef = _firestore.collection('battles').doc();
    
    final battle = BattleModel(
      id: battleRef.id,
      challengerUid: challengerUid,
      opponentUid: opponentUid,
      genre: genre,
      status: BattleStatus.pending,
      currentRound: 1,
      maxRounds: maxRounds,
      currentTurnUid: challengerUid,
      createdAt: DateTime.now(),
      moves: [],
      movesCount: {},
    );

    await battleRef.set(battle.toMap());
    return battleRef.id;
  }

  // Stream a single battle
  Stream<BattleModel?> streamBattle(String battleId) {
    return _firestore
        .collection('battles')
        .doc(battleId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return BattleModel.fromMap(doc.data()!, id: doc.id);
    });
  }

  // Stream all battles for a user
  Stream<List<BattleModel>> streamUserBattles(String userId) {
    return _firestore
        .collection('battles')
        .where(Filter.or(
          Filter('challengerUid', isEqualTo: userId),
          Filter('opponentUid', isEqualTo: userId),
        ))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BattleModel.fromMap(doc.data(), id: doc.id))
          .toList();
    });
  }

  // Stream active battles for a user
  Stream<List<BattleModel>> streamUserActiveBattles(String userId) {
    return _firestore
        .collection('battles')
        .where(Filter.or(
          Filter('challengerUid', isEqualTo: userId),
          Filter('opponentUid', isEqualTo: userId),
        ))
        .where('status', whereIn: ['active', 'pending'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BattleModel.fromMap(doc.data(), id: doc.id))
          .toList();
    });
  }

  // Stream completed battles for a user
  Stream<List<BattleModel>> streamUserCompletedBattles(String userId) {
    return _firestore
        .collection('battles')
        .where(Filter.or(
          Filter('challengerUid', isEqualTo: userId),
          Filter('opponentUid', isEqualTo: userId),
        ))
        .where('status', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BattleModel.fromMap(doc.data(), id: doc.id))
          .toList();
    });
  }

  // Stream all active battles (for search/spectating)
  Stream<List<BattleModel>> streamAllActiveBattles() {
    return _firestore
        .collection('battles')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BattleModel.fromMap(doc.data(), id: doc.id))
          .toList();
    });
  }

  // Stream moves for a battle
  Stream<List<MoveModel>> streamBattleMoves(String battleId) {
    return _firestore
        .collection('battles')
        .doc(battleId)
        .collection('moves')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final List<MoveModel> moves = [];
      for (final doc in snapshot.docs) {
        moves.add(MoveModel.fromMap(doc.data(), doc.id));
      }
      return moves;
    });
  }

  // Accept a battle challenge
  Future<void> acceptChallenge(String battleId) async {
    await _firestore.collection('battles').doc(battleId).update({
      'status': 'active',
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  // Decline a battle challenge
  Future<void> declineChallenge(String battleId) async {
    await _firestore.collection('battles').doc(battleId).update({
      'status': 'declined',
    });
  }

  // Cancel a battle challenge
  Future<void> cancelChallenge(String battleId) async {
    await _firestore.collection('battles').doc(battleId).update({
      'status': 'cancelled',
    });
  }

  // ✅ RACE-FREE SUBMIT MOVE (NEW IMPLEMENTATION)
  Future<void> submitMove(String battleId, MoveModel move) async { // <-- FIX 1: Accepts String battleId
  final battleDocRef = _firestore.collection('battles').doc(battleId);
  
  // 1. NON-ATOMIC READS: Get the necessary data for checks
  
  // A) Read the battle document itself to get currentTurnUid and round
  final battleSnapshot = await battleDocRef.get();
  if (!battleSnapshot.exists) {
      throw Exception("Battle document not found.");
  }
  final battle = BattleModel.fromMap(battleSnapshot.data()!, id: battleId); // <-- FIX 2: Create model internally

  // B) Get moves count (Must be outside the transaction)
  final movesSnapshotBefore = await battleDocRef
      .collection('moves')
      .where('round', isEqualTo: battle.currentRound)
      .get();
  
  final movesThisRoundIncludingCurrent = movesSnapshotBefore.docs.length + 1;
  
  // 🔍 DEBUG LOGGING
  print('📊 SUBMIT MOVE DEBUG:');
  print('  battleId: $battleId');
  print('  currentRound: ${battle.currentRound}');
  print('  maxRounds: ${battle.maxRounds}');
  print('  movesSnapshotBefore.docs.length: ${movesSnapshotBefore.docs.length}');
  print('  movesThisRoundIncludingCurrent: $movesThisRoundIncludingCurrent');
  print('  currentTurnUid (before): ${battle.currentTurnUid}');
  
  // 2. Determine updates based on count (Logic)
  final nextTurnUid = (battle.currentTurnUid == battle.challengerUid)
      ? battle.opponentUid
      : battle.challengerUid;
  
  print('  nextTurnUid (after): $nextTurnUid');

  Map<String, dynamic> updates = {
    'currentTurnUid': nextTurnUid, // Flips the turn
    'lastActivity': FieldValue.serverTimestamp(),
  };

  if (movesThisRoundIncludingCurrent == 2) {
    print('  ⚠️ 2 MOVES DETECTED - Completing round or battle');
    if (battle.currentRound < battle.maxRounds) {
      print('  ➡️ Advancing to next round');
      updates['currentRound'] = battle.currentRound + 1;
      updates['currentTurnUid'] = battle.challengerUid; // Challenger starts new round
    } else {
      print('  🏁 MARKING BATTLE AS COMPLETED');
      updates['status'] = 'completed';
    }
  } else {
    print('  ✅ Only ${movesThisRoundIncludingCurrent} move(s) - keeping battle active');
  }

  // 3. ATOMIC WRITE: Use a Transaction to guarantee the move and status update commit together
  await _firestore.runTransaction((transaction) async {
    // Save the new move (atomic write 1)
    final moveDocRef = battleDocRef.collection('moves').doc(move.id);
    transaction.set(moveDocRef, move.toMap());

    // Update the battle status (atomic write 2)
    transaction.update(battleDocRef, updates);
  }).catchError((error) {
    print('❌ Submission Transaction failed: $error');
    throw Exception('Failed to submit move and flip turn: $error'); 
  });
}

  // Vote for a move
  Future<void> voteForMove(String battleId, String moveId, String voterId, int score) async {
    final moveRef = _firestore
        .collection('battles')
        .doc(battleId)
        .collection('moves')
        .doc(moveId);
    
    await moveRef.update({
      'votes.$voterId': score,
    });
  }

  // Finalize battle and calculate winner
  Future<void> finalizeBattle(String battleId) async {
    debugPrint('🏆 FINALIZING BATTLE: $battleId');
    
    final battleDoc = await _firestore.collection('battles').doc(battleId).get();
    final battle = BattleModel.fromMap(battleDoc.data()!, id: battleId);
    
    // Get all moves for this battle
    final movesSnapshot = await _firestore
        .collection('battles')
        .doc(battleId)
        .collection('moves')
        .get();
    
    // Calculate scores for each player
    int challengerScore = 0;
    int opponentScore = 0;
    
    for (var moveDoc in movesSnapshot.docs) {
      final move = MoveModel.fromMap(moveDoc.data(), moveDoc.id);
      final totalVotes = move.totalScore;
      
      if (move.submittedByUid == battle.challengerUid) {
        challengerScore += totalVotes;
      } else if (move.submittedByUid == battle.opponentUid) {
        opponentScore += totalVotes;
      }
    }
    
    debugPrint('📊 Final Scores: Challenger=$challengerScore, Opponent=$opponentScore');
    
    // Determine winner
    String? winnerUid;
    if (challengerScore > opponentScore) {
      winnerUid = battle.challengerUid;
    } else if (opponentScore > challengerScore) {
      winnerUid = battle.opponentUid;
    } else {
      winnerUid = 'Draw';
    }
    
    // Update battle with final results
    await _firestore.collection('battles').doc(battleId).update({
      'status': 'completed',
      'winnerUid': winnerUid,
      'challengerFinalScore': challengerScore,
      'opponentFinalScore': opponentScore,
      'completedAt': FieldValue.serverTimestamp(),
    });
    
    debugPrint('✅ Battle finalized successfully\n');
  }

  // Get battle statistics for a user
  Future<Map<String, int>> getUserBattleStats(String userId) async {
    final battlesSnapshot = await _firestore
        .collection('battles')
        .where(Filter.or(
          Filter('challengerUid', isEqualTo: userId),
          Filter('opponentUid', isEqualTo: userId),
        ))
        .where('status', isEqualTo: 'completed')
        .get();
    
    int wins = 0;
    int losses = 0;
    int draws = 0;
    
    for (var doc in battlesSnapshot.docs) {
      final battle = BattleModel.fromMap(doc.data(), id: doc.id);
      if (battle.winnerUid == userId) {
        wins++;
      } else if (battle.winnerUid == 'Draw') {
        draws++;
      } else if (battle.winnerUid != null) {
        losses++;
      }
    }
    
    return {
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'total': battlesSnapshot.docs.length,
    };
  }

  // Get active battles count
  Future<int> getActiveBattlesCount(String userId) async {
    final snapshot = await _firestore
        .collection('battles')
        .where(Filter.or(
          Filter('challengerUid', isEqualTo: userId),
          Filter('opponentUid', isEqualTo: userId),
        ))
        .where('status', isEqualTo: 'active')
        .get();
    
    return snapshot.docs.length;
  }

  // Check if users have an active battle
  Future<bool> hasActiveBattle(String userId1, String userId2) async {
    final snapshot = await _firestore
        .collection('battles')
        .where('status', isEqualTo: 'active')
        .get();
    
    for (var doc in snapshot.docs) {
      final battle = BattleModel.fromMap(doc.data(), id: doc.id);
      if ((battle.challengerUid == userId1 && battle.opponentUid == userId2) ||
          (battle.challengerUid == userId2 && battle.opponentUid == userId1)) {
        return true;
      }
    }
    
    return false;
  }
}