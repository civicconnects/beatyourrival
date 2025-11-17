// lib/services/activity_service.dart
// --- START COPY & PASTE HERE ---

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_model.dart';
import 'auth_service.dart';

// --- SERVICE PROVIDER ---
final activityServiceProvider = Provider((ref) {
  return ActivityService(ref);
});

// --- STREAM PROVIDER ---
// Fetches all activities where the current user is a participant
final activityFeedStreamProvider = StreamProvider<List<ActivityModel>>((ref) {
  final currentUid = ref.watch(authStateChangesProvider).value?.uid;
  if (currentUid == null) {
    return Stream.value([]); // Return empty stream if not logged in
  }
  return ref.read(activityServiceProvider).getActivityFeedStream(currentUid);
});


class ActivityService {
  final ProviderRef _ref;
  final CollectionReference _activityCollection = FirebaseFirestore.instance.collection('activity');

  ActivityService(this._ref);

  // --- NEW READ METHOD ---
  Stream<List<ActivityModel>> getActivityFeedStream(String userId) {
    // Get all activities where the 'participants' list contains the current user's ID
    return _activityCollection
        .where('participants', arrayContains: userId)
        .orderBy('timestamp', descending: true)
        .limit(30) // Get the last 30 activities
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ActivityModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
        });
  }

  // --- UPDATED WRITE METHODS ---

  Future<void> logChallengeSent(String battleId, String challengerUid, String opponentUid) async {
    final activity = ActivityModel(
      id: '', // Firestore will generate
      type: ActivityType.challengeSent,
      timestamp: DateTime.now(),
      participants: [challengerUid, opponentUid], // So both users see it
      actorUid: challengerUid,
      targetUid: opponentUid,
      battleId: battleId,
    );
    await _activityCollection.add(activity.toMap());
  }

  Future<void> logChallengeAccepted(String battleId, String challengerUid, String opponentUid) async {
    final activity = ActivityModel(
      id: '',
      type: ActivityType.challengeAccepted,
      timestamp: DateTime.now(),
      participants: [challengerUid, opponentUid],
      actorUid: opponentUid, // The opponent is the one who accepted
      targetUid: challengerUid,
      battleId: battleId,
    );
    await _activityCollection.add(activity.toMap());
  }

  Future<void> logChallengeDeclined(String battleId, String challengerUid, String opponentUid) async {
    final activity = ActivityModel(
      id: '',
      type: ActivityType.challengeDeclined,
      timestamp: DateTime.now(),
      participants: [challengerUid, opponentUid],
      actorUid: opponentUid, // The opponent is the one who declined
      targetUid: challengerUid,
      battleId: battleId,
    );
    await _activityCollection.add(activity.toMap());
  }
  
  // --- NEW LOGGING METHOD ---
  Future<void> logChallengeCanceled(String battleId, String challengerUid, String opponentUid) async {
    final activity = ActivityModel(
      id: '',
      type: ActivityType.challengeCanceled, // Use the new type
      timestamp: DateTime.now(),
      participants: [challengerUid, opponentUid],
      actorUid: challengerUid, // The challenger is the one who canceled
      targetUid: opponentUid,
      battleId: battleId,
    );
    await _activityCollection.add(activity.toMap());
  }

  Future<void> logBattleCompleted(String battleId, String challengerUid, String opponentUid, String winnerUid, {int? challengerScore, int? opponentScore}) async {
    final activity = ActivityModel(
      id: '',
      type: ActivityType.battleCompleted,
      timestamp: DateTime.now(),
      participants: [challengerUid, opponentUid],
      actorUid: winnerUid, // The winner (or "Draw")
      targetUid: winnerUid == challengerUid ? opponentUid : challengerUid, // The loser
      battleId: battleId,
      challengerScore: challengerScore,
      opponentScore: opponentScore,
    );
    await _activityCollection.add(activity.toMap());
  }
  
  // You can add logFriendRequest and logFriendAccepted here later
}
// --- END COPY & PASTE HERE ---