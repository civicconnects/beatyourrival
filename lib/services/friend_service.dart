// lib/services/friend_service.dart
// --- START COPY & PASTE HERE ---
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'user_service.dart';

// --- SERVICE PROVIDER ---
final friendServiceProvider = Provider((ref) {
  return FriendService(ref.read(userServiceProvider));
});

// --- STREAM PROVIDERS ---

// Provider to stream the user models of a user's friends
final friendsListStreamProvider = StreamProvider.family<List<UserModel>, String>((ref, userId) {
  return ref.watch(friendServiceProvider).getFriendsListStream(userId);
});

// Provider to stream the user models of incoming friend requests
final friendRequestsStreamProvider = StreamProvider.family<List<UserModel>, String>((ref, userId) {
  return ref.watch(friendServiceProvider).getFriendRequestsStream(userId);
});


class FriendService {
  final UserService _userService;
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('Users');

  FriendService(this._userService);

  /// Sends a friend request from [currentUserId] to [targetUserId]
  Future<void> sendFriendRequest(String currentUserId, String targetUserId) async {
    // Add the current user's ID to the target's 'friendRequests' list
    await _usersCollection.doc(targetUserId).update({
      'friendRequests': FieldValue.arrayUnion([currentUserId])
    });
  }

  /// Accepts a friend request from [requestorId] for [currentUserId]
  Future<void> acceptFriendRequest(String currentUserId, String requestorId) async {
    // Use a batch write to make it all-or-nothing
    final batch = FirebaseFirestore.instance.batch();

    // 1. Add requestor to current user's 'friends' list
    final currentUserRef = _usersCollection.doc(currentUserId);
    batch.update(currentUserRef, {
      'friends': FieldValue.arrayUnion([requestorId]),
      'friendRequests': FieldValue.arrayRemove([requestorId]) // Also remove the request
    });

    // 2. Add current user to requestor's 'friends' list
    final requestorRef = _usersCollection.doc(requestorId);
    batch.update(requestorRef, {
      'friends': FieldValue.arrayUnion([currentUserId])
    });

    await batch.commit();
  }

  /// Declines a friend request from [requestorId] for [currentUserId]
  Future<void> declineFriendRequest(String currentUserId, String requestorId) async {
    // Just remove the requestor's ID from the current user's 'friendRequests' list
    await _usersCollection.doc(currentUserId).update({
      'friendRequests': FieldValue.arrayRemove([requestorId])
    });
  }

  /// Removes a friend
  Future<void> removeFriend(String currentUserId, String friendId) async {
    final batch = FirebaseFirestore.instance.batch();

    // 1. Remove friendId from current user's 'friends' list
    final currentUserRef = _usersCollection.doc(currentUserId);
    batch.update(currentUserRef, {
      'friends': FieldValue.arrayRemove([friendId])
    });

    // 2. Remove currentUserId from friend's 'friends' list
    final friendRef = _usersCollection.doc(friendId);
    batch.update(friendRef, {
      'friends': FieldValue.arrayRemove([currentUserId])
    });

    await batch.commit();
  }

  /// Gets a stream of UserModel objects for all friend requests
  Stream<List<UserModel>> getFriendRequestsStream(String userId) {
    // 1. Get the current user's document to find their 'friendRequests' list
    return _usersCollection.doc(userId).snapshots().asyncMap((userDoc) async {
      if (!userDoc.exists) return [];
      
      final user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>, userDoc.id);
      final requestIds = user.friendRequests;

      if (requestIds.isEmpty) return [];

      // 2. Fetch the user profiles for each ID in the requests list
      final requestProfiles = <UserModel>[];
      // Use Future.wait for efficient fetching
      final profileFutures = requestIds.map((id) => _userService.getUserProfile(id)).toList();
      final profiles = await Future.wait(profileFutures);
      
      for (final profile in profiles) {
        if (profile != null) {
          requestProfiles.add(profile);
        }
      }
      return requestProfiles;
    });
  }
  
  /// Gets a stream of UserModel objects for all friends
  Stream<List<UserModel>> getFriendsListStream(String userId) {
    // 1. Get the current user's document to find their 'friends' list
    return _usersCollection.doc(userId).snapshots().asyncMap((userDoc) async {
      if (!userDoc.exists) return [];

      final user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>, userDoc.id);
      final friendIds = user.friends;

      if (friendIds.isEmpty) return [];

      // 2. Fetch the user profiles for each ID in the friends list
      final friendProfiles = <UserModel>[];
      // Use Future.wait for efficient fetching
      final profileFutures = friendIds.map((id) => _userService.getUserProfile(id)).toList();
      final profiles = await Future.wait(profileFutures);

      for (final profile in profiles) {
        if (profile != null) {
          friendProfiles.add(profile);
        }
      }
      return friendProfiles;
    });
  }
}
// --- END COPY & PASTE HERE ---