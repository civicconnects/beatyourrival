# Premium vs Free Battle Implementation Plan

**Business Model**: Two-tier system for battle experiences

---

## 🎯 **Battle Flow Comparison**

### **💰 PREMIUM USERS - Live Battles**

**Flow:**
```
1. User A (premium) clicks "Go Live"
2. Camera starts → streams to LiveKit
3. User B (premium) joins as opponent → watches LIVE
4. Other premium users can join as spectators → watch LIVE
5. Battle is RECORDED automatically by LiveKit
6. After 90 seconds, battle ends
7. Recording URL saved to Firestore
8. Anyone can replay the battle later
```

**Technology:**
- LiveKit for live streaming
- LiveKit Cloud Recording
- Firebase Firestore for metadata
- Real-time video/audio

---

### **🆓 FREE USERS - Async Battles**

**Flow:**
```
1. User A (free) clicks "Record Battle"
2. Camera starts → records LOCALLY on phone
3. After 90 seconds, video stops recording
4. Video UPLOADS to Firebase Storage
5. User B (free) gets notification
6. User B watches RECORDED video (not live)
7. User B clicks "Record Response"
8. User B records their response (90 seconds)
9. User B's video uploads to Firebase Storage
10. Both videos saved, anyone can replay
```

**Technology:**
- Local camera recording (native)
- Firebase Storage for video files
- Firebase Firestore for metadata
- Video player for playback

---

## 🔐 **Premium Check Implementation**

### **Add Premium Field to UserModel**

**File**: `lib/models/user_model.dart`

```dart
class UserModel {
  final String uid;
  final String username;
  final String email;
  final int eloScore;
  final int totalBattles;
  final int wins;
  final int losses;
  final DateTime createdAt;
  
  // ✅ NEW: Premium status
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  
  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.eloScore = 1000,
    this.totalBattles = 0,
    this.wins = 0,
    this.losses = 0,
    required this.createdAt,
    this.isPremium = false,  // Default: free user
    this.premiumExpiresAt,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'eloScore': eloScore,
      'totalBattles': totalBattles,
      'wins': wins,
      'losses': losses,
      'createdAt': createdAt.toIso8601String(),
      'isPremium': isPremium,
      'premiumExpiresAt': premiumExpiresAt?.toIso8601String(),
    };
  }
  
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      eloScore: map['eloScore'] ?? 1000,
      totalBattles: map['totalBattles'] ?? 0,
      wins: map['wins'] ?? 0,
      losses: map['losses'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      isPremium: map['isPremium'] ?? false,
      premiumExpiresAt: map['premiumExpiresAt'] != null 
        ? DateTime.parse(map['premiumExpiresAt'])
        : null,
    );
  }
  
  // Helper: Check if premium is active
  bool get isActivePremium {
    if (!isPremium) return false;
    if (premiumExpiresAt == null) return true;  // Lifetime premium
    return DateTime.now().isBefore(premiumExpiresAt!);
  }
}
```

---

## 🎬 **Premium: Live Battle Recording**

### **Update LiveBattleScreen to Record**

**File**: `lib/screens/battle/live_battle_screen.dart`

Add recording after connection (around line 184):

```dart
await _room!.connect(
  liveKitUrl, 
  token, 
  roomOptions: roomOptions,
);

// ✅ NEW: Start recording (only if performer)
if (widget.isHost) {
  try {
    // Check if room supports recording
    final canRecord = await _room!.canRecord();
    if (canRecord) {
      await _room!.startRecording();
      print("🎥 LiveKit recording started!");
      
      if (mounted) {
        setState(() {
          _statusMessage = "🎥 Recording started";
        });
      }
    }
  } catch (e) {
    print("⚠️ Recording failed to start: $e");
    // Don't fail the battle, just log it
  }
}
```

Save recording URL when battle ends (in `_finishPerformance` around line 307):

