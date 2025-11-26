// lib/screens/battle/live_battle_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Your LiveKit server URL
const String liveKitUrl = "wss://beatrival-3no5kwuv.livekit.cloud"; 

// API Key & Secret (Used to generate token automatically)
const String apiKey = "APIgnf66ubks29J";
const String apiSecret = "J3NLrIxAgEMXf7aP29LRLBHPIX4qOdsmN5pbLpKYeeWB";

class LiveBattleScreen extends ConsumerStatefulWidget {
  final String battleId;
  final bool isHost; // true = performer, false = watcher
  final String? hostId;
  final String? hostUsername;
  final String? player2Id;
  final String? player2Username;
  final String moveTitle;

  const LiveBattleScreen({
    super.key, 
    required this.battleId, 
    required this.isHost,
    this.hostId,
    this.hostUsername,
    this.player2Id,
    this.player2Username,
    required this.moveTitle,
  });

  @override
  ConsumerState<LiveBattleScreen> createState() => _LiveBattleScreenState();
}

class _LiveBattleScreenState extends ConsumerState<LiveBattleScreen> {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _isConnected = false;
  List<ParticipantTrack> participantTracks = [];
  
  // Timer (only for performer)
  Timer? _battleTimer;
  int _secondsRemaining = 90; 
  bool _timerStarted = false;
  
  // Track mic and camera state locally
  bool _isMicEnabled = true;
  bool _isCameraEnabled = true;
  
  // Track if move has been submitted
  bool _moveSubmitted = false;
  
  // Connection status for better UX
  String _statusMessage = "Initializing...";
  bool _isConnecting = true;
  int _connectionProgress = 0; // 0-100 progress indicator

  @override
  void initState() {
    super.initState();
    // Don't start timer here - wait for successful connection
    _initializeConnection();
  }

  Future<void> _initializeConnection() async {
    setState(() {
      _statusMessage = "Preparing your battle...";
      _connectionProgress = 10;
    });
    
    // Small delay to show UI
    await Future.delayed(const Duration(milliseconds: 500));
    
    await _connect();
  }

