import 'package:hadir_mobile_full/features/auth/domain/use_cases/authentication_use_cases.dart';
import 'package:hadir_mobile_full/shared/domain/entities/administrator.dart';

/// Simple authentication repository implementation with hardcoded credentials
/// Perfect for MVP and demonstration purposes
class SimpleAuthRepository implements AuthRepository {
  /// Current authenticated administrator (in-memory session)
  Administrator? _currentUser;

  /// Demo administrator account data
  static final _demoAdmin = Administrator(
    id: 'admin-001',
    username: 'admin',
    email: 'admin@hadir.edu',
    fullName: 'System Administrator',
    role: AdministratorRole.admin,
    status: AdminStatus.active,
    lastLoginAt: DateTime.now(),
    passwordChangedAt: DateTime.now().subtract(const Duration(days: 30)),
    failedLoginAttempts: 0,
    isAccountLocked: false,
    createdAt: DateTime.now().subtract(const Duration(days: 90)),
    updatedAt: DateTime.now(),
  );

  /// Hardcoded credentials for demo purposes
  static const String _validUsername = 'admin';
  static const String _validPassword = 'hadir2025';

  @override
  Future<Administrator?> authenticate(String username, String password) async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Simple credential validation
    if (username.trim() == _validUsername && password.trim() == _validPassword) {
      // Update last login time
      _currentUser = _demoAdmin.copyWith(
        lastLoginAt: DateTime.now(),
        failedLoginAttempts: 0,
      );
      
      // Record successful login attempt
      await recordLoginAttempt(username, true);
      
      return _currentUser;
    }

    // Record failed login attempt
    await recordLoginAttempt(username, false);
    
    return null; // Invalid credentials
  }

  @override
  Future<Administrator?> getCurrentUser() async {
    // Return currently authenticated user from memory
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    // Simulate logout delay
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Clear current user session
    _currentUser = null;
  }

  @override
  Future<bool> hasPermissions(List<Permission> permissions) async {
    final user = _currentUser;
    if (user == null) return false;

    // Admin role has all permissions
    if (user.role == AdministratorRole.admin) {
      return true;
    }

    // Check if user has all required permissions
    final userPermissions = user.role.permissions;
    return permissions.every((permission) => userPermissions.contains(permission));
  }

  @override
  Future<bool> refreshToken() async {
    // Simulate token refresh for demo purposes
    await Future.delayed(const Duration(milliseconds: 200));
    
    // For simple auth, just check if user is still logged in
    return _currentUser != null;
  }

  @override
  Future<void> recordLoginAttempt(String username, bool success) async {
    // In a real implementation, this would log to database or analytics
    // For demo purposes, just print to console
    final timestamp = DateTime.now().toIso8601String();
    final status = success ? 'SUCCESS' : 'FAILED';
    
    print('[AUTH] $timestamp - Login attempt for "$username": $status');
    
    // Simulate database write delay
    await Future.delayed(const Duration(milliseconds: 50));
  }
}