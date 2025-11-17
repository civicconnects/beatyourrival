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
      title: _moveTitleController.text,
      link: _trackLinkController.text,
      submittedByUid: currentUid,
      round: battle.currentRound,
      submittedAt: DateTime.now(),
      votes: const {}, 
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
  
  void _showRatingDialog(String moveId) {
    double _currentSliderValue = 5;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Rate this Move'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Score: ${_currentSliderValue.round()}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Slider(
                    value: _currentSliderValue,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _currentSliderValue.round().toString(),
                    onChanged: (double value) {
                      setDialogState(() {
                        _currentSliderValue = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                     _handleVote(moveId, _currentSliderValue.round());
                     Navigator.pop(context);
                  }, 
                  child: const Text('Submit Score')
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleVote(String moveId, int score) async {
    final currentUid = ref.read(authServiceProvider).currentUser?.uid;
    if (currentUid == null) return;
    
    try {
      await ref.read(battleServiceProvider).voteForMove(
        widget.battleId, 
        moveId, 
        currentUid,
        score 
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vote cast!')));
      }
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
        Navigator.of(context).pop(); 
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

  void _showVoters(Map<String, int> votes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scores'),
        content: Text('${votes.length} people have rated this move.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
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

        // Determine User Roles
        final bool isParticipant = (currentUserId == battle.challengerUid || currentUserId == battle.opponentUid);
        final bool isSpectator = !isParticipant;
        final bool isMyTurn = battle.currentTurnUid == currentUserId;

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
                
                final bool isBattleOverAndUnjudged = battle.status == BattleStatus.completed && battle.winnerUid == null;

                final List<Widget> bodyWidgets = [
                    _buildBattleHeader(battle, isSpectator),
                    const Divider(height: 32),
                ];
                
                // --- WIDGET LOGIC ---
                if (battle.status == BattleStatus.completed && battle.winnerUid != null) {
                  // 1. Battle Finished & Judged
                  bodyWidgets.add(_buildFinalScore(context, battle, currentUserId, opponentUsername, isSpectator));
                }
                else if (isBattleOverAndUnjudged) {
                  // 2. Battle Finished, Needs Judging
                  if (isParticipant) {
                    bodyWidgets.add(_buildFinalizeButton(battle));
                  } else {
                     bodyWidgets.add(const Center(child: Text("Voting in progress... cast your vote below!", style: TextStyle(fontStyle: FontStyle.italic))));
                  }
                }
                else if (battle.status == BattleStatus.active) {
                  // 3. Active Battle
                  if (isMyTurn && isParticipant) {
                    bodyWidgets.add(_buildSubmissionForm(battle));
                  } else {
                     String msg = isSpectator 
                        ? "Battle in progress. Round ${battle.currentRound}." 
                        : "Waiting for $opponentUsername to submit their move...";
                     bodyWidgets.add(_buildInfoMessage(msg, Icons.hourglass_empty));
                  }
                }
                else if (battle.status == BattleStatus.pending) {
                  // 4. Pending Challenge
                  if (isSpectator) {
                     bodyWidgets.add(_buildInfoMessage("Challenge Pending Acceptance.", Icons.pending));
                  } else {
                     bodyWidgets.add(_buildPendingMessage(battle, currentUserId, opponentUsername));
                  }
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
                    title: Text(isSpectator ? 'Spectating Battle' : 'vs $opponentUsername'),
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

  Widget _buildInfoMessage(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: TextStyle(color: Colors.grey.shade800))),
      ]),
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
            onPressed: () async {
              final shouldCancel = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cancel Challenge?'),
                  content: const Text('Are you sure you want to cancel this challenge?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Cancel')),
                  ],
                ),
              );

              if (shouldCancel == true && mounted) {
                await ref.read(battleServiceProvider).cancelChallenge(battle.id!);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade100,
            child: Text('You have been challenged by $opponentUsername!'),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Accept'),
                onPressed: () => ref.read(battleServiceProvider).acceptChallenge(battle.id!),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('Decline'),
                onPressed: () => ref.read(battleServiceProvider).declineChallenge(battle.id!),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildBattleHeader(BattleModel battle, bool isSpectator) {
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
        Row(
          children: [
             if (isSpectator) 
               Container(
                 margin: const EdgeInsets.only(right: 8),
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(4)),
                 child: Text("SPECTATING", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple.shade700)),
               ),
             Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                battle.status.toString().split('.').last.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinalScore(BuildContext context, BattleModel battle, String currentUserId, String opponentUsername, bool isSpectator) {
    // If spectator, we don't say "YOU WON", we say who won.
    // But for simplicity in this snippet, we show the neutral score.
    
    final bool isWinner = battle.winnerUid == currentUserId;
    final bool isDraw = battle.winnerUid == 'Draw';
    
    // Logic to find scores needs to be neutral if spectator
    int myScore = 0;
    int opponentScore = 0;
    
    if (isSpectator) {
       // For spectator: myScore = challenger, opponentScore = opponent
       myScore = battle.challengerFinalScore ?? 0;
       opponentScore = battle.opponentFinalScore ?? 0;
    } else {
       myScore = (battle.challengerUid == currentUserId) ? (battle.challengerFinalScore ?? 0) : (battle.opponentFinalScore ?? 0);
       opponentScore = (battle.challengerUid == currentUserId) ? (battle.opponentFinalScore ?? 0) : (battle.challengerFinalScore ?? 0);
    }

    String resultText;
    Color resultColor;
    
    if (isDraw) {
      resultText = 'DRAW';
      resultColor = Colors.grey.shade700;
    } else if (isSpectator) {
       resultText = 'BATTLE FINISHED'; // Neutral for spectator
       resultColor = Colors.blueGrey;
    } else if (isWinner) {
      resultText = 'YOU WON!';
      resultColor = Colors.green.shade700;
    } else {
      resultText = 'YOU LOST';
      resultColor = Colors.red.shade700;
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
          Text(resultText, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: resultColor)),
          const SizedBox(height: 4),
          if (isSpectator)
             Text('Challenger: $myScore - Opponent: $opponentScore', style: const TextStyle(fontSize: 16))
          else
             Text('Final Score: $myScore - $opponentScore', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildFinalizeButton(BattleModel battle) {
    return ElevatedButton(
      onPressed: _isFinalizing ? null : () => _handleFinalizeBattle(battle),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
      child: _isFinalizing
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
        : const Text('Tally Votes & Finalize Battle'),
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
                value!.isEmpty ? 'Please enter a move title' : null,
            onSaved: (value) => _moveTitleController.text = value ?? '',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _trackLinkController,
            decoration: const InputDecoration(
              labelText: 'Track Link (e.g., YouTube URL)',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value!.isEmpty ? 'Please enter a track link' : null,
            onSaved: (value) => _trackLinkController.text = value ?? '',
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
            // If I'm the user, senderName is "You". If opponent, it's their name.
            // If I'm a spectator, neither is "You".
            String senderName;
            if (move.submittedByUid == currentUserId) senderName = 'You';
            else if (move.submittedByUid == battle.challengerUid) senderName = 'Challenger'; // Or fetch name
            else senderName = 'Opponent'; // Or fetch name

            final hasVoted = move.votes.containsKey(currentUserId);

            moveWidgets.add(
              Card(
                elevation: 1,
                color: isMine ? Colors.blue.shade50 : Colors.grey.shade50,
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  title: Text(move.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Submitted by $senderName'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Display Total Score
                      Text('${move.totalScore} pts', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const SizedBox(width: 8),
                      
                      // Vote Button (Visible to everyone except the person who made the move)
                      if (!isMine)
                        IconButton(
                          icon: Icon(
                            hasVoted ? Icons.star : Icons.star_border,
                            color: hasVoted ? Colors.orange : Colors.grey,
                          ),
                          tooltip: 'Rate this move',
                          onPressed: () {
                            _showRatingDialog(move.id); 
                          },
                        ),
                    ],
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tapped on: ${move.link}')),
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