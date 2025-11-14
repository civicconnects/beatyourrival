// lib/screens/home/leaderboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import 'profile_screen.dart'; // Import ProfileScreen

// Stream provider for the top 50 users based on ELO score
final leaderboardProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  final userService = ref.watch(userServiceProvider);
  return userService.getLeaderboard(limit: 50); // Fetch top 50 users
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Rankings'),
      ),
      body: leaderboardAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('Leaderboard is currently empty.'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final rank = index + 1;
              
              // Determine medal colors
              Color? rankColor;
              IconData? rankIcon;
              if (rank == 1) {
                rankColor = Colors.amber;
                rankIcon = Icons.emoji_events;
              } else if (rank == 2) {
                rankColor = Colors.grey.shade400;
                rankIcon = Icons.emoji_events;
              } else if (rank == 3) {
                rankColor = Colors.brown;
                rankIcon = Icons.emoji_events;
              }

              return ListTile(
                leading: Container(
                  width: 48,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (rankIcon != null) 
                        Icon(rankIcon, color: rankColor, size: 20),
                      Text(
                        '#$rank',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: rankColor ?? Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                title: Text(user.username),
                subtitle: Text('ELO: ${user.eloScore}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('W:${user.wins} L:${user.totalBattles - user.wins - user.draws}'),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
                onTap: () {
                  // FIX: Navigating to the ProfileScreen with the correct named parameter 'targetUid'
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(targetUid: user.uid),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading leaderboard: $e')),
      ),
    );
  }
}