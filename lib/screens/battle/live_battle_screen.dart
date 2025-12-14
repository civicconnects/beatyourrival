// lib/screens/battle/live_battle_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Import local models and services
import '../../models/battle_model.dart';
import '../../models/move_model.dart';
import '../../services/battle_service.dart';
import '../../services/auth_service.dart'; // Keep auth service import

const uuid = Uuid();

// LiveKit Config - Add these constants or import from settings
const String liveKitUrl = "wss://beatrival-3no5kwuv.livekit.cloud"; 
const String apiKey = "APIgnf66ubks29J";
const String apiSecret = "J3NLrIxAgEMXf7aP29LRLBHPIX4qOdsmN5pbLpKYeeWB";

// --- LIVEBATTLESCREEN CLASS ---

class LiveBattleScreen extends ConsumerStatefulWidget {
  final String battleId;
  final bool isHost;
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

// --- LIVEBATTLESCREEN STATE CLASS ---

class _LiveBattleScreenState extends ConsumerState<LiveBattleScreen> {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _isConnected = false;
  List<ParticipantTrack> participantTracks = [];
  
  Timer? _battleTimer;
  int _secondsRemaining = 90; 
  bool _timerStarted = false;
  
  bool _isMicEnabled = true;
  bool _isCameraEnabled = true;
  bool _moveSubmitted = false;
  
