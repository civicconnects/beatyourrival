// lib/widgets/battle_card.dart

import 'package:flutter/material.dart';
import '../models/battle_model.dart';

class BattleCard extends StatelessWidget { // <-- MUST BE 'BattleCard'
  final BattleModel battle;

  const BattleCard({super.key, required this.battle});

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color statusColor;

    switch (battle.status) {
      case BattleStatus.pending:
        statusText = 'Pending';
        statusColor = Colors.orange;
        break;
      case BattleStatus.active:
        statusText = 'Active';
        statusColor = Colors.green;
        break;
      case BattleStatus.completed:
        statusText = 'Completed';
        statusColor = Colors.blue;
        break;
      case BattleStatus.declined:
        statusText = 'Declined';
        statusColor = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        title: Text(
          'Battle ID: ${battle.id.substring(0, 8)}...',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Challenger: ${battle.challengerUid.substring(0, 5)}... vs Opponent: ${battle.opponentUid.substring(0, 5)}...',
        ),
        trailing: Chip(
          label: Text(statusText),
          backgroundColor: statusColor.withOpacity(0.2),
          labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
        ),
        onTap: () {
          // Placeholder for navigation
        },
      ),
    );
  }
}