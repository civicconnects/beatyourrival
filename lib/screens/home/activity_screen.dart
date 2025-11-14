// lib/screens/home/activity_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/activity_model.dart';
import '../../models/user_model.dart';
import '../../services/activity_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(globalActivityStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Feed'),
        centerTitle: true,
      ),
      body: activityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading activity: $e')),
        data: (activities) {
          if (activities.isEmpty) {
            return const Center(
              child: Text('No recent activity yet. Start a battle!'),
            );
          }

          // Fetch all user profiles related to the activities
          final usersAsync = ref.watch(activityUsersProvider(activities));

          return usersAsync.when(
            loading: () => const Center(child: Text('Loading user data...')),
            error: (e, st) => Center(child: Text('Error loading users: $e')),
            data: (usersMap) {
              return ListView.builder(
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return ActivityTile(activity: activity, usersMap: usersMap);
                },
              );
            },
          );
        },
      ),
    );
  }
}

// --- Activity Tile Widget ---

class ActivityTile extends StatelessWidget {
  final ActivityModel activity;
  final Map<String, UserModel> usersMap;

  const ActivityTile({
    super.key,
    required this.activity,
    required this.usersMap,
  });

  @override
  Widget build(BuildContext context) {
    // Helper function to safely get a username
    String getUsername(String uid) => usersMap[uid]?.username ?? 'Unknown User';

    IconData icon;
    Color color;
    TextSpan message;

    final challengerName = getUsername(activity.challengerUid);
    final opponentName = getUsername(activity.opponentUid);
    final timeAgo = timeago.format(activity.timestamp);

    switch (activity.type) {
      case ActivityType.challengeSent:
        icon = Icons.send;
        color = Colors.blue;
        message = TextSpan(
          children: [
            TextSpan(text: '$challengerName ', style: const TextStyle(fontWeight: FontWeight.bold)),
            const TextSpan(text: 'challenged '),
            TextSpan(text: opponentName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const TextSpan(text: ' to a battle.'),
          ],
        );
        break;

      case ActivityType.challengeAccepted:
        icon = Icons.check_circle;
        color = Colors.green;
        message = TextSpan(
          children: [
            TextSpan(text: opponentName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const TextSpan(text: ' accepted the challenge from '),
            TextSpan(text: challengerName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const TextSpan(text: '. Battle is ON!'),
          ],
        );
        break;

      case ActivityType.challengeDeclined:
        icon = Icons.cancel;
        color = Colors.red;
        message = TextSpan(
          children: [
            TextSpan(text: opponentName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const TextSpan(text: ' declined the challenge from '),
            TextSpan(text: challengerName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const TextSpan(text: '.'),
          ],
        );
        break;

      case ActivityType.battleCompleted:
        icon = Icons.military_tech;
        color = Colors.purple;
        String winnerText;

        if (activity.winnerUid == 'Draw') {
          winnerText = 'The battle between $challengerName and $opponentName ended in a Draw.';
        } else if (activity.winnerUid != null) {
          final winnerName = getUsername(activity.winnerUid!);
          winnerText = '$winnerName won the battle against $opponentName.';
        } else {
          winnerText = 'A battle was completed.';
        }

        message = TextSpan(
          text: winnerText,
          style: const TextStyle(fontWeight: FontWeight.w600),
        );
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: RichText(text: message),
        trailing: Text(
          timeAgo,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}