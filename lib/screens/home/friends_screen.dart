// lib/screens/home/friends_screen.dart
// --- START COPY & PASTE HERE ---

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../services/friend_service.dart';
import 'profile_screen.dart'; // To tap on a friend's profile

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authStateChangesProvider).value?.uid;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Friends')),
        body: const Center(child: Text('Please log in to see your friends.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Section 1: Friend Requests ---
          Text(
            'Friend Requests',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          _buildFriendRequestsList(context, ref, currentUserId),
          
          const Divider(height: 32),

          // --- Section 2: Current Friends ---
          Text(
            'Your Friends',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          _buildFriendsList(context, ref, currentUserId),
        ],
      ),
    );
  }

  // --- Helper Widget for Friend Requests ---
  Widget _buildFriendRequestsList(BuildContext context, WidgetRef ref, String currentUserId) {
    // Watch the new provider from friend_service.dart
    final requestsAsync = ref.watch(friendRequestsStreamProvider(currentUserId));
    final friendService = ref.read(friendServiceProvider);

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading requests: $err')),
      data: (requests) {
        if (requests.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No new friend requests.', style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return Column(
          children: requests.map((user) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
                  child: user.profileImageUrl == null ? Text(user.username[0].toUpperCase()) : null,
                ),
                title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('ELO: ${user.eloScore.toStringAsFixed(0)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Accept Button
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      tooltip: 'Accept',
                      onPressed: () {
                        friendService.acceptFriendRequest(currentUserId, user.uid);
                      },
                    ),
                    // Decline Button
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Decline',
                      onPressed: () {
                        friendService.declineFriendRequest(currentUserId, user.uid);
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // --- Helper Widget for Friends List ---
  Widget _buildFriendsList(BuildContext context, WidgetRef ref, String currentUserId) {
    // Watch the new provider from friend_service.dart
    final friendsAsync = ref.watch(friendsListStreamProvider(currentUserId));

    return friendsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading friends: $err')),
      data: (friends) {
        if (friends.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('You have not added any friends yet. Use the Search tab to find users and send requests from their profile.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return Column(
          children: friends.map((user) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
                  child: user.profileImageUrl == null ? Text(user.username[0].toUpperCase()) : null,
                ),
                title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('ELO: ${user.eloScore.toStringAsFixed(0)}'),
                onTap: () {
                  // Allow tapping on a friend to see their profile
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(targetUid: user.uid),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
// --- END COPY & PASTE HERE ---