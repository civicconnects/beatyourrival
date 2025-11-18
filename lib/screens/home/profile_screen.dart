// lib/screens/home/profile_screen.dart
// --- START COPY & PASTE HERE ---

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart'; 
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/friend_service.dart'; 
import '../../providers/navigation_provider.dart'; 

class ProfileScreen extends ConsumerWidget {
  final String? targetUid; 
  const ProfileScreen({super.key, this.targetUid}); 

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAuthUid = ref.watch(authStateChangesProvider).value?.uid;
    final uidToShow = targetUid ?? currentAuthUid; 

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
              tooltip: 'Logout',
              onPressed: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true) {
                  await ref.read(authServiceProvider).signOut();
                }
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
          return _buildProfileContent(context, ref, user, currentAuthUid);
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, WidgetRef ref, UserModel targetUser, String? currentAuthUid) { 
    final currentUserProfileAsync = ref.watch(currentUserProfileStreamProvider);
    
    return currentUserProfileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading current user: $err')),
      data: (currentUser) {
        if (currentUser == null && targetUid != null) {
           return const Center(child: Text('Authenticating...'));
        }
        
        final bool showStats = (targetUid == null) || targetUser.isStatsPublic;
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor,
                  backgroundImage: targetUser.profileImageUrl != null ? NetworkImage(targetUser.profileImageUrl!) : null,
                  child: targetUser.profileImageUrl == null ? Text(
                    targetUser.username[0].toUpperCase(),
                    style: const TextStyle(fontSize: 40, color: Colors.white),
                  ) : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  targetUser.username,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 16),
              
              if (targetUid != null && currentUser != null) 
                _buildFriendButton(context, ref, currentUser, targetUser),
              
              const Divider(height: 32),
              
              // --- MY PROFILE SETTINGS ---
              if (targetUid == null) ...[
                SwitchListTile(
                  title: const Text('Ready to Battle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  subtitle: Text(targetUser.isReadyToBattle ? 'Visible in search' : 'Hidden from search'),
                  value: targetUser.isReadyToBattle,
                  onChanged: (bool isReady) {
                    ref.read(userServiceProvider).updateUserReadyStatus(targetUser.uid, isReady);
                  },
                  activeColor: Colors.green,
                  secondary: Icon(targetUser.isReadyToBattle ? Icons.shield : Icons.shield_outlined),
                ),
                SwitchListTile(
                  title: const Text('Show Win/Loss Record', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  subtitle: Text(targetUser.isStatsPublic ? 'Visible to everyone' : 'Private (Hidden)'),
                  value: targetUser.isStatsPublic,
                  onChanged: (bool isPublic) {
                    ref.read(userServiceProvider).updateUserStatsVisibility(targetUser.uid, isPublic);
                  },
                  activeColor: Colors.blue,
                  secondary: Icon(targetUser.isStatsPublic ? Icons.visibility : Icons.visibility_off),
                ),
                SwitchListTile(
                  title: const Text('Go Silent Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  subtitle: Text(targetUser.isSilentMode ? 'Notifications OFF' : 'Notifications ON'),
                  value: targetUser.isSilentMode,
                  onChanged: (bool isSilent) {
                    ref.read(userServiceProvider).updateUserSilentMode(targetUser.uid, isSilent);
                  },
                  activeColor: Colors.orange,
                  secondary: Icon(targetUser.isSilentMode ? Icons.notifications_off : Icons.notifications_active),
                ),
                const Divider(height: 32),
              ],

              _buildInfoRow('ELO Rating', targetUser.eloScore.toStringAsFixed(0), Icons.star),
              _buildInfoRow('Total Battles', targetUser.totalBattles.toString(), Icons.military_tech),
              
              if (showStats) ...[
                _buildInfoRow('Wins', targetUser.wins.toString(), Icons.emoji_events, color: Colors.green),
                _buildInfoRow('Losses', targetUser.losses.toString(), Icons.cancel, color: Colors.red),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(child: Text('Win/Loss record is private.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
                ),
              ],
              
              if (targetUid == null) 
                _buildInfoRow('Email', targetUser.email, Icons.email),
            ],
          ),
        );
      }
    );
  }

  Widget _buildFriendButton(BuildContext context, WidgetRef ref, UserModel currentUser, UserModel targetUser) {
    final friendService = ref.read(friendServiceProvider);
    final bool isFriend = currentUser.friends.contains(targetUser.uid);
    final bool hasSentRequest = targetUser.friendRequests.contains(currentUser.uid);
    final bool hasReceivedRequest = currentUser.friendRequests.contains(targetUser.uid);

    if (isFriend) {
      return Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Friends'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          onPressed: () async {
            final shouldRemove = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Remove Friend?'),
                content: Text('Are you sure you want to remove ${targetUser.username} as a friend?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
                ],
              ),
            );
            if (shouldRemove == true) {
              friendService.removeFriend(currentUser.uid, targetUser.uid);
            }
          },
        ),
      );
    }
    
    if (hasSentRequest) {
      // FIX: Removed 'const' from Center because ElevatedButton is not const
      return Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.send, size: 16),
          label: const Text('Friend Request Sent'),
          onPressed: null, 
        ),
      );
    }
    
    if (hasReceivedRequest) {
      return Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.person_add_alt_1, size: 16),
          label: const Text('Respond to Request'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          onPressed: () {
            ref.read(homeTabIndexProvider.notifier).state = 3; 
            Navigator.of(context).pop(); 
          },
        ),
      );
    }

    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.person_add, size: 16),
        label: const Text('Add Friend'),
        onPressed: () {
          friendService.sendFriendRequest(currentUser.uid, targetUser.uid);
        },
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
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          ),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}
// --- END COPY & PASTE HERE ---