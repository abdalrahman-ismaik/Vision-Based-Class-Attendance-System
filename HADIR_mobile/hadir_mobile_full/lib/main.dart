import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/hadir_app.dart';

// Export the main app widget for testing
export 'app/hadir_app.dart';

/// Development mode flag - Set to true to skip authentication and use mock data
const bool kDevelopmentMode = true;

void main() {
  runApp(
    const ProviderScope(
      child: HadirApp(),
    ),
  );
}


