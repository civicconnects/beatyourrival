// lib/screens/home/dashboard_screen.dart
// --- START COPY & PASTE HERE ---

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart';
import '../../services/battle_service.dart'; // FIX: This import was missing/broken
import '../battle/battle_detail_screen.dart';
import '../../models/battle_model.dart'; 
import '../../services/user_service.dart'; 

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(authStateChangesProvider).value?.uid;

    if (currentUid == null) {
      return const Center(child: Text('Please log in.'));
    }

    // This provider comes from battle_service.dart
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
                data: (battles) {
                  if (battles.isEmpty) {
                     // Wrap in RefreshIndicator so you can pull-to-refresh even if empty
                     return RefreshIndicator(
                       onRefresh: () async {
                         return ref.refresh(userCompletedBattlesStreamProvider(currentUid).future);
                       },
                       child: ListView(
                         physics: const AlwaysScrollableScrollPhysics(),
                         children: const [
                           SizedBox(height: 200),
                           Center(child: Text('No completed battles yet!')),
                         ],
                       ),
                     );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      return ref.refresh(userCompletedBattlesStreamProvider(currentUid).future);
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: battles.length,
                      itemBuilder: (context, index) {
                        final battle = battles[index];
                        final opponentId = battle.challengerUid == currentUid 
                            ? battle.opponentUid 
                            : battle.challengerUid;
                        
                        return _CompletedBattleTile(
                          battle: battle, 
                          opponentId: opponentId, 
                          currentUserId: currentUid
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error loading battles: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- HELPER WIDGET ---
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
    final opponentProfileAsync = ref.watch(userProfileFutureProvider(opponentId));

    return opponentProfileAsync.when(
      loading: () => const ListTile(title: Text('Loading completed battle...')),
      error: (err, stack) => ListTile(title: Text('Error loading battle: $err')),
      data: (opponent) {
        final opponentUsername = opponent?.username ?? 'Unknown Rival';
        
        final bool isWinner = battle.winnerUid == currentUserId;
        final bool isDraw = battle.winnerUid == 'Draw';

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