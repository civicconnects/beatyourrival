// lib/screens/home/new_battle_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../services/battle_service.dart.old'; // REQUIRED: Import BattleService

// ----------------------------------------------------------------------
// 1. Riverpod Provider: Search Results
final searchResultsProvider = FutureProvider.family<List<UserModel>, String>((ref, query) async {
  // Use a slight delay to avoid searching on every key press (debouncing)
  await Future.delayed(const Duration(milliseconds: 300));
  
  final userService = ref.read(userServiceProvider);
  final currentUserId = ref.watch(authStateChangesProvider).value?.uid;

  if (currentUserId == null || query.trim().isEmpty || query.length < 2) {
    return [];
  }

  // NOTE: This search requires the composite index (username, uid) to be built in Firestore.
  return userService.searchUsers(query, currentUserId);
});
// ----------------------------------------------------------------------

class NewBattleScreen extends ConsumerStatefulWidget {
  const NewBattleScreen({super.key});

  @override
  ConsumerState<NewBattleScreen> createState() => _NewBattleScreenState();
}

class _NewBattleScreenState extends ConsumerState<NewBattleScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isChallenging = false; // State to manage button loading

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text != _searchQuery) {
         _onSearchChanged(_searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  // 2. UPDATED: Logic to create a battle document
  Future<void> _challengeUser(UserModel opponent) async {
    final currentUserId = ref.read(authStateChangesProvider).value?.uid;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Not authenticated.')),
      );
      return;
    }

    setState(() {
      _isChallenging = true;
    });

    try {
      final battleService = ref.read(battleServiceProvider);
      
      // Call the service method to create the battle
      await battleService.createBattle(
        challengerUid: currentUserId,
        opponentUid: opponent.uid,
      );

      // Success feedback and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Challenge sent to ${opponent.username}!')),
      );
      
      // Pop the New Battle screen to return to the main Battles list
      Navigator.of(context).pop(); 

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send challenge: $e')),
      );
    } finally {
      setState(() {
        _isChallenging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsyncValue = ref.watch(searchResultsProvider(_searchQuery));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Battle: Find Opponent'),
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Opponent Username',
                hintText: 'e.g., dwhite4388',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),

          // 2. Search Results List
          Expanded(
            child: searchResultsAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (users) {
                if (_searchQuery.isEmpty) {
                  return const Center(child: Text('Enter a username to search for a rival.'));
                }
                if (_searchQuery.length < 2) {
                  return const Center(child: Text('Type at least 2 characters to search.'));
                }
                if (users.isEmpty) {
                  // This is the message you will see if the index is still building
                  return Center(child: Text('No users found matching "$_searchQuery". (Check Firestore Index)'));
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(user.username),
                      subtitle: Text('Age: ${user.age}'),
                      trailing: ElevatedButton(
                        // Disable button while a challenge is being sent
                        onPressed: _isChallenging ? null : () => _challengeUser(user),
                        child: _isChallenging 
                            ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Challenge'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}