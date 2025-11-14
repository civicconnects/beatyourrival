// lib/services/auth_service.dart
// --- START COPY & PASTE HERE ---
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart'; 
import 'user_service.dart'; 

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref));

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

class AuthService {
  final Ref _ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthService(this._ref);

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // FIX: Renamed to match login_screen
  Future<void> signInWithEmail(String email, String password) async { 
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // FIX: Renamed to match register_screen
  Future<void> signUpWithEmail(String username, String email, String password) async { 
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user != null) {
      final user = userCredential.user!;
      
      // FIX: Construct a UserModel object
      final newUserProfile = UserModel(
        uid: user.uid,
        username: username,
        email: email, 
        eloScore: 1000, 
        totalBattles: 0,
        wins: 0,
        losses: 0,
        profileImageUrl: null,
        createdAt: DateTime.now(),
      );

      // FIX: Call createUserProfile with the single object
      await _ref.read(userServiceProvider).createUserProfile(newUserProfile);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
// --- END COPY & PASTE HERE ---