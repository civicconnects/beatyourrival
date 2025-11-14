// lib/screens/challenge/challenge_screen.dart
// --- START COPY & PASTE HERE ---
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../services/battle_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart'; 
import '../../providers/navigation_provider.dart'; 

class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({super.key});

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen> {
  String? _selectedGenre;
  int _selectedRounds = 3;

  @override
  Widget build(BuildContext context) {
    final usersAsyncValue = ref.watch(allUserProfilesStreamProvider);
    final currentUid = ref.watch(authStateChangesProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Start New Challenge'),
        centerTitle: true,
      ),
      body: usersAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading users: $err')),
        data: (users) {
          final searchableUsers = users.where((user) => user.uid != currentUid).toList();

          if (searchableUsers.isEmpty) {
            return const Center(child: Text('No other users found to challenge.'));
          }

          return ListView.builder(
            itemCount: searchableUsers.length,
            itemBuilder: (context, index) {
              final user = searchableUsers[index];
              return ListTile(
                title: Text(user.username),
                subtitle: Text('ELO: ${user.eloScore.toStringAsFixed(0)}'),
                trailing: ElevatedButton(
                  onPressed: () => _showChallengeDialog(context, ref, currentUid!, user),
                  child: const Text('Challenge'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showChallengeDialog(
      BuildContext context, WidgetRef ref, String challengerUid, UserModel opponent) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Challenge ${opponent.username}'),
              content: Column(
                // FIX: Corrected typo from MainAxisSizeC to MainAxisSize
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Select Genre'),
                    value: _selectedGenre,
                    items: ['Rock', 'Hip Hop', 'Electronic', 'Pop', 'Reggae']
                        .map((genre) => DropdownMenuItem(value: genre, child: Text(genre)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedGenre = value),
                    validator: (value) => value == null ? 'Please select a genre' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Number of Rounds'),
                    value: _selectedRounds,
                    items: [3, 5, 7, 9]
                        .map((rounds) => DropdownMenuItem(value: rounds, child: Text('$rounds Rounds')))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedRounds = value!),
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
                          final battleService = ref.read(battleServiceProvider);
                          
                          await battleService.createBattle(
                            challengerUid: challengerUid,
                            opponentUid: opponent.uid,
                            genre: _selectedGenre!,
                            maxRounds: _selectedRounds,
                          );

                          if (mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Challenge sent to ${opponent.username} for $_selectedRounds rounds of $_selectedGenre!')),
                            );
                            ref.read(homeTabIndexProvider.notifier).state = 2; // Navigate to Battles tab
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
// --- END COPY & PASTE HERE ---