// lib/screens/battle/battle_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/battle_model.dart';
import '../../models/move_model.dart';
import '../../services/auth_service.dart';
import '../../services/battle_service.dart';
import '../../services/user_service.dart';
import 'live_battle_screen.dart';

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

  // ENHANCED: Show dialog with Category and Genre dropdowns - ALWAYS SHOWS
  void _showGoLiveDialog(BattleModel battle, String currentUserId, String opponentUsername, bool isPerformer) {
    print("🎭 Opening Go Live Dialog - isPerformer: $isPerformer");
    
    final TextEditingController titleController = TextEditingController();
    String selectedCategory = 'Freestyle';
    String selectedGenre = 'Hip Hop';
    
    // Category options
    final List<String> categories = [
      'Freestyle',
      'Singing',
      'Dancing',
      'Rapping',
      'Beatboxing',
      'DJ Mix',
      'Instrumental',
    ];
    
    // Genre options
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
      'House',
    ];
    
    // Auto-generate title based on selections
    void updateTitle() {
      titleController.text = '$selectedGenre $selectedCategory - Round ${battle.currentRound}';
    }
    
    // Set initial title
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
                      // Category Dropdown (only for performers)
                      const Text(
                        'Performance Category:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                      
                      // Genre Dropdown (only for performers)
                      const Text(
                        'Music Genre:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                                    color: _getGenreColor(genre),
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
                      
                      // Title Field (only for performers)
                      const Text(
                        'Performance Title:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                      // Watcher info
                      const Icon(Icons.remove_red_eye, size: 48, color: Colors.blue),
                      const SizedBox(height: 16),
                      const Text(
                        'You are about to watch the live performance.',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Performer: ${battle.currentTurnUid == currentUserId ? "You" : opponentUsername}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Info Box
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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
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
                  onPressed: () {
                    if (isPerformer) {
                      final moveTitle = titleController.text.trim();
                      if (moveTitle.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a title'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      
                      Navigator.of(context).pop(); // Close dialog
                      
                      // Build enhanced move title with metadata
                      final enhancedTitle = '[$selectedCategory] $moveTitle';
                      
                      print("🚀 Starting live performance with title: $enhancedTitle");
                      
                      // Navigate to live battle screen as PERFORMER
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LiveBattleScreen(
                            battleId: battle.id!,
                            isHost: true, // PERFORMER
                            hostId: battle.challengerUid,
                            hostUsername: battle.challengerUid == currentUserId ? "You" : opponentUsername,
                            player2Id: battle.opponentUid,
                            player2Username: battle.opponentUid == currentUserId ? "You" : opponentUsername,
                            moveTitle: enhancedTitle,
                          ),
                        ),
                      );
                    } else {
                      Navigator.of(context).pop(); // Close dialog
                      
                      print("👀 Joining as watcher");
                      
                      // Navigate to live battle screen as WATCHER
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LiveBattleScreen(
                            battleId: battle.id!,
                            isHost: false, // WATCHER
                            hostId: battle.currentTurnUid,
                            hostUsername: battle.currentTurnUid == currentUserId 
                              ? "You" 
                              : opponentUsername,
                            player2Id: battle.currentTurnUid == battle.challengerUid 
                              ? battle.opponentUid 
                              : battle.challengerUid,
                            player2Username: "Viewer",
                            moveTitle: 'Watching Live Performance',
                          ),
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
  
  // Helper function to get category icon
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Singing':
        return Icons.mic;
      case 'Dancing':
        return Icons.directions_run;
      case 'Rapping':
        return Icons.speaker;
      case 'Beatboxing':
        return Icons.graphic_eq;
      case 'DJ Mix':
        return Icons.album;
      case 'Instrumental':
        return Icons.piano;
      case 'Freestyle':
      default:
        return Icons.star;
    }
  }
  
  // Helper function to get genre color
  Color _getGenreColor(String genre) {
    switch (genre) {
      case 'Hip Hop':
        return Colors.orange;
      case 'R&B':
        return Colors.purple;
      case 'Pop':
        return Colors.pink;
      case 'Rock':
        return Colors.red;
      case 'Electronic':
        return Colors.blue;
      case 'Jazz':
        return Colors.brown;
      case 'Latin':
        return Colors.green;
      case 'Afrobeat':
        return Colors.amber;
      case 'Dancehall':
        return Colors.teal;
      case 'Trap':
        return Colors.deepPurple;
      case 'Drill':
        return Colors.black87;
      case 'House':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
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
    double currentSliderValue = 5;
    
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
                  Text('Score: ${currentSliderValue.round()}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Slider(
                    value: currentSliderValue,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: currentSliderValue.round().toString(),
                    onChanged: (double value) {
                      setDialogState(() {
                        currentSliderValue = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                     _handleVote(moveId, currentSliderValue.round());
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
        
        print("🎮 Battle Status: ${battle.status}, Round: ${battle.currentRound}/${battle.maxRounds}, My Turn: $isMyTurn, Current Turn: ${battle.currentTurnUid}");

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
                    
                    // LIVE BUTTON WITH FIXED DIALOG TRIGGER
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
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isMyTurn && isParticipant 
                                ? Colors.green 
                                : Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              // ALWAYS show dialog - determine role inside dialog
                              final bool shouldPerform = isMyTurn && isParticipant;
                              print("🎬 Live button pressed - Should Perform: $shouldPerform");
                              
                              // ALWAYS CALL THE DIALOG
                              _showGoLiveDialog(
                                battle, 
                                currentUserId, 
                                opponentUsername,
                                shouldPerform, // Pass whether they should perform
                              );
                            },
                          ),
                        ),
                      ),
                    
                    const Divider(height: 32),
                ];
                
                if (battle.status == BattleStatus.completed && battle.winnerUid != null) {
                  bodyWidgets.add(_buildFinalScore(context, battle, currentUserId, opponentUsername, isSpectator));
                }
                else if (isBattleOverAndUnjudged) {
                  if (isParticipant) {
                    bodyWidgets.add(_buildFinalizeButton(battle));
                  } else {
                     bodyWidgets.add(const Center(child: Text("Voting in progress... cast your vote below!", style: TextStyle(fontStyle: FontStyle.italic))));
                  }
                }
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
                else if (battle.status == BattleStatus.pending) {
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
            child: Text('You have been challenged by $opponentUsername!', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.blue.shade900)),
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
    final bool isWinner = battle.winnerUid == currentUserId;
    final bool isDraw = battle.winnerUid == 'Draw';
    
    int myScore = 0;
    int opponentScore = 0;
    
    if (isSpectator) {
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
       resultText = 'BATTLE FINISHED';
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a track link';
              }
              final uri = Uri.tryParse(value);
              if (uri == null || !uri.hasAbsolutePath) {
                return 'Please enter a valid URL (http://...)';
              }
              return null;
            },
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
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                : const Text('Submit Move'),
          ),
        ],
      ),
    );
  }

  Widget _buildMovesHistory(BuildContext context, BattleModel battle,
      String currentUserId, String opponentUsername) {
    final movesAsync = ref.watch(battleMovesStreamProvider(widget.battleId));
    
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
            String senderName;
            if (move.submittedByUid == currentUserId) {
              senderName = 'You';
            } else if (move.submittedByUid == battle.challengerUid) senderName = 'Challenger';
            else senderName = 'Opponent';

            final hasVoted = move.votes.containsKey(currentUserId);
            final int myScore = move.votes[currentUserId] ?? 0;

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
                      TextButton.icon(
                        icon: const Icon(Icons.people_outline, size: 16, color: Colors.blueGrey),
                        label: Text('${move.totalScore} pts', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                        onPressed: () => _showVoters(move.votes),
                      ),
                      const SizedBox(width: 8),
                      if (!isMine)
                        IconButton(
                          icon: Icon(
                            hasVoted ? Icons.star : Icons.star_border,
                            color: hasVoted ? Colors.orange : Colors.grey,
                          ),
                          tooltip: hasVoted ? 'You rated this $myScore/10' : 'Rate this move',
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

class _VoterTile extends ConsumerWidget {
  final String userId;
  const _VoterTile({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileFutureProvider(userId));

    return userAsync.when(
      data: (user) => ListTile(
        leading: CircleAvatar(
          backgroundImage: user?.profileImageUrl != null ? NetworkImage(user!.profileImageUrl!) : null,
          child: user?.profileImageUrl == null ? const Icon(Icons.person) : null,
        ),
        title: Text(user?.username ?? 'Unknown User'),
      ),
      loading: () => const ListTile(title: Text('Loading...')),
      error: (_, __) => const ListTile(title: Text('Error')),
    );
  }
}