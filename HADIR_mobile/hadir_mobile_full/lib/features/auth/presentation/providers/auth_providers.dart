import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hadir_mobile_full/shared/domain/entities/administrator.dart';
import 'package:hadir_mobile_full/features/auth/domain/use_cases/authentication_use_cases.dart';
import 'package:hadir_mobile_full/shared/domain/exceptions/hadir_exceptions.dart';

/// Authentication state for the application
class AuthState {
  const AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.administrator,
    this.error,
  });

  final bool isAuthenticated;
  final bool isLoading;
  final Administrator? administrator;
  final HadirException? error;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    Administrator? administrator,
    HadirException? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      administrator: administrator ?? this.administrator,
      error: error ?? this.error,
    );
  }

  factory AuthState.initial() {
    return const AuthState(
      isAuthenticated: false,
      isLoading: false,
    );
  }

  factory AuthState.loading() {
    return const AuthState(
      isAuthenticated: false,
      isLoading: true,
    );
  }

  factory AuthState.authenticated(Administrator administrator) {
    return AuthState(
      isAuthenticated: true,
      isLoading: false,
      administrator: administrator,
    );
  }

  factory AuthState.error(HadirException error) {
    return AuthState(
      isAuthenticated: false,
      isLoading: false,
      error: error,
    );
  }
}

/// Authentication controller for managing login, logout, and session state
class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
  }) : super(AuthState.initial());

  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  /// Authenticate user with username and password
  Future<void> login(String username, String password) async {
    try {
      state = AuthState.loading();

      // Use existing LoginUseCase
      final result = await loginUseCase.call(
        LoginParams(
          username: username,
          password: password,
        ),
      );

      result.fold(
        (error) => state = AuthState.error(error),
        (administrator) => state = AuthState.authenticated(administrator),
      );
    } catch (e) {
      final exception = e is HadirException ? e : GenericHadirException(e.toString());
      state = AuthState.error(exception);
    }
  }

  /// Logout current user and clear session
  Future<void> logout() async {
    try {
      state = AuthState.loading();
      
      // Use existing LogoutUseCase
      final result = await logoutUseCase.call();
      
      result.fold(
        (error) => state = AuthState.error(error),
        (_) => state = AuthState.initial(),
      );
    } catch (e) {
      final exception = e is HadirException ? e : GenericHadirException(e.toString());
      state = AuthState.error(exception);
    }
  }

  /// Check if user session is still valid
  Future<void> checkAuthStatus() async {
    try {
      state = AuthState.loading();
      
      // Use existing GetCurrentUserUseCase
      final result = await getCurrentUserUseCase.call();
      
      result.fold(
        (error) => state = AuthState.error(error),
        (administrator) {
          if (administrator != null) {
            state = AuthState.authenticated(administrator);
          } else {
            state = AuthState.initial();
          }
        },
      );
    } catch (e) {
      final exception = e is HadirException ? e : GenericHadirException(e.toString());
      state = AuthState.error(exception);
    }
  }

  /// Clear any authentication errors
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  /// Reset authentication state
  void reset() {
    state = AuthState.initial();
  }
}

/// Login form state for managing form input validation
class LoginFormState {
  const LoginFormState({
    required this.username,
    required this.password,
    required this.isValid,
    this.usernameError,
    this.passwordError,
  });

  final String username;
  final String password;
  final bool isValid;
  final String? usernameError;
  final String? passwordError;

  LoginFormState copyWith({
    String? username,
    String? password,
    bool? isValid,
    String? usernameError,
    String? passwordError,
  }) {
    return LoginFormState(
      username: username ?? this.username,
      password: password ?? this.password,
      isValid: isValid ?? this.isValid,
      usernameError: usernameError ?? this.usernameError,
      passwordError: passwordError ?? this.passwordError,
    );
  }

  factory LoginFormState.initial() {
    return const LoginFormState(
      username: '',
      password: '',
      isValid: false,
    );
  }
}

/// Login form controller for managing form state and validation
class LoginFormController extends StateNotifier<LoginFormState> {
  LoginFormController() : super(LoginFormState.initial());

  /// Update username and validate
  void updateUsername(String username) {
    state = state.copyWith(username: username);
    _validateForm();
  }

  /// Update password and validate
  void updatePassword(String password) {
    state = state.copyWith(password: password);
    _validateForm();
  }

  /// Simple form validation
  void _validateForm() {
    String? usernameError;
    String? passwordError;
    
    // Basic validation logic (matching LoginUseCase validation)
    if (state.username.trim().isEmpty) {
      usernameError = 'Username is required';
    } else if (!RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(state.username)) {
      usernameError = 'Username must be 3-30 characters, alphanumeric and underscore only';
    }
    
    if (state.password.trim().isEmpty) {
      passwordError = 'Password is required';
    }
    
    final isValid = usernameError == null && passwordError == null;
    
    state = state.copyWith(
      isValid: isValid,
      usernameError: usernameError,
      passwordError: passwordError,
    );
  }

