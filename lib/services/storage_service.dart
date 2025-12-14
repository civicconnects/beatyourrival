// lib/services/storage_service.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for storage service
final storageServiceProvider = Provider((ref) => StorageService());

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload battle video to Firebase Storage
  /// Path: battle_videos/{userId}/{battleId}_{timestamp}.mp4
  /// Returns: Download URL or null if failed
  Future<String?> uploadBattleVideo({
    required String battleId,
    required File videoFile,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ StorageService: No authenticated user');
        return null;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${battleId}_$timestamp.mp4';
      final path = 'battle_videos/${user.uid}/$fileName';

      print('📤 Uploading video to: $path');
      print('📦 File size: ${await videoFile.length()} bytes');

      // Create reference
      final ref = _storage.ref().child(path);

      // Upload file with metadata
      final uploadTask = ref.putFile(
        videoFile,
        SettableMetadata(
          contentType: 'video/mp4',
          customMetadata: {
            'battleId': battleId,
            'uploadedBy': user.uid,
            'uploadedAt': timestamp.toString(),
          },
        ),
      );

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('⏳ Upload progress: ${progress.toStringAsFixed(1)}%');
      });

      // Wait for completion
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Video uploaded successfully!');
      print('🔗 Download URL: $downloadUrl');

      return downloadUrl;
    } catch (e, stackTrace) {
      print('❌ STORAGE ERROR: Failed to upload video: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Delete a video from Firebase Storage
  Future<bool> deleteBattleVideo(String videoUrl) async {
    try {
      final ref = _storage.refFromURL(videoUrl);
      await ref.delete();
      print('✅ Video deleted: $videoUrl');
      return true;
    } catch (e) {
      print('❌ Failed to delete video: $e');
      return false;
    }
  }

  /// Get video metadata
  Future<FullMetadata?> getVideoMetadata(String videoUrl) async {
    try {
      final ref = _storage.refFromURL(videoUrl);
      return await ref.getMetadata();
    } catch (e) {
      print('❌ Failed to get video metadata: $e');
      return null;
    }
  }
}