```dart
Future<void> _finishPerformance() async {
  if (_moveSubmitted || !widget.isHost) return; 
  
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  setState(() => _moveSubmitted = true);
  _battleTimer?.cancel();

  try {
    // Submit move
    final move = MoveModel(
      id: uuid.v4(),
      title: widget.moveTitle,
      link: 'LIVE_PERFORMANCE_ROUND_${widget.battleId}',
      submittedByUid: user.uid,
      round: 1,
      submittedAt: DateTime.now(),
      votes: const {},
    );

    await ref.read(battleServiceProvider).submitMove(widget.battleId, move);

    // ✅ NEW: Get and save recording URL
    try {
      // Wait a moment for recording to finalize
      await Future.delayed(const Duration(seconds: 2));
      
      final recordings = await _room!.getRecordings();
      if (recordings.isNotEmpty) {
        final recordingUrl = recordings.first.downloadUrl;
        
        // Save to Firestore
        await FirebaseFirestore.instance
          .collection('Battles')
          .doc(widget.battleId)
          .update({
            'recordingUrl': recordingUrl,
            'recordedAt': FieldValue.serverTimestamp(),
          });
        
        print("🎥 Recording saved: $recordingUrl");
      }
    } catch (recordingError) {
      print("⚠️ Failed to save recording URL: $recordingError");
      // Don't fail the battle, recording is optional
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Live move recorded! Turn flipped.'), 
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
    setState(() => _moveSubmitted = false);
  }
}
```

---

## 📹 **Free: Async Battle Recording**

### **Create New Screen: RecordedBattleScreen**

**File**: `lib/screens/battle/recorded_battle_screen.dart`

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../models/move_model.dart';
import '../../services/battle_service.dart';

const uuid = Uuid();

class RecordedBattleScreen extends ConsumerStatefulWidget {
  final String battleId;
  final String moveTitle;
  
  const RecordedBattleScreen({
    super.key,
    required this.battleId,
    required this.moveTitle,
  });
  
  @override
  ConsumerState<RecordedBattleScreen> createState() => _RecordedBattleScreenState();
}

