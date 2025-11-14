// lib/widgets/profile/user_profile_data_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

class UserProfileDataWidget extends ConsumerWidget {
  const UserProfileDataWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsyncValue = ref.watch(currentUserProfileStreamProvider);

    return userProfileAsyncValue.when(
      data: (UserModel? user) {
        if (user == null) {
          return const Center(child: Text("User profile not found."));
        }
        
        // This is where you display the actual user data
        return Column(
          children: [
            // Example of displaying data
            Text('Username: ${user.username}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Email: ${user.email}'),
            const SizedBox(height: 10),
            Text('Elo Score: ${user.eloScore}', style: const TextStyle(fontSize: 18, color: Colors.green)),
            Text('Total Battles: ${user.totalBattles}'),
            Text('Wins: ${user.battlesWon}'),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading profile: $err')),
    );
  }
}