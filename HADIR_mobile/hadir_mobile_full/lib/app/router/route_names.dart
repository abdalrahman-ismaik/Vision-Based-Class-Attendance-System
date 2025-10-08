/// Route name constants for the HADIR Mobile application
/// 
/// This file contains all the route paths used throughout the application
/// to ensure consistency and avoid typos in navigation.
class RouteNames {
  // Authentication & Onboarding
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  
  // Main App Routes
  static const String dashboard = '/dashboard';
  static const String studentRegistration = '/student-registration';
  static const String camera = '/camera';
  static const String profile = '/profile';
  static const String settings = '/settings';
  
  // Detail Routes
  static const String studentDetail = '/student';
  static const String results = '/results';
  
  // Camera Sub-routes
  static const String cameraPreview = '/camera/preview';
  static const String cameraCapture = '/camera/capture';
  static const String cameraReview = '/camera/review';
  
  // Settings Sub-routes
  static const String settingsGeneral = '/settings/general';
  static const String settingsCamera = '/settings/camera';
  static const String settingsAbout = '/settings/about';
  
  /// Helper method to build student detail route with ID
  static String studentDetailWithId(String id) => '$studentDetail/$id';
  
  /// Helper method to build camera route with student ID parameter
  static String cameraWithStudentId(String studentId) => '$camera?studentId=$studentId';
  
  /// All protected routes that require authentication
  static const List<String> protectedRoutes = [
    dashboard,
    studentRegistration,
    camera,
    profile,
    settings,
    studentDetail,
    results,
    cameraPreview,
    cameraCapture,
    cameraReview,
    settingsGeneral,
    settingsCamera,
    settingsAbout,
  ];
  
  /// All public routes that don't require authentication
  static const List<String> publicRoutes = [
    splash,
    onboarding,
    login,
  ];
  
  /// Check if a route is protected
  static bool isProtectedRoute(String route) {
    return protectedRoutes.any((protectedRoute) => 
        route.startsWith(protectedRoute));
  }
  
  /// Check if a route is public
  static bool isPublicRoute(String route) {
    return publicRoutes.contains(route);
  }
}