// lib/screens/home/profile_screen.dart
// --- START COPY & PASTE HERE ---
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class ProfileScreen extends ConsumerWidget {
  final String? targetUid;
  const ProfileScreen({super.key, this.targetUid}); 

  @override
  Widget build(BuildContext context, WidgetRef ref) { // 'ref' is available here
    final currentUid = ref.watch(authStateChangesProvider).value?.uid;
    final uidToShow = targetUid ?? currentUid; 

    if (uidToShow == null) {
      return const Scaffold(body: Center(child: Text('User not found.')));
    }

    final userProfileAsync = ref.watch(userProfileStreamProvider(uidToShow));
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: targetUid != null, 
        title: Text(targetUid == null ? 'My Profile' : 'User Profile'),
        actions: [
          if (targetUid == null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                ref.read(authServiceProvider).signOut();
              },
            ),
        ],
      ),
      body: userProfileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading profile: $err')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User profile not found.'));
          }
          // FIX: Pass 'ref' to the helper method
          return _buildProfileContent(context, ref, user); 
        },
      ),
    );
  }

  // FIX: Added 'WidgetRef ref' as a parameter
  Widget _buildProfileContent(BuildContext context, WidgetRef ref, UserModel user) { 
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).primaryColor,
              backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
              child: user.profileImageUrl == null ? Text(
                user.username[0].toUpperCase(),
                style: const TextStyle(fontSize: 40, color: Colors.white),
              ) : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user.username,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const Divider(height: 32),
          // --- V3.0 STATUS TOGGLE ---
          SwitchListTile(
            title: const Text('Ready to Battle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            subtitle: Text(user.isReadyToBattle ? 'You are visible to challengers' : 'You are hidden from search'),
            value: user.isReadyToBattle,
            onChanged: (bool isReady) {
              // FIX: 'ref' is now available here
              ref.read(userServiceProvider).updateUserReadyStatus(user.uid, isReady);
            },
            activeColor: Colors.green,
            secondary: Icon(user.isReadyToBattle ? Icons.shield : Icons.shield_outlined),
          ),
          // --------------------------------
          const Divider(height: 32),
          _buildInfoRow('ELO Rating', user.eloScore.toStringAsFixed(0), Icons.star),
          _buildInfoRow('Total Battles', user.totalBattles.toString(), Icons.military_tech),
          _buildInfoRow('Wins', user.wins.toString(), Icons.emoji_events, color: Colors.green),
          _buildInfoRow('Losses', user.losses.toString(), Icons.cancel, color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.grey.shade600, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.black87),
          ),
        ],
      ),
    );
  }
}
// --- END COPY & PASTE HERE ---