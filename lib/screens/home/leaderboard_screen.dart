// lib/screens/home/leaderboard_screen.dart
// --- START COPY & PASTE HERE ---

import 'package:flutter/material.dart';
// FIX: Corrected the broken import path
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import 'profile_screen.dart'; // To allow tapping on a user to see their profile

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider that streams all user profiles
    final usersAsyncValue = ref.watch(allUserProfilesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rankings'),
        centerTitle: true,
      ),
      body: usersAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading users: $err')),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          // Sort the list of users by their ELO score, from highest to lowest
          users.sort((a, b) => b.eloScore.compareTo(a.eloScore));

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final rank = index + 1; // Rank starts at 1

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  // Show the rank number
                  leading: Text(
                    '$rank',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: rank == 1 ? Colors.amber[700] : (rank == 2 ? Colors.grey[600] : (rank == 3 ? Colors.brown[600] : Colors.black)),
                    ),
                  ),
                  // Show the username
                  title: Text(
                    user.username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // Show their Win/Loss record
                  subtitle: Text('Record: ${user.wins}W - ${user.losses}L'),
                  // Show their ELO score
                  trailing: Text(
                    'ELO: ${user.eloScore.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueGrey,
                    ),
                  ),
                  onTap: () {
                    // Allow tapping on a user to navigate to their profile
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(targetUid: user.uid),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
// --- END COPY & PASTE HERE ---