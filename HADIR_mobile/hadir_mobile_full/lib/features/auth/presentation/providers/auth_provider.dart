import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hadir_mobile_full/shared/domain/entities/administrator.dart';
import 'package:hadir_mobile_full/features/auth/domain/use_cases/authentication_use_cases.dart';

/// Authentication state
class AuthState {
  const AuthState({
    this.administrator,
    this.isLoading = false,
    this.error,
  });

  final Administrator? administrator;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => administrator != null;

  AuthState copyWith({
    Administrator? administrator,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      administrator: administrator ?? this.administrator,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Authentication provider
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authUseCases) : super(const AuthState());

  final AuthenticationUseCases _authUseCases;

  /// Login user
  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authUseCases.login(
        LoginParams(username: username, password: password),
      );

      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          error: failure.message,
        ),
        (administrator) => state = state.copyWith(
          administrator: administrator,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed: ${e.toString()}',
      );
    }
  }

  /// Logout user
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      final result = await _authUseCases.logout();
      
      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          error: failure.message,
        ),
        (_) => state = const AuthState(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Logout failed: ${e.toString()}',
      );
    }
  }

  /// Get current user
  Future<void> getCurrentUser() async {
    state = state.copyWith(isLoading: true);

    try {
      final result = await _authUseCases.getCurrentUser();
      
      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          error: failure.message,
        ),
        (administrator) => state = state.copyWith(
          administrator: administrator,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get current user: ${e.toString()}',
      );
    }
  }

  /// Validate permissions
  Future<bool> hasPermissions(List<Permission> permissions) async {
    try {
      final result = await _authUseCases.validatePermissions(
        ValidatePermissionsParams(permissions: permissions),
      );
      
      return result.fold(
        (failure) => false,
        (hasPermissions) => hasPermissions,
      );
    } catch (e) {
      return false;
    }
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  // This would be injected with actual dependencies
  throw UnimplementedError('AuthNotifier requires AuthenticationUseCases dependency');
});