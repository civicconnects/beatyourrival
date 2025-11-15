// lib/providers/navigation_provider.dart
// --- START COPY & PASTE HERE ---

import 'package:flutter_riverpod/flutter_riverpod.dart';

// This provider controls which tab is selected in the main HomeScreen
final homeTabIndexProvider = StateProvider<int>((ref) => 0);
// --- END COPY & PASTE HERE ---