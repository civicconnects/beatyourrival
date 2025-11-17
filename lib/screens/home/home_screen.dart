// lib/screens/home/home_screen.dart
// --- START COPY & PASTE HERE ---

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/navigation_provider.dart'; 

// Import all the screens for the tabs
import 'dashboard_screen.dart';
import 'battles_screen.dart';     // FIX: Added BattlesScreen import
import 'search_screen.dart';
import 'leaderboard_screen.dart'; 
import 'friends_screen.dart';     
import 'activity_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // FIX: Made the list 'static const' AND added all 7 pages
  static const List<Widget> _pages = [
    DashboardScreen(),    // Index 0
    BattlesScreen(),      // Index 1
    SearchScreen(),     // Index 2
    LeaderboardScreen(),// Index 3
    FriendsScreen(),    // Index 4
    ActivityScreen(),   // Index 5
    ProfileScreen(),    // Index 6
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the centralized provider for the current tab index
    final selectedIndex = ref.watch(homeTabIndexProvider);

    return Scaffold(
      // Display the page that corresponds to the selected index
      body: _pages[selectedIndex],
      
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bolt), // Battles icon
            label: 'Battles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Rankings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people), // Friends icon
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
// --- END COPY & PASTE HERE ---