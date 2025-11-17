// lib/services/battle_service.dart
// --- START COPY & PASTE HERE ---

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart'; // Make sure rxdart is in pubspec.yaml

import '../models/battle_model.dart';
import '../models/move_model.dart';
import 'activity_service.dart';
import 'user_service.dart';
import 'elo_service.dart';

final battleServiceProvider = Provider((ref) {
  return BattleService(ref);
});

// Stream for a single battle
final battleStreamProvider = StreamProvider.family<BattleModel?, String>((ref, battleId) {
  return ref.read(battleServiceProvider).getBattleStream(battleId);
});

// Stream for moves of a specific battle
final battleMovesStreamProvider = StreamProvider.family<List<MoveModel>, String>((ref, battleId) {
  return ref.read(battleServiceProvider).getMovesStream(battleId);
});

// Stream for ALL battles the user is involved in
final allUserBattlesStreamProvider = StreamProvider.family<List<BattleModel>, String>((ref, userId) {
  return ref.read(battleServiceProvider).getUserBattlesStream(userId);
});

// FIX: Provider for active/pending battles (NO .stream, prevents spinning)
final userActiveBattlesStreamProvider = StreamProvider.family<List<BattleModel>, String>((ref, userId) {
  return ref.read(battleServiceProvider).getUserBattlesStream(userId).map((battles) {
    return battles.where((b) => b.status == BattleStatus.active || b.status == BattleStatus.pending).toList();
  });
});

// FIX: Provider for completed battles (NO .stream, prevents spinning)
final userCompletedBattlesStreamProvider = StreamProvider.family<List<BattleModel>, String>((ref, userId) {
  return ref.read(battleServiceProvider).getUserBattlesStream(userId).map((battles) {
    return battles.where((b) => b.status == BattleStatus.completed || b.status == BattleStatus.declined || b.status == BattleStatus.rejected).toList();
  });
});

// NEW: Provider for GLOBAL active battles (Spectator Mode)
final allActiveBattlesStreamProvider = StreamProvider<List<BattleModel>>((ref) {
  return ref.read(battleServiceProvider).getAllActiveBattlesStream();
});


class BattleService {
  final ProviderRef _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _battleCollection;
  late final ActivityService _activityService;
  late final UserService _userService;
  late final EloService _eloService;

  BattleService(this._ref) {
    _battleCollection = _firestore.collection('battles'); // lowercase 'b'
    _activityService = _ref.read(activityServiceProvider);
    _userService = _ref.read(userServiceProvider);
    _eloService = _ref.read(eloServiceProvider);
  }

  // ----------------------------------------------------
  // Stream Getters
  // ----------------------------------------------------

