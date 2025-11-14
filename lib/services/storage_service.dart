// lib/services/storage_service.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageServiceProvider = Provider((ref) {
  return StorageService();
});

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Uploads a file to Firebase Storage and returns the public download URL.
  Future<String> uploadUserProfileImage(String uid, File imageFile) async {
    final storageRef = _storage.ref().child('users/$uid/profile_image.jpg');
    
    // Upload file
    final uploadTask = storageRef.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    // Await completion and get the download URL
    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();
    
    return downloadUrl;
  }
}