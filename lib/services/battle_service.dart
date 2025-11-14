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

// Provider for active/pending battles (used by battles_screen.dart)
final userActiveBattlesStreamProvider = StreamProvider.family<List<BattleModel>, String>((ref, userId) {
  // FIX: Get the stream directly from the service and filter it
  return ref.read(battleServiceProvider).getUserBattlesStream(userId).map((battles) {
    return battles.where((b) => b.status == BattleStatus.active || b.status == BattleStatus.pending).toList();
  });
});

// Provider for completed battles (used by dashboard_screen.dart)
final userCompletedBattlesStreamProvider = StreamProvider.family<List<BattleModel>, String>((ref, userId) {
  // FIX: Get the stream directly from the service and filter it
  return ref.read(battleServiceProvider).getUserBattlesStream(userId).map((battles) {
    return battles.where((b) => b.status == BattleStatus.completed || b.status == BattleStatus.declined).toList();
  });
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
        .collection('moves') // Ensure this subcollection name is correct
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MoveModel.fromMap(doc.data()!, doc.id)) 
            .toList())
        .handleError((error) {
          print('Error in getMovesStream: $error');
          return <MoveModel>[];
        })
        .startWith(const []); // Start with empty list
  }

  // Fetches all battles for a given user (Challenger OR Opponent)
  Stream<List<BattleModel>> getUserBattlesStream(String userId) {
    // 1. Get battles where user is challenger
    final challengerStream = _battleCollection
        .where('challengerUid', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BattleModel.fromMap(doc.data()! as Map<String, dynamic>, id: doc.id)) 
            .toList())
        .handleError((error) {
          print('Error in challengerStream: $error');
          return <BattleModel>[];
        })
        .startWith(const []); // FIX: Emit an empty list immediately

    // 2. Get battles where user is opponent
    final opponentStream = _battleCollection
        .where('opponentUid', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BattleModel.fromMap(doc.data()! as Map<String, dynamic>, id: doc.id)) 
            .toList())
        .handleError((error) {
          print('Error in opponentStream: $error');
          return <BattleModel>[];
        })
        .startWith(const []); // FIX: Emit an empty list immediately

    // 3. Combine streams using rxdart
    return Rx.combineLatest2(
      challengerStream,
      opponentStream,
      (List<BattleModel> challengerBattles, List<BattleModel> opponentBattles) {
        
        final Map<String, BattleModel> battlesMap = {};
        
        for (var battle in challengerBattles) {
          battlesMap[battle.id!] = battle;
        }
        for (var battle in opponentBattles) {
          battlesMap[battle.id!] = battle;
        }
        
        // This stream provides ALL battles (active, pending, completed, etc.)
        final allBattles = battlesMap.values.toList();
        
        // Sort by creation date (newest first)
        allBattles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return allBattles;
      }
    ).handleError((error) {
      print('Error in combineLatest2: $error');
      return <BattleModel>[];
    });
  }

  // Retrieves only completed battles for a given user
  Stream<List<BattleModel>> getUserCompletedBattlesStream(String uid) {
     // 1. Get completed as challenger
     final challengerStream = _battleCollection
        .where('challengerUid', isEqualTo: uid)
        .where('status', isEqualTo: BattleStatus.completed.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BattleModel.fromMap(doc.data() as Map<String, dynamic>, id: doc.id)) 
            .toList())
        .handleError((error) {
          print('Error in completed challengerStream: $error');
          return <BattleModel>[];
        })
        .startWith(const []); // FIX: Emit an empty list immediately

    // 2. Get completed as opponent
    final opponentStream = _battleCollection
        .where('opponentUid', isEqualTo: uid)
        .where('status', isEqualTo: BattleStatus.completed.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BattleModel.fromMap(doc.data() as Map<String, dynamic>, id: doc.id)) 
            .toList())
        .handleError((error) {
          print('Error in completed opponentStream: $error');
          return <BattleModel>[];
        })
        .startWith(const []); // FIX: Emit an empty list immediately
        
    // 3. Combine streams
    return Rx.combineLatest2(
      challengerStream,
      opponentStream,
      (List<BattleModel> challengerBattles, List<BattleModel> opponentBattles) {
         final Map<String, BattleModel> battlesMap = {};
        for (var battle in challengerBattles) { battlesMap[battle.id!] = battle; }
        for (var battle in opponentBattles) { battlesMap[battle.id!] = battle; }
        
        final completedBattles = battlesMap.values.toList();
        completedBattles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return completedBattles;
      }
    ).handleError((error) {
      print('Error in completed combineLatest2: $error');
      return <BattleModel>[];
    });
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

  Future<void> createBattle({ // Changed from challengeUser to createBattle
    required String challengerUid,
    required String opponentUid,
    required String genre,
    required int maxRounds,
  }) async {
    final newBattle = BattleModel(
      id: '', // Firestore will assign
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
    await _battleCollection.doc(battleId).update({
      'status': BattleStatus.declined.name,
    });
    
    final battle = await getBattleById(battleId);
    if (battle != null) {
      await _activityService.logChallengeDeclined(battle.id!, battle.challengerUid, battle.opponentUid);
    }
  }

  Future<void> submitMove(BattleModel battle, MoveModel move) async {
    final battleRef = _battleCollection.doc(battle.id);
    final movesRef = battleRef.collection('moves');
    bool isFinalMove = false;

    await _firestore.runTransaction((transaction) async {
      final battleSnapshot = await transaction.get(battleRef);
      if (!battleSnapshot.exists) {
        throw Exception("Battle not found.");
      }
      final currentBattle = BattleModel.fromMap(battleSnapshot.data() as Map<String, dynamic>, id: battleSnapshot.id);

      if (currentBattle.status != BattleStatus.active) {
        throw Exception("This battle is no longer active.");
      }
      if (currentBattle.currentTurnUid != move.submittedByUid) {
        throw Exception("It's not your turn!");
      }

      final nextTurnUid = currentBattle.currentTurnUid == currentBattle.challengerUid 
          ? currentBattle.opponentUid 
          : currentBattle.challengerUid;

      final movesSnapshot = await movesRef.where('round', isEqualTo: currentBattle.currentRound).get();
      final movesThisRound = movesSnapshot.docs.length + 1;

      int nextRound = currentBattle.currentRound;
      BattleStatus nextStatus = currentBattle.status;

      if (movesThisRound == 2) { // Round is complete
        if (currentBattle.currentRound < currentBattle.maxRounds) {
          nextRound = currentBattle.currentRound + 1;
        } else {
          // This was the last move of the last round
          nextStatus = BattleStatus.completed;
          isFinalMove = true;
        }
      }

      // 1. Add the new move
      transaction.set(movesRef.doc(), move.toMap()); // auto-generates move ID

      // 2. Update the main battle document
      transaction.update(battleRef, {
        'currentTurnUid': nextTurnUid,
        'currentRound': nextRound,
        'status': nextStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    
    // Trigger judging *after* the transaction is complete
    if (isFinalMove) {
      await finalizeBattle(battle.id!); // Call the public method
    }
  }
  
  Future<void> voteForMove(String battleId, String moveId, String userId) async {
    final moveRef = _battleCollection.doc(battleId).collection('moves').doc(moveId);

    await _firestore.runTransaction((transaction) async {
      final moveSnapshot = await transaction.get(moveRef);
      if (!moveSnapshot.exists) {
        throw Exception("Move not found!");
      }
      
      final moveData = moveSnapshot.data()!;
      final List<String> currentVotes = List<String>.from(moveData['votes'] ?? []);

      if (currentVotes.contains(userId)) {
        currentVotes.remove(userId);
      } else {
        currentVotes.add(userId);
      }
      
      transaction.update(moveRef, {'votes': currentVotes});
    });
  }

  // --- NEW: Method to total votes and finalize the battle ---
  Future<void> finalizeBattle(String battleId) async {
    // 1. Get the battle
    final battle = await getBattleById(battleId);
    if (battle == null) return;
    
    // 2. Get all moves for the battle
    final movesSnapshot = await _battleCollection.doc(battleId).collection('moves').get();
    final allMoves = movesSnapshot.docs.map((doc) => MoveModel.fromMap(doc.data()!, doc.id)).toList();

    // 3. Tally votes
    int challengerTotalVotes = 0;
    int opponentTotalVotes = 0;

    for (final move in allMoves) {
      if (move.submittedByUid == battle.challengerUid) {
        challengerTotalVotes += move.votes.length;
      } else if (move.submittedByUid == battle.opponentUid) {
        opponentTotalVotes += move.votes.length;
      }
    }
    
    // 4. Determine Winner and ELO scores
    String winnerUid;
    double scoreForChallengerElo;
    bool isDraw;

    if (challengerTotalVotes > opponentTotalVotes) {
      winnerUid = battle.challengerUid;
      scoreForChallengerElo = 1.0;
      isDraw = false;
    } else if (opponentTotalVotes > challengerTotalVotes) {
      winnerUid = battle.opponentUid;
      scoreForChallengerElo = 0.0;
      isDraw = false;
    } else {
      // --- This is what happens on a TIE ---
      winnerUid = 'Draw';
      scoreForChallengerElo = 0.5;
      isDraw = true;
    }

    // 5. Update ELO and User Stats
    await _eloService.processBattleResult(
      battle.challengerUid,
      battle.opponentUid,
      scoreForChallengerElo,
      isDraw,
    );

    // 6. Update the Battle document with the final winner and scores
    await _battleCollection.doc(battleId).update({
      'winnerUid': winnerUid,
      'challengerFinalScore': challengerTotalVotes,
      'opponentFinalScore': opponentTotalVotes,
      'completedTimestamp': FieldValue.serverTimestamp(),
    });
    
    // 7. Log the completed activity
    await _activityService.logBattleCompleted(
      battleId, 
      battle.challengerUid, 
      battle.opponentUid, 
      winnerUid,
      challengerScore: challengerTotalVotes,
      opponentScore: opponentTotalVotes,
    );
  }
}
// --- END COPY & PASTE HERE ---