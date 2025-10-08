import 'package:dartz/dartz.dart';
import 'package:hadir_mobile_full/shared/domain/entities/administrator.dart';
import 'package:hadir_mobile_full/shared/domain/exceptions/hadir_exceptions.dart';

/// Result type for use case operations
typedef UseCaseResult<T> = Either<HadirException, T>;

/// Abstract base class for authentication repository
abstract class AuthRepository {
  /// Authenticate user with username and password
  Future<Administrator?> authenticate(String username, String password);
  
  /// Get current authenticated user
  Future<Administrator?> getCurrentUser();
  
  /// Logout current user
  Future<void> logout();
  
  /// Check if user has required permissions
  Future<bool> hasPermissions(List<Permission> permissions);
  
  /// Refresh authentication token
  Future<bool> refreshToken();
  
  /// Record login attempt
  Future<void> recordLoginAttempt(String username, bool success);
}

/// Parameters for login use case
class LoginParams {
  const LoginParams({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;
}

/// Parameters for permission validation
class ValidatePermissionsParams {
  const ValidatePermissionsParams({
    required this.permissions,
  });

  final List<Permission> permissions;
}

/// Use case for user login
class LoginUseCase {
  const LoginUseCase(this._authRepository);

  final AuthRepository _authRepository;

  /// Execute login operation
  /// 
  /// [params] - Login parameters containing username and password
  /// 
  /// Returns authenticated administrator or authentication exception
  Future<UseCaseResult<Administrator>> call(LoginParams params) async {
    try {
      // Validate input parameters
      if (params.username.trim().isEmpty) {
        return Left(const FieldRequiredException('username'));
      }

      if (params.password.trim().isEmpty) {
        return Left(const FieldRequiredException('password'));
      }

      // Validate username format (3-30 characters, alphanumeric and underscore)
      if (!RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(params.username)) {
        return Left(const InvalidFormatException('username', 'Username must be 3-30 characters, alphanumeric and underscore only'));
      }

      // Attempt authentication
      final administrator = await _authRepository.authenticate(
        params.username,
        params.password,
      );

      if (administrator == null) {
        // Record failed login attempt
        await _authRepository.recordLoginAttempt(params.username, false);
        return Left(const InvalidCredentialsException());
      }

      // Check if account can login
      if (!administrator.canLogin) {
        await _authRepository.recordLoginAttempt(params.username, false);
        
        if (administrator.isAccountLocked) {
          return Left(const AccountLockedException());
        }
        
        if (administrator.status != AdminStatus.active) {
          return Left(const AccountDisabledException());
        }
      }

      // Record successful login attempt
      await _authRepository.recordLoginAttempt(params.username, true);

      return Right(administrator);
    } on AuthenticationException catch (e) {
      return Left(e);
    } on Exception catch (e) {
      return Left(GenericHadirException('Login failed: ${e.toString()}'));
    }
  }
}

/// Use case for user logout
class LogoutUseCase {
  const LogoutUseCase(this._authRepository);

  final AuthRepository _authRepository;

  /// Execute logout operation
  /// 
  /// Returns success or authentication exception
  Future<UseCaseResult<void>> call() async {
    try {
      await _authRepository.logout();
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(e);
    } on Exception catch (e) {
      return Left(GenericHadirException('Logout failed: ${e.toString()}'));
    }
  }
}

/// Use case for getting current user
class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._authRepository);

  final AuthRepository _authRepository;

  /// Execute get current user operation
  /// 
  /// Returns current administrator or null if not authenticated
  Future<UseCaseResult<Administrator?>> call() async {
    try {
      final administrator = await _authRepository.getCurrentUser();
      return Right(administrator);
    } on AuthenticationException catch (e) {
      return Left(e);
    } on Exception catch (e) {
      return Left(GenericHadirException('Failed to get current user: ${e.toString()}'));
    }
  }
}

/// Use case for validating permissions
class ValidatePermissionsUseCase {
  const ValidatePermissionsUseCase(this._authRepository);

  final AuthRepository _authRepository;

  /// Execute permission validation
  /// 
  /// [params] - Permission validation parameters
  /// 
  /// Returns true if user has all required permissions
  Future<UseCaseResult<bool>> call(ValidatePermissionsParams params) async {
    try {
      if (params.permissions.isEmpty) {
        return const Right(true);
      }

      final hasPermissions = await _authRepository.hasPermissions(params.permissions);
      
      if (!hasPermissions) {
        return Left(const InsufficientPermissionsException());
      }

      return Right(hasPermissions);
    } on AuthenticationException catch (e) {
      return Left(e);
    } on Exception catch (e) {
      return Left(GenericHadirException('Permission validation failed: ${e.toString()}'));
    }
  }
}

/// Use case for refreshing authentication token
class RefreshTokenUseCase {
  const RefreshTokenUseCase(this._authRepository);

  final AuthRepository _authRepository;

  /// Execute token refresh operation
  /// 
  /// Returns true if token was successfully refreshed
  Future<UseCaseResult<bool>> call() async {
    try {
      final success = await _authRepository.refreshToken();
      
      if (!success) {
        return Left(const SessionExpiredException('Token refresh failed'));
      }

      return Right(success);
    } on AuthenticationException catch (e) {
      return Left(e);
    } on Exception catch (e) {
      return Left(GenericHadirException('Token refresh failed: ${e.toString()}'));
    }
  }
}

/// Container class for all authentication use cases
class AuthenticationUseCases {
  const AuthenticationUseCases({
    required this.login,
    required this.logout,
    required this.getCurrentUser,
    required this.validatePermissions,
    required this.refreshToken,
  });

  final LoginUseCase login;
  final LogoutUseCase logout;
  final GetCurrentUserUseCase getCurrentUser;
  final ValidatePermissionsUseCase validatePermissions;
  final RefreshTokenUseCase refreshToken;

  /// Factory method to create authentication use cases
  factory AuthenticationUseCases.create(AuthRepository authRepository) {
    return AuthenticationUseCases(
      login: LoginUseCase(authRepository),
      logout: LogoutUseCase(authRepository),
      getCurrentUser: GetCurrentUserUseCase(authRepository),
      validatePermissions: ValidatePermissionsUseCase(authRepository),
      refreshToken: RefreshTokenUseCase(authRepository),
    );
  }
}