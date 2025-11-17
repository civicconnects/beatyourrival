// lib/screens/home/search_screen.dart
// --- START COPY & PASTE HERE ---
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart';
import '../../services/battle_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../models/battle_model.dart';
import 'profile_screen.dart'; 
import '../battle/battle_detail_screen.dart';
import '../../providers/navigation_provider.dart'; 

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedGenre;
  int _selectedRounds = 1; // Default to 1 round

  @override
  void initState() {
    super.initState();
    // Initialize TabController with 2 tabs
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Find Users'),
            Tab(text: 'Active Battles (Spectate)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(context),
          _buildActiveBattlesList(context),
        ],
      ),
    );
  }

  // --- TAB 1: FIND USERS ---
  Widget _buildUserList(BuildContext context) {
    final usersAsyncValue = ref.watch(allUserProfilesStreamProvider);
    final currentUid = ref.watch(authStateChangesProvider).value?.uid;

    return usersAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (users) {
        final searchableUsers = users.where((user) => user.uid != currentUid).toList();

        if (searchableUsers.isEmpty) {
          return const Center(child: Text('No other users found.'));
        }

        return ListView.builder(
          itemCount: searchableUsers.length,
          itemBuilder: (context, index) {
            final user = searchableUsers[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
                child: user.profileImageUrl == null ? Text(user.username[0].toUpperCase()) : null,
              ),
              title: Text(user.username),
              subtitle: Text('ELO: ${user.eloScore.toStringAsFixed(0)}'),
              trailing: ElevatedButton(
                onPressed: () => _showChallengeDialog(context, ref, currentUid!, user),
                child: const Text('Challenge'),
              ),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ProfileScreen(targetUid: user.uid),
                ));
              },
            );
          },
        );
      },
    );
  }

  // --- TAB 2: ACTIVE BATTLES (SPECTATOR MODE) ---
  Widget _buildActiveBattlesList(BuildContext context) {
    // Uses the provider we added to battle_service.dart
    final battlesAsync = ref.watch(allActiveBattlesStreamProvider);

    return battlesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (battles) {
        if (battles.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No active battles right now.\nStart one yourself!', textAlign: TextAlign.center),
            ),
          );
        }

        return ListView.builder(
          itemCount: battles.length,
          itemBuilder: (context, index) {
            final battle = battles[index];
            return _ActiveBattleTile(battle: battle);
          },
        );
      },
    );
  }

  void _showChallengeDialog(
      BuildContext context, WidgetRef ref, String challengerUid, UserModel opponent) {
    // Reset to 1 round every time dialog opens
    _selectedRounds = 1; 
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Challenge ${opponent.username}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Select Genre'),
                    value: _selectedGenre,
                    items: ['Hip Hop', 'Pop', 'Rock', 'R&B', 'Electronic', 'Country', 'Reggae']
                        .map((genre) => DropdownMenuItem(value: genre, child: Text(genre)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedGenre = value),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Number of Rounds'),
                    value: _selectedRounds,
                    // FIX: Ensure '1' is in the list
                    items: [1, 3, 5, 7, 9]
                        .map((rounds) => DropdownMenuItem(value: rounds, child: Text('$rounds Rounds')))
                        .toList(),
                    onChanged: (value) {
                       if (value != null) setState(() => _selectedRounds = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _selectedGenre == null
                      ? null
                      : () async {
                          await ref.read(battleServiceProvider).createBattle(
                            challengerUid: challengerUid,
                            opponentUid: opponent.uid,
                            genre: _selectedGenre!,
                            maxRounds: _selectedRounds,
                          );

                          if (mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Challenge Sent!')),
                            );
                            ref.read(homeTabIndexProvider.notifier).state = 1; // Navigate to Battles tab
                          }
                        },
                  child: const Text('Send Challenge'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// --- HELPER WIDGET FOR BATTLE TILE ---
class _ActiveBattleTile extends ConsumerWidget {
  final BattleModel battle;
  const _ActiveBattleTile({required this.battle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We need to fetch names for BOTH users to display "UserA vs UserB"
    final challengerAsync = ref.watch(userProfileFutureProvider(battle.challengerUid));
    final opponentAsync = ref.watch(userProfileFutureProvider(battle.opponentUid));

    // Wait for both to load
    if (challengerAsync.isLoading || opponentAsync.isLoading) {
      return const Card(child: ListTile(title: Text('Loading battle info...')));
    }

    final cName = challengerAsync.value?.username ?? 'Unknown';
    final oName = opponentAsync.value?.username ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.remove_red_eye, color: Colors.blue), // Spectator Eye Icon
        title: Text('$cName vs $oName', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${battle.genre} • Round ${battle.currentRound}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigate to the SAME battle detail screen
          // The detail screen already has logic to handle spectators!
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => BattleDetailScreen(battleId: battle.id!),
          ));
        },
      ),
    );
  }
}
// --- END COPY & PASTE HERE ---