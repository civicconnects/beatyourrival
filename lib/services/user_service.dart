// lib/services/user_service.dart
// --- START COPY & PASTE HERE ---

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart'; 
import 'auth_service.dart';

final userServiceProvider = Provider((ref) => UserService());

final allUserProfilesStreamProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.read(userServiceProvider).getAllUserProfiles();
});

final userProfileFutureProvider = FutureProvider.family<UserModel?, String>((ref, userId) {
  return ref.read(userServiceProvider).getUserProfile(userId);
});

final userProfileStreamProvider = StreamProvider.family<UserModel?, String>((ref, userId) {
  return ref.read(userServiceProvider).getUserProfileStream(userId);
});

final currentUserProfileStreamProvider = StreamProvider<UserModel?>((ref) {
  final uid = ref.watch(authStateChangesProvider).value?.uid;
  if (uid == null) {
    return Stream.value(null);
  }
  return ref.read(userServiceProvider).getUserProfileStream(uid);
});

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'Users'; 

  Future<void> createUserProfile(UserModel user) async {
    await _firestore.collection(_collection).doc(user.uid).set(user.toMap());
  }
  
  Stream<List<UserModel>> getAllUserProfiles() {
    return _firestore.collection(_collection).snapshots().map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id)) 
        .toList());
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection(_collection).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id); 
  }
  
  Stream<UserModel?> getUserProfileStream(String uid) {
    return _firestore.collection(_collection).doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, doc.id); 
    });
  }
  
  Stream<List<UserModel>> searchUsersByUsername(String query) {
    if (query.isEmpty) return Stream.value([]);
    
    final endQuery = query + '\uf8ff'; 
    return _firestore.collection(_collection)
        .orderBy('username')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThan: endQuery)
        .limit(10)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return UserModel.fromMap(doc.data(), doc.id); 
          }).toList();
        });
  }

  Future<List<UserModel>> getTopUsersByElo() async {
    final snapshot = await _firestore.collection(_collection)
        .orderBy('eloScore', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) {
      return UserModel.fromMap(doc.data(), doc.id); 
    }).toList();
  }
  
  Future<void> updateUserStats(String uid, bool isWinner, bool isDraw) async {
     final userDoc = _firestore.collection(_collection).doc(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      
      int currentTotalBattles = data['totalBattles'] ?? 0;
      int currentBattlesWon = data['wins'] ?? 0;
      int currentLosses = data['losses'] ?? 0;

      currentTotalBattles += 1;
      if (isWinner && !isDraw) {
        currentBattlesWon += 1;
      } else if (!isWinner && !isDraw) {
        currentLosses += 1;
      }
      
      transaction.update(userDoc, {
        'totalBattles': currentTotalBattles,
        'wins': currentBattlesWon,
        'losses': currentLosses,
      });
    });
  }

  Future<void> updateEloScore(String uid, int newElo) async {
    await _firestore.collection(_collection).doc(uid).update({'eloScore': newElo});
  }
  
  Future<void> updateUserReadyStatus(String uid, bool isReady) async {
    await _firestore.collection(_collection).doc(uid).update({
      'isReadyToBattle': isReady,
      'isOnline': true, 
    });
  }

  Future<void> updateUserStatsVisibility(String uid, bool isPublic) async {
    await _firestore.collection(_collection).doc(uid).update({
      'isStatsPublic': isPublic,
    });
  }

  // --- NEW: Update silent mode ---
  Future<void> updateUserSilentMode(String uid, bool isSilent) async {
    await _firestore.collection(_collection).doc(uid).update({
      'isSilentMode': isSilent,
    });
  }
}
// --- END COPY & PASTE HERE ---