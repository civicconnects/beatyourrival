// lib/screens/home/battles_screen.dart
// --- START COPY & PASTE HERE ---

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/battle_model.dart';
import '../../models/user_model.dart'; 
import '../../services/auth_service.dart';
import '../../services/battle_service.dart'; 
import '../../services/user_service.dart'; 
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


// --- HELPER WIDGET ---
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
    final opponentProfileAsync = ref.watch(userProfileFutureProvider(opponentId));

    return opponentProfileAsync.when(
      data: (opponent) {
        final opponentUsername = opponent?.username ?? 'Unknown Rival';
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ListTile(
            title: Text(
              'Battle with $opponentUsername', 
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Status: ${battle.status.toString().split('.').last.toUpperCase()}',
            ),
            trailing: _buildTrailingWidget(context, ref, battle, isChallenger), // FIX: Pass context
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

  // --- WIDGET WITH THE FIX ---
  Widget _buildTrailingWidget(BuildContext context, WidgetRef ref, BattleModel battle, bool isChallenger) {
    final battleService = ref.read(battleServiceProvider);

    if (battle.status == BattleStatus.pending) {
      if (isChallenger) {
        // FIX: If I am the challenger, I can cancel
        return IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          tooltip: 'Cancel Challenge',
          onPressed: () async {
            // Show confirmation dialog
            final shouldCancel = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cancel Challenge?'),
                content: const Text('Are you sure you want to cancel this challenge?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Yes, Cancel'),
                  ),
                ],
              ),
            );

            if (shouldCancel == true) {
              await battleService.cancelChallenge(battle.id!);
            }
          },
        );
      } else {
        // Opponent (the current user) needs to accept or decline
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              tooltip: 'Accept',
              onPressed: () => battleService.acceptChallenge(battle.id!), 
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: 'Decline',
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