// lib/widgets/battle_list_tile.dart
// --- START COPY & PASTE HERE ---

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/battle_model.dart';
import '../services/user_service.dart';

class BattleListTile extends ConsumerWidget {
  final BattleModel battle;
  final String currentUid;
  final Widget? actionWidget; // For Accept/Reject buttons on pending challenges
  final VoidCallback? onTap;

  const BattleListTile({
    super.key,
    required this.battle,
    required this.currentUid,
    this.actionWidget,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine the opponent's UID
    final opponentUid = battle.challengerUid == currentUid 
        ? battle.opponentUid 
        : battle.challengerUid;

    // Fetch the opponent's profile asynchronously
    final opponentProfileAsync = ref.watch(userProfileFutureProvider(opponentUid));

    return opponentProfileAsync.when(
      loading: () => const ListTile(
        leading: CircularProgressIndicator(strokeWidth: 2),
        title: Text('Loading Opponent...'),
      ),
      error: (e, st) => ListTile(
        title: const Text('Error loading rival'),
        subtitle: Text(e.toString()),
      ),
      data: (opponent) {
        if (opponent == null) {
          return const ListTile(title: Text('Rival not found.'));
        }

        String statusText;
        Color statusColor;

        if (battle.status == 'pending') {
          statusText = 'Pending Challenge';
          statusColor = Colors.orange;
        } else if (battle.currentTurnUid == currentUid) {
          statusText = "IT'S YOUR TURN!";
          statusColor = Colors.deepPurple;
        } else {
          statusText = 'Waiting for ${opponent.username}';
          statusColor = Colors.blueGrey;
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              child: Text(opponent.username[0].toUpperCase()),
            ),
            title: Text(
              opponent.username,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: $statusText', style: TextStyle(color: statusColor, fontWeight: FontWeight.w500)),
                Text('ELO: ${opponent.eloScore.toInt()}'),
              ],
            ),
            trailing: actionWidget ?? const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onTap,
          ),
        );
      },
    );
  }
}
// --- END COPY & PASTE HERE ---