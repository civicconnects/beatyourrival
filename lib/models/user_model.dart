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
  final bool isStatsPublic; 
  
  // --- NEW FIELD: Silent Mode ---
  final bool isSilentMode;
  // -----------------------------

  final List<String> friends;
  final List<String> friendRequests;
  
  // ✅ NEW: Premium and Trial fields
  final bool isPremium;
  final DateTime? premiumExpiresAt;

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
    this.isStatsPublic = true,
    this.isSilentMode = false, // Default is OFF (receive notifications)
    this.friends = const [], 
    this.friendRequests = const [],
    this.isPremium = false,  // Default: free trial user
    this.premiumExpiresAt,
  });
  
  // ✅ Check if user is in 3-day trial period
  bool get isInTrialPeriod {
    final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
    return daysSinceCreation < 3;  // First 3 days = trial
  }
  
  // ✅ Check if user has active premium subscription
  bool get hasActivePremium {
    if (!isPremium) return false;
    if (premiumExpiresAt == null) return true;  // Lifetime premium
    return DateTime.now().isBefore(premiumExpiresAt!);
  }
  
  // ✅ Check if user can access battles (premium OR in trial)
  bool get canAccessBattles {
    return hasActivePremium || isInTrialPeriod;
  }
  
  // ✅ Get days remaining in trial
  int get trialDaysRemaining {
    if (!isInTrialPeriod) return 0;
    final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
    return 3 - daysSinceCreation;
  }

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
      'isStatsPublic': isStatsPublic,
      'isSilentMode': isSilentMode,
      'friends': friends, 
      'friendRequests': friendRequests,
      'isPremium': isPremium,
      'premiumExpiresAt': premiumExpiresAt != null ? Timestamp.fromDate(premiumExpiresAt!) : null,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) { 
    List<String> castList(dynamic list) {
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
      isStatsPublic: map['isStatsPublic'] as bool? ?? true,
      isSilentMode: map['isSilentMode'] as bool? ?? false,
      friends: castList(map['friends']), 
      friendRequests: castList(map['friendRequests']),
      isPremium: map['isPremium'] as bool? ?? false,
      premiumExpiresAt: map['premiumExpiresAt'] != null 
        ? (map['premiumExpiresAt'] as Timestamp).toDate()
        : null,
    );
  }
}
// --- END COPY & PASTE HERE ---