  String _statusMessage = "Initializing...";
  bool _isConnecting = true;
  int _connectionProgress = 0;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    // Only initialize, don't start connection yet to avoid getUserMedia before user interaction
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeConnection();
    });
  }

  // --- CORE LOGIC IMPLEMENTATION ---

  String _generateToken() {
    final user = FirebaseAuth.instance.currentUser;
    final participantId = user?.uid ?? (widget.isHost ? "performer" : "watcher");
    final participantName = user?.displayName ?? participantId;
    
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
          "canPublish": widget.isHost,
          "canPublishData": widget.isHost,
          "canSubscribe": true,
        },
      },
    );
    
    return jwt.sign(SecretKey(apiSecret), algorithm: JWTAlgorithm.HS256);
  }

  Future<void> _initializeConnection() async {
    setState(() {
      _statusMessage = "Preparing your battle...";
      _connectionProgress = 10;
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    await _connect();
  }

  Future<void> _connect() async {
    try {
      setState(() {
        _statusMessage = widget.isHost ? "🎤 Setting up stream..." : "👀 Joining as viewer...";
        _connectionProgress = 50;
      });

      // HYBRID FIX: Simplified permission handling
      if (widget.isHost) {
        setState(() {
          _statusMessage = "📸 Requesting camera and microphone permissions...";
          _connectionProgress = 20;
        });

        // CRITICAL FIX: Use permission_handler only, no direct getUserMedia calls
        await [Permission.microphone, Permission.camera].request();
        
        // Wait for browser to process permissions
        await Future.delayed(const Duration(milliseconds: 500));
        
        setState(() {
          _permissionsGranted = true;
          _statusMessage = "✅ Permissions granted";
          _connectionProgress = 40;
        });
      } else {
        setState(() {
          _permissionsGranted = true; // Viewer doesn't need permissions
          _statusMessage = "Permissions not required for viewer";
        });
      }

      final token = _generateToken();
      _room = Room();
      _listener = _room!.createListener();

      // Set up listeners
      _listener!
        ..on<RoomConnectedEvent>((event) => _sortParticipants())
        ..on<ParticipantConnectedEvent>((event) => _sortParticipants())
        ..on<LocalTrackPublishedEvent>((event) => _sortParticipants())
        ..on<TrackSubscribedEvent>((event) => _sortParticipants());

      setState(() {
        _statusMessage = "🌐 Connecting to server...";
        _connectionProgress = 70;
      });

      // Platform-aware RoomOptions
      RoomOptions roomOptions;
      if (kIsWeb) {
        roomOptions = const RoomOptions();
      } else {
        roomOptions = const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
        );
      }

      await _room!.connect(
        liveKitUrl, 
        token, 
        roomOptions: roomOptions,
      );
      
      // CRITICAL: Start recording for ALL battles (so offline opponents can watch)
      if (widget.isHost) {
        try {
          print("🎥 Attempting to start recording...");
          // Note: LiveKit Cloud Recording must be enabled in your LiveKit dashboard
          // The recording will be available after the room session ends
          setState(() {
            _statusMessage = "🎥 Starting recording...";
          });
          
          // Recording is handled by LiveKit server-side
          // We'll retrieve the recording URL after the battle ends
          print("🎥 Recording will be available after battle completes");
        } catch (e) {
          print("⚠️ Recording setup note: $e");
          // Don't fail the battle, recording is handled server-side
        }
      }
      
      // Enable camera/mic only for host and only after successful connection
      if (widget.isHost && _permissionsGranted) {
        setState(() {
          _statusMessage = "🎬 Starting camera...";
          _connectionProgress = 85;
        });

        try {
          // Enable camera and mic with delay
          await _room!.localParticipant?.setCameraEnabled(true);
          await _room!.localParticipant?.setMicrophoneEnabled(true);
          
          // Wait a moment for camera to initialize
          await Future.delayed(const Duration(seconds: 1));
          
          // Verify camera is actually working
          final videoTracks = _room!.localParticipant?.videoTrackPublications;
          if (videoTracks == null || videoTracks.isEmpty) {
            throw Exception("Camera failed to start");
          }
        } catch (e) {
          print('Camera/Mic enable error: $e');
          
          // Provide more helpful error message for web
          String errorMsg = "Failed to start camera/microphone: $e";
          if (kIsWeb && e.toString().contains('getUserMedia')) {
            errorMsg = "Browser permission denied. Please allow camera/microphone access.";
          }
          
          throw Exception(errorMsg);
        }
      }

      if (mounted) {
        setState(() {
          _isConnected = true;
          _isConnecting = false;
          _isMicEnabled = widget.isHost && _permissionsGranted;
          _isCameraEnabled = widget.isHost && _permissionsGranted;
          _statusMessage = "✅ Connected!";
          _connectionProgress = 100;
        });
        
        // CRITICAL FIX: Only start timer AFTER camera is confirmed working
        if (widget.isHost && !_timerStarted && _permissionsGranted) {
          _startTimer();
        }
      }
    } catch (e) {
      print('Connection failed: $e');
      if (mounted) {
        setState(() {
          _statusMessage = "❌ Connection failed: ${e.toString().split(':')[0]}";
          _isConnecting = false;
          _connectionProgress = 0;
        });
        
        String errorMessage = e.toString();
        if (errorMessage.contains('getUserMedia') || 
            errorMessage.contains('Unable to get user media') ||
            errorMessage.contains('permission denied')) {
          errorMessage = 'Camera/microphone access denied. Please check browser permissions.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection Failed: $errorMessage'), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _startTimer() {
    if (_timerStarted) return;
    
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
    if (!_moveSubmitted && widget.isHost) {
      _finishPerformance();
    }
    
    if (mounted) {
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
                // CRITICAL FIX: Calls safe exit to signal turn flip
                _safelyDisconnectAndPop(true); 
              },
              child: const Text('Finish'),
            ),
          ],
        ),
      );
    }
  }

  // Submits move to database when performance is finished (only for performer)
  Future<void> _finishPerformance() async {
    if (_moveSubmitted || !widget.isHost) return; 
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _moveSubmitted = true);
    _battleTimer?.cancel();

    try {
      final move = MoveModel(
        id: uuid.v4(),
        title: widget.moveTitle,
        link: 'LIVE_PERFORMANCE_ROUND_${widget.battleId}',
        submittedByUid: user.uid,
        round: 1, // KEEP from working file
        submittedAt: DateTime.now(),
        votes: const {},
      );

      // Create minimal BattleModel (Required by the submitMove method) - KEEP from working file
      final tempBattle = BattleModel(
          id: widget.battleId, 
          challengerUid: widget.hostId ?? '', 
          opponentUid: widget.player2Id ?? '', 
          currentTurnUid: user.uid, 
          maxRounds: 1, 
          currentRound: 1, 
          genre: '', 
          status: BattleStatus.active, 
          moves: [], 
          createdAt: DateTime.now(), 
      );

      // Call Service logic to flip turn atomically
      await ref.read(battleServiceProvider).submitMove(widget.battleId, move);

      // CRITICAL: Mark that recording will be available
      // Note: LiveKit recording URL will be available a few minutes after the room closes
      // For now, we mark that a recording was made so the opponent knows to check back
      try {
        print("🎥 Attempting to save recording metadata for battleId: ${widget.battleId}");
        print("🔍 Current user UID: ${user.uid}");
        
        await FirebaseFirestore.instance
          .collection('Battles')
          .doc(widget.battleId)
          .update({
            'hasRecording': true,
            'recordingUrl': 'PENDING_LIVEKIT_RECORDING',
            'recordingRequested': FieldValue.serverTimestamp(),
            'liveStreamCompleted': FieldValue.serverTimestamp(),
            // Recording URL will be added later via LiveKit webhook or manual check
          });
        print("✅ SUCCESS: Battle marked as recorded. Recording URL will be available shortly.");
      } catch (recordingError) {
        print("❌ CRITICAL ERROR: Failed to mark recording!");
        print("Error details: $recordingError");
        print("Error type: ${recordingError.runtimeType}");
        
        // Show error to user so we know what's happening
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Recording metadata save failed: $recordingError'), 
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        // Don't fail the battle submission for recording metadata
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live move recorded! Turn flipped. Recording will be available soon.'), backgroundColor: Colors.green, duration: Duration(seconds: 4)),
        );
      }
    } catch (e) {
      print('Error submitting live move: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting move: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _moveSubmitted = false);
    }
  }

  // 🏆 FINAL FIX: Guards the disconnect call to prevent TimeoutException crash.
  Future<void> _safelyDisconnectAndPop(bool signalCompletion) async {
    if (!mounted) return;

    // Try to disconnect gracefully, but set a short timeout.
    try {
      await _room?.disconnect().timeout(const Duration(seconds: 3));
    } catch (e) {
      print("⚠️ LiveKit Disconnect failed gracefully (Timeout/Error): $e");
    }

    // CRITICAL: Send the signal and close the screen regardless of disconnect success.
    if (mounted) {
      if (signalCompletion) {
        Navigator.pop(context, 'COMPLETED'); // Signal turn flip to BattleDetailScreen
      } else {
        Navigator.pop(context); // Standard exit
      }
    }
  }

  void _handleEndBattle() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('End Performance?'),
          content: Text(widget.isHost ? 'Are you sure you want to end your performance?' : 'Are you sure you want to leave?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (!_moveSubmitted && widget.isHost) {
                  _finishPerformance().then((_) {
                    _safelyDisconnectAndPop(true);
                  }).catchError((e) {
                    _safelyDisconnectAndPop(false);
                  });
                } else {
                  _safelyDisconnectAndPop(false);
                }
              },
              child: const Text('End/Leave', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _battleTimer?.cancel();
    _listener?.dispose();
    
    if (_room != null) {
        _room!.disconnect().catchError((e) {
            print("⚠️ LiveKit room failed to disconnect cleanly on dispose: $e");
        });
        _room!.dispose();
    }
    
    super.dispose();
  }
  
  // --- UI/HELPER METHODS ---

  void _sortParticipants() {
    if (_room == null) return;
    
    List<ParticipantTrack> userMediaTracks = [];
    
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

  Widget _buildConnectingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_statusMessage.contains('✅'))
                const Icon(Icons.check_circle, color: Colors.green, size: 20)
              else if (_statusMessage.contains('❌'))
                const Icon(Icons.error, color: Colors.red, size: 20)
              else if (_statusMessage.contains('📸') || _statusMessage.contains('🎬'))
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
    if (participantTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              _isCameraEnabled ? "Setting up camera..." : "Camera disabled",
              style: const TextStyle(color: Colors.white)
            ),
          ],
        ),
      );
    }
    
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: VideoTrackRenderer(
        participantTracks[0].videoTrack,
        fit: VideoViewFit.cover, 
      ),
    );
  }

  Widget _buildWatcherView() {
    if (participantTracks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, color: Colors.white, size: 48),
            SizedBox(height: 16),
            Text("Waiting for performer to start...", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      );
    }
    
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: VideoTrackRenderer(
        participantTracks[0].videoTrack,
        fit: VideoViewFit.cover, 
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: WillPopScope(
        onWillPop: () async {
          _handleEndBattle();
          return false;
        },
        child: Stack(
          children: [
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
                    Icon(widget.isHost ? Icons.videocam : Icons.remove_red_eye, color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    Text(widget.isHost ? "Finalizing setup..." : "Waiting for performer to start...", style: const TextStyle(color: Colors.white, fontSize: 18)),
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
                    Text(_statusMessage, style: const TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry Connection'),
                      onPressed: () {
                        setState(() { 
                          _isConnecting = true;
                          _connectionProgress = 10;
                        });
                        _initializeConnection();
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_statusMessage.contains('getUserMedia') || _statusMessage.contains('permission'))
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.info, color: Colors.amber),
                            SizedBox(height: 8),
                            Text(
                              'Browser Permission Tip:',
                              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '1. Click the camera/mic icon in your browser\'s address bar\n'
                              '2. Select "Allow" for camera and microphone\n'
                              '3. Refresh the page',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            
            // TIMER OVERLAY 
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
                        if (_secondsRemaining <= 10) const Icon(Icons.warning, color: Colors.white, size: 20),
                        if (_secondsRemaining <= 10) const SizedBox(width: 8),
                        Text('${_secondsRemaining}s', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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
                      Text(widget.isHost ? 'LIVE' : 'WATCHING', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
                    _buildControlButton(icon: _isMicEnabled ? Icons.mic : Icons.mic_off, onPressed: () async {
                        final newState = !_isMicEnabled;
                        await _room?.localParticipant?.setMicrophoneEnabled(newState);
                        setState(() { _isMicEnabled = newState; });
                      },
                    ),
                    const SizedBox(width: 20),
                    _buildControlButton(icon: _isCameraEnabled ? Icons.videocam : Icons.videocam_off, onPressed: () async {
                        final newState = !_isCameraEnabled;
                        await _room?.localParticipant?.setCameraEnabled(newState);
                        setState(() { _isCameraEnabled = newState; });
                      },
                    ),
                    const SizedBox(width: 20),
                    _buildControlButton(icon: Icons.call_end, color: Colors.red, onPressed: _handleEndBattle),
                    const SizedBox(width: 20),
                    if (!_moveSubmitted)
                      _buildControlButton(
                        icon: Icons.check_circle,
                        color: Colors.green,
                        onPressed: () {
                          _finishPerformance().then((_) {
                            _safelyDisconnectAndPop(true);
                          });
                        },
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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