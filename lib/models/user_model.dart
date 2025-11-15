// lib/models/user_model.dart
// --- START COPY & PASTE HERE ---
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String email; 
  final double eloScore;
  final int totalBattles;
  final String? profileImageUrl;
  final int wins;
  final int losses;
  final DateTime createdAt;
  final bool isOnline;
  final bool isReadyToBattle;

  // --- NEW FIELDS FOR FRIENDS ---
  final List<String> friends;
  final List<String> friendRequests;
  // ------------------------------

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.eloScore,
    required this.totalBattles,
    this.profileImageUrl,
    required this.wins,
    required this.losses,
    required this.createdAt,
    this.isOnline = false,
    this.isReadyToBattle = false,
    this.friends = const [], // Add to constructor
    this.friendRequests = const [], // Add to constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'eloScore': eloScore,
      'totalBattles': totalBattles,
      'profileImageUrl': profileImageUrl,
      'wins': wins,
      'losses': losses,
      'createdAt': Timestamp.fromDate(createdAt),
      'isOnline': isOnline,
      'isReadyToBattle': isReadyToBattle,
      'friends': friends, // Add to map
      'friendRequests': friendRequests, // Add to map
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) { 
    // Helper to safely cast lists
    List<String> _castList(dynamic list) {
      if (list == null) return [];
      return (list as List<dynamic>).map((item) => item as String).toList();
    }
    
    return UserModel(
      uid: id,
      username: map['username'] as String? ?? 'Unnamed User',
      email: map['email'] as String? ?? '',
      eloScore: (map['eloScore'] as num? ?? 1000).toDouble(),
      totalBattles: map['totalBattles'] as int? ?? 0,
      profileImageUrl: map['profileImageUrl'] as String?,
      wins: map['wins'] as int? ?? 0,
      losses: map['losses'] as int? ?? 0,
      createdAt: (map['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      isOnline: map['isOnline'] as bool? ?? false,
      isReadyToBattle: map['isReadyToBattle'] as bool? ?? false,
      friends: _castList(map['friends']), // Add to factory
      friendRequests: _castList(map['friendRequests']), // Add to factory
    );
  }
}
// --- END COPY & PASTE HERE ---