  void _startTimer() {
    if (_timerStarted) return; // Prevent multiple timers
    
    _timerStarted = true;
    print("🚀 Timer started! 90 seconds countdown begins now.");
    
    _battleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        _battleTimer?.cancel();
        _onTimeUp();
      }
    });
  }

  void _onTimeUp() {
    // Submit the move when time is up using _finishPerformance
    if (!_moveSubmitted && widget.isHost) {
      _finishPerformance();
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(widget.isHost ? 'Time\'s Up!' : 'Performance Ended'),
        content: Text(widget.isHost 
          ? 'Your 90-second performance has ended. Your move has been submitted.'
          : 'The performer has finished their 90-second battle.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); 
              Navigator.of(context).pop(); 
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  // Generate token dynamically
  String _generateToken() {
    final user = FirebaseAuth.instance.currentUser;
    final participantId = user?.uid ?? (widget.isHost ? "performer_${DateTime.now().millisecondsSinceEpoch}" : "watcher_${DateTime.now().millisecondsSinceEpoch}");
    final participantName = user?.displayName ?? (widget.isHost ? "Performer" : "Watcher");
    
    // Create JWT payload - adjust permissions based on role
    final jwt = JWT(
      {
        "iss": apiKey,
        "sub": participantId,
        "iat": DateTime.now().millisecondsSinceEpoch ~/ 1000,
        "exp": DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        "name": participantName,
        "video": {
          "room": widget.battleId,
          "roomJoin": true,
          "canPublish": widget.isHost, // Only performer can publish
          "canPublishData": widget.isHost,
          "canSubscribe": true, // Everyone can watch
        },
      },
    );
    
    // Sign and return token
    return jwt.sign(SecretKey(apiSecret), algorithm: JWTAlgorithm.HS256);
  }

  Future<void> _connect() async {
    try {
      // Step 1: Request permissions (only if performer)
      if (widget.isHost) {
        setState(() {
          _statusMessage = "📸 Requesting camera access...";
          _connectionProgress = 20;
        });
        
        final cameraStatus = await Permission.camera.request();
        final micStatus = await Permission.microphone.request();
        
        if (cameraStatus.isDenied || micStatus.isDenied) {
          setState(() {
            _statusMessage = "❌ Camera/Mic permission denied";
            _isConnecting = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Camera and microphone permissions are required to perform'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        setState(() {
          _statusMessage = "✅ Permissions granted";
          _connectionProgress = 30;
        });
        
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        setState(() {
          _statusMessage = "👀 Joining as viewer...";
          _connectionProgress = 30;
        });
      }

      // Step 2: Create room
      setState(() {
        _statusMessage = "🏗️ Setting up battle room...";
        _connectionProgress = 40;
      });
      
      _room = Room();
      _listener = _room!.createListener();

      // Listen for participant changes
      _listener!
        ..on<RoomConnectedEvent>((event) {
          print('Connected to room ${event.room.name} as ${widget.isHost ? "PERFORMER" : "WATCHER"}');
          _sortParticipants();
        })
        ..on<ParticipantConnectedEvent>((event) {
          print('Participant ${event.participant.identity} connected');
          _sortParticipants();
        })
        ..on<ParticipantDisconnectedEvent>((event) {
          print('Participant ${event.participant.identity} disconnected');
          _sortParticipants();
        })
        ..on<LocalTrackPublishedEvent>((event) {
          print('Local track published');
          _sortParticipants();
        })
        ..on<TrackSubscribedEvent>((event) {
          print('Track subscribed');
          _sortParticipants();
        })
        ..on<TrackUnsubscribedEvent>((event) {
          print('Track unsubscribed');
          _sortParticipants();
        });

      // Step 3: Generate Token
      setState(() {
        _statusMessage = "🔐 Generating secure token...";
        _connectionProgress = 50;
      });
      
      final token = _generateToken();
      print("Generated Token for ${widget.isHost ? 'PERFORMER' : 'WATCHER'}");

      // Step 4: Connect to LiveKit
      setState(() {
        _statusMessage = "🌐 Connecting to LiveKit server...";
        _connectionProgress = 60;
      });
      
      await _room!.connect(
        liveKitUrl,
        token,
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultVideoPublishOptions: VideoPublishOptions(
            simulcast: true,
            videoCodec: 'h264',
            backupVideoCodec: BackupVideoCodec(enabled: true),
          ),
          defaultAudioPublishOptions: AudioPublishOptions(
            dtx: true,
          ),
        ),
      );
      
      setState(() {
        _statusMessage = "✅ Connected to room";
        _connectionProgress = 70;
      });
      
      // Step 5: Turn on Camera & Mic ONLY if performer
      if (widget.isHost) {
        setState(() {
          _statusMessage = "📹 Starting camera...";
          _connectionProgress = 80;
        });
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        try {
          await _room!.localParticipant?.setCameraEnabled(true);
          setState(() {
            _statusMessage = "🎤 Enabling microphone...";
            _connectionProgress = 90;
          });
          
          await _room!.localParticipant?.setMicrophoneEnabled(true);
          print("Camera and Mic enabled for performer");
          
          setState(() {
            _statusMessage = "🎬 Starting performance...";
            _connectionProgress = 95;
          });
          
        } catch (cameraError) {
          print("Camera/Mic error: $cameraError");
          setState(() {
            _statusMessage = "⚠️ Camera warming up...";
          });
          // Try one more time after a delay
          await Future.delayed(const Duration(seconds: 2));
          try {
            await _room!.localParticipant?.setCameraEnabled(true);
            await _room!.localParticipant?.setMicrophoneEnabled(true);
          } catch (retryError) {
            print("Retry failed: $retryError");
          }
        }
      } else {
        // Watchers don't publish video/audio
        await _room!.localParticipant?.setCameraEnabled(false);
        await _room!.localParticipant?.setMicrophoneEnabled(false);
        print("Camera and Mic disabled for watcher");
        
        setState(() {
          _statusMessage = "👀 Ready to watch";
          _connectionProgress = 95;
        });
      }

      // Step 6: Final setup
      setState(() {
        _statusMessage = "✅ All set!";
        _connectionProgress = 100;
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() {
          _isConnected = true;
          _isConnecting = false;
          _isMicEnabled = widget.isHost;
          _isCameraEnabled = widget.isHost;
        });
        
        // START TIMER ONLY NOW - After everything is ready!
        if (widget.isHost && !_timerStarted) {
          _startTimer();
        }
      }
      
    } catch (e) {
      print('Failed to connect: $e');
      setState(() {
        _statusMessage = "❌ Connection failed";
        _isConnecting = false;
        _connectionProgress = 0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // KEEPING YOUR EXISTING _sortParticipants LOGIC
  void _sortParticipants() {
    if (_room == null) return;
    
    List<ParticipantTrack> userMediaTracks = [];
    
    // Add local participant (only if performer)
    if (_room!.localParticipant != null && widget.isHost) {
      for (final track in _room!.localParticipant!.videoTrackPublications) {
        if (track.track != null) {
          userMediaTracks.add(ParticipantTrack(
            participant: _room!.localParticipant!,
            videoTrack: track.track as VideoTrack,
            isScreenShare: track.isScreenShare,
          ));
        }
      }
    }
    
    // Add remote participants
    for (final participant in _room!.remoteParticipants.values) {
      for (final track in participant.videoTrackPublications) {
        if (track.track != null && track.subscribed) {
          userMediaTracks.add(ParticipantTrack(
            participant: participant,
            videoTrack: track.track as VideoTrack,
            isScreenShare: track.isScreenShare,
          ));
        }
      }
    }
    
    if (mounted) {
      setState(() {
        participantTracks = userMediaTracks;
      });
    }
  }

  // Submit move to database when performance is finished (only for performer)
  Future<void> _finishPerformance() async {
    if (_moveSubmitted || !widget.isHost) return; // Only performer can submit
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Mark as submitted immediately to prevent duplicates
      setState(() {
        _moveSubmitted = true;
      });

      final moveData = {
        'userId': user.uid,
        'username': user.displayName ?? 'Anonymous',
        'moveTitle': widget.moveTitle,
        'videoUrl': 'live_battle_${widget.battleId}_${DateTime.now().millisecondsSinceEpoch}',
        'votes': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'isLiveBattle': true,
        'duration': 90 - _secondsRemaining, // How long they performed
      };

      // Add move to the battle's moves subcollection
      await FirebaseFirestore.instance
          .collection('battles')
          .doc(widget.battleId)
          .collection('moves')
          .add(moveData);

      // Update battle status
      final updateData = <String, dynamic>{};
      
      // Switch turns
      updateData['currentTurn'] = widget.isHost 
        ? (widget.player2Id ?? '') 
        : (widget.hostId ?? '');
      
      updateData['lastActivity'] = FieldValue.serverTimestamp();

      // Check if battle should end
      final battleDoc = await FirebaseFirestore.instance
          .collection('battles')
          .doc(widget.battleId)
          .get();
      
      final battleData = battleDoc.data();
      final currentRound = battleData?['currentRound'] ?? 1;
      final maxRounds = battleData?['maxRounds'] ?? 1;
      
      // If both players have performed in the final round, end the battle
      if (currentRound >= maxRounds && !widget.isHost) {
        updateData['status'] = 'voting';
        updateData['votingStartTime'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance
          .collection('battles')
          .doc(widget.battleId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Performance submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error submitting live move: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting move: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Reset submission state on error
      setState(() {
        _moveSubmitted = false;
      });
    }
  }

  void _handleEndBattle() {
    // Submit move if not already submitted (performer only)
    if (!_moveSubmitted && widget.isHost) {
      _finishPerformance().then((_) {
        Navigator.pop(context);
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _battleTimer?.cancel();
    _listener?.dispose();
    _room?.disconnect();
    _room?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.isHost ? '🔴 Live Performance' : '👀 Watching Live',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              widget.moveTitle,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: _handleEndBattle,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content based on connection state
          if (_isConnecting)
            _buildConnectingView()
          else if (_isConnected && participantTracks.isNotEmpty)
            widget.isHost 
              ? _buildPerformerView() 
              : _buildWatcherView()
          else if (_isConnected)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isHost ? Icons.videocam : Icons.remove_red_eye,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isHost 
                      ? "Finalizing setup..." 
                      : "Waiting for performer to start...",
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: () {
                      setState(() {
                        _isConnecting = true;
                      });
                      _initializeConnection();
                    },
                  ),
                ],
              ),
            ),
          
          // TIMER OVERLAY (only for performer after connection)
          if (widget.isHost && _isConnected && _timerStarted)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: _secondsRemaining <= 10 ? Colors.red : Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_secondsRemaining <= 10)
                        const Icon(Icons.warning, color: Colors.white, size: 20),
                      if (_secondsRemaining <= 10)
                        const SizedBox(width: 8),
                      Text(
                        '${_secondsRemaining}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // LIVE INDICATOR
          if (_isConnected)
            Positioned(
              top: widget.isHost && _timerStarted ? 60 : 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      widget.isHost ? 'LIVE' : 'WATCHING',
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 12, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // CONTROLS (only for performer)
          if (widget.isHost && _isConnected)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mic toggle
                  _buildControlButton(
                    icon: _isMicEnabled ? Icons.mic : Icons.mic_off,
                    onPressed: () async {
                      final newState = !_isMicEnabled;
                      await _room?.localParticipant?.setMicrophoneEnabled(newState);
                      setState(() {
                        _isMicEnabled = newState;
                      });
                    },
                  ),
                  const SizedBox(width: 20),
                  // Camera toggle
                  _buildControlButton(
                    icon: _isCameraEnabled ? Icons.videocam : Icons.videocam_off,
                    onPressed: () async {
                      final newState = !_isCameraEnabled;
                      await _room?.localParticipant?.setCameraEnabled(newState);
                      setState(() {
                        _isCameraEnabled = newState;
                      });
                    },
                  ),
                  const SizedBox(width: 20),
                  // End call
                  _buildControlButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    onPressed: _handleEndBattle,
                  ),
                  const SizedBox(width: 20),
                  // Submit move button
                  if (!_moveSubmitted)
                    _buildControlButton(
                      icon: Icons.check_circle,
                      color: Colors.green,
                      onPressed: () {
                        _finishPerformance().then((_) {
                          Navigator.pop(context);
                        });
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated progress indicator
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: _connectionProgress / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isHost ? Colors.green : Colors.blue,
                  ),
                ),
              ),
              Text(
                '$_connectionProgress%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Status message with icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_statusMessage.contains('✅'))
                const Icon(Icons.check_circle, color: Colors.green, size: 20)
              else if (_statusMessage.contains('❌'))
                const Icon(Icons.error, color: Colors.red, size: 20)
              else if (_statusMessage.contains('📸'))
                const Icon(Icons.camera_alt, color: Colors.white, size: 20)
              else if (_statusMessage.contains('🎤'))
                const Icon(Icons.mic, color: Colors.white, size: 20)
              else if (_statusMessage.contains('🌐'))
                const Icon(Icons.cloud, color: Colors.white, size: 20)
              else
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  _statusMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          
          // Tips while waiting
          if (_connectionProgress < 50)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    widget.isHost ? Icons.tips_and_updates : Icons.info,
                    color: Colors.amber,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isHost 
                      ? 'Tip: Make sure you\'re in a well-lit area for best video quality'
                      : 'Getting ready to watch the performance...',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPerformerView() {
    // Performer sees their own camera
    if (participantTracks.isEmpty) {
      return const Center(
        child: Text("Setting up camera...", style: TextStyle(color: Colors.white)),
      );
    }
    
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: VideoTrackRenderer(
        participantTracks[0].videoTrack,
      ),
    );
  }

  Widget _buildWatcherView() {
    // Watchers see the performer's stream
    if (participantTracks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, color: Colors.white, size: 48),
            SizedBox(height: 16),
            Text(
              "Waiting for performer to start...",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: VideoTrackRenderer(
        participantTracks[0].videoTrack, // Show first (performer's) video
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.white,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        iconSize: 28,
        onPressed: onPressed,
      ),
    );
  }
}

// Helper class to track participants
class ParticipantTrack {
  final Participant participant;
  final VideoTrack videoTrack;
  final bool isScreenShare;

  ParticipantTrack({
    required this.participant,
    required this.videoTrack,
    required this.isScreenShare,
  });
}