// lib/services/activity_service.dart
// --- START COPY & PASTE HERE ---

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_model.dart';
import 'auth_service.dart';

final activityServiceProvider = Provider((ref) {
  return ActivityService(ref);
});

final activityFeedStreamProvider = StreamProvider<List<ActivityModel>>((ref) {
  final currentUid = ref.watch(authStateChangesProvider).value?.uid;
  if (currentUid == null) {
    return Stream.value([]); 
  }
  return ref.read(activityServiceProvider).getActivityFeedStream(currentUid);
});

class ActivityService {
  // FIX: Changed 'ProviderRef' to 'Ref' to fix the crash
  final Ref _ref;
  final CollectionReference _activityCollection = FirebaseFirestore.instance.collection('activity');

  ActivityService(this._ref);

  Stream<List<ActivityModel>> getActivityFeedStream(String userId) {
    return _activityCollection
        .where('participants', arrayContains: userId)
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ActivityModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
        });
  }

  Future<void> logChallengeSent(String battleId, String challengerUid, String opponentUid) async {
    final activity = ActivityModel(
      id: '', 
      type: ActivityType.challengeSent,
      timestamp: DateTime.now(),
      participants: [challengerUid, opponentUid], 
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
      actorUid: opponentUid, 
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
      actorUid: opponentUid, 
      targetUid: challengerUid,
      battleId: battleId,
    );
    await _activityCollection.add(activity.toMap());
  }
  
  Future<void> logChallengeCanceled(String battleId, String challengerUid, String opponentUid) async {
    final activity = ActivityModel(
      id: '',
      type: ActivityType.challengeCanceled, 
      timestamp: DateTime.now(),
      participants: [challengerUid, opponentUid],
      actorUid: challengerUid, 
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
      actorUid: winnerUid, 
      targetUid: winnerUid == challengerUid ? opponentUid : challengerUid, 
      battleId: battleId,
      challengerScore: challengerScore,
      opponentScore: opponentScore,
    );
    await _activityCollection.add(activity.toMap());
  }
  
  Future<void> logFriendRequest(String senderUid, String receiverUid) async {
    final activity = ActivityModel(
      id: '',
      type: ActivityType.friendRequest,
      timestamp: DateTime.now(),
      participants: [senderUid, receiverUid],
      actorUid: senderUid,
      targetUid: receiverUid,
    );
    await _activityCollection.add(activity.toMap());
  }
  
  Future<void> logFriendAccepted(String accepterUid, String requestorUid) async {
    final activity = ActivityModel(
      id: '',
      type: ActivityType.friendAccepted,
      timestamp: DateTime.now(),
      participants: [accepterUid, requestorUid], 
      actorUid: accepterUid,
      targetUid: requestorUid,
    );
    await _activityCollection.add(activity.toMap());
  }
}
// --- END COPY & PASTE HERE ---