// lib/services/auth_service.dart
// --- START COPY & PASTE HERE ---

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_service.dart';

final authServiceProvider = Provider((ref) => AuthService(ref.read(userServiceProvider)));

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final UserService _userService;

  AuthService(this._userService);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Sign-in failed');
    }
  }

  Future<void> signUpWithEmail(String email, String password, String username) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // FIX: Calls the new initialization method
      await _userService.initializeNewUserProfile(userCredential.user!, username, email);
      
      // FIX: Send email verification (but don't fail registration if this fails)
      try {
        await userCredential.user!.sendEmailVerification();
      } catch (verificationError) {
        // Log but don't fail registration
        print('Email verification send failed: $verificationError');
        // User can still use the app, just not verified
      }

    } on FirebaseAuthException catch (e) {
      // Provide more specific error messages
      String errorMessage = 'Registration failed';
      
      if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already registered. Try logging in instead.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak. Use at least 6 characters.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address.';
      } else if (e.message != null) {
        errorMessage = e.message!;
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      // Catch any other errors (like Firestore errors)
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // NEW METHOD: Handles sending the verification link
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  User? get currentUser => _firebaseAuth.currentUser;
}
// --- END COPY & PASTE HERE ---