// lib/services/elo_service.dart
// --- START COPY & PASTE HERE ---
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_service.dart';
import '../models/user_model.dart';

final eloServiceProvider = Provider((ref) {
  // FIX: Ensure UserService is read correctly
  return EloService(ref.read(userServiceProvider));
});

class EloService {
  final UserService _userService;
  static const int kFactor = 32; 

  EloService(this._userService);

  double getExpectedScore(int ratingA, int ratingB) {
    return 1.0 / (1.0 + pow(10, (ratingB - ratingA) / 400));
  }

  Map<String, int> calculateNewRatings(int ratingA, int ratingB, double scoreA) {
    final expectedA = getExpectedScore(ratingA, ratingB);
    final expectedB = getExpectedScore(ratingB, ratingA); 

    // FIX: Ensure calculation results in an int
    final newRatingA = (ratingA + (kFactor * (scoreA - expectedA))).round();
    final newRatingB = (ratingB + (kFactor * ((1.0 - scoreA) - expectedB))).round();

    return {'ratingA': newRatingA, 'ratingB': newRatingB};
  }

  Future<void> processBattleResult(String uidA, String uidB, double scoreA, bool draw) async {
    final Future<UserModel?> futureProfileA = _userService.getUserProfile(uidA);
    final Future<UserModel?> futureProfileB = _userService.getUserProfile(uidB);

    final List<UserModel?> profiles = await Future.wait([futureProfileA, futureProfileB]);
    final userA = profiles[0];
    final userB = profiles[1];

    if (userA == null || userB == null) {
      throw Exception('Could not process battle: One or both user profiles not found.');
    }
    
    final bool aWon = scoreA == 1.0;

    await _userService.updateUserStats(uidA, aWon, draw);
    await _userService.updateUserStats(uidB, !aWon && !draw, draw); 

    // FIX: Cast double ELO scores to int for calculation
    final currentRatingA = userA.eloScore.round();
    final currentRatingB = userB.eloScore.round();

    final newRatings = calculateNewRatings(currentRatingA, currentRatingB, scoreA);
    final finalRatingA = newRatings['ratingA']!;
    final finalRatingB = newRatings['ratingB']!;

    // FIX: Call the correct, existing method name
    await _userService.updateEloScore(uidA, finalRatingA);
    await _userService.updateEloScore(uidB, finalRatingB);
  }
}
// --- END COPY & PASTE HERE ---