class _RecordedBattleScreenState extends ConsumerState<RecordedBattleScreen> {
  CameraController? _cameraController;
  bool _isRecording = false;
  bool _isUploading = false;
  int _secondsRemaining = 90;
  String? _videoPath;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: true,
    );
    
    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }
  
  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    setState(() {
      _isRecording = true;
      _secondsRemaining = 90;
    });
    
    // Start recording
    await _cameraController!.startVideoRecording();
    
    // Start countdown timer
    _startCountdown();
  }
  
  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && _secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
        _startCountdown();
      } else if (_secondsRemaining == 0) {
        _stopRecording();
      }
    });
  }
  
  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    setState(() => _isRecording = false);
    
    final videoFile = await _cameraController!.stopVideoRecording();
    setState(() => _videoPath = videoFile.path);
    
    // Show preview and upload option
    _showUploadDialog();
  }
  
  void _showUploadDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Recording Complete!'),
        content: const Text('Upload your battle video?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);  // Go back to battle screen
            },
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadVideo();
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _uploadVideo() async {
    if (_videoPath == null) return;
    
    setState(() => _isUploading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      
      // Upload to Firebase Storage
      final fileName = '${widget.battleId}_${user.uid}_${uuid.v4()}.mp4';
      final storageRef = FirebaseStorage.instance
        .ref('battles/${widget.battleId}/$fileName');
      
      final uploadTask = storageRef.putFile(File(_videoPath!));
      
      // Show upload progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (mounted) {
          setState(() {
            _uploadProgress = progress;
          });
        }
      });
      
      await uploadTask;
      
      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();
      
      // Create move with video URL
      final move = MoveModel(
        id: uuid.v4(),
        title: widget.moveTitle,
        link: downloadUrl,  // Video URL
        submittedByUid: user.uid,
        round: 1,
        submittedAt: DateTime.now(),
        votes: const {},
      );
      
      // Submit move to battle
      await ref.read(battleServiceProvider).submitMove(widget.battleId, move);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video uploaded! Battle move submitted.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);  // Return to battle screen
      }
    } catch (e) {
      print('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isUploading = false);
      }
    }
  }
  
  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
  
  double _uploadProgress = 0.0;
  
  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          SizedBox.expand(
            child: CameraPreview(_cameraController!),
          ),
          
          // Timer overlay
          if (_isRecording)
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _secondsRemaining <= 10 ? Colors.red : Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_secondsRemaining}s',
                    style: const TextStyle(
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
            const Positioned(
              top: 40,
              right: 20,
              child: Row(
                children: [
                  Icon(Icons.circle, color: Colors.red, size: 12),
                  SizedBox(width: 8),
                  Text(
                    'RECORDING',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          
          // Upload progress
          if (_isUploading)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Uploading...',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: Colors.white30,
                          valueColor: const AlwaysStoppedAnimation(Colors.green),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Controls
          if (!_isRecording && !_isUploading)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _startRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: const Icon(Icons.fiber_manual_record, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
          
          if (_isRecording)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _stopRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.red, width: 4),
                    ),
                    child: const Icon(Icons.stop, color: Colors.red, size: 40),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

---

## 🎮 **Battle Entry Point: Premium Check**

### **Update BattleDetailScreen to Check Premium**

**File**: `lib/screens/battle/battle_detail_screen.dart`

Modify the "Go Live" button logic (around line 78):

```dart
void _showBattleOptionsDialog(BattleModel battle, String currentUserId) async {
  // Get current user's profile
  final userProfile = await ref.read(userServiceProvider).getUserProfile(currentUserId);
  final isPremium = userProfile?.isActivePremium ?? false;
  
  if (!mounted) return;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(isPremium ? 'Battle Options' : 'Choose Battle Type'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPremium) ...[
            // Premium: Live battle option
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.red),
              title: const Text('Go Live'),
              subtitle: const Text('Stream your battle in real-time'),
              onTap: () {
                Navigator.pop(context);
                _showGoLiveDialog(battle, currentUserId, opponentUsername, true);
              },
            ),
            const Divider(),
          ],
          // Free: Recorded battle option (available to everyone)
          ListTile(
            leading: Icon(
              Icons.video_call,
              color: isPremium ? Colors.blue : Colors.green,
            ),
            title: const Text('Record Battle'),
            subtitle: Text(
              isPremium 
                ? 'Record for later playback'
                : 'Upload your battle video',
            ),
            onTap: () {
              Navigator.pop(context);
              _showRecordBattleDialog(battle, currentUserId);
            },
          ),
          if (!isPremium) ...[
            const Divider(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upgrade to Premium for live battles!',
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

// NEW: Show record battle dialog
void _showRecordBattleDialog(BattleModel battle, String currentUserId) {
  final TextEditingController titleController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Record Your Battle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Battle Title',
              hintText: 'e.g., "My Epic Rap"',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'You\'ll have 90 seconds to record your performance.',
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
          onPressed: () {
            final title = titleController.text.trim();
            if (title.isEmpty) return;
            
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecordedBattleScreen(
                  battleId: battle.id,
                  moveTitle: title,
                ),
              ),
            );
          },
          child: const Text('Start Recording'),
        ),
      ],
    ),
  );
}
```

---

## 👥 **Premium: Spectator Support**

### **Update Token Generation for Spectators**

**File**: `lib/screens/battle/live_battle_screen.dart`

Modify `_generateToken()` (line 86):

```dart
String _generateToken() {
  final user = FirebaseAuth.instance.currentUser;
  final participantId = user?.uid ?? uuid.v4();
  final participantName = user?.displayName ?? "Guest";
  
  // Determine role
  bool canPublish = false;
  if (widget.isHost) {
    canPublish = true;  // Performer can publish
  } else if (widget.isChallenger) {
    canPublish = false;  // Challenger watches (for now)
  } else {
    canPublish = false;  // Spectators watch only
  }
  
  final jwt = JWT(
    {
      "iss": apiKey,
      "sub": participantId,
      "iat": DateTime.now().millisecondsSinceEpoch ~/ 1000,
      "exp": DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      "name": participantName,
      "video": {
        "room": widget.battleId,
        "roomJoin": true,  // Anyone can join
        "canPublish": canPublish,
        "canPublishData": false,
        "canSubscribe": true,  // Everyone can watch
      },
    },
  );
  
  return jwt.sign(SecretKey(apiSecret), algorithm: JWTAlgorithm.HS256);
}
```

**Add spectator count UI:**

```dart
// In build method, add viewer count
if (_isConnected && _room != null)
  Positioned(
    top: 20,
    left: 20,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.remove_red_eye, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            '${_room!.participants.length}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  ),
```

---

## 💳 **Stripe Premium Purchase**

### **Add Premium Purchase Screen**

**File**: `lib/screens/home/premium_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});
  
  Future<void> _purchasePremium(BuildContext context) async {
    try {
      // TODO: Call your backend to create Stripe payment intent
      // For now, just mock upgrade
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Update user to premium
      await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .update({
          'isPremium': true,
          'premiumExpiresAt': DateTime.now()
            .add(const Duration(days: 365))  // 1 year
            .toIso8601String(),
        });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to Premium! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade to Premium')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.star, size: 100, color: Colors.amber),
            const SizedBox(height: 24),
            const Text(
              'BeatYourRival Premium',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            
            // Features list
            _buildFeature(
              icon: Icons.videocam,
              title: 'Live Battles',
              description: 'Stream your battles in real-time',
            ),
            _buildFeature(
              icon: Icons.remove_red_eye,
              title: 'Watch Live',
              description: 'Watch other premium battles as they happen',
            ),
            _buildFeature(
              icon: Icons.people,
              title: 'Spectator Mode',
              description: 'Let others watch your battles live',
            ),
            _buildFeature(
              icon: Icons.video_library,
              title: 'Auto Recording',
              description: 'All your battles automatically recorded',
            ),
            
            const SizedBox(height: 32),
            
            // Pricing
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    '\$9.99/month',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'or \$99.99/year (save 17%)',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Purchase button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _purchasePremium(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                child: const Text(
                  'Upgrade Now',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            Text(
              'Cancel anytime. No commitment.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 📊 **Cost Analysis**

### **Premium Users:**
- **Live streaming**: Free (LiveKit supports live)
- **Recording**: $0.008/min = $0.012 per 90-sec battle
- **Storage**: Included in LiveKit
- **Bandwidth**: Included in LiveKit

**1000 premium battles/month**: ~$12/month

---

### **Free Users:**
- **Recording**: Free (local)
- **Storage**: Firebase Storage ($0.026/GB/month)
- **90-sec video**: ~50MB
- **Bandwidth**: $0.12/GB download

**1000 free battles/month**: 
- Storage: 50GB = $1.30/month
- Bandwidth (each viewed once): 50GB = $6/month
- **Total**: ~$7.30/month

---

## ✅ **Implementation Priority**

### **Week 1: Core Premium Features**
1. ✅ Add `isPremium` field to UserModel (2 hours)
2. ✅ Add premium check in battle screen (2 hours)
3. ✅ Add LiveKit recording (4 hours)
4. ✅ Add recording URL save (2 hours)

**Total**: 1-2 days

---

### **Week 2: Free User Battles**
1. ✅ Create RecordedBattleScreen (1 day)
2. ✅ Add video upload to Firebase Storage (4 hours)
3. ✅ Add video playback UI (4 hours)

**Total**: 2 days

---

### **Week 3: Spectators & Polish**
1. ✅ Add spectator support (1 day)
2. ✅ Add viewer count UI (2 hours)
3. ✅ Create premium purchase screen (4 hours)

**Total**: 2 days

---

## 📋 **Summary**

**Premium Users Get:**
- ✅ Live streaming (real-time)
- ✅ Auto-recording
- ✅ Spectators can watch
- ✅ Instant opponent response

**Free Users Get:**
- ✅ Record battles (async)
- ✅ Upload to cloud
- ✅ Opponent watches recording
- ✅ Opponent records response
- ❌ No live streaming
- ❌ No spectators

**Implementation Time**: 5-7 days total

---

**Document Created**: December 13, 2025  
**Purpose**: Implementation plan for premium vs free battle tiers  
**Status**: Ready for development
