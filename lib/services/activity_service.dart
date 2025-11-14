// lib/services/activity_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_model.dart';
import '../models/user_model.dart';
import 'user_service.dart';

final activityServiceProvider = Provider((ref) {
  return ActivityService(ref);
});

// Stream provider for the global activity feed
final globalActivityStreamProvider = StreamProvider<List<ActivityModel>>((ref) {
  return ref.watch(activityServiceProvider).getGlobalActivityStream();
});

// Future provider to fetch all users related to a list of activities (for display)
final activityUsersProvider = FutureProvider.family<Map<String, UserModel>, List<ActivityModel>>((ref, activities) async {
  final uids = activities
      .expand((a) => [a.challengerUid, a.opponentUid, a.winnerUid ?? ''])
      .where((uid) => uid.isNotEmpty && uid != 'Draw')
      .toSet()
      .toList();
  
  if (uids.isEmpty) return {};

  final userService = ref.read(userServiceProvider);
  final users = await Future.wait(uids.map((uid) => userService.getUserProfile(uid)));
  
  // Create a map from UID to UserModel for quick lookup
  return Map.fromEntries(
    users.where((user) => user != null).map((user) => MapEntry(user!.uid, user)),
  );
});


class ActivityService {
  final ProviderRef _ref;
  final CollectionReference _activityCollection =
      FirebaseFirestore.instance.collection('activities');

  ActivityService(this._ref);

  // ----------------------------------------------------
  // Stream Getter
  // ----------------------------------------------------

  Stream<List<ActivityModel>> getGlobalActivityStream() {
    return _activityCollection
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ActivityModel.fromMap(data);
      }).toList();
    });
  }

  // ----------------------------------------------------
  // Logging Methods (NEW/UPDATED)
  // ----------------------------------------------------
  
  Future<void> _logActivity(ActivityModel activity) async {
    await _activityCollection.add(activity.toMap());
  }

  Future<void> logChallengeSent(String battleId, String challengerUid, String opponentUid) async {
    final activity = ActivityModel(
      id: '',
      battleId: battleId,
      challengerUid: challengerUid,
      opponentUid: opponentUid,
      type: ActivityType.challengeSent,
      timestamp: DateTime.now(),
    );
    await _logActivity(activity);
  }

  Future<void> logChallengeAccepted(String battleId, String challengerUid, String opponentUid) async {
    final activity = ActivityModel(
      id: '',
      battleId: battleId,
      challengerUid: challengerUid,
      opponentUid: opponentUid,
      type: ActivityType.challengeAccepted,
      timestamp: DateTime.now(),
    );
    await _logActivity(activity);
  }

  Future<void> logChallengeDeclined(String battleId, String challengerUid, String opponentUid) async {
    final activity = ActivityModel(
      id: '',
      battleId: battleId,
      challengerUid: challengerUid,
      opponentUid: opponentUid,
      type: ActivityType.challengeDeclined,
      timestamp: DateTime.now(),
    );
    await _logActivity(activity);
  }

  Future<void> logBattleCompleted(
    String battleId, 
    String challengerUid, 
    String opponentUid, 
    String winnerUid, 
    {int? challengerScore, int? opponentScore}
  ) async {
    final activity = ActivityModel(
      id: '',
      battleId: battleId,
      challengerUid: challengerUid,
      opponentUid: opponentUid,
      winnerUid: winnerUid,
      challengerScore: challengerScore,
      opponentScore: opponentScore,
      type: ActivityType.battleCompleted,
      timestamp: DateTime.now(),
    );
    await _logActivity(activity);
  }
}