  /// Clear form and reset to initial state
  void clearForm() {
    state = LoginFormState.initial();
  }

  /// Get current form data for submission
  LoginFormData getFormData() {
    return LoginFormData(
      username: state.username,
      password: state.password,
    );
  }
}

/// Form data structure for login submission
class LoginFormData {
  const LoginFormData({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;
}

/// Session management state
class SessionState {
  const SessionState({
    required this.isActive,
    required this.expiresAt,
    this.lastActivity,
    this.sessionId,
  });

  final bool isActive;
  final DateTime expiresAt;
  final DateTime? lastActivity;
  final String? sessionId;

  SessionState copyWith({
    bool? isActive,
    DateTime? expiresAt,
    DateTime? lastActivity,
    String? sessionId,
  }) {
    return SessionState(
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      lastActivity: lastActivity ?? this.lastActivity,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  factory SessionState.inactive() {
    return SessionState(
      isActive: false,
      expiresAt: DateTime.now(),
    );
  }

  factory SessionState.active({
    required Duration duration,
    String? sessionId,
  }) {
    final now = DateTime.now();
    return SessionState(
      isActive: true,
      expiresAt: now.add(duration),
      lastActivity: now,
      sessionId: sessionId,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Session controller for managing user session lifecycle
class SessionController extends StateNotifier<SessionState> {
  SessionController() : super(SessionState.inactive()) {
    _startSessionTimer();
  }

  static const Duration sessionDuration = Duration(hours: 8); // 8-hour session
  static const Duration warningDuration = Duration(minutes: 15); // Warn 15 minutes before expiry

  /// Start a new session
  void startSession({String? sessionId}) {
    state = SessionState.active(
      duration: sessionDuration,
      sessionId: sessionId ?? _generateSessionId(),
    );
  }

  /// End current session
  void endSession() {
    state = SessionState.inactive();
  }

  /// Update last activity timestamp
  void updateActivity() {
    if (state.isActive && !state.isExpired) {
      state = state.copyWith(lastActivity: DateTime.now());
    }
  }

  /// Extend current session
  void extendSession() {
    if (state.isActive) {
      state = state.copyWith(
        expiresAt: DateTime.now().add(sessionDuration),
        lastActivity: DateTime.now(),
      );
    }
  }

  /// Check if session is expiring soon
  bool get isExpiringSoon {
    if (!state.isActive || state.isExpired) return false;
    
    final timeUntilExpiry = state.expiresAt.difference(DateTime.now());
    return timeUntilExpiry <= warningDuration;
  }

  /// Get remaining session time
  Duration get remainingTime {
    if (!state.isActive || state.isExpired) return Duration.zero;
    
    return state.expiresAt.difference(DateTime.now());
  }

  /// Start session monitoring timer
  void _startSessionTimer() {
    // In a real implementation, this would set up a timer to check session expiry
    // For now, we'll just track state
  }

  /// Generate unique session ID
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }
}

// =============================================================================
// PROVIDERS
// =============================================================================

/// Provider for LoginUseCase
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  // This would be injected from a service locator in a real implementation
  throw UnimplementedError('LoginUseCase provider not implemented yet');
});

/// Provider for LogoutUseCase
final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  // This would be injected from a service locator in a real implementation
  throw UnimplementedError('LogoutUseCase provider not implemented yet');
});

/// Provider for GetCurrentUserUseCase
final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  // This would be injected from a service locator in a real implementation
  throw UnimplementedError('GetCurrentUserUseCase provider not implemented yet');
});

/// Provider for authentication controller
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    loginUseCase: ref.watch(loginUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    getCurrentUserUseCase: ref.watch(getCurrentUserUseCaseProvider),
  );
});

/// Provider for login form controller
final loginFormControllerProvider = StateNotifierProvider<LoginFormController, LoginFormState>((ref) {
  return LoginFormController();
});

/// Provider for session controller
final sessionControllerProvider = StateNotifierProvider<SessionController, SessionState>((ref) {
  return SessionController();
});

/// Provider for checking if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).isAuthenticated;
});

/// Provider for current authenticated user
final currentUserProvider = Provider<Administrator?>((ref) {
  return ref.watch(authControllerProvider).administrator;
});

/// Provider for authentication loading state
final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).isLoading;
});

/// Provider for authentication error
final authErrorProvider = Provider<HadirException?>((ref) {
  return ref.watch(authControllerProvider).error;
});

/// Provider for login form validity
final isLoginFormValidProvider = Provider<bool>((ref) {
  return ref.watch(loginFormControllerProvider).isValid;
});

/// Provider for session expiry warning
final sessionExpiryWarningProvider = Provider<bool>((ref) {
  final sessionController = ref.watch(sessionControllerProvider.notifier);
  return sessionController.isExpiringSoon;
});

/// Provider for remaining session time
final remainingSessionTimeProvider = Provider<Duration>((ref) {
  final sessionController = ref.watch(sessionControllerProvider.notifier);
  return sessionController.remainingTime;
});