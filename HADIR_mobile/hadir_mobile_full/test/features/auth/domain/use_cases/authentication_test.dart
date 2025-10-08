import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hadir_mobile_full/features/auth/domain/use_cases/authentication_use_cases.dart';
import 'package:hadir_mobile_full/features/auth/domain/repositories/auth_repository.dart';
import 'package:hadir_mobile_full/shared/domain/entities/administrator.dart';
import 'package:hadir_mobile_full/features/auth/data/models/auth_requests.dart';
import 'package:hadir_mobile_full/shared/exceptions/auth_exceptions.dart';

import 'authentication_test.mocks.dart';

// Generate mocks
@GenerateMocks([AuthRepository])
void main() {
  group('Authentication Use Cases', () {
    late AuthenticationUseCases authUseCases;
    late MockAuthRepository mockAuthRepository;
    
    setUp(() {
      mockAuthRepository = MockAuthRepository();
      authUseCases = AuthenticationUseCases(mockAuthRepository);
    });

    group('LoginUseCase', () {
      test('should return Administrator when login succeeds with valid credentials', () async {
        // Arrange
        const loginRequest = LoginRequest(
          username: 'admin001',
          password: 'SecurePass123!',
        );
        
        final expectedAdmin = Administrator(
          id: 'admin-uuid-123',
          username: 'admin001',
          firstName: 'John',
          lastName: 'Admin',
          email: 'john.admin@university.edu',
          role: AdminRole.operator,
          permissions: const [
            Permission.registerStudents,
            Permission.viewRegistrations,
            Permission.manageStudents,
          ],
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)),
        );
        
        when(mockAuthRepository.login(loginRequest))
            .thenAnswer((_) async => expectedAdmin);
        
        // Act
        final result = await authUseCases.login(loginRequest);
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(expectedAdmin));
        expect(result.data?.username, equals('admin001'));
        expect(result.data?.role, equals(AdminRole.operator));
        expect(result.data?.isActive, isTrue);
        verify(mockAuthRepository.login(loginRequest)).called(1);
      });

      test('should return failure when login fails with invalid credentials', () async {
        // Arrange
        const invalidLoginRequest = LoginRequest(
          username: 'admin001',
          password: 'WrongPassword',
        );
        
        when(mockAuthRepository.login(invalidLoginRequest))
            .thenThrow(const InvalidCredentialsException('Invalid username or password'));
        
        // Act
        final result = await authUseCases.login(invalidLoginRequest);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<InvalidCredentialsException>());
        expect(result.error?.message, equals('Invalid username or password'));
        expect(result.data, isNull);
        verify(mockAuthRepository.login(invalidLoginRequest)).called(1);
      });

      test('should return failure when login fails due to inactive account', () async {
        // Arrange
        const loginRequest = LoginRequest(
          username: 'inactive_admin',
          password: 'ValidPass123!',
        );
        
        when(mockAuthRepository.login(loginRequest))
            .thenThrow(const AccountInactiveException('Administrator account is inactive'));
        
        // Act
        final result = await authUseCases.login(loginRequest);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<AccountInactiveException>());
        expect(result.error?.message, equals('Administrator account is inactive'));
        verify(mockAuthRepository.login(loginRequest)).called(1);
      });

      test('should return failure when login fails due to account lockout', () async {
        // Arrange
        const loginRequest = LoginRequest(
          username: 'locked_admin',
          password: 'ValidPass123!',
        );
        
        when(mockAuthRepository.login(loginRequest))
            .thenThrow(const AccountLockedException('Account locked due to multiple failed attempts'));
        
        // Act
        final result = await authUseCases.login(loginRequest);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<AccountLockedException>());
        expect(result.error?.message, equals('Account locked due to multiple failed attempts'));
        verify(mockAuthRepository.login(loginRequest)).called(1);
      });

      test('should validate login request parameters', () async {
        // Arrange
        const emptyUsernameRequest = LoginRequest(
          username: '',
          password: 'ValidPass123!',
        );
        
        // Act
        final result = await authUseCases.login(emptyUsernameRequest);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<ValidationException>());
        expect(result.error?.message, contains('Username cannot be empty'));
        verifyNever(mockAuthRepository.login(any));
      });

      test('should validate password requirements', () async {
        // Arrange
        const weakPasswordRequest = LoginRequest(
          username: 'admin001',
          password: '123', // Too weak
        );
        
        // Act
        final result = await authUseCases.login(weakPasswordRequest);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<ValidationException>());
        expect(result.error?.message, contains('Password does not meet requirements'));
        verifyNever(mockAuthRepository.login(any));
      });

      test('should handle network connectivity issues during login', () async {
        // Arrange
        const loginRequest = LoginRequest(
          username: 'admin001',
          password: 'ValidPass123!',
        );
        
        when(mockAuthRepository.login(loginRequest))
            .thenThrow(const NetworkException('No internet connection'));
        
        // Act
        final result = await authUseCases.login(loginRequest);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<NetworkException>());
        expect(result.error?.message, equals('No internet connection'));
        verify(mockAuthRepository.login(loginRequest)).called(1);
      });

      test('should update last login time on successful authentication', () async {
        // Arrange
        const loginRequest = LoginRequest(
          username: 'admin002',
          password: 'SecurePass456!',
        );
        
        final beforeLogin = DateTime.now();
        final loggedInAdmin = Administrator(
          id: 'admin-uuid-456',
          username: 'admin002',
          firstName: 'Jane',
          lastName: 'Admin',
          email: 'jane.admin@university.edu',
          role: AdminRole.supervisor,
          permissions: const [
            Permission.registerStudents,
            Permission.viewRegistrations,
            Permission.manageStudents,
            Permission.exportData,
            Permission.manageAdministrators,
          ],
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          lastLoginAt: DateTime.now(),
        );
        
        when(mockAuthRepository.login(loginRequest))
            .thenAnswer((_) async => loggedInAdmin);
        
        // Act
        final result = await authUseCases.login(loginRequest);
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data?.lastLoginAt, isNotNull);
        expect(result.data?.lastLoginAt?.isAfter(beforeLogin), isTrue);
        verify(mockAuthRepository.login(loginRequest)).called(1);
      });
    });

    group('LogoutUseCase', () {
      test('should successfully logout authenticated administrator', () async {
        // Arrange
        const adminId = 'admin-uuid-123';
        
        when(mockAuthRepository.logout(adminId))
            .thenAnswer((_) async => {});
        
        // Act
        final result = await authUseCases.logout(adminId);
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
        expect(result.error, isNull);
        verify(mockAuthRepository.logout(adminId)).called(1);
      });

      test('should handle logout failure gracefully', () async {
        // Arrange
        const adminId = 'admin-uuid-456';
        
        when(mockAuthRepository.logout(adminId))
            .thenThrow(const AuthException('Failed to logout administrator'));
        
        // Act
        final result = await authUseCases.logout(adminId);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<AuthException>());
        expect(result.error?.message, equals('Failed to logout administrator'));
        verify(mockAuthRepository.logout(adminId)).called(1);
      });

      test('should validate administrator ID parameter', () async {
        // Arrange
        const emptyAdminId = '';
        
        // Act
        final result = await authUseCases.logout(emptyAdminId);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<ValidationException>());
        expect(result.error?.message, contains('Administrator ID cannot be empty'));
        verifyNever(mockAuthRepository.logout(any));
      });

      test('should clear session data on successful logout', () async {
        // Arrange
        const adminId = 'admin-uuid-789';
        
        when(mockAuthRepository.logout(adminId))
            .thenAnswer((_) async => {});
        when(mockAuthRepository.clearSessionData(adminId))
            .thenAnswer((_) async => {});
        
        // Act
        final result = await authUseCases.logout(adminId);
        
        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockAuthRepository.logout(adminId)).called(1);
        verify(mockAuthRepository.clearSessionData(adminId)).called(1);
      });
    });

    group('GetCurrentUserUseCase', () {
      test('should return current authenticated administrator', () async {
        // Arrange
        final expectedAdmin = Administrator(
          id: 'current-admin-123',
          username: 'current_admin',
          firstName: 'Current',
          lastName: 'User',
          email: 'current.user@university.edu',
          role: AdminRole.operator,
          permissions: const [
            Permission.registerStudents,
            Permission.viewRegistrations,
          ],
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
          lastLoginAt: DateTime.now().subtract(const Duration(minutes: 30)),
        );
        
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => expectedAdmin);
        
        // Act
        final result = await authUseCases.getCurrentUser();
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(expectedAdmin));
        expect(result.data?.username, equals('current_admin'));
        expect(result.data?.isActive, isTrue);
        verify(mockAuthRepository.getCurrentUser()).called(1);
      });

      test('should return null when no user is authenticated', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => null);
        
        // Act
        final result = await authUseCases.getCurrentUser();
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
        verify(mockAuthRepository.getCurrentUser()).called(1);
      });

      test('should handle session expiry gracefully', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenThrow(const SessionExpiredException('Authentication session has expired'));
        
        // Act
        final result = await authUseCases.getCurrentUser();
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<SessionExpiredException>());
        expect(result.error?.message, equals('Authentication session has expired'));
        verify(mockAuthRepository.getCurrentUser()).called(1);
      });

      test('should validate session token integrity', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenThrow(const InvalidTokenException('Authentication token is invalid or corrupted'));
        
        // Act
        final result = await authUseCases.getCurrentUser();
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<InvalidTokenException>());
        expect(result.error?.message, equals('Authentication token is invalid or corrupted'));
        verify(mockAuthRepository.getCurrentUser()).called(1);
      });
    });

    group('ValidatePermissionsUseCase', () {
      test('should return true when administrator has required permission', () async {
        // Arrange
        const adminId = 'admin-with-permissions';
        const requiredPermission = Permission.registerStudents;
        
        final adminWithPermissions = Administrator(
          id: adminId,
          username: 'permission_admin',
          firstName: 'Permission',
          lastName: 'Test',
          email: 'permission.test@university.edu',
          role: AdminRole.operator,
          permissions: const [
            Permission.registerStudents,
            Permission.viewRegistrations,
            Permission.manageStudents,
          ],
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          lastLoginAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        
        when(mockAuthRepository.getAdministratorById(adminId))
            .thenAnswer((_) async => adminWithPermissions);
        
        // Act
        final result = await authUseCases.validatePermissions(adminId, [requiredPermission]);
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isTrue);
        verify(mockAuthRepository.getAdministratorById(adminId)).called(1);
      });

      test('should return false when administrator lacks required permission', () async {
        // Arrange
        const adminId = 'admin-limited-permissions';
        const requiredPermission = Permission.exportData;
        
        final adminLimitedPermissions = Administrator(
          id: adminId,
          username: 'limited_admin',
          firstName: 'Limited',
          lastName: 'Access',
          email: 'limited.access@university.edu',
          role: AdminRole.operator,
          permissions: const [
            Permission.registerStudents,
            Permission.viewRegistrations,
          ],
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          lastLoginAt: DateTime.now().subtract(const Duration(minutes: 45)),
        );
        
        when(mockAuthRepository.getAdministratorById(adminId))
            .thenAnswer((_) async => adminLimitedPermissions);
        
        // Act
        final result = await authUseCases.validatePermissions(adminId, [requiredPermission]);
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isFalse);
        verify(mockAuthRepository.getAdministratorById(adminId)).called(1);
      });

      test('should validate multiple permissions correctly', () async {
        // Arrange
        const adminId = 'admin-multi-permissions';
        const requiredPermissions = [
          Permission.registerStudents,
          Permission.viewRegistrations,
          Permission.manageStudents,
        ];
        
        final adminMultiPermissions = Administrator(
          id: adminId,
          username: 'multi_admin',
          firstName: 'Multi',
          lastName: 'Permission',
          email: 'multi.permission@university.edu',
          role: AdminRole.supervisor,
          permissions: const [
            Permission.registerStudents,
            Permission.viewRegistrations,
            Permission.manageStudents,
            Permission.exportData,
          ],
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          lastLoginAt: DateTime.now().subtract(const Duration(minutes: 10)),
        );
        
        when(mockAuthRepository.getAdministratorById(adminId))
            .thenAnswer((_) async => adminMultiPermissions);
        
        // Act
        final result = await authUseCases.validatePermissions(adminId, requiredPermissions);
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isTrue);
        verify(mockAuthRepository.getAdministratorById(adminId)).called(1);
      });

      test('should return false when administrator is inactive', () async {
        // Arrange
        const adminId = 'inactive-admin';
        const requiredPermission = Permission.registerStudents;
        
        final inactiveAdmin = Administrator(
          id: adminId,
          username: 'inactive_admin',
          firstName: 'Inactive',
          lastName: 'User',
          email: 'inactive.user@university.edu',
          role: AdminRole.operator,
          permissions: const [Permission.registerStudents],
          isActive: false, // Inactive administrator
          createdAt: DateTime.now().subtract(const Duration(days: 180)),
          lastLoginAt: DateTime.now().subtract(const Duration(days: 30)),
        );
        
        when(mockAuthRepository.getAdministratorById(adminId))
            .thenAnswer((_) async => inactiveAdmin);
        
        // Act
        final result = await authUseCases.validatePermissions(adminId, [requiredPermission]);
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isFalse);
        verify(mockAuthRepository.getAdministratorById(adminId)).called(1);
      });

      test('should handle administrator not found error', () async {
        // Arrange
        const nonExistentAdminId = 'non-existent-admin';
        const requiredPermission = Permission.registerStudents;
        
        when(mockAuthRepository.getAdministratorById(nonExistentAdminId))
            .thenThrow(const NotFoundException('Administrator not found'));
        
        // Act
        final result = await authUseCases.validatePermissions(nonExistentAdminId, [requiredPermission]);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<NotFoundException>());
        expect(result.error?.message, equals('Administrator not found'));
        verify(mockAuthRepository.getAdministratorById(nonExistentAdminId)).called(1);
      });

      test('should validate role-based permissions correctly', () async {
        // Arrange
        const supervisorAdminId = 'supervisor-admin';
        const operatorAdminId = 'operator-admin';
        const adminPermissions = [Permission.manageAdministrators];
        
        final supervisor = Administrator(
          id: supervisorAdminId,
          username: 'supervisor_admin',
          firstName: 'Super',
          lastName: 'Visor',
          email: 'supervisor@university.edu',
          role: AdminRole.supervisor,
          permissions: const [
            Permission.registerStudents,
            Permission.viewRegistrations,
            Permission.manageStudents,
            Permission.exportData,
            Permission.manageAdministrators,
          ],
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 100)),
          lastLoginAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        
        final operator = Administrator(
          id: operatorAdminId,
          username: 'operator_admin',
          firstName: 'Oper',
          lastName: 'Ator',
          email: 'operator@university.edu',
          role: AdminRole.operator,
          permissions: const [
            Permission.registerStudents,
            Permission.viewRegistrations,
            Permission.manageStudents,
          ],
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 50)),
          lastLoginAt: DateTime.now().subtract(const Duration(minutes: 15)),
        );
        
        when(mockAuthRepository.getAdministratorById(supervisorAdminId))
            .thenAnswer((_) async => supervisor);
        when(mockAuthRepository.getAdministratorById(operatorAdminId))
            .thenAnswer((_) async => operator);
        
        // Act
        final supervisorResult = await authUseCases.validatePermissions(supervisorAdminId, adminPermissions);
        final operatorResult = await authUseCases.validatePermissions(operatorAdminId, adminPermissions);
        
        // Assert
        expect(supervisorResult.isSuccess, isTrue);
        expect(supervisorResult.data, isTrue); // Supervisor has admin permissions
        expect(operatorResult.isSuccess, isTrue);
        expect(operatorResult.data, isFalse); // Operator lacks admin permissions
        verify(mockAuthRepository.getAdministratorById(supervisorAdminId)).called(1);
        verify(mockAuthRepository.getAdministratorById(operatorAdminId)).called(1);
      });
    });

    group('RefreshTokenUseCase', () {
      test('should successfully refresh valid authentication token', () async {
        // Arrange
        const refreshToken = 'valid-refresh-token-123';
        const newAccessToken = 'new-access-token-456';
        
        final refreshResult = AuthTokens(
          accessToken: newAccessToken,
          refreshToken: refreshToken,
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );
        
        when(mockAuthRepository.refreshToken(refreshToken))
            .thenAnswer((_) async => refreshResult);
        
        // Act
        final result = await authUseCases.refreshToken(refreshToken);
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data?.accessToken, equals(newAccessToken));
        expect(result.data?.refreshToken, equals(refreshToken));
        expect(result.data?.expiresAt, isNotNull);
        verify(mockAuthRepository.refreshToken(refreshToken)).called(1);
      });

      test('should handle expired refresh token', () async {
        // Arrange
        const expiredRefreshToken = 'expired-refresh-token';
        
        when(mockAuthRepository.refreshToken(expiredRefreshToken))
            .thenThrow(const TokenExpiredException('Refresh token has expired'));
        
        // Act
        final result = await authUseCases.refreshToken(expiredRefreshToken);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<TokenExpiredException>());
        expect(result.error?.message, equals('Refresh token has expired'));
        verify(mockAuthRepository.refreshToken(expiredRefreshToken)).called(1);
      });

      test('should handle invalid refresh token format', () async {
        // Arrange
        const invalidToken = 'invalid-token-format';
        
        when(mockAuthRepository.refreshToken(invalidToken))
            .thenThrow(const InvalidTokenException('Invalid refresh token format'));
        
        // Act
        final result = await authUseCases.refreshToken(invalidToken);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<InvalidTokenException>());
        expect(result.error?.message, equals('Invalid refresh token format'));
        verify(mockAuthRepository.refreshToken(invalidToken)).called(1);
      });

      test('should validate refresh token parameter', () async {
        // Arrange
        const emptyToken = '';
        
        // Act
        final result = await authUseCases.refreshToken(emptyToken);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<ValidationException>());
        expect(result.error?.message, contains('Refresh token cannot be empty'));
        verifyNever(mockAuthRepository.refreshToken(any));
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle database connection failures gracefully', () async {
        // Arrange
        const loginRequest = LoginRequest(
          username: 'admin_db_fail',
          password: 'ValidPass123!',
        );
        
        when(mockAuthRepository.login(loginRequest))
            .thenThrow(const DatabaseException('Database connection failed'));
        
        // Act
        final result = await authUseCases.login(loginRequest);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<DatabaseException>());
        expect(result.error?.message, equals('Database connection failed'));
        verify(mockAuthRepository.login(loginRequest)).called(1);
      });

      test('should handle concurrent login attempts appropriately', () async {
        // Arrange
        const loginRequest = LoginRequest(
          username: 'concurrent_admin',
          password: 'ValidPass123!',
        );
        
        when(mockAuthRepository.login(loginRequest))
            .thenThrow(const ConcurrencyException('Another login session is in progress'));
        
        // Act
        final result = await authUseCases.login(loginRequest);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<ConcurrencyException>());
        expect(result.error?.message, equals('Another login session is in progress'));
        verify(mockAuthRepository.login(loginRequest)).called(1);
      });

      test('should handle authentication rate limiting', () async {
        // Arrange
        const loginRequest = LoginRequest(
          username: 'rate_limited_admin',
          password: 'ValidPass123!',
        );
        
        when(mockAuthRepository.login(loginRequest))
            .thenThrow(const RateLimitException('Too many login attempts. Please try again later'));
        
        // Act
        final result = await authUseCases.login(loginRequest);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<RateLimitException>());
        expect(result.error?.message, equals('Too many login attempts. Please try again later'));
        verify(mockAuthRepository.login(loginRequest)).called(1);
      });

      test('should handle security policy violations', () async {
        // Arrange
        const loginRequest = LoginRequest(
          username: 'policy_violation_admin',
          password: 'ValidPass123!',
        );
        
        when(mockAuthRepository.login(loginRequest))
            .thenThrow(const SecurityPolicyException('Login not allowed from this location'));
        
        // Act
        final result = await authUseCases.login(loginRequest);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<SecurityPolicyException>());
        expect(result.error?.message, equals('Login not allowed from this location'));
        verify(mockAuthRepository.login(loginRequest)).called(1);
      });
    });

    group('Performance and Security Tests', () {
      test('should complete login operations within acceptable timeframe', () async {
        // Arrange
        const loginRequest = LoginRequest(
          username: 'performance_admin',
          password: 'ValidPass123!',
        );
        
        final admin = Administrator(
          id: 'performance-admin-id',
          username: 'performance_admin',
          firstName: 'Performance',
          lastName: 'Test',
          email: 'performance@university.edu',
          role: AdminRole.operator,
          permissions: const [Permission.registerStudents],
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          lastLoginAt: DateTime.now(),
        );
        
        when(mockAuthRepository.login(loginRequest))
            .thenAnswer((_) async {
          // Simulate authentication processing time
          await Future.delayed(const Duration(milliseconds: 100));
          return admin;
        });
        
        // Act
        final stopwatch = Stopwatch()..start();
        final result = await authUseCases.login(loginRequest);
        stopwatch.stop();
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete within 5 seconds
        verify(mockAuthRepository.login(loginRequest)).called(1);
      });

      test('should not expose sensitive information in error messages', () async {
        // Arrange
        const loginRequest = LoginRequest(
          username: 'admin001',
          password: 'WrongPassword',
        );
        
        when(mockAuthRepository.login(loginRequest))
            .thenThrow(const InvalidCredentialsException('Authentication failed'));
        
        // Act
        final result = await authUseCases.login(loginRequest);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error?.message, equals('Authentication failed'));
        expect(result.error?.message, isNot(contains('admin001'))); // Should not expose username
        expect(result.error?.message, isNot(contains('WrongPassword'))); // Should not expose password
        verify(mockAuthRepository.login(loginRequest)).called(1);
      });

      test('should handle memory efficiently during batch permission validation', () async {
        // Arrange
        const adminId = 'batch-permissions-admin';
        final largePermissionSet = Permission.values; // All available permissions
        
        final adminWithAllPermissions = Administrator(
          id: adminId,
          username: 'batch_admin',
          firstName: 'Batch',
          lastName: 'Test',
          email: 'batch@university.edu',
          role: AdminRole.supervisor,
          permissions: Permission.values,
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          lastLoginAt: DateTime.now(),
        );
        
        when(mockAuthRepository.getAdministratorById(adminId))
            .thenAnswer((_) async => adminWithAllPermissions);
        
        // Act
        final result = await authUseCases.validatePermissions(adminId, largePermissionSet);
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isTrue);
        verify(mockAuthRepository.getAdministratorById(adminId)).called(1);
      });
    });
  });
}