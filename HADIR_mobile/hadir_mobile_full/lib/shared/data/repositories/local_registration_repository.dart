import '../data_sources/local_database_data_source.dart';

/// SQLite implementation of RegistrationRepository
/// Provides concrete data persistence for registration sessions using local SQLite database
/// 
/// NOTE: This is a foundational implementation that establishes the repository structure.
/// Full implementation with all interface methods will be completed when all domain models
/// and computer vision components are implemented in later tasks (T031-T036).
class LocalRegistrationRepository {
  final LocalDatabaseDataSource _dataSource;
  
  LocalRegistrationRepository(this._dataSource);

  static const String _sessionsTable = 'registration_sessions';
  static const String _framesTable = 'selected_frames';

  /// Basic database operations for registration sessions
  Future<void> insertSession(Map<String, dynamic> sessionData) async {
    await _dataSource.insert(_sessionsTable, sessionData);
  }

  Future<List<Map<String, dynamic>>> getSessionsByStudentId(String studentId) async {
    return await _dataSource.query(
      _sessionsTable,
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getSessionById(String sessionId) async {
    final maps = await _dataSource.query(
      _sessionsTable,
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<void> updateSession(String sessionId, Map<String, dynamic> updates) async {
    await _dataSource.update(
      _sessionsTable,
      updates,
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> deleteSession(String sessionId) async {
    await _dataSource.transaction((txn) async {
      // Delete associated frames first
      await txn.delete(
        _framesTable,
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      
      // Delete the session
      await txn.delete(
        _sessionsTable,
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    });
  }

  /// Basic database operations for selected frames
  Future<void> insertFrame(Map<String, dynamic> frameData) async {
    await _dataSource.insert(_framesTable, frameData);
  }

  Future<List<Map<String, dynamic>>> getFramesBySessionId(String sessionId) async {
    return await _dataSource.query(
      _framesTable,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp_ms ASC',
    );
  }

  Future<void> deleteFrame(String frameId) async {
    await _dataSource.delete(
      _framesTable,
      where: 'id = ?',
      whereArgs: [frameId],
    );
  }

  /// Utility methods for repository operations
  Future<int> getSessionCount() async {
    final result = await _dataSource.rawQuery('SELECT COUNT(*) as count FROM $_sessionsTable');
    return result.first['count'] as int;
  }

  Future<int> getFrameCount(String sessionId) async {
    final result = await _dataSource.rawQuery(
      'SELECT COUNT(*) as count FROM $_framesTable WHERE session_id = ?',
      [sessionId],
    );
    return result.first['count'] as int;
  }
}