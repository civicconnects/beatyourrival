// lib/screens/home/home_screen.dart
// --- START COPY & PASTE HERE ---

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/navigation_provider.dart'; 

// Import services to check for notifications
import '../../services/auth_service.dart';
import '../../services/battle_service.dart';
import '../../services/friend_service.dart';
import '../../services/user_service.dart';
import '../../models/battle_model.dart';

// Import all the screens for the tabs
import 'dashboard_screen.dart';
import 'battles_screen.dart'; // FIX: Re-imported BattlesScreen
import 'search_screen.dart';
import 'leaderboard_screen.dart'; 
import 'friends_screen.dart';     
import 'activity_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // FIX: This list now contains all 7 pages
  static const List<Widget> _pages = [
    DashboardScreen(),    // Index 0
    BattlesScreen(),      // Index 1 (FIX: Added BattlesScreen back)
    SearchScreen(),       // Index 2
    LeaderboardScreen(),  // Index 3
    FriendsScreen(),      // Index 4
    ActivityScreen(),     // Index 5
    ProfileScreen(),      // Index 6
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the centralized provider for the current tab index
    final selectedIndex = ref.watch(homeTabIndexProvider);
    final currentUid = ref.watch(authStateChangesProvider).value?.uid;

    // --- NOTIFICATION LOGIC ---
    bool showBattleBadge = false;
    bool showFriendBadge = false;

    if (currentUid != null) {
      // 1. Check User Profile for "Silent Mode"
      final userProfileAsync = ref.watch(currentUserProfileStreamProvider);
      
      // Only calculate badges if data is loaded AND Silent Mode is FALSE
      if (userProfileAsync.value != null && userProfileAsync.value!.isSilentMode == false) {
        
        // A. Check for Battle Notifications
        final battlesAsync = ref.watch(userActiveBattlesStreamProvider(currentUid));
        battlesAsync.whenData((battles) {
          final hasActionableBattle = battles.any((b) {
             final isMyTurn = b.status == BattleStatus.active && b.currentTurnUid == currentUid;
             final isPendingChallenge = b.status == BattleStatus.pending && b.opponentUid == currentUid;
             return isMyTurn || isPendingChallenge;
          });
          if (hasActionableBattle) showBattleBadge = true;
        });

        // B. Check for Friend Request Notifications
        final friendRequestsAsync = ref.watch(friendRequestsStreamProvider(currentUid));
        friendRequestsAsync.whenData((requests) {
          if (requests.isNotEmpty) showFriendBadge = true;
        });
      }
    }
    // --------------------------

    return Scaffold(
      // Safety check to prevent index errors
      body: selectedIndex < _pages.length ? _pages[selectedIndex] : _pages[0],
      
      bottomNavigationBar: BottomNavigationBar(
        // Set the current index from the provider
        currentIndex: selectedIndex,
        
        // This is the function that updates the provider when a tab is tapped
        onTap: (index) {
          ref.read(homeTabIndexProvider.notifier).state = index;
        },
        
        // --- Styling for the navigation bar ---
        type: BottomNavigationBarType.fixed, // Allows more than 3 items
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        // ------------------------------------
        
        // FIX: Added all 7 items to the navigation bar
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          // BATTLES TAB (With Badge)
          BottomNavigationBarItem(
            icon: showBattleBadge 
                ? const Badge(child: Icon(Icons.bolt)) 
                : const Icon(Icons.bolt),
            label: 'Battles',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Rankings',
          ),
          // FRIENDS TAB (With Badge)
          BottomNavigationBarItem(
            icon: showFriendBadge 
                ? const Badge(child: Icon(Icons.people)) 
                : const Icon(Icons.people),
            label: 'Friends',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Activity',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
// --- END COPY & PASTE HERE ---