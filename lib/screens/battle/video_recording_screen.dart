// lib/screens/battle/video_recording_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

// Import local services
import '../../models/battle_model.dart';
import '../../models/move_model.dart';
import '../../services/battle_service.dart';
import '../../services/storage_service.dart';

const uuid = Uuid();

class VideoRecordingScreen extends ConsumerStatefulWidget {
  final String battleId;
  final String moveTitle;
  final BattleModel battle;

  const VideoRecordingScreen({
    super.key,
    required this.battleId,
    required this.moveTitle,
    required this.battle,
  });

  @override
  ConsumerState<VideoRecordingScreen> createState() =>
      _VideoRecordingScreenState();
}

class _VideoRecordingScreenState extends ConsumerState<VideoRecordingScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  bool _isInitialized = false;
  bool _isUploading = false;
  String? _recordedVideoPath;

  // Timer
  Timer? _recordingTimer;
  int _secondsRemaining = 90;
  bool _timerStarted = false;

  String _statusMessage = "Initializing camera...";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      // Request permissions
      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();

      if (!cameraStatus.isGranted || !micStatus.isGranted) {
        setState(() {
          _statusMessage = "Camera/Microphone permissions denied";
        });
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _statusMessage = "No cameras available";
        });
        return;
      }

      // Use front camera if available (for performers)
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      // Initialize controller
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _cameraController!.initialize();

      setState(() {
        _isInitialized = true;
        _statusMessage = "Ready to record";
      });
    } catch (e) {
      print('❌ Camera initialization error: $e');
      setState(() {
        _statusMessage = "Camera error: $e";
      });
    }
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _statusMessage = "Recording...";
      });

      // Start 90-second countdown
      _startTimer();
    } catch (e) {
      print('❌ Failed to start recording: $e');
      _showSnackBar("Failed to start recording: $e", isError: true);
    }
  }

  void _startTimer() {
    _timerStarted = true;
    _secondsRemaining = 90;

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining--;
      });

      if (_secondsRemaining <= 0) {
        timer.cancel();
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) {
      return;
    }

    try {
      _recordingTimer?.cancel();
      final XFile video = await _cameraController!.stopVideoRecording();

      setState(() {
        _isRecording = false;
        _recordedVideoPath = video.path;
        _statusMessage = "Recording complete. Uploading...";
      });

      print('✅ Video saved to: ${video.path}');

      // Upload and submit move
      await _uploadAndSubmitMove(video.path);
    } catch (e) {
      print('❌ Failed to stop recording: $e');
      _showSnackBar("Failed to stop recording: $e", isError: true);
    }
  }

  Future<void> _uploadAndSubmitMove(String videoPath) async {
    setState(() {
      _isUploading = true;
      _statusMessage = "Uploading video...";
    });

    try {
      // Upload video to Firebase Storage
      final storageService = ref.read(storageServiceProvider);
      final videoFile = File(videoPath);
      final downloadUrl = await storageService.uploadBattleVideo(
        battleId: widget.battleId,
        videoFile: videoFile,
      );

      if (downloadUrl == null) {
        throw Exception('Failed to upload video');
      }

      print('✅ Video uploaded: $downloadUrl');

      // Submit move with video URL
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final move = MoveModel(
        id: uuid.v4(),
        title: widget.moveTitle,
        link: downloadUrl, // Video URL instead of LIVE_PERFORMANCE_ROUND_
        submittedByUid: user.uid,
        round: widget.battle.currentRound,
        submittedAt: DateTime.now(),
      );

      print('🎯 Submitting move with video URL...');
      await ref.read(battleServiceProvider).submitMove(
            widget.battleId,
            move,
          );

      print('✅ Move submitted successfully!');

      setState(() {
        _isUploading = false;
        _statusMessage = "Success!";
      });

      // Navigate back
      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar("Video recorded and submitted!", isError: false);
      }
    } catch (e, stackTrace) {
      print('❌ CRITICAL ERROR: Failed to upload/submit: $e');
      print('Stack trace: $stackTrace');

      setState(() {
        _isUploading = false;
        _statusMessage = "Upload failed: $e";
      });

      _showSnackBar("Failed to submit video: $e", isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.orange : Colors.green,
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Record Performance'),
        backgroundColor: Colors.black,
      ),
      body: _isInitialized
          ? Stack(
              children: [
                // Camera preview
                Center(
                  child: AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                ),

                // Timer overlay
                if (_timerStarted)
                  Positioned(
                    top: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _secondsRemaining <= 10
                              ? Colors.red
                              : Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatTime(_secondsRemaining),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Recording indicator
                if (_isRecording)
                  Positioned(
                    top: 40,
                    right: 20,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.circle,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),

                // Status message
                Positioned(
                  bottom: 120,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                // Control buttons
                if (!_isUploading)
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _isRecording
                          ? ElevatedButton(
                              onPressed: _stopRecording,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                'Stop Recording',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _startRecording,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                'Start Recording',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ),

                // Upload progress
                if (_isUploading)
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 20),
                          Text(
                            'Uploading video...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    _statusMessage,
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
    );
  }
}
