import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/hadir_app.dart';
import 'shared/data/data_sources/database_helper.dart';

// Export the main app widget for testing
export 'app/hadir_app.dart';

/// Development mode flag - Set to true to skip authentication and use mock data
const bool kDevelopmentMode = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check and upgrade database if needed
  try {
    final currentVersion = await DatabaseHelper.getDatabaseVersion();
    if (currentVersion < 5) {
      print('[HADIR] Database needs upgrade from v$currentVersion to v5');
      await DatabaseHelper.forceUpgrade();
      print('[HADIR] Database upgraded successfully!');
    }
  } catch (e) {
    print('[HADIR] Database check failed: $e');
  }
  
  runApp(
    const ProviderScope(
      child: HadirApp(),
    ),
  );
}


