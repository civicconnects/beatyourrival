// lib/screens/home/dashboard_screen.dart
// --- START COPY & PASTE HERE ---

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart';
import '../../services/battle_service.dart'; 
import '../battle/battle_detail_screen.dart';
import '../../models/battle_model.dart'; 
import '../../providers/navigation_provider.dart';
import '../../services/user_service.dart'; // We need this to get opponent's name

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(authStateChangesProvider).value?.uid;

    if (currentUid == null) {
      return const Center(child: Text('Please log in.'));
    }

    final completedBattlesAsync = ref.watch(userCompletedBattlesStreamProvider(currentUid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Stats Summary Coming Soon!', style: TextStyle(fontSize: 18)),
            const Divider(height: 32),
            Text(
              'Completed Battles',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: completedBattlesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error loading battles: $err')),
                data: (battles) {
                  if (battles.isEmpty) {
                    return const Center(child: Text('No completed battles yet!'));
                  }

                  return ListView.builder(
                    itemCount: battles.length,
                    itemBuilder: (context, index) {
                      final battle = battles[index];
                      // We need to find out who the opponent was
                      final opponentId = battle.challengerUid == currentUid 
                          ? battle.opponentUid 
                          : battle.challengerUid;
                      
                      // Use the new _CompletedBattleTile to show the score
                      return _CompletedBattleTile(
                        battle: battle, 
                        opponentId: opponentId, 
                        currentUserId: currentUid
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- NEW HELPER WIDGET ---
// This widget fetches the opponent's name and displays the final score
class _CompletedBattleTile extends ConsumerWidget {
  final BattleModel battle;
  final String opponentId;
  final String currentUserId;

  const _CompletedBattleTile({
    required this.battle,
    required this.opponentId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the opponent's profile to show their name
    final opponentProfileAsync = ref.watch(userProfileFutureProvider(opponentId));

    return opponentProfileAsync.when(
      loading: () => const ListTile(title: Text('Loading completed battle...')),
      error: (err, stack) => ListTile(title: Text('Error loading battle: $err')),
      data: (opponent) {
        final opponentUsername = opponent?.username ?? 'Unknown Rival';
        
        // --- FIX: This is the corrected display logic ---
        final bool isWinner = battle.winnerUid == currentUserId;
        final bool isDraw = battle.winnerUid == 'Draw'; // Check for "Draw" string

        final int myScore = (battle.challengerUid == currentUserId)
            ? (battle.challengerFinalScore ?? 0)
            : (battle.opponentFinalScore ?? 0);
            
        final int opponentScore = (battle.challengerUid == currentUserId)
            ? (battle.opponentFinalScore ?? 0)
            : (battle.challengerFinalScore ?? 0);
            
        String resultText;
        Color resultColor;
        
        if (isDraw) {
          resultText = 'DRAW';
          resultColor = Colors.grey;
        } else if (isWinner) {
          resultText = 'WIN';
          resultColor = Colors.green;
        } else {
          resultText = 'LOSS';
          resultColor = Colors.red;
        }
        // --- END FIX ---

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          child: ListTile(
            title: Text('vs $opponentUsername', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Final Score: $myScore - $opponentScore'),
            trailing: Text(
              resultText,
              style: TextStyle(color: resultColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BattleDetailScreen(battleId: battle.id!),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
// --- END COPY & PASTE HERE ---