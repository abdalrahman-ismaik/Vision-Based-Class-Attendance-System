import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hadir_mobile_full/features/auth/presentation/screens/login_screen.dart';
import 'package:hadir_mobile_full/features/registration/presentation/screens/registration_screen.dart';
import 'package:hadir_mobile_full/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:hadir_mobile_full/features/student_management/presentation/screens/student_list_screen.dart';
import 'package:hadir_mobile_full/features/student_management/presentation/screens/student_detail_screen.dart';
import 'package:hadir_mobile_full/features/auth/presentation/providers/auth_provider_setup.dart';
import 'package:hadir_mobile_full/main.dart' show kDevelopmentMode;

/// Authentication-aware router for HADIR Mobile application
final authRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      // If not authenticated and not on login page, redirect to login
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      // If authenticated and on login page, redirect to dashboard
      if (isAuthenticated && isLoggingIn) {
        return '/dashboard';
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/login',
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/registration', 
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/students',
        builder: (context, state) => const StudentListScreen(),
      ),
      GoRoute(
        path: '/students/:id',
        builder: (context, state) {
          final studentId = state.pathParameters['id']!;
          return StudentDetailScreen(studentId: studentId);
        },
      ),
      // Add more routes as needed
    ],
  );
});

/// Simple router without authentication (for initial setup)
final simpleRouter = GoRouter(
  // In development mode, start directly at dashboard screen
  initialLocation: kDevelopmentMode ? '/dashboard' : '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/registration',
      builder: (context, state) => const RegistrationScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/students',
      builder: (context, state) => const StudentListScreen(),
    ),
    GoRoute(
      path: '/students/:id',
      builder: (context, state) {
        final studentId = state.pathParameters['id']!;
        return StudentDetailScreen(studentId: studentId);
      },
    ),
    GoRoute(
      path: '/',
      redirect: (context, state) => kDevelopmentMode ? '/dashboard' : '/login',
    ),
  ],
);