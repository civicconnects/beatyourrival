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
  
  // FIX: Added fields for V3.0
  final bool isOnline;
  final bool isReadyToBattle;

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
      'createdAt': Timestamp.fromDate(createdAt), // Store as Timestamp
      'isOnline': isOnline,
      'isReadyToBattle': isReadyToBattle,
    };
  }

  // FIX: Factory constructor now accepts 'id' as a required second argument
  factory UserModel.fromMap(Map<String, dynamic> map, String id) { 
    return UserModel(
      uid: id, // Use the passed ID
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
    );
  }
}
// --- END COPY & PASTE HERE ---