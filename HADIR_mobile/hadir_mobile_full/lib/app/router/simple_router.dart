import 'route_names.dart';

/// Router configuration for the HADIR Mobile application
/// 
/// This is a simplified version that will be expanded when Flutter 
/// packages are available and feature pages are implemented.
class AppRouter {
  
  /// Basic route configuration structure
  /// This will be replaced with actual GoRouter implementation
  static final Map<String, String> routeConfig = {
    // Authentication & Onboarding
    RouteNames.splash: 'SplashPage',
    RouteNames.onboarding: 'OnboardingPage', 
    RouteNames.login: 'LoginPage',
    
    // Main App Routes
    RouteNames.dashboard: 'DashboardPage',
    RouteNames.studentRegistration: 'StudentRegistrationPage', 
    RouteNames.camera: 'CameraPage',
    RouteNames.profile: 'ProfilePage',
    RouteNames.settings: 'SettingsPage',
    
    // Detail Routes
    RouteNames.studentDetail: 'StudentDetailPage',
    RouteNames.results: 'ResultsPage',
  };
  
  /// Get route name for a path
  static String? getRouteName(String path) {
    return routeConfig[path];
  }
  
  /// Get all available routes
  static List<String> get availableRoutes => routeConfig.keys.toList();
  
  /// Check if route exists
  static bool hasRoute(String path) {
    return routeConfig.containsKey(path);
  }
  
  /// Navigation helper methods
  /// These will be replaced with actual GoRouter navigation
  
  static void navigateToLogin() {
    print('Navigate to: ${RouteNames.login}');
  }
  
  static void navigateToDashboard() {
    print('Navigate to: ${RouteNames.dashboard}');
  }
  
  static void navigateToStudentRegistration() {
    print('Navigate to: ${RouteNames.studentRegistration}');
  }
  
  static void navigateToCamera({String? studentId}) {
    print('Navigate to: ${RouteNames.camera}${studentId != null ? '?studentId=$studentId' : ''}');
  }
  
  static void navigateToProfile() {
    print('Navigate to: ${RouteNames.profile}');
  }
  
  static void navigateToSettings() {
    print('Navigate to: ${RouteNames.settings}');
  }
  
  static void navigateToStudentDetail(String studentId) {
    print('Navigate to: ${RouteNames.studentDetailWithId(studentId)}');
  }
  
  static void navigateToResults() {
    print('Navigate to: ${RouteNames.results}');
  }
  
  /// Navigation guards
  /// These will be integrated with actual auth system
  
  static bool canNavigateToRoute(String route) {
    // For now, allow all navigation
    // This will be connected to AuthGuard later
    return true;
  }
  
  static String? getAuthRedirect(String route) {
    // This will implement actual auth checking
    if (RouteNames.isProtectedRoute(route)) {
      // In real implementation, check auth state
      // For now, return null (no redirect)
      return null;
    }
    return null;
  }
}

/// Router state management
/// This will be replaced with proper state management once Riverpod is available
class RouterState {
  static String currentRoute = RouteNames.splash;
  static Map<String, dynamic> routeParameters = {};
  
  static void updateCurrentRoute(String route, {Map<String, dynamic>? parameters}) {
    currentRoute = route;
    routeParameters = parameters ?? {};
    print('Router: Current route updated to $route');
    if (routeParameters.isNotEmpty) {
      print('Router: Route parameters: $routeParameters');
    }
  }
  
  static bool isCurrentRoute(String route) {
    return currentRoute == route;
  }
}

/// Route transition configuration
/// This will be used when implementing actual page transitions
class RouteTransitions {
  static const Duration defaultDuration = Duration(milliseconds: 300);
  
  // Transition types
  static const String slideFromRight = 'slide_from_right';
  static const String slideFromLeft = 'slide_from_left';
  static const String slideFromBottom = 'slide_from_bottom';
  static const String fade = 'fade';
  static const String scale = 'scale';
  
  // Route-specific transitions
  static final Map<String, String> routeTransitions = {
    RouteNames.login: slideFromRight,
    RouteNames.dashboard: fade,
    RouteNames.studentRegistration: slideFromRight,
    RouteNames.camera: slideFromBottom,
    RouteNames.profile: slideFromRight,
    RouteNames.settings: slideFromRight,
    RouteNames.studentDetail: slideFromRight,
    RouteNames.results: slideFromRight,
  };
  
  static String getTransitionForRoute(String route) {
    return routeTransitions[route] ?? slideFromRight;
  }
}