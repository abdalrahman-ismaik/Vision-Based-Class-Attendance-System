import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/hadir_app.dart';
import 'shared/data/data_sources/database_helper.dart';
import 'core/services/backend_config_service.dart';
import 'core/services/error_log_service.dart';

// Export the main app widget for testing
export 'app/hadir_app.dart';

/// Development mode flag - Set to true to skip authentication and use mock data
const bool kDevelopmentMode = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize backend configuration service
  try {
    await BackendConfigService.initialize();
    print('[HADIR] Backend config service initialized');
  } catch (e) {
    print('[HADIR] Backend config initialization failed: $e');
  }
  
  // Initialize error logging service
  try {
    await ErrorLogService.initialize();
    print('[HADIR] Error logging service initialized');
    
    // Log app startup
    await ErrorLogService.instance.logInfo(
      'Application',
      'HADIR Mobile app started',
    );
  } catch (e) {
    print('[HADIR] Error logging initialization failed: $e');
  }
  
  // Check and upgrade database if needed
  try {
    final currentVersion = await DatabaseHelper.getDatabaseVersion();
    if (currentVersion < 5) {
      print('[HADIR] Database needs upgrade from v$currentVersion to v5');
      await DatabaseHelper.forceUpgrade();
      print('[HADIR] Database upgraded successfully!');
      
      await ErrorLogService.instance.logInfo(
        'Database',
        'Database upgraded from v$currentVersion to v5',
      );
    }
  } catch (e) {
    print('[HADIR] Database check failed: $e');
    
    await ErrorLogService.instance.logError(
      'Database',
      'Database check or upgrade failed: $e',
      stackTrace: e.toString(),
    );
  }
  
  runApp(
    const ProviderScope(
      child: HadirApp(),
    ),
  );
}


