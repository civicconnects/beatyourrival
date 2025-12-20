// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Your generated Firebase options file
import 'firebase_options.dart'; 
// The screen we created to check if the user is logged in
import 'screens/auth_checker.dart'; 

void main() async {
  try {
    // 1. Ensure Flutter widgets are initialized before any only async calls
    WidgetsFlutterBinding.ensureInitialized(); 

    // 2. Initialize Firebase using the generated options for the current platform
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 3. Run the application wrapped in ProviderScope for Riverpod state management
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  } catch (e, stack) {
    // If initialization fails, run a simple error app to show the error
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Center(
              child: Text(
                'CRITICAL INIT ERROR:\n$e\n\n$stack',
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeatRivals',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // 👇 CRITICAL CHANGE: Use AuthChecker as the initial screen
      // AuthChecker decides if the user sees LoginScreen or HomeScreen
      home: const AuthChecker(),
    );
  }
}