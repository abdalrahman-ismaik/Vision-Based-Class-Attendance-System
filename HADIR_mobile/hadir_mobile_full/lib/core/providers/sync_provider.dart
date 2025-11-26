import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hadir_mobile_full/core/config/sync_config.dart';
import 'package:hadir_mobile_full/core/services/sync_service.dart';
import 'package:hadir_mobile_full/shared/data/data_sources/local_database_data_source.dart';

/// Provider for Dio HTTP client configured for backend communication
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: SyncConfig.backendBaseUrl,
      connectTimeout: SyncConfig.connectionTimeout,
      receiveTimeout: SyncConfig.receiveTimeout,
      sendTimeout: SyncConfig.sendTimeout,
      headers: SyncConfig.defaultHeaders,
    ),
  );

  // Add interceptors for logging (development only)
  if (SyncConfig.enableDetailedLogging) {
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: SyncConfig.logRequestBodies,
        responseHeader: false,
        responseBody: SyncConfig.logResponseBodies,
        error: true,
        logPrint: (obj) => print('[DIO] $obj'),
      ),
    );
  }

  return dio;
});

/// Provider for local database data source
final databaseProvider = Provider<LocalDatabaseDataSource>((ref) {
  return LocalDatabaseDataSource();
});

/// Provider for SyncService
/// 
/// This is the main service for syncing students to backend.
/// Use this provider to access sync functionality throughout the app.
/// 
/// Example usage:
/// ```dart
/// final syncService = ref.read(syncServiceProvider);
/// final result = await syncService.syncStudent(
///   student: student,
///   imageFile: imageFile,
/// );
/// ```
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    dio: ref.watch(dioProvider),
    database: ref.watch(databaseProvider),
  );
});

/// Stream provider for watching sync status of a specific student
/// 
/// This provider will emit new values whenever the student's
/// sync status changes in the database.
/// 
/// Example usage:
/// ```dart
/// final syncStatus = ref.watch(syncStatusStreamProvider(studentId));
/// syncStatus.when(
///   data: (status) => Text('Status: ${status.displayText}'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
final syncStatusStreamProvider = StreamProvider.family<String?, String>(
  (ref, studentId) async* {
    final database = ref.watch(databaseProvider);
    final db = await database.database;
    
    // Initial value
    final initial = await db.query(
      'students',
      columns: ['sync_status'],
      where: 'id = ?',
      whereArgs: [studentId],
    );
    
    if (initial.isNotEmpty) {
      yield initial.first['sync_status'] as String?;
    }
    
    // Note: For real-time updates, you would need to implement
    // a database change listener or use a Stream-based database
    // For now, this returns the initial value
    // TODO: Implement real-time sync status updates (Day 3)
  },
);

/// Future provider for getting list of students that need syncing
/// 
/// Returns students where sync_status is 'not_synced' or 'failed'
/// 
/// Example usage:
/// ```dart
/// final studentsToSync = ref.watch(studentsToSyncProvider);
/// studentsToSync.when(
///   data: (students) => Text('${students.length} students to sync'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
final studentsToSyncProvider = FutureProvider<List<dynamic>>((ref) async {
  final syncService = ref.watch(syncServiceProvider);
  return await syncService.getStudentsToSync();
});

/// State provider for tracking ongoing sync operations
/// 
/// Use this to show global sync progress (e.g., "Syncing 3 students...")
/// 
/// Example usage:
/// ```dart
/// final isSyncing = ref.watch(isSyncingProvider);
/// if (isSyncing) {
///   return Text('Syncing...');
/// }
/// ```
final isSyncingProvider = StateProvider<bool>((ref) => false);

/// State provider for last sync timestamp
/// 
/// Stores when the last successful sync occurred
final lastSyncTimestampProvider = StateProvider<DateTime?>((ref) => null);

/// State provider for sync error message
/// 
/// Stores the last sync error for display to user
final syncErrorProvider = StateProvider<String?>((ref) => null);
