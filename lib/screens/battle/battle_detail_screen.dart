// lib/screens/battle/battle_detail_screen.dart
// --- START COPY & PASTE HERE ---
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/battle_model.dart';
import '../../models/move_model.dart';
import '../../services/auth_service.dart';
import '../../services/battle_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart'; 

const uuid = Uuid();

class BattleDetailScreen extends ConsumerStatefulWidget {
  final String battleId; 

  const BattleDetailScreen({super.key, required this.battleId});

  @override
  ConsumerState<BattleDetailScreen> createState() => _BattleDetailScreenState();
}

class _BattleDetailScreenState extends ConsumerState<BattleDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _moveTitleController;
  late final TextEditingController _trackLinkController; 
  bool _isSubmittingMove = false;
  bool _isFinalizing = false; 

  @override
  void initState() {
    super.initState();
    _moveTitleController = TextEditingController();
    _trackLinkController = TextEditingController(); 
  }

  @override
  void dispose() {
    _moveTitleController.dispose();
    _trackLinkController.dispose();
    super.dispose();
  }

  Future<void> _submitMove(BattleModel battle) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final currentUid = ref.read(authServiceProvider).currentUser?.uid;
    if (currentUid == null) return;
    
    setState(() { _isSubmittingMove = true; });

    final move = MoveModel(
      id: uuid.v4(),
      title: _moveTitleController.text.trim(),
      link: _trackLinkController.text.trim(),
      submittedByUid: currentUid,
      round: battle.currentRound,
      submittedAt: DateTime.now(),
      votes: const [], 
    );

    try {
      await ref.read(battleServiceProvider).submitMove(battle, move);
      _moveTitleController.clear();
      _trackLinkController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Move submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit move: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSubmittingMove = false; });
      }
    }
  }
  
  Future<void> _handleVote(String moveId) async {
    final currentUid = ref.read(authServiceProvider).currentUser?.uid;
    if (currentUid == null) return;
    
    try {
      await ref.read(battleServiceProvider).voteForMove(
        widget.battleId, 
        moveId, 
        currentUid,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voting failed: $e')),
        );
      }
    }
  }
  
  Future<void> _handleFinalizeBattle(BattleModel battle) async {
    setState(() { _isFinalizing = true; });
    try {
      await ref.read(battleServiceProvider).finalizeBattle(battle.id!);
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Battle finalized! Scores are in.')),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to finalize battle: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isFinalizing = false; });
      }
    }
  }

  Future<void> _handleCancelChallenge(String battleId) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Challenge?'),
        content: const Text('Are you sure you want to cancel this challenge? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (shouldCancel == true && mounted) {
      try {
        await ref.read(battleServiceProvider).cancelChallenge(battleId);
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel challenge: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authServiceProvider).currentUser?.uid;
    final battleAsync = ref.watch(battleStreamProvider(widget.battleId));

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Error: User not logged in.')),
      );
    }

    return battleAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading Battle...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error loading battle: $err')),
      ),
      data: (battle) {
        if (battle == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Battle Not Found')),
            body: const Center(child: Text('This battle does not exist.')),
          );
        }

        final opponentId = battle.challengerUid == currentUserId
            ? battle.opponentUid
            : battle.challengerUid;

        return ref.watch(userProfileFutureProvider(opponentId)).when(
              loading: () => Scaffold(
                appBar: AppBar(title: const Text('Loading Rival...')),
                body: const Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: Center(child: Text('Error loading opponent: $err')),
              ),
              data: (opponentProfile) {
                final opponentUsername = opponentProfile?.username ?? 'Unknown Rival';
                final isMyTurn = battle.currentTurnUid == currentUserId;
                
                final bool isBattleOverAndUnjudged = battle.status == BattleStatus.completed && battle.winnerUid == null;

                final List<Widget> bodyWidgets = [
                    _buildBattleHeader(battle),
                    const Divider(height: 32),
                ];
                
                if (battle.status == BattleStatus.completed && battle.winnerUid != null) {
                  bodyWidgets.add(_buildFinalScore(context, battle, currentUserId, opponentUsername));
                }
                else if (isBattleOverAndUnjudged) {
                  bodyWidgets.add(_buildFinalizeButton(battle));
                }
                else if (battle.status == BattleStatus.active && isMyTurn) {
                  bodyWidgets.add(_buildSubmissionForm(battle));
                }
                else if (battle.status == BattleStatus.active && !isMyTurn) {
                  bodyWidgets.add(_buildWaitingMessage(context, opponentUsername));
                }
                else if (battle.status == BattleStatus.pending) {
                  bodyWidgets.add(_buildPendingMessage(battle, currentUserId, opponentUsername));
                }
                
                bodyWidgets.addAll([
                  const Divider(height: 32),
                  Text(
                    'Moves History',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  _buildMovesHistory(context, battle, currentUserId, opponentUsername),
                ]);

                return Scaffold(
                  appBar: AppBar(
                    title: Text('vs $opponentUsername'),
                    centerTitle: true,
                  ),
                  body: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: bodyWidgets, 
                  ),
                );
              },
            );
      },
    );
  }

  Widget _buildPendingMessage(BattleModel battle, String currentUserId, String opponentUsername) {
    final isChallenger = battle.challengerUid == currentUserId;

    if (isChallenger) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.yellow.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.yellow.shade700)
            ),
            child: Center(
              child: Text(
                'Waiting for $opponentUsername to accept the challenge.',
                style: TextStyle(fontSize: 16, color: Colors.yellow.shade900),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.cancel_schedule_send, size: 18),
            label: const Text('Cancel Challenge'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _handleCancelChallenge(battle.id!),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade700)
            ),
            child: Text(
              'You have been challenged by $opponentUsername!', 
              textAlign: TextAlign.center, 
              style: TextStyle(fontSize: 16, color: Colors.blue.shade900)
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                    onPressed: () async {
                      try {
                        await ref.read(battleServiceProvider).acceptChallenge(battle.id!);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to accept: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Decline'),
                    onPressed: () async {
                      try {
                        await ref.read(battleServiceProvider).declineChallenge(battle.id!);
                        if (mounted && Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to decline: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildBattleHeader(BattleModel battle) {
    String statusText;
    Color statusColor;

    switch (battle.status) {
      case BattleStatus.active:
        statusText = 'Active Battle';
        statusColor = Colors.green;
        break;
      case BattleStatus.pending:
        statusText = 'Pending Challenge';
        statusColor = Colors.orange;
        break;
      case BattleStatus.completed:
        statusText = 'Battle Finished';
        statusColor = Colors.red;
        break;
      case BattleStatus.declined:
        statusText = 'Challenge Declined';
        statusColor = Colors.grey;
        break;
      case BattleStatus.rejected:
        statusText = 'Challenge Rejected';
        statusColor = Colors.grey;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (battle.status != BattleStatus.completed)
              Text('Round ${battle.currentRound} of ${battle.maxRounds}',
                  style: const TextStyle(fontSize: 16)),
            Text('Genre: ${battle.genre}',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            statusText.toUpperCase(),
            style: TextStyle(
                color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalScore(BuildContext context, BattleModel battle, String currentUserId, String opponentUsername) {
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
    IconData resultIcon;
    
    if (isDraw) {
      resultText = 'The battle was a Draw!';
      resultColor = Colors.grey.shade700;
      resultIcon = Icons.handshake;
    } else if (isWinner) {
      resultText = 'You are the Winner!';
      resultColor = Colors.green.shade700;
      resultIcon = Icons.emoji_events;
    } else {
      resultText = 'You were defeated.';
      resultColor = Colors.red.shade700;
      resultIcon = Icons.warning;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: resultColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: resultColor.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(resultIcon, color: resultColor, size: 40),
          const SizedBox(height: 8),
          Text(
            resultText,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: resultColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Final Score: $myScore (You) - $opponentScore ($opponentUsername)',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalizeButton(BattleModel battle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              const Text(
                'The battle is complete! All moves are in.',
                style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Cast your votes now. When ready, a participant can finalize the battle.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isFinalizing ? null : () => _handleFinalizeBattle(battle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isFinalizing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                  : const Text('Tally Votes & Finalize Battle'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingMessage(BuildContext context, String opponentUsername) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Colors.blue, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Waiting for $opponentUsername to submit their move...',
              style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionForm(BattleModel battle) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Submit Your Move (Round ${battle.currentRound})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _moveTitleController,
            decoration: const InputDecoration(
              labelText: 'Move Title (e.g., Artist - Song Name)',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Please enter a move title' : null,
            onSaved: (value) => _moveTitleController.text = value?.trim() ?? '',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _trackLinkController,
            decoration: const InputDecoration(
              labelText: 'Track Link (e.g., YouTube URL)',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Please enter a track link' : null,
            onSaved: (value) => _trackLinkController.text = value?.trim() ?? '',
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSubmittingMove ? null : () => _submitMove(battle),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 18),
            ),
            child: _isSubmittingMove 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                : const Text('Submit Move'),
          ),
        ],
      ),
    );
  }

  Widget _buildMovesHistory(BuildContext context, BattleModel battle,
      String currentUserId, String opponentUsername) {
    final movesAsync = ref.watch(battleMovesStreamProvider(battle.id!));
    
    return movesAsync.when(
      loading: () => const Center(child: LinearProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading moves: $err')),
      data: (moves) {
        if (moves.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text('No moves submitted yet for this round.',
                  style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        final List<Widget> moveWidgets = [];

        final movesByRound = <int, List<MoveModel>>{};
        for (var move in moves) {
          movesByRound.putIfAbsent(move.round, () => []).add(move);
        }

        final sortedRounds = movesByRound.keys.toList()..sort((a, b) => b.compareTo(a));

        for (var round in sortedRounds) {
          final movesInRound = movesByRound[round]!;
          
          moveWidgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: Text(
                'Round $round Moves:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );

          for (var move in movesInRound) {
            final isMine = move.submittedByUid == currentUserId;
            final senderName = isMine ? 'You' : opponentUsername;
            final hasVoted = move.votes.contains(currentUserId);

            moveWidgets.add(
              Card(
                elevation: 1,
                color: isMine ? Colors.blue.shade50 : Colors.grey.shade50,
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  title: Text(move.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Submitted by $senderName'),
                  trailing: isMine
                    ? Text('${move.votes.length} Vote${move.votes.length == 1 ? '' : 's'}')
                    : IconButton(
                        icon: Icon(
                          hasVoted ? Icons.favorite : Icons.favorite_border,
                          color: hasVoted ? Colors.red : Colors.grey,
                        ),
                        tooltip: 'Vote for this move',
                        onPressed: () {
                          _handleVote(move.id);
                        },
                      ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Track link: ${move.link}')),
                    );
                  },
                ),
              ),
            );
          }
        }

        return Column(children: moveWidgets);
      },
    );
  }
}
// --- END COPY & PASTE HERE ---