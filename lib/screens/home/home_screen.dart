// lib/screens/home/home_screen.dart
// --- START COPY & PASTE HERE ---

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/navigation_provider.dart'; 

// Import services to check for notifications
import '../../services/auth_service.dart';
import '../../services/battle_service.dart';
import '../../services/friend_service.dart';
import '../../models/battle_model.dart';

// Import all the screens for the tabs
import 'dashboard_screen.dart';
import 'battles_screen.dart';
import 'search_screen.dart';
import 'leaderboard_screen.dart'; 
import 'friends_screen.dart';     
import 'activity_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // This list holds the widgets for each tab
  static const List<Widget> _pages = [
    DashboardScreen(),    // Index 0
    BattlesScreen(),      // Index 1
    SearchScreen(),       // Index 2
    LeaderboardScreen(),  // Index 3
    FriendsScreen(),      // Index 4
    ActivityScreen(),     // Index 5
    ProfileScreen(),      // Index 6
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(homeTabIndexProvider);
    final currentUid = ref.watch(authStateChangesProvider).value?.uid;

    // --- NOTIFICATION LOGIC ---
    bool showBattleBadge = false;
    bool showFriendBadge = false;

    if (currentUid != null) {
      // 1. Check for Battle Notifications (My Turn or Pending Challenge)
      final battlesAsync = ref.watch(userActiveBattlesStreamProvider(currentUid));
      
      battlesAsync.whenData((battles) {
        // Check if there are ANY battles where it's my turn OR I have a pending challenge
        final hasActionableBattle = battles.any((b) {
           final isMyTurn = b.status == BattleStatus.active && b.currentTurnUid == currentUid;
           final isPendingChallenge = b.status == BattleStatus.pending && b.opponentUid == currentUid;
           return isMyTurn || isPendingChallenge;
        });
        if (hasActionableBattle) showBattleBadge = true;
      });

      // 2. Check for Friend Request Notifications
      final friendRequestsAsync = ref.watch(friendRequestsStreamProvider(currentUid));
      
      friendRequestsAsync.whenData((requests) {
        if (requests.isNotEmpty) showFriendBadge = true;
      });
    }
    // --------------------------

    return Scaffold(
      body: _pages[selectedIndex],
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          ref.read(homeTabIndexProvider.notifier).state = index;
        },
        
        type: BottomNavigationBarType.fixed, 
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        
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