import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hadir_mobile_full/features/auth/data/repositories/simple_auth_repository.dart';
import 'package:hadir_mobile_full/features/auth/domain/use_cases/authentication_use_cases.dart';
import 'package:hadir_mobile_full/features/auth/presentation/providers/auth_providers.dart';
import 'package:hadir_mobile_full/shared/domain/entities/administrator.dart';
import 'package:hadir_mobile_full/shared/domain/exceptions/hadir_exceptions.dart';

// =============================================================================
// REPOSITORY PROVIDERS
// =============================================================================

/// Provider for authentication repository
/// Uses SimpleAuthRepository for MVP/demo purposes
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SimpleAuthRepository();
});

// =============================================================================
// USE CASE PROVIDERS
// =============================================================================

/// Provider for LoginUseCase
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

/// Provider for LogoutUseCase
final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

/// Provider for GetCurrentUserUseCase
final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

// =============================================================================
// PRESENTATION PROVIDERS (Override the ones in auth_providers.dart)
// =============================================================================

/// Provider for authentication controller (fully wired)
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

// =============================================================================
// CONVENIENCE PROVIDERS
// =============================================================================

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