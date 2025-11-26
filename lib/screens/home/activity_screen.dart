// lib/screens/home/activity_screen.dart
// --- START COPY & PASTE HERE ---

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/activity_model.dart';
import '../../services/activity_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import 'profile_screen.dart';
import '../battle/battle_detail_screen.dart';
import '../../providers/navigation_provider.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authStateChangesProvider).value?.uid;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Activity')),
        body: const Center(child: Text('Please log in to see activity.')),
      );
    }

    final activityAsync = ref.watch(activityFeedStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Feed'),
        centerTitle: true,
      ),
      body: activityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading activity: $err')),
        data: (activities) {
          if (activities.isEmpty) {
            return const Center(
              child: Text(
                'No recent activity.\nChallenge a user or complete a battle!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              // Use a dedicated widget to handle fetching user names
              return _ActivityTile(activity: activity);
            },
          );
        },
      ),
    );
  }
}

// A helper widget to build the correct text for each activity type
class _ActivityTile extends ConsumerWidget {
  final ActivityModel activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We need to fetch the user profiles to display their names
    final actorProfileAsync = ref.watch(userProfileFutureProvider(activity.actorUid));
    
    // Not all activities have a target user, so we handle null
    final targetProfileAsync = activity.targetUid != null
        ? ref.watch(userProfileFutureProvider(activity.targetUid!))
        : null;

    return actorProfileAsync.when(
      loading: () => const ListTile(title: Text('Loading activity...')),
      error: (err, stack) => ListTile(title: Text('Error loading user: $err')),
      data: (actor) {
        // This handles the case where the target is also loading
        return targetProfileAsync != null
            ? targetProfileAsync.when(
                loading: () => const ListTile(title: Text('Loading activity...')),
                error: (err, stack) => ListTile(title: Text('Error loading user: $err')),
                data: (target) {
                  return _buildTile(context, ref, actor?.username, target?.username);
                },
              )
            : _buildTile(context, ref, actor?.username, null); // Build with no target
      },
    );
  }

  Widget _buildTile(BuildContext context, WidgetRef ref, String? actorName, String? targetName) {
    final String actor = actorName ?? 'Someone';
    final String target = targetName ?? 'someone';
    final String time = timeago.format(activity.timestamp);
    final currentUserId = ref.watch(authStateChangesProvider).value?.uid;

    IconData icon;
    String titleText;
    VoidCallback? onTap;

    switch (activity.type) {
      case ActivityType.challengeSent:
        icon = Icons.send;
        titleText = (activity.actorUid == currentUserId) 
            ? 'You challenged $target.' 
            : '$actor challenged you.';
        onTap = () {
          if (activity.battleId != null) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => BattleDetailScreen(battleId: activity.battleId!),
            ));
          }
        };
        break;
      case ActivityType.challengeAccepted:
        icon = Icons.check_circle_outline;
        titleText = (activity.actorUid == currentUserId)
            ? 'You accepted $target\'s challenge.'
            : '$actor accepted your challenge.';
        onTap = () {
          if (activity.battleId != null) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => BattleDetailScreen(battleId: activity.battleId!),
            ));
          }
        };
        break;
      case ActivityType.challengeDeclined:
        icon = Icons.cancel_outlined;
        titleText = (activity.actorUid == currentUserId)
            ? 'You declined $target\'s challenge.'
            : '$actor declined your challenge.';
        onTap = () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ProfileScreen(targetUid: activity.actorUid),
          ));
        };
        break;
      case ActivityType.challengeCanceled:
        icon = Icons.block;
        titleText = (activity.actorUid == currentUserId)
            ? 'You canceled your challenge to $target.'
            : '$actor canceled their challenge.';
        onTap = () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ProfileScreen(targetUid: activity.actorUid),
          ));
        };
        break;
      case ActivityType.battleCompleted:
        icon = Icons.emoji_events;
        String winner = actorName ?? 'A user';
        String loser = targetName ?? 'a user';
        if (activity.actorUid == 'Draw') {
          titleText = 'A battle between $loser and $target ended in a Draw!';
          icon = Icons.handshake;
        } else if (activity.actorUid == currentUserId) {
          titleText = 'You defeated $target in a battle!';
        } else {
          titleText = '$actor defeated you in a battle.';
        }
        onTap = () {
          if (activity.battleId != null) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => BattleDetailScreen(battleId: activity.battleId!),
            ));
          }
        };
        break;
      case ActivityType.friendRequest:
        icon = Icons.person_add;
        titleText = '$actor sent you a friend request.';
        onTap = () {
          ref.read(homeTabIndexProvider.notifier).state = 4; // Go to Friends tab
        };
        break;
      case ActivityType.friendAccepted: 
        icon = Icons.people;
        titleText = (activity.actorUid == currentUserId)
            ? 'You and $target are now friends.'
            : 'You and $actor are now friends.';
        onTap = () {
          final profileId = activity.actorUid == currentUserId ? activity.targetUid : activity.actorUid;
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ProfileScreen(targetUid: profileId),
          ));
        };
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(titleText),
        subtitle: Text(time),
        onTap: onTap,
      ),
    );
  }
}
// --- END COPY & PASTE HERE ---