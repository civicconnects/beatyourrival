import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/battle_model.dart';
import '../../models/move_model.dart';
import '../../services/auth_service.dart';
import '../../services/battle_service.dart';
import '../../services/user_service.dart';
import '../../services/activity_service.dart';
import 'video_recording_screen.dart';
import 'video_player_screen.dart';

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

  // Helper function to get category icon
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Singing': return Icons.mic;
      case 'Dancing': return Icons.directions_run;
      case 'Rapping': return Icons.speaker;
      case 'Beatboxing': return Icons.graphic_eq;
      case 'DJ Mix': return Icons.album;
      case 'Instrumental': return Icons.piano;
      case 'Freestyle':
      default: return Icons.star;
    }
  }
  
  // Helper function to get genre color
  Color _getGenreColor(String genre) {
    switch (genre) {
      case 'Hip Hop': return Colors.orange;
      case 'R&B': return Colors.purple;
      case 'Pop': return Colors.pink;
      case 'Rock': return Colors.red;
      case 'Electronic': return Colors.blue;
      case 'Jazz': return Colors.brown;
      case 'Latin': return Colors.green;
      case 'Afrobeat': return Colors.amber;
      case 'Dancehall': return Colors.teal;
      case 'Trap': return Colors.deepPurple;
      case 'Drill': return Colors.black87;
      case 'House': return Colors.indigo;
      default: return Colors.grey;
    }
  }
  
  // ✅ COMPLETE Go Live Dialog (All Features)
  void _showGoLiveDialog(BattleModel battle, String currentUserId, String opponentUsername, bool isPerformer) {
    print("🎭 Opening Go Live Dialog - isPerformer: $isPerformer");
    
    final TextEditingController titleController = TextEditingController();
    String selectedCategory = 'Freestyle';
    String selectedGenre = 'Hip Hop';
    
    final List<String> categories = [
      'Freestyle', 
      'Singing', 
      'Dancing', 
      'Rapping', 
      'Beatboxing', 
      'DJ Mix', 
      'Instrumental'
    ];
    
    final List<String> genres = [
      'Hip Hop', 
      'R&B', 
      'Pop', 
      'Rock', 
      'Electronic', 
      'Jazz', 
      'Latin', 
      'Afrobeat', 
      'Dancehall', 
      'Trap', 
      'Drill', 
      'House'
    ];
    
    void updateTitle() {
      titleController.text = '$selectedGenre $selectedCategory - Round ${battle.currentRound}';
    }
    
    updateTitle();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    isPerformer ? Icons.live_tv : Icons.remove_red_eye,
                    color: isPerformer ? Colors.red : Colors.blue,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(isPerformer ? '🎤 Go Live' : '👀 Watch Live'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPerformer) ...[
                      const Text(
                        'Performance Category:', 
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down),
                          items: categories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(
                                    _getCategoryIcon(category), 
                                    size: 20, 
                                    color: Colors.deepPurple,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(category),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setDialogState(() {
                                selectedCategory = newValue;
                                updateTitle();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      const Text(
                        'Music Genre:', 
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: selectedGenre,
                          isExpanded: true,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down),
                          items: genres.map((String genre) {
                            return DropdownMenuItem<String>(
                              value: genre,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.music_note, 
                                    size: 20, 
                                    color: _getGenreColor(genre)
                                  ),
                                  const SizedBox(width: 8),
                                  Text(genre),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setDialogState(() {
                                selectedGenre = newValue;
                                updateTitle();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      const Text(
                        'Performance Title:', 
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Freestyle Round ${battle.currentRound}',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.title),
                          helperText: 'This title will be shown to viewers',
                          helperStyle: const TextStyle(fontSize: 12),
                        ),
                        maxLength: 50,
                      ),
                    ] else ...[
                      const Center(
                        child: Icon(Icons.remove_red_eye, size: 48, color: Colors.blue),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'You are about to watch the live performance.', 
                          style: TextStyle(fontSize: 14), 
                          textAlign: TextAlign.center
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Performer: ${battle.currentTurnUid == currentUserId ? "You" : opponentUsername}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer, color: Colors.amber.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isPerformer 
                                ? 'You will have 90 seconds to perform'
                                : 'The performance will last 90 seconds',
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  icon: Icon(isPerformer ? Icons.videocam : Icons.remove_red_eye),
                  label: Text(isPerformer ? 'Start Live' : 'Watch Live'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPerformer ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onPressed: () async {
                    if (isPerformer) {
                      final moveTitle = titleController.text.trim();
                      if (moveTitle.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a performance title'))
                        );
                        return;
                      }

                      Navigator.of(context).pop(); // Close dialog
                      
                      final enhancedTitle = '[$selectedCategory] $moveTitle';
                      
                      // ✅ Navigate to Video Recording Screen
                      print("🎥 Opening video recording screen...");
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => VideoRecordingScreen(
                            battleId: battle.id!,
                            moveTitle: enhancedTitle,
                            battle: battle,
                          ),
                        ),
                      );
                      
                      // Note: Video recording screen handles move submission internally
                      print("✅ Returned from video recording screen");

                    } else {
                      // SPECTATOR: Can only watch recorded videos, not live
                      Navigator.of(context).pop(); // Close dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Spectators can watch performances after they are recorded. Check "Moves History" section.'),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 4),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // ✅ FIXED: Submit Live Move (uses battle.id!)
  Future<void> _submitLiveMove(BattleModel battle, String moveTitle) async {
    final currentUid = ref.read(authServiceProvider).currentUser?.uid;
    if (currentUid == null) return;
    
    final move = MoveModel(
      id: uuid.v4(),
      title: moveTitle, 
      link: 'LIVE_PERFORMANCE_ROUND_${battle.currentRound}',
      submittedByUid: currentUid,
      round: battle.currentRound,
      submittedAt: DateTime.now(),
      votes: const {}, 
    );

    try {
      // ✅ CRITICAL FIX: Pass battleId instead of battle object
      // Assuming BattleService.submitMove signature is now (String battleId, MoveModel move)
      await ref.read(battleServiceProvider).submitMove(battle.id!, move);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live move recorded! Turn flipped.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Failed to record live move: $e';
        if (e.toString().contains('NOT_YOUR_TURN')) {
          errorMsg = 'It is no longer your turn. Another move was submitted.';
        } else if (e.toString().contains('MOVE_CONFLICT')) {
          errorMsg = 'Move conflict detected. Please refresh the battle.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ✅ FIXED: Submit Regular Move (uses battle.id!)
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
      // ✅ CRITICAL FIX: Pass battleId instead of battle object
      // Assuming BattleService.submitMove signature is now (String battleId, MoveModel move)
      await ref.read(battleServiceProvider).submitMove(battle.id!, move);
      
      _moveTitleController.clear();
      _trackLinkController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Move submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Failed to submit move: $e';
        if (e.toString().contains('NOT_YOUR_TURN')) {
          errorMsg = 'It is no longer your turn.';
        } else if (e.toString().contains('MOVE_CONFLICT')) {
          errorMsg = 'Move conflict detected. Please refresh.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSubmittingMove = false; });
      }
    }
  }
  
  // ✅ COMPLETE Rating Dialog
  void _showRatingDialog(String moveId) {
    double currentSliderValue = 5;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Rate This Move'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${currentSliderValue.toInt()}',
                  style: const TextStyle(
                    fontSize: 48, 
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: currentSliderValue,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: currentSliderValue.round().toString(),
                  activeColor: Colors.deepPurple,
                  onChanged: (double value) {
                    setDialogState(() {
                      currentSliderValue = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  '1 = Poor, 10 = Amazing',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _handleVote(moveId, currentSliderValue.toInt());
                },
                child: const Text('Submit Rating'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ✅ Vote Handler
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote cast!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voting failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // ✅ Finalize Battle Handler
  Future<void> _handleFinalizeBattle(BattleModel battle) async {
    setState(() { _isFinalizing = true; });
    try {
      await ref.read(battleServiceProvider).finalizeBattle(battle.id!);
      
      // ✅ Log battle completion activity
      try {
        // Get updated battle to get winnerUid and scores
        final updatedBattle = await ref.read(battleServiceProvider).streamBattle(battle.id!).first;
        if (updatedBattle != null && updatedBattle.winnerUid != null) {
          await ref.read(activityServiceProvider).logBattleCompleted(
            battle.id!,
            battle.challengerUid,
            battle.opponentUid,
            updatedBattle.winnerUid!,
            challengerScore: updatedBattle.challengerFinalScore,
            opponentScore: updatedBattle.opponentFinalScore,
          );
        }
      } catch (activityError) {
        print('⚠️ Failed to log battle completion activity: $activityError');
        // Don't fail the finalization if activity logging fails
      }
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Battle finalized! Scores are in.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); 
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to finalize battle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isFinalizing = false; });
      }
    }
  }

  // ✅ Show Voters Dialog
  void _showVoters(Map<String, int> votes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voter Scores'),
        content: SizedBox(
          width: double.maxFinite,
          child: votes.isEmpty 
            ? const Text('No votes yet')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: votes.length,
                itemBuilder: (context, index) {
                  final entry = votes.entries.elementAt(index);
                  return _VoterTile(userId: entry.key, score: entry.value);
                },
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Close')
          )
        ],
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

        final bool isParticipant = (currentUserId == battle.challengerUid || 
                                    currentUserId == battle.opponentUid);
        final bool isSpectator = !isParticipant;
        final bool isMyTurn = battle.currentTurnUid == currentUserId;
        
        print("🎮 Battle Status: ${battle.status}, Round: ${battle.currentRound}/${battle.maxRounds}, My Turn: $isMyTurn");

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
                
                final bool isBattleOverAndUnjudged = 
                  battle.status == BattleStatus.completed && battle.winnerUid == null;

                final List<Widget> bodyWidgets = [
                    _buildBattleHeader(battle, isSpectator),
                    
                    // ✅ LIVE BUTTON (Complete with all logic)
                    if (battle.status == BattleStatus.active)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            icon: Icon(
                              isMyTurn && isParticipant 
                                ? Icons.videocam 
                                : Icons.remove_red_eye
                            ),
                            label: Text(
                              isMyTurn && isParticipant 
                                ? '📹 START LIVE PERFORMANCE' 
                                : (!isParticipant 
                                    ? '🔴 WATCH LIVE STREAM' 
                                    : '👀 WATCH OPPONENT LIVE'),
                              style: const TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isMyTurn && isParticipant 
                                ? Colors.green 
                                : Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              final bool shouldPerform = isMyTurn && isParticipant;
                              print("🎬 Live button pressed - Should Perform: $shouldPerform");
                              
                              _showGoLiveDialog(
                                battle, 
                                currentUserId, 
                                opponentUsername,
                                shouldPerform, 
                              );
                            },
                          ),
                        ),
                      ),
                    
                    const Divider(height: 32),
                ];
                
                // ✅ Final Score Display (if battle completed)
                if (battle.status == BattleStatus.completed && battle.winnerUid != null) {
                  bodyWidgets.add(
                    _buildFinalScore(context, battle, currentUserId, opponentUsername, isSpectator)
                  );
                }
                // ✅ Finalize Button (if voting phase)
                else if (isBattleOverAndUnjudged) {
                  if (isParticipant) {
                    bodyWidgets.add(_buildFinalizeButton(battle));
                  } else {
                    bodyWidgets.add(
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "Voting in progress... cast your vote below!",
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }
                }
                // ✅ Active Battle UI
                else if (battle.status == BattleStatus.active) {
                  if (isMyTurn && isParticipant) {
                    bodyWidgets.add(_buildSubmissionForm(battle));
                  } else {
                    String msg = isSpectator 
                        ? "Battle in progress. Round ${battle.currentRound}." 
                        : "Waiting for $opponentUsername to submit their move...";
                    bodyWidgets.add(_buildInfoMessage(msg, Icons.hourglass_empty));
                  }
                }
                // ✅ Pending Challenge UI
                else if (battle.status == BattleStatus.pending) {
                  if (isSpectator) {
                    bodyWidgets.add(
                      _buildInfoMessage("Challenge Pending Acceptance.", Icons.pending)
                    );
                  } else {
                    bodyWidgets.add(
                      _buildPendingMessage(battle, currentUserId, opponentUsername)
                    );
                  }
                }
                
                // ✅ Moves History
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
                    title: Text(
                      isSpectator ? 'Spectating Battle' : 'vs $opponentUsername'
                    ),
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

  // ✅ Info Message Widget
  Widget _buildInfoMessage(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message, 
              style: TextStyle(color: Colors.grey.shade800)
            )
          ),
        ],
      ),
    );
  }

  // ✅ COMPLETE Pending Message (Accept/Decline/Cancel)
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
                style: TextStyle(
                  fontSize: 16, 
                  color: Colors.yellow.shade900,
                  fontWeight: FontWeight.w500,
                ),
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
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () async {
              final shouldCancel = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cancel Challenge?'),
                  content: const Text(
                    'Are you sure you want to cancel this challenge?'
                  ),
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
                await ref.read(battleServiceProvider).cancelChallenge(battle.id!);
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
      );
    } else {
      // Opponent view - Accept or Decline
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'You have been challenged by $opponentUsername!', 
              textAlign: TextAlign.center, 
              style: TextStyle(
                fontSize: 16, 
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Accept'),
                  onPressed: () => ref.read(battleServiceProvider).acceptChallenge(battle.id!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, 
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('Decline'),
                  onPressed: () => ref.read(battleServiceProvider).declineChallenge(battle.id!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, 
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  // ✅ Battle Header
  Widget _buildBattleHeader(BattleModel battle, bool isSpectator) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (battle.status != BattleStatus.completed)
              Text(
                'Round ${battle.currentRound} of ${battle.maxRounds}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 4),
            Text(
              'Genre: ${battle.genre}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        Row(
          children: [
            if (isSpectator) 
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50, 
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.purple.shade300),
                ),
                child: Text(
                  "SPECTATING", 
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.purple.shade700,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(battle.status),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                battle.status.toString().split('.').last.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper to get status color
  Color _getStatusColor(BattleStatus status) {
    switch (status) {
      case BattleStatus.active: return Colors.green;
      case BattleStatus.pending: return Colors.orange;
      case BattleStatus.completed: return Colors.blue;
      case BattleStatus.declined: return Colors.red;
      case BattleStatus.rejected: return Colors.grey;
    }
  }

  // ✅ Final Score Display
  Widget _buildFinalScore(
    BuildContext context, 
    BattleModel battle, 
    String currentUserId, 
    String opponentUsername, 
    bool isSpectator
  ) {
    final bool isWinner = battle.winnerUid == currentUserId;
    final bool isDraw = battle.winnerUid == 'Draw';
    
    int myScore = 0;
    int opponentScore = 0;
    
    if (isSpectator) {
        myScore = battle.challengerFinalScore ?? 0;
        opponentScore = battle.opponentFinalScore ?? 0;
    } else {
        myScore = (battle.challengerUid == currentUserId) 
          ? (battle.challengerFinalScore ?? 0) 
          : (battle.opponentFinalScore ?? 0);
        opponentScore = (battle.challengerUid == currentUserId) 
          ? (battle.opponentFinalScore ?? 0) 
          : (battle.challengerFinalScore ?? 0);
    }

    String resultText;
    Color resultColor;
    IconData resultIcon;
    
    if (isDraw) {
      resultText = 'DRAW';
      resultColor = Colors.grey.shade700;
      resultIcon = Icons.handshake;
    } else if (isSpectator) {
        resultText = 'BATTLE FINISHED';
        resultColor = Colors.blueGrey;
        resultIcon = Icons.sports_kabaddi;
    } else if (isWinner) {
      resultText = 'YOU WON!';
      resultColor = Colors.green.shade700;
      resultIcon = Icons.emoji_events;
    } else {
      resultText = 'YOU LOST';
      resultColor = Colors.red.shade700;
      resultIcon = Icons.sentiment_dissatisfied;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: resultColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: resultColor.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Icon(resultIcon, size: 48, color: resultColor),
          const SizedBox(height: 8),
          Text(
            resultText, 
            style: TextStyle(
              fontSize: 28, 
              fontWeight: FontWeight.bold, 
              color: resultColor,
            ),
          ),
          const SizedBox(height: 8),
          if (isSpectator)
              Text(
                'Challenger: $myScore - Opponent: $opponentScore', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              )
          else
              Text(
                'Final Score: $myScore - $opponentScore', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
        ],
      ),
    );
  }

  // ✅ Finalize Button
  Widget _buildFinalizeButton(BattleModel battle) {
    return ElevatedButton.icon(
      onPressed: _isFinalizing ? null : () => _handleFinalizeBattle(battle),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue, 
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      icon: _isFinalizing 
        ? const SizedBox(
            width: 20, 
            height: 20, 
            child: CircularProgressIndicator(
              strokeWidth: 3, 
              color: Colors.white,
            ),
          )
        : const Icon(Icons.how_to_vote),
      label: Text(
        _isFinalizing ? 'Finalizing...' : 'Tally Votes & Finalize Battle',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  // ✅ COMPLETE Submission Form
  Widget _buildSubmissionForm(BattleModel battle) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Submit Your Move (Round ${battle.currentRound})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _moveTitleController,
                decoration: const InputDecoration(
                  labelText: 'Move Title',
                  hintText: 'e.g., Artist - Song Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a move title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _trackLinkController,
                decoration: const InputDecoration(
                  labelText: 'Track Link',
                  hintText: 'YouTube, SoundCloud, etc.',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a track link';
                  }
                  final uri = Uri.tryParse(value);
                  if (uri == null || !uri.hasAbsolutePath) {
                    return 'Please enter a valid URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isSubmittingMove ? null : () => _submitMove(battle),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18),
                ),
                icon: _isSubmittingMove 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(
                        color: Colors.white, 
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(Icons.send),
                label: Text(_isSubmittingMove ? 'Submitting...' : 'Submit Move'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ COMPLETE Moves History
  Widget _buildMovesHistory(
    BuildContext context, 
    BattleModel battle,
    String currentUserId, 
    String opponentUsername
  ) {
    final movesAsync = ref.watch(battleMovesStreamProvider(widget.battleId));
    
    return movesAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error loading moves: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      data: (moves) {
        if (moves.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No moves submitted yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        // Group moves by round
        final movesByRound = <int, List<MoveModel>>{};
        for (var move in moves) {
          movesByRound.putIfAbsent(move.round, () => []).add(move);
        }

        final sortedRounds = movesByRound.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        final List<Widget> moveWidgets = [];

        for (var round in sortedRounds) {
          final movesInRound = movesByRound[round]!;
          
          moveWidgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.military_tech, size: 20, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Text(
                    'Round $round',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
          );

          for (var move in movesInRound) {
            final isMine = move.submittedByUid == currentUserId;
            String senderName;
            
            if (move.submittedByUid == currentUserId) {
              senderName = 'You';
            } else if (move.submittedByUid == battle.challengerUid) {
              senderName = 'Challenger';
            } else {
              senderName = 'Opponent';
            }

            final hasVoted = move.votes.containsKey(currentUserId);
            final int myScore = move.votes[currentUserId] ?? 0;

            // Check if move has a valid video URL
            final bool hasVideo = move.link.isNotEmpty && 
                                  move.link.startsWith('http') && 
                                  !move.link.contains('LIVE_PERFORMANCE_ROUND') &&
                                  !move.link.contains('PENDING_LIVEKIT_RECORDING');
            
            moveWidgets.add(
              Card(
                elevation: 1,
                color: isMine ? Colors.blue.shade50 : Colors.grey.shade50,
                margin: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isMine ? Colors.blue : Colors.grey,
                        child: Text(
                          senderName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        move.title, 
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Submitted by $senderName'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            icon: const Icon(
                              Icons.people_outline, 
                              size: 16, 
                              color: Colors.blueGrey,
                            ),
                            label: Text(
                              '${move.totalScore} pts', 
                              style: const TextStyle(
                                color: Colors.blueGrey, 
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () => _showVoters(move.votes),
                          ),
                          const SizedBox(width: 8),
                          if (!isMine)
                            IconButton(
                              icon: Icon(
                                hasVoted ? Icons.star : Icons.star_border,
                                color: hasVoted ? Colors.orange : Colors.grey,
                              ),
                              tooltip: hasVoted 
                                ? 'You rated this $myScore/10' 
                                : 'Rate this move',
                              onPressed: () => _showRatingDialog(move.id),
                            ),
                        ],
                      ),
                    ),
                    // Watch Video Button
                    if (hasVideo)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              print('🎥 Opening video player for: ${move.link}');
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => VideoPlayerScreen(
                                    videoUrl: move.link,
                                    title: '${senderName}\'s Performance',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_circle_outline),
                            label: Text(isMine ? 'Watch Your Performance' : 'Watch Performance'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                  ],
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

// ✅ Voter Tile Widget
class _VoterTile extends ConsumerWidget {
  final String userId;
  final int score;
  
  const _VoterTile({required this.userId, required this.score});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileFutureProvider(userId));

    return userAsync.when(
      data: (user) => ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundImage: user?.profileImageUrl != null 
            ? NetworkImage(user!.profileImageUrl!) 
            : null,
          child: user?.profileImageUrl == null 
            ? const Icon(Icons.person, size: 16) 
            : null,
        ),
        title: Text(user?.username ?? 'Unknown User'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$score/10',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade900,
            ),
          ),
        ),
      ),
      loading: () => const ListTile(
        dense: true,
        leading: CircleAvatar(radius: 16, child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))),
        title: Text('Loading...'),
      ),
      error: (_, __) => const ListTile(
        dense: true,
        leading: Icon(Icons.error, size: 20),
        title: Text('Error loading user'),
      ),
    );
  }
}