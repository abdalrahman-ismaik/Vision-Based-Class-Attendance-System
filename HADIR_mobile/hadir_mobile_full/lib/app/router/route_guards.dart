import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';

/// Authentication state provider
/// This would normally be connected to your actual auth service
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});

/// Authentication state model
class AuthState {
  final bool isAuthenticated;
  final bool isOnboardingComplete;
  final String? userId;
  final String? userEmail;
  
  const AuthState({
    this.isAuthenticated = false,
    this.isOnboardingComplete = false,
    this.userId,
    this.userEmail,
  });
  
  AuthState copyWith({
    bool? isAuthenticated,
    bool? isOnboardingComplete,
    String? userId,
    String? userEmail,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}

/// Authentication state notifier
class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(const AuthState()) {
    _checkInitialAuthState();
  }
  
  /// Check initial authentication state
  /// In a real app, this would check saved tokens, session data, etc.
  void _checkInitialAuthState() {
    // For now, we'll simulate checking saved auth state
    // In production, this would check SharedPreferences, secure storage, etc.
    
    // Simulate initial state - not authenticated, onboarding not complete
    state = const AuthState(
      isAuthenticated: false,
      isOnboardingComplete: false,
    );
  }
  
  /// Sign in user
  Future<bool> signIn(String email, String password) async {
    try {
      // Simulate authentication API call
      await Future.delayed(const Duration(seconds: 1));
      
      // For demo purposes, accept any email/password
      if (email.isNotEmpty && password.isNotEmpty) {
        state = state.copyWith(
          isAuthenticated: true,
          userId: 'user_123',
          userEmail: email,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Sign out user
  Future<void> signOut() async {
    state = const AuthState(
      isAuthenticated: false,
      isOnboardingComplete: true, // Keep onboarding complete
    );
  }
  
  /// Complete onboarding
  void completeOnboarding() {
    state = state.copyWith(isOnboardingComplete: true);
  }
  
  /// Reset auth state (for testing/development)
  void reset() {
    state = const AuthState();
  }
}

/// Route guard provider
final authGuardProvider = Provider<AuthGuard>((ref) {
  final authState = ref.watch(authStateProvider);
  return AuthGuard(authState);
});

/// Authentication guard for routes
class AuthGuard {
  final AuthState _authState;
  
  AuthGuard(this._authState);
  
  /// Check if user is authenticated
  bool get isAuthenticated => _authState.isAuthenticated;
  
  /// Check if onboarding is complete
  bool get isOnboardingComplete => _authState.isOnboardingComplete;
  
  /// Redirect to login if not authenticated
  String? redirectIfNotAuthenticated(GoRouterState state) {
    if (!_authState.isAuthenticated) {
      return RouteNames.login;
    }
    return null;
  }
  
  /// Redirect to onboarding if not complete
  String? redirectIfOnboardingNotComplete(GoRouterState state) {
    if (!_authState.isOnboardingComplete) {
      return RouteNames.onboarding;
    }
    return null;
  }
  
  /// Check if route requires authentication
  bool requiresAuth(String route) {
    return RouteNames.isProtectedRoute(route);
  }
  
  /// Check if user can access route
  bool canAccessRoute(String route) {
    // Public routes are always accessible
    if (RouteNames.isPublicRoute(route)) {
      return true;
    }
    
    // Protected routes require authentication
    if (RouteNames.isProtectedRoute(route)) {
      return _authState.isAuthenticated;
    }
    
    // Default to requiring authentication for unknown routes
    return _authState.isAuthenticated;
  }
  
  /// Get appropriate redirect for current auth state
  String? getRedirectForAuthState(String currentRoute) {
    // If onboarding not complete, redirect to onboarding
    if (!_authState.isOnboardingComplete && currentRoute != RouteNames.onboarding) {
      return RouteNames.onboarding;
    }
    
    // If not authenticated and trying to access protected route, redirect to login
    if (!_authState.isAuthenticated && RouteNames.isProtectedRoute(currentRoute)) {
      return RouteNames.login;
    }
    
    // If authenticated and trying to access login, redirect to dashboard
    if (_authState.isAuthenticated && currentRoute == RouteNames.login) {
      return RouteNames.dashboard;
    }
    
    return null; // No redirect needed
  }
}