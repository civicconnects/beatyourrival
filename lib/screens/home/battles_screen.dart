// lib/screens/home/battles_screen.dart
// --- START COPY & PASTE HERE ---

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/battle_model.dart';
import '../../models/user_model.dart'; // We need UserModel for the opponent's profile
import '../../services/auth_service.dart';
import '../../services/battle_service.dart.old'; 
import '../../services/user_service.dart'; // Required for userProfileFutureProvider
import '../battle/battle_detail_screen.dart'; 
import '../challenge/challenge_screen.dart'; 

class BattlesScreen extends ConsumerWidget {
  const BattlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authStateChangesProvider).value?.uid;

    if (currentUserId == null) {
      return Scaffold( 
        appBar: AppBar( 
          title: const Text('⚔️ Your Active Battles'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('Please log in to view your battles.', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    final battlesAsyncValue = ref.watch(userActiveBattlesStreamProvider(currentUserId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚔️ Your Active Battles'),
        centerTitle: true,
      ),
      body: battlesAsyncValue.when(
        data: (battles) {
          if (battles.isEmpty) {
            return const Center(child: Text('You have no active or pending battles. Challenge someone!'));
          }

          return ListView.builder(
            itemCount: battles.length,
            itemBuilder: (context, index) {
              final battle = battles[index];
              final isChallenger = battle.challengerUid == currentUserId;
              // Get the *other* person's ID
              final opponentId = isChallenger ? battle.opponentUid : battle.challengerUid;

              // Use the new helper widget to display the battle
              return _BattleListTile(
                battle: battle,
                opponentId: opponentId,
                isChallenger: isChallenger,
                currentUserId: currentUserId,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading battles: $err')),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ChallengeScreen()),
          );
        },
        child: const Icon(Icons.send),
        tooltip: 'Challenge New Opponent',
      ),
    );
  }
}


// --- NEW HELPER WIDGET ---
// This widget fetches the opponent's profile to display their name
class _BattleListTile extends ConsumerWidget {
  final BattleModel battle;
  final String opponentId;
  final bool isChallenger;
  final String currentUserId;

  const _BattleListTile({
    required this.battle,
    required this.opponentId,
    required this.isChallenger,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the Future provider to get the opponent's profile
    final opponentProfileAsync = ref.watch(userProfileFutureProvider(opponentId));

    return opponentProfileAsync.when(
      data: (opponent) {
        // If the opponent profile is loaded, show the real tile
        final opponentUsername = opponent?.username ?? 'Unknown Rival';
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ListTile(
            title: Text(
              'Battle with $opponentUsername', // <-- FIX: Shows username
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Status: ${battle.status.toString().split('.').last.toUpperCase()}',
            ),
            trailing: _buildTrailingWidget(ref, battle, isChallenger),
            onTap: () {
              if (battle.id != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BattleDetailScreen(battleId: battle.id!),
                  ),
                );
              }
            },
          ),
        );
      },
      // Show placeholder tiles while loading or if an error occurs
      loading: () => const Card(
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: ListTile(
          title: Text('Loading Rival...'),
          subtitle: Text('Status: ...'),
        ),
      ),
      error: (err, stack) => Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: ListTile(
          title: const Text('Error Loading Rival'),
          subtitle: Text(err.toString()),
        ),
      ),
    );
  }

  // This is the same logic as before, just moved inside the new widget
  Widget _buildTrailingWidget(WidgetRef ref, BattleModel battle, bool isChallenger) {
    final battleService = ref.read(battleServiceProvider);

    if (battle.status == BattleStatus.pending) {
      if (isChallenger) {
        return const Text('Awaiting Acceptance');
      } else {
        // Opponent (the current user) needs to accept or decline
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => battleService.acceptChallenge(battle.id!), 
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => battleService.declineChallenge(battle.id!), 
            ),
          ],
        );
      }
    } else if (battle.status == BattleStatus.active) {
      final isMyTurn = battle.currentTurnUid == currentUserId;
      return Text(isMyTurn ? 'YOUR TURN' : 'Opponent\'s Turn',
          style: TextStyle(fontWeight: FontWeight.bold, color: isMyTurn ? Colors.blue : Colors.grey));
    }
    
    return const SizedBox.shrink();
  }
}
// --- END COPY & PASTE HERE ---