import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hadir_mobile_full/features/auth/presentation/screens/login_screen.dart';
import 'package:hadir_mobile_full/features/auth/presentation/providers/auth_provider.dart';
import 'package:hadir_mobile_full/features/auth/presentation/providers/auth_state.dart';
import 'package:hadir_mobile_full/shared/domain/entities/administrator.dart';
import 'package:hadir_mobile_full/features/auth/data/models/auth_requests.dart';
import 'package:hadir_mobile_full/shared/exceptions/auth_exceptions.dart';
import 'package:hadir_mobile_full/shared/presentation/widgets/custom_button.dart';
import 'package:hadir_mobile_full/shared/presentation/widgets/custom_text_field.dart';
import 'package:hadir_mobile_full/shared/presentation/widgets/loading_overlay.dart';

import 'login_screen_test.mocks.dart';

// Generate mocks
@GenerateMocks([AuthProvider])
void main() {
  group('LoginScreen Widget Tests', () {
    late MockAuthProvider mockAuthProvider;
    
    setUp(() {
      mockAuthProvider = MockAuthProvider();
    });

    Widget createLoginScreen() {
      return ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => mockAuthProvider),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      );
    }

    group('UI Elements and Layout', () {
      testWidgets('should display all essential UI elements', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        // Assert
        expect(find.text('HADIR'), findsOneWidget); // App title
        expect(find.text('Administrator Login'), findsOneWidget); // Screen title
        expect(find.text('Welcome back! Please sign in to continue.'), findsOneWidget); // Subtitle
        
        // Form fields
        expect(find.byType(CustomTextField), findsNWidgets(2)); // Username and password fields
        expect(find.text('Username'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        
        // Buttons
        expect(find.byType(CustomButton), findsOneWidget); // Login button
        expect(find.text('Sign In'), findsOneWidget);
        
        // Additional elements
        expect(find.byIcon(Icons.visibility_off), findsOneWidget); // Password visibility toggle
        expect(find.byType(Image), findsOneWidget); // University logo
      });

      testWidgets('should display university branding correctly', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        // Assert
        expect(find.byType(Image), findsOneWidget); // University logo
        expect(find.text('HADIR'), findsOneWidget); // App name
        expect(find.text('Higher Education Attendance & Identity Recognition'), findsOneWidget); // App description
        expect(find.text('University Administration System'), findsOneWidget); // System description
      });

      testWidgets('should have proper responsive layout', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        await tester.pump();
        
        // Assert
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold, isNotNull);
        
        // Check for proper scrollable content
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        
        // Check for proper padding and spacing
        expect(find.byType(Padding), findsWidgets);
        expect(find.byType(SizedBox), findsWidgets); // Spacing elements
      });

      testWidgets('should display form validation hints', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        // Assert
        // Check username field hints
        final usernameField = tester.widget<CustomTextField>(
          find.byKey(const Key('username_field'))
        );
        expect(usernameField.hintText, equals('Enter your administrator username'));
        expect(usernameField.prefixIcon, equals(Icons.person));
        
        // Check password field hints
        final passwordField = tester.widget<CustomTextField>(
          find.byKey(const Key('password_field'))
        );
        expect(passwordField.hintText, equals('Enter your password'));
        expect(passwordField.prefixIcon, equals(Icons.lock));
        expect(passwordField.obscureText, isTrue);
      });
    });

    group('Form Input and Validation', () {
      testWidgets('should accept username input', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        final usernameField = find.byKey(const Key('username_field'));
        await tester.enterText(usernameField, 'admin001');
        await tester.pump();
        
        // Assert
        expect(find.text('admin001'), findsOneWidget);
      });

      testWidgets('should accept password input and hide text', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        final passwordField = find.byKey(const Key('password_field'));
        await tester.enterText(passwordField, 'SecurePass123!');
        await tester.pump();
        
        // Assert
        final textField = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(const Key('password_field')),
            matching: find.byType(TextField),
          ),
        );
        expect(textField.obscureText, isTrue);
      });

      testWidgets('should toggle password visibility', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        // Initially password should be hidden
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
        
        // Tap visibility toggle
        await tester.tap(find.byIcon(Icons.visibility_off));
        await tester.pump();
        
        // Assert
        expect(find.byIcon(Icons.visibility), findsOneWidget);
        
        // Tap again to hide
        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pump();
        
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      });

      testWidgets('should validate empty username field', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        // Leave username empty and try to submit
        final passwordField = find.byKey(const Key('password_field'));
        await tester.enterText(passwordField, 'ValidPass123!');
        
        final loginButton = find.byKey(const Key('login_button'));
        await tester.tap(loginButton);
        await tester.pump();
        
        // Assert
        expect(find.text('Username is required'), findsOneWidget);
      });

      testWidgets('should validate empty password field', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        // Leave password empty and try to submit
        final usernameField = find.byKey(const Key('username_field'));
        await tester.enterText(usernameField, 'admin001');
        
        final loginButton = find.byKey(const Key('login_button'));
        await tester.tap(loginButton);
        await tester.pump();
        
        // Assert
        expect(find.text('Password is required'), findsOneWidget);
      });

      testWidgets('should validate minimum password requirements', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        final usernameField = find.byKey(const Key('username_field'));
        final passwordField = find.byKey(const Key('password_field'));
        
        await tester.enterText(usernameField, 'admin001');
        await tester.enterText(passwordField, '123'); // Too weak
        
        final loginButton = find.byKey(const Key('login_button'));
        await tester.tap(loginButton);
        await tester.pump();
        
        // Assert
        expect(find.text('Password must be at least 8 characters long'), findsOneWidget);
      });

      testWidgets('should validate username format', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        final usernameField = find.byKey(const Key('username_field'));
        final passwordField = find.byKey(const Key('password_field'));
        
        await tester.enterText(usernameField, 'invalid@username'); // Invalid characters
        await tester.enterText(passwordField, 'ValidPass123!');
        
        final loginButton = find.byKey(const Key('login_button'));
        await tester.tap(loginButton);
        await tester.pump();
        
        // Assert
        expect(find.text('Username can only contain letters, numbers, and underscores'), findsOneWidget);
      });

      testWidgets('should clear validation errors when input is corrected', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        final usernameField = find.byKey(const Key('username_field'));
        final loginButton = find.byKey(const Key('login_button'));
        
        // Trigger validation error
        await tester.tap(loginButton);
        await tester.pump();
        expect(find.text('Username is required'), findsOneWidget);
        
        // Correct the input
        await tester.enterText(usernameField, 'admin001');
        await tester.pump();
        
        // Assert
        expect(find.text('Username is required'), findsNothing);
      });
    });

    group('Authentication Flow', () {
      testWidgets('should call login with correct credentials', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        when(mockAuthProvider.login(any)).thenAnswer((_) async {});
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        final usernameField = find.byKey(const Key('username_field'));
        final passwordField = find.byKey(const Key('password_field'));
        final loginButton = find.byKey(const Key('login_button'));
        
        await tester.enterText(usernameField, 'admin001');
        await tester.enterText(passwordField, 'SecurePass123!');
        await tester.tap(loginButton);
        await tester.pump();
        
        // Assert
        verify(mockAuthProvider.login(const LoginRequest(
          username: 'admin001',
          password: 'SecurePass123!',
        ))).called(1);
      });

      testWidgets('should show loading state during authentication', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.loading());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        // Assert
        expect(find.byType(LoadingOverlay), findsOneWidget);
        expect(find.text('Authenticating...'), findsOneWidget);
        
        // Login button should be disabled during loading
        final loginButton = tester.widget<CustomButton>(find.byKey(const Key('login_button')));
        expect(loginButton.isEnabled, isFalse);
      });

      testWidgets('should display authentication success message', (WidgetTester tester) async {
        // Arrange
        final loggedInAdmin = Administrator(
          id: 'admin-123',
          username: 'admin001',
          firstName: 'John',
          lastName: 'Admin',
          email: 'john.admin@university.edu',
          role: AdminRole.operator,
          permissions: const [Permission.registerStudents],
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          lastLoginAt: DateTime.now(),
        );
        
        when(mockAuthProvider.state).thenReturn(AuthState.authenticated(loggedInAdmin));
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        // Assert
        expect(find.text('Welcome back, John Admin!'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('should display invalid credentials error', (WidgetTester tester) async {
        // Arrange
        const error = InvalidCredentialsException('Invalid username or password');
        when(mockAuthProvider.state).thenReturn(const AuthState.error(error));
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        // Assert
        expect(find.text('Invalid username or password'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
        
        // Error styling
        final errorText = tester.widget<Text>(find.text('Invalid username or password'));
        expect(errorText.style?.color, equals(Colors.red));
      });

      testWidgets('should display account inactive error', (WidgetTester tester) async {
        // Arrange
        const error = AccountInactiveException('Your administrator account has been deactivated');
        when(mockAuthProvider.state).thenReturn(const AuthState.error(error));
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        // Assert
        expect(find.text('Your administrator account has been deactivated'), findsOneWidget);
        expect(find.text('Please contact system administrator for assistance'), findsOneWidget);
        expect(find.byIcon(Icons.block), findsOneWidget);
      });

      testWidgets('should display account locked error', (WidgetTester tester) async {
        // Arrange
        const error = AccountLockedException('Account locked due to multiple failed login attempts');
        when(mockAuthProvider.state).thenReturn(const AuthState.error(error));
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        // Assert
        expect(find.text('Account locked due to multiple failed login attempts'), findsOneWidget);
        expect(find.text('Please try again after 30 minutes'), findsOneWidget);
        expect(find.byIcon(Icons.lock), findsOneWidget);
      });

      testWidgets('should display network error message', (WidgetTester tester) async {
        // Arrange
        const error = NetworkException('No internet connection available');
        when(mockAuthProvider.state).thenReturn(const AuthState.error(error));
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        // Assert
        expect(find.text('No internet connection available'), findsOneWidget);
        expect(find.text('Please check your network connection and try again'), findsOneWidget);
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
        
        // Retry button should be visible
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('should allow retry after network error', (WidgetTester tester) async {
        // Arrange
        const error = NetworkException('Connection timeout');
        when(mockAuthProvider.state).thenReturn(const AuthState.error(error));
        when(mockAuthProvider.clearError()).thenReturn(null);
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        final retryButton = find.text('Retry');
        await tester.tap(retryButton);
        await tester.pump();
        
        // Assert
        verify(mockAuthProvider.clearError()).called(1);
      });

      testWidgets('should handle rate limiting error', (WidgetTester tester) async {
        // Arrange
        const error = RateLimitException('Too many login attempts. Please try again in 5 minutes.');
        when(mockAuthProvider.state).thenReturn(const AuthState.error(error));
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        // Assert
        expect(find.text('Too many login attempts. Please try again in 5 minutes.'), findsOneWidget);
        expect(find.byIcon(Icons.timer), findsOneWidget);
        
        // Login button should be disabled
        final loginButton = tester.widget<CustomButton>(find.byKey(const Key('login_button')));
        expect(loginButton.isEnabled, isFalse);
      });
    });

    group('Keyboard and Navigation', () {
      testWidgets('should navigate between fields using Tab key', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        final usernameField = find.byKey(const Key('username_field'));
        final passwordField = find.byKey(const Key('password_field'));
        
        // Focus username field and press Tab
        await tester.tap(usernameField);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        
        // Assert
        final passwordFocusNode = tester.widget<CustomTextField>(passwordField).focusNode;
        expect(passwordFocusNode?.hasFocus, isTrue);
      });

      testWidgets('should submit form using Enter key', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        when(mockAuthProvider.login(any)).thenAnswer((_) async {});
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        final usernameField = find.byKey(const Key('username_field'));
        final passwordField = find.byKey(const Key('password_field'));
        
        await tester.enterText(usernameField, 'admin002');
        await tester.enterText(passwordField, 'ValidPass456!');
        
        // Press Enter while focused on password field
        await tester.tap(passwordField);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        
        // Assert
        verify(mockAuthProvider.login(const LoginRequest(
          username: 'admin002',
          password: 'ValidPass456!',
        ))).called(1);
      });

      testWidgets('should handle back button navigation', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        // Simulate back button press
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/navigation',
          const StandardMethodCodec().encodeMethodCall(const MethodCall('routePopped')),
          (data) {},
        );
        await tester.pump();
        
        // Assert - Should show exit confirmation dialog
        expect(find.text('Exit Application?'), findsOneWidget);
        expect(find.text('Are you sure you want to exit HADIR?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Exit'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper accessibility labels', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        // Assert
        expect(find.bySemanticsLabel('Username input field'), findsOneWidget);
        expect(find.bySemanticsLabel('Password input field'), findsOneWidget);
        expect(find.bySemanticsLabel('Sign in button'), findsOneWidget);
        expect(find.bySemanticsLabel('Toggle password visibility'), findsOneWidget);
      });

      testWidgets('should support screen reader navigation', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        // Assert
        final semantics = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
        expect(semantics.debugDescribeChildren(), contains('TextField'));
        expect(semantics.debugDescribeChildren(), contains('Button'));
      });

      testWidgets('should have sufficient color contrast', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        // Assert
        final loginButton = tester.widget<CustomButton>(find.byKey(const Key('login_button')));
        expect(loginButton.backgroundColor, isNotNull);
        expect(loginButton.textColor, isNotNull);
        
        // Test high contrast mode
        await tester.binding.platformDispatcher.onAccessibilityFeaturesChanged?.call();
        await tester.pump();
        
        // Should still be accessible
        expect(find.byType(CustomButton), findsOneWidget);
      });

      testWidgets('should support large font sizes', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaleFactor: 2.0), // Large font size
            child: createLoginScreen(),
          ),
        );
        
        // Assert
        expect(find.text('Administrator Login'), findsOneWidget);
        expect(find.text('Username'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
        
        // Layout should still be functional
        final scaffold = find.byType(Scaffold);
        expect(scaffold, findsOneWidget);
      });
    });

    group('Security Features', () {
      testWidgets('should clear password field on navigation away', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        final passwordField = find.byKey(const Key('password_field'));
        await tester.enterText(passwordField, 'SecretPassword123!');
        await tester.pump();
        
        // Simulate navigation away (lifecycle change)
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        
        // Assert
        final textController = tester.widget<CustomTextField>(passwordField).controller;
        expect(textController?.text, isEmpty);
      });

      testWidgets('should disable copy/paste on password field', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        // Assert
        final passwordField = tester.widget<CustomTextField>(find.byKey(const Key('password_field')));
        expect(passwordField.enableInteractiveSelection, isFalse);
      });

      testWidgets('should show password strength indicator', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        final passwordField = find.byKey(const Key('password_field'));
        
        // Test weak password
        await tester.enterText(passwordField, '123');
        await tester.pump();
        expect(find.text('Weak'), findsOneWidget);
        
        // Test medium password
        await tester.enterText(passwordField, 'Password123');
        await tester.pump();
        expect(find.text('Medium'), findsOneWidget);
        
        // Test strong password
        await tester.enterText(passwordField, 'SecurePass123!@#');
        await tester.pump();
        expect(find.text('Strong'), findsOneWidget);
      });

      testWidgets('should implement session timeout warning', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        // Simulate long idle time
        await tester.binding.scheduleFrameCallback((_) {
          // Simulate session timeout warning
        });
        
        // Fast forward time
        await tester.pump(const Duration(minutes: 25)); // Close to 30-minute timeout
        
        // Assert - Should show timeout warning
        expect(find.text('Session Timeout Warning'), findsOneWidget);
        expect(find.text('Your session will expire in 5 minutes'), findsOneWidget);
        expect(find.text('Extend Session'), findsOneWidget);
      });
    });

    group('Performance and Responsiveness', () {
      testWidgets('should handle rapid button taps without duplicate requests', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        when(mockAuthProvider.login(any)).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 500));
        });
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        final usernameField = find.byKey(const Key('username_field'));
        final passwordField = find.byKey(const Key('password_field'));
        final loginButton = find.byKey(const Key('login_button'));
        
        await tester.enterText(usernameField, 'admin003');
        await tester.enterText(passwordField, 'RapidTest123!');
        
        // Rapid taps
        await tester.tap(loginButton);
        await tester.tap(loginButton);
        await tester.tap(loginButton);
        await tester.pump();
        
        // Assert - Should only call login once
        verify(mockAuthProvider.login(any)).called(1);
      });

      testWidgets('should maintain smooth animations during state changes', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Act
        await tester.pumpWidget(createLoginScreen());
        
        // Change to loading state
        when(mockAuthProvider.state).thenReturn(const AuthState.loading());
        await tester.pump();
        
        // Assert - Should have smooth transition
        expect(find.byType(LoadingOverlay), findsOneWidget);
        
        // Change to error state
        const error = NetworkException('Connection failed');
        when(mockAuthProvider.state).thenReturn(const AuthState.error(error));
        await tester.pump();
        
        // Should transition smoothly
        expect(find.text('Connection failed'), findsOneWidget);
      });

      testWidgets('should optimize for different screen sizes', (WidgetTester tester) async {
        // Arrange
        when(mockAuthProvider.state).thenReturn(const AuthState.initial());
        
        // Test tablet layout
        await tester.binding.setSurfaceSize(const Size(1024, 768));
        await tester.pumpWidget(createLoginScreen());
        
        // Should adapt layout for larger screens
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.byType(Container), findsWidgets); // Layout containers
        
        // Test phone layout
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pump();
        
        // Should still be functional on smaller screens
        expect(find.text('Administrator Login'), findsOneWidget);
        expect(find.byType(CustomTextField), findsNWidgets(2));
      });
    });
  });
}