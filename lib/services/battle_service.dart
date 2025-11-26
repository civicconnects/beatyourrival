// lib/services/battle_service.dart

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

// NEW PROVIDERS FOR ACTIVE AND COMPLETED BATTLES
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
      currentTurnUid: challengerUid, // Challenger goes first
      createdAt: DateTime.now(),
      moves: [],
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
      // Explicitly type the list to avoid type inference issues
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

  // Submit a move with enhanced debug logging
  Future<void> submitMove(BattleModel battle, MoveModel move) async {
    debugPrint('🎯 SUBMIT MOVE CALLED - Battle ID: ${battle.id}');
    debugPrint('📊 Current Round: ${battle.currentRound} / Max Rounds: ${battle.maxRounds}');
    debugPrint('👤 Current Turn: ${battle.currentTurnUid}');
    debugPrint('📝 Move submitted by: ${move.submittedByUid}');
    debugPrint('🎵 Move title: ${move.title}');
    
    final battleDocRef = _firestore.collection('battles').doc(battle.id!);
    
    // Add the move to the moves subcollection
    await battleDocRef.collection('moves').add(move.toMap());
    debugPrint('✅ Move added to database');
    
    // Determine the next turn
    final nextTurnUid = (battle.currentTurnUid == battle.challengerUid)
        ? battle.opponentUid
        : battle.challengerUid;
    
    debugPrint('🔄 Next turn will be: $nextTurnUid');
    debugPrint('   - Challenger: ${battle.challengerUid}');
    debugPrint('   - Opponent: ${battle.opponentUid}');
    
    // Check if we need to advance the round
    final movesSnapshot = await battleDocRef
        .collection('moves')
        .where('round', isEqualTo: battle.currentRound)
        .get();
    
    final movesThisRound = movesSnapshot.docs.length;
    debugPrint('📊 Moves submitted this round: $movesThisRound');
    
    // List all moves for debugging
    for (var moveDoc in movesSnapshot.docs) {
      final moveData = moveDoc.data();
      debugPrint('   - Move by ${moveData['submittedByUid']}: ${moveData['title']}');
    }
    
    Map<String, dynamic> updates = {
      'currentTurnUid': nextTurnUid,
      'lastActivity': FieldValue.serverTimestamp(),
    };
    
    // If both players have submitted moves for this round
    if (movesThisRound >= 2) {
      debugPrint('🎉 Both players have submitted for round ${battle.currentRound}');
      
      if (battle.currentRound < battle.maxRounds) {
        // Advance to the next round
        updates['currentRound'] = battle.currentRound + 1;
        debugPrint('➡️ Advancing to round ${battle.currentRound + 1}');
        debugPrint('   Still ${battle.maxRounds - battle.currentRound} rounds remaining');
      } else {
        // Battle is complete, move to voting phase
        updates['status'] = 'completed';
        debugPrint('🏁 Battle complete! All ${battle.maxRounds} rounds finished');
        debugPrint('📊 Moving to voting phase');
      }
    } else {
      debugPrint('⏳ Waiting for other player to submit their move');
      debugPrint('   Need ${2 - movesThisRound} more move(s) for this round');
    }
    
    // Update the battle document
    debugPrint('📝 Updating battle document with:');
    updates.forEach((key, value) {
      debugPrint('   - $key: $value');
    });
    
    await battleDocRef.update(updates);
    debugPrint('✅ Battle document updated successfully');
    debugPrint('🎯 SUBMIT MOVE COMPLETED\n');
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
        debugPrint('   Challenger move: ${move.title} - Score: $totalVotes');
      } else if (move.submittedByUid == battle.opponentUid) {
        opponentScore += totalVotes;
        debugPrint('   Opponent move: ${move.title} - Score: $totalVotes');
      }
    }
    
    debugPrint('📊 Final Scores:');
    debugPrint('   - Challenger: $challengerScore');
    debugPrint('   - Opponent: $opponentScore');
    
    // Determine winner
    String? winnerUid;
    if (challengerScore > opponentScore) {
      winnerUid = battle.challengerUid;
      debugPrint('🎉 Winner: Challenger (${battle.challengerUid})');
    } else if (opponentScore > challengerScore) {
      winnerUid = battle.opponentUid;
      debugPrint('🎉 Winner: Opponent (${battle.opponentUid})');
    } else {
      winnerUid = 'Draw';
      debugPrint('🤝 Result: Draw!');
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