  Stream<BattleModel?> getBattleStream(String battleId) {
    return _battleCollection.doc(battleId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return BattleModel.fromMap(doc.data()! as Map<String, dynamic>, id: doc.id); 
    });
  }

  Stream<List<MoveModel>> getMovesStream(String battleId) {
    return _battleCollection
        .doc(battleId)
        .collection('moves') 
        .orderBy('submittedAt', descending: false) 
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MoveModel.fromMap(doc.data()!, doc.id)) 
            .toList())
        .startWith(const []); // FIX: Prevents spinning on empty lists
  }

  // FIX: New method to get ALL active battles for spectators
  Stream<List<BattleModel>> getAllActiveBattlesStream() {
    return _battleCollection
        .where('status', isEqualTo: BattleStatus.active.name)
        .orderBy('createdAt', descending: true) // Show newest first
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BattleModel.fromMap(doc.data()! as Map<String, dynamic>, id: doc.id)) 
            .toList())
        .startWith(const []);
  }

  // This is the working, non-spinning stream logic
  Stream<List<BattleModel>> getUserBattlesStream(String userId) {
    final challengerStream = _battleCollection
        .where('challengerUid', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BattleModel.fromMap(doc.data()! as Map<String, dynamic>, id: doc.id)) 
            .toList())
        .startWith(const []); // FIX: Prevents spinning

    final opponentStream = _battleCollection
        .where('opponentUid', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BattleModel.fromMap(doc.data()! as Map<String, dynamic>, id: doc.id)) 
            .toList())
        .startWith(const []); // FIX: Prevents spinning

    return Rx.combineLatest2(
      challengerStream,
      opponentStream,
      (List<BattleModel> challengerBattles, List<BattleModel> opponentBattles) {
        final Map<String, BattleModel> battlesMap = {};
        for (var battle in challengerBattles) { battlesMap[battle.id!] = battle; }
        for (var battle in opponentBattles) { battlesMap[battle.id!] = battle; }
        
        final allBattles = battlesMap.values.toList();
        allBattles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return allBattles;
      }
    );
  }

  Future<BattleModel?> getBattleById(String battleId) async {
    final doc = await _battleCollection.doc(battleId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return BattleModel.fromMap(data, id: doc.id);
  }

  // ----------------------------------------------------
  // Actions
  // ----------------------------------------------------

  Future<void> createBattle({
    required String challengerUid,
    required String opponentUid,
    required String genre,
    required int maxRounds,
  }) async {
    final newBattle = BattleModel(
      id: '', 
      challengerUid: challengerUid,
      opponentUid: opponentUid,
      status: BattleStatus.pending,
      createdAt: DateTime.now(),
      moves: const [], 
      currentRound: 1,
      currentTurnUid: challengerUid,
      maxRounds: maxRounds, 
      genre: genre, 
    );

    final docRef = await _battleCollection.add(newBattle.toMap());
    await _activityService.logChallengeSent(docRef.id, challengerUid, opponentUid);
  }

  Future<void> acceptChallenge(String battleId) async {
    await _battleCollection.doc(battleId).update({
      'status': BattleStatus.active.name,
    });
    final battle = await getBattleById(battleId);
    if (battle != null) {
      await _activityService.logChallengeAccepted(battle.id!, battle.challengerUid, battle.opponentUid);
    }
  }

  Future<void> declineChallenge(String battleId) async {
    await _battleCollection.doc(battleId).update({'status': BattleStatus.declined.name});
    final battle = await getBattleById(battleId);
    if (battle != null) {
      await _activityService.logChallengeDeclined(battle.id!, battle.challengerUid, battle.opponentUid);
    }
  }

  // FIX: Method required for "Cancel" button
  Future<void> cancelChallenge(String battleId) async {
    final battle = await getBattleById(battleId); 
    if (battle == null) return;

    await _battleCollection.doc(battleId).update({
      'status': BattleStatus.rejected.name, 
    });
    await _activityService.logChallengeCanceled(battle.id!, battle.challengerUid, battle.opponentUid);
  }

  Future<void> submitMove(BattleModel battle, MoveModel move) async {
    final battleRef = _battleCollection.doc(battle.id);
    final movesRef = battleRef.collection('moves');

    await _firestore.runTransaction((transaction) async {
      final battleSnapshot = await transaction.get(battleRef);
      if (!battleSnapshot.exists) throw Exception("Battle not found.");
      final currentBattle = BattleModel.fromMap(battleSnapshot.data() as Map<String, dynamic>, id: battleSnapshot.id);

      if (currentBattle.status != BattleStatus.active) throw Exception("Battle not active.");
      if (currentBattle.currentTurnUid != move.submittedByUid) throw Exception("Not your turn!");

      final nextTurnUid = currentBattle.currentTurnUid == currentBattle.challengerUid 
          ? currentBattle.opponentUid 
          : currentBattle.challengerUid;

      final movesSnapshot = await movesRef.where('round', isEqualTo: currentBattle.currentRound).get();
      final movesThisRound = movesSnapshot.docs.length + 1;

      int nextRound = currentBattle.currentRound;
      BattleStatus nextStatus = currentBattle.status;

      if (movesThisRound == 2) { 
        if (currentBattle.currentRound < currentBattle.maxRounds) {
          nextRound = currentBattle.currentRound + 1;
        } else {
          nextStatus = BattleStatus.completed;
        }
      }

      transaction.set(movesRef.doc(), move.toMap()); 

      transaction.update(battleRef, {
        'currentTurnUid': nextTurnUid,
        'currentRound': nextRound,
        'status': nextStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    // Note: No auto-finalize call here. The user clicks "Tally Votes".
  }
  
  // FIX: Updated to accept a score (1-10) and save to Map
  Future<void> voteForMove(String battleId, String moveId, String userId, int score) async {
    final moveRef = _battleCollection.doc(battleId).collection('moves').doc(moveId);

    await _firestore.runTransaction((transaction) async {
      final moveSnapshot = await transaction.get(moveRef);
      if (!moveSnapshot.exists) throw Exception("Move not found!");
      
      final moveData = moveSnapshot.data()!;
      final Map<String, dynamic> rawVotes = moveData['votes'] ?? {};
      
      // Save score: { "userId": 8 }
      rawVotes[userId] = score;
      
      transaction.update(moveRef, {'votes': rawVotes});
    });
  }

  // FIX: Updated to calculate winner by POINTS, not vote count
  Future<void> finalizeBattle(String battleId) async {
    final battle = await getBattleById(battleId);
    if (battle == null) return;
    
    final movesSnapshot = await _battleCollection.doc(battleId).collection('moves').get();
    final allMoves = movesSnapshot.docs.map((doc) => MoveModel.fromMap(doc.data()!, doc.id)).toList();

    int challengerScore = 0;
    int opponentScore = 0;

    for (final move in allMoves) {
      if (move.submittedByUid == battle.challengerUid) {
        challengerScore += move.totalScore; // Uses new totalScore property
      } else if (move.submittedByUid == battle.opponentUid) {
        opponentScore += move.totalScore; 
      }
    }
    
    String winnerUid;
    double scoreForChallengerElo;
    bool isDraw;

    if (challengerScore > opponentScore) {
      winnerUid = battle.challengerUid;
      scoreForChallengerElo = 1.0;
      isDraw = false;
    } else if (opponentScore > challengerScore) {
      winnerUid = battle.opponentUid;
      scoreForChallengerElo = 0.0;
      isDraw = false;
    } else {
      winnerUid = 'Draw';
      scoreForChallengerElo = 0.5;
      isDraw = true;
    }

    await _eloService.processBattleResult(
      battle.challengerUid,
      battle.opponentUid,
      scoreForChallengerElo,
      isDraw,
    );

    await _battleCollection.doc(battleId).update({
      'winnerUid': winnerUid,
      'challengerFinalScore': challengerScore,
      'opponentFinalScore': opponentScore,
      'completedTimestamp': FieldValue.serverTimestamp(),
    });
    
    await _activityService.logBattleCompleted(
      battleId, 
      battle.challengerUid, 
      battle.opponentUid, 
      winnerUid,
      challengerScore: challengerScore,
      opponentScore: opponentScore,
    );
  }
}
// --- END COPY & PASTE HERE ---