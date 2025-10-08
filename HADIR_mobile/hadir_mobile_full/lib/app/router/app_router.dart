// TODO: Add imports once packages are available and code is generated
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Add feature page imports once pages are created
// import '../features/auth/presentation/pages/login_page.dart';
// import '../features/onboarding/presentation/pages/onboarding_page.dart';
// import '../features/dashboard/presentation/pages/dashboard_page.dart';
// import '../features/student_registration/presentation/pages/student_registration_page.dart';
// import '../features/camera/presentation/pages/camera_page.dart';
// import '../features/profile/presentation/pages/profile_page.dart';
// import '../features/settings/presentation/pages/settings_page.dart';

import 'route_names.dart';
// import 'route_guards.dart';

/// Global router configuration for the HADIR Mobile application
/// 
/// This router handles navigation between different screens and implements
/// authentication guards to protect certain routes.
class AppRouter {
  /// Router instance provider
  static final provider = Provider<GoRouter>((ref) {
    final authGuard = ref.watch(authGuardProvider);
    
    return GoRouter(
      initialLocation: RouteNames.splash,
      debugLogDiagnostics: true,
      routes: [
        // Splash/Loading Route
        GoRoute(
          path: RouteNames.splash,
          name: 'splash',
          builder: (context, state) => const SplashPage(),
        ),
        
        // Onboarding Route
        GoRoute(
          path: RouteNames.onboarding,
          name: 'onboarding',
          builder: (context, state) => const OnboardingPage(),
        ),
        
        // Authentication Route
        GoRoute(
          path: RouteNames.login,
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        
        // Dashboard Route (Protected)
        GoRoute(
          path: RouteNames.dashboard,
          name: 'dashboard',
          builder: (context, state) => const DashboardPage(),
          redirect: (context, state) => authGuard.redirectIfNotAuthenticated(state),
        ),
        
        // Student Registration Route (Protected)
        GoRoute(
          path: RouteNames.studentRegistration,
          name: 'student-registration',
          builder: (context, state) => const StudentRegistrationPage(),
          redirect: (context, state) => authGuard.redirectIfNotAuthenticated(state),
        ),
        
        // Camera Route (Protected)
        GoRoute(
          path: RouteNames.camera,
          name: 'camera',
          builder: (context, state) {
            final studentId = state.uri.queryParameters['studentId'];
            return CameraPage(studentId: studentId);
          },
          redirect: (context, state) => authGuard.redirectIfNotAuthenticated(state),
        ),
        
        // Profile Route (Protected)
        GoRoute(
          path: RouteNames.profile,
          name: 'profile',
          builder: (context, state) => const ProfilePage(),
          redirect: (context, state) => authGuard.redirectIfNotAuthenticated(state),
        ),
        
        // Settings Route (Protected)
        GoRoute(
          path: RouteNames.settings,
          name: 'settings',
          builder: (context, state) => const SettingsPage(),
          redirect: (context, state) => authGuard.redirectIfNotAuthenticated(state),
        ),
        
        // Student Detail Routes
        GoRoute(
          path: '${RouteNames.studentDetail}/:id',
          name: 'student-detail',
          builder: (context, state) {
            final studentId = state.pathParameters['id']!;
            return StudentDetailPage(studentId: studentId);
          },
          redirect: (context, state) => authGuard.redirectIfNotAuthenticated(state),
        ),
        
        // Results/Reports Route
        GoRoute(
          path: RouteNames.results,
          name: 'results',
          builder: (context, state) => const ResultsPage(),
          redirect: (context, state) => authGuard.redirectIfNotAuthenticated(state),
        ),
      ],
      
      // Error handling
      errorBuilder: (context, state) => ErrorPage(
        error: state.error?.toString() ?? 'Unknown error',
      ),
      
      // Custom redirect logic
      redirect: (context, state) {
        final isAuthenticated = authGuard.isAuthenticated;
        final isOnboardingComplete = authGuard.isOnboardingComplete;
        
        // Handle initial app state
        if (state.matchedLocation == RouteNames.splash) {
          if (!isOnboardingComplete) {
            return RouteNames.onboarding;
          } else if (!isAuthenticated) {
            return RouteNames.login;
          } else {
            return RouteNames.dashboard;
          }
        }
        
        // Allow access to onboarding and login without authentication
        if (state.matchedLocation == RouteNames.onboarding ||
            state.matchedLocation == RouteNames.login) {
          return null;
        }
        
        // Redirect to login if not authenticated and trying to access protected routes
        if (!isAuthenticated) {
          return RouteNames.login;
        }
        
        return null; // No redirect needed
      },
    );
  });
}

/// Splash/Loading Page
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.face,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            
            // App Title
            Text(
              'HADIR Mobile',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              'AI-Enhanced Student Registration',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 48),
            
            // Loading indicator
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

/// Error Page for handling navigation errors
class ErrorPage extends StatelessWidget {
  final String error;
  
  const ErrorPage({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              
              Text(
                'Oops! Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: () => context.go(RouteNames.dashboard),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder pages - these will be replaced with actual implementations
class StudentDetailPage extends StatelessWidget {
  final String studentId;
  
  const StudentDetailPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Student Details - $studentId')),
      body: Center(
        child: Text('Student ID: $studentId'),
      ),
    );
  }
}

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results & Reports')),
      body: const Center(
        child: Text('Results and Reports'),
      ),
    );
  }
}