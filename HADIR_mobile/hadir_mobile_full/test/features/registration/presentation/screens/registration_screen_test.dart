import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hadir_mobile_full/features/registration/presentation/screens/registration_screen.dart';
import 'package:hadir_mobile_full/features/registration/presentation/providers/registration_provider.dart';
import 'package:hadir_mobile_full/features/registration/presentation/providers/registration_state.dart';
import 'package:hadir_mobile_full/features/registration/presentation/widgets/student_info_form.dart';
import 'package:hadir_mobile_full/features/registration/presentation/widgets/guided_pose_capture.dart';
import 'package:hadir_mobile_full/features/registration/presentation/widgets/progress_indicator_widget.dart';
import 'package:hadir_mobile_full/shared/domain/entities/student.dart';
import 'package:hadir_mobile_full/shared/domain/entities/registration_session.dart';
import 'package:hadir_mobile_full/shared/domain/entities/pose_target.dart';
import 'package:hadir_mobile_full/features/registration/data/models/registration_requests.dart';
import 'package:hadir_mobile_full/shared/exceptions/registration_exceptions.dart';
import 'package:hadir_mobile_full/shared/presentation/widgets/custom_button.dart';
import 'package:hadir_mobile_full/shared/presentation/widgets/custom_text_field.dart';

import 'registration_screen_test.mocks.dart';

// Generate mocks
@GenerateMocks([RegistrationProvider])
void main() {
  group('RegistrationScreen Widget Tests', () {
    late MockRegistrationProvider mockRegistrationProvider;
    
    setUp(() {
      mockRegistrationProvider = MockRegistrationProvider();
    });

    Widget createRegistrationScreen() {
      return ProviderScope(
        overrides: [
          registrationProvider.overrideWith((ref) => mockRegistrationProvider),
        ],
        child: const MaterialApp(
          home: RegistrationScreen(),
        ),
      );
    }

    group('Screen Layout and Navigation', () {
      testWidgets('should display registration screen with proper layout', (WidgetTester tester) async {
        // Arrange
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.initial());
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Assert
        expect(find.text('Student Registration'), findsOneWidget);
        expect(find.text('HADIR - Face Recognition System'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
        
        // Should show step indicator
        expect(find.byType(ProgressIndicatorWidget), findsOneWidget);
        expect(find.text('Step 1 of 2'), findsOneWidget);
      });

      testWidgets('should show student information form initially', (WidgetTester tester) async {
        // Arrange
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.initial());
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Assert
        expect(find.byType(StudentInfoForm), findsOneWidget);
        expect(find.text('Student Information'), findsOneWidget);
        expect(find.text('Please fill in the student details below'), findsOneWidget);
        
        // Should not show pose capture yet
        expect(find.byType(GuidedPoseCapture), findsNothing);
      });

      testWidgets('should navigate to pose capture after form completion', (WidgetTester tester) async {
        // Arrange
        final sessionInProgress = RegistrationSession(
          id: 'session-123',
          studentId: 'STU20240001',
          administratorId: 'admin-456',
          status: SessionStatus.inProgress,
          startedAt: DateTime.now(),
          poseTargets: const [
            PoseTarget.frontalFace,
            PoseTarget.leftProfile,
            PoseTarget.rightProfile,
            PoseTarget.upwardAngle,
            PoseTarget.downwardAngle,
          ],
          capturedFrames: const [],
          qualityMetrics: QualityMetrics.initial(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        when(mockRegistrationProvider.state).thenReturn(RegistrationState.sessionStarted(sessionInProgress));
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Assert
        expect(find.byType(GuidedPoseCapture), findsOneWidget);
        expect(find.text('Face Capture'), findsOneWidget);
        expect(find.text('Step 2 of 2'), findsOneWidget);
        
        // Should not show form anymore
        expect(find.byType(StudentInfoForm), findsNothing);
      });

      testWidgets('should show back button on pose capture step', (WidgetTester tester) async {
        // Arrange
        final sessionInProgress = RegistrationSession(
          id: 'session-789',
          studentId: 'STU20240002',
          administratorId: 'admin-789',
          status: SessionStatus.inProgress,
          startedAt: DateTime.now(),
          poseTargets: const [
            PoseTarget.frontalFace,
            PoseTarget.leftProfile,
            PoseTarget.rightProfile,
            PoseTarget.upwardAngle,
            PoseTarget.downwardAngle,
          ],
          capturedFrames: const ['frame-1'],
          qualityMetrics: QualityMetrics(
            averageConfidence: 0.92,
            averageSharpness: 0.85,
            averageBrightness: 0.72,
            averageContrast: 0.78,
            averageFaceVisibility: 0.94,
            overallSessionQuality: 0.84,
            completionRate: 0.2,
            processingTime: 2500,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        when(mockRegistrationProvider.state).thenReturn(RegistrationState.sessionStarted(sessionInProgress));
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Assert
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
        expect(find.byKey(const Key('back_to_form_button')), findsOneWidget);
      });

      testWidgets('should handle back navigation from pose capture to form', (WidgetTester tester) async {
        // Arrange
        final sessionInProgress = RegistrationSession(
          id: 'session-back-nav',
          studentId: 'STU20240003',
          administratorId: 'admin-back',
          status: SessionStatus.inProgress,
          startedAt: DateTime.now(),
          poseTargets: const [
            PoseTarget.frontalFace,
            PoseTarget.leftProfile,
            PoseTarget.rightProfile,
            PoseTarget.upwardAngle,
            PoseTarget.downwardAngle,
          ],
          capturedFrames: const ['frame-1', 'frame-2'],
          qualityMetrics: QualityMetrics(
            averageConfidence: 0.89,
            averageSharpness: 0.82,
            averageBrightness: 0.75,
            averageContrast: 0.80,
            averageFaceVisibility: 0.91,
            overallSessionQuality: 0.83,
            completionRate: 0.4,
            processingTime: 4800,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        when(mockRegistrationProvider.state).thenReturn(RegistrationState.sessionStarted(sessionInProgress));
        when(mockRegistrationProvider.cancelCurrentSession()).thenAnswer((_) async {
          return null;
        });
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        final backButton = find.byKey(const Key('back_to_form_button'));
        await tester.tap(backButton);
        await tester.pump();
        
        // Should show confirmation dialog
        expect(find.text('Cancel Registration?'), findsOneWidget);
        expect(find.text('Going back will cancel the current registration session. Are you sure?'), findsOneWidget);
        expect(find.text('Keep Registering'), findsOneWidget);
        expect(find.text('Cancel Session'), findsOneWidget);
        
        // Confirm cancellation
        await tester.tap(find.text('Cancel Session'));
        await tester.pump();
        
        // Assert
        verify(mockRegistrationProvider.cancelCurrentSession()).called(1);
      });
    });

    group('Student Information Form', () {
      testWidgets('should display all required student information fields', (WidgetTester tester) async {
        // Arrange
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.initial());
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Assert - Check all form fields are present
        expect(find.text('Student ID'), findsOneWidget);
        expect(find.text('First Name'), findsOneWidget);
        expect(find.text('Last Name'), findsOneWidget);
        expect(find.text('Email Address'), findsOneWidget);
        expect(find.text('Phone Number'), findsOneWidget);
        expect(find.text('Date of Birth'), findsOneWidget);
        expect(find.text('Gender'), findsOneWidget);
        expect(find.text('Nationality'), findsOneWidget);
        expect(find.text('Major'), findsOneWidget);
        expect(find.text('Enrollment Year'), findsOneWidget);
        expect(find.text('Academic Level'), findsOneWidget);
        
        // Check input fields
        expect(find.byType(CustomTextField), findsNWidgets(8)); // Text input fields
        expect(find.byType(DropdownButtonFormField), findsNWidgets(3)); // Gender, Nationality, Academic Level dropdowns
      });

      testWidgets('should validate required fields', (WidgetTester tester) async {
        // Arrange
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.initial());
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Try to proceed without filling required fields
        final continueButton = find.byKey(const Key('continue_to_capture_button'));
        await tester.tap(continueButton);
        await tester.pump();
        
        // Assert - Should show validation errors
        expect(find.text('Student ID is required'), findsOneWidget);
        expect(find.text('First name is required'), findsOneWidget);
        expect(find.text('Last name is required'), findsOneWidget);
        expect(find.text('Email is required'), findsOneWidget);
        expect(find.text('Phone number is required'), findsOneWidget);
        expect(find.text('Date of birth is required'), findsOneWidget);
      });

      testWidgets('should validate student ID format', (WidgetTester tester) async {
        // Arrange
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.initial());
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        final studentIdField = find.byKey(const Key('student_id_field'));
        await tester.enterText(studentIdField, 'INVALID123'); // Invalid format
        
        final continueButton = find.byKey(const Key('continue_to_capture_button'));
        await tester.tap(continueButton);
        await tester.pump();
        
        // Assert
        expect(find.text('Student ID must follow format: STU########'), findsOneWidget);
      });

      testWidgets('should validate email format', (WidgetTester tester) async {
        // Arrange
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.initial());
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        final emailField = find.byKey(const Key('email_field'));
        await tester.enterText(emailField, 'invalid-email'); // Invalid format
        
        final continueButton = find.byKey(const Key('continue_to_capture_button'));
        await tester.tap(continueButton);
        await tester.pump();
        
        // Assert
        expect(find.text('Please enter a valid email address'), findsOneWidget);
      });

      testWidgets('should validate phone number format', (WidgetTester tester) async {
        // Arrange
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.initial());
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        final phoneField = find.byKey(const Key('phone_field'));
        await tester.enterText(phoneField, '123'); // Invalid format
        
        final continueButton = find.byKey(const Key('continue_to_capture_button'));
        await tester.tap(continueButton);
        await tester.pump();
        
        // Assert
        expect(find.text('Please enter a valid phone number'), findsOneWidget);
      });

      testWidgets('should validate enrollment year range', (WidgetTester tester) async {
        // Arrange
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.initial());
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        final enrollmentYearField = find.byKey(const Key('enrollment_year_field'));
        await tester.enterText(enrollmentYearField, '1999'); // Too early
        
        final continueButton = find.byKey(const Key('continue_to_capture_button'));
        await tester.tap(continueButton);
        await tester.pump();
        
        // Assert
        expect(find.text('Enrollment year must be between 2000 and ${DateTime.now().year + 1}'), findsOneWidget);
      });

      testWidgets('should start registration session with valid data', (WidgetTester tester) async {
        // Arrange
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.initial());
        when(mockRegistrationProvider.startRegistrationSession(any)).thenAnswer((_) async {
          return null;
        });
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Fill in valid data
        await tester.enterText(find.byKey(const Key('student_id_field')), 'STU20240001');
        await tester.enterText(find.byKey(const Key('first_name_field')), 'Ahmed');
        await tester.enterText(find.byKey(const Key('last_name_field')), 'Hassan');
        await tester.enterText(find.byKey(const Key('email_field')), 'ahmed.hassan@student.university.edu');
        await tester.enterText(find.byKey(const Key('phone_field')), '+962781234567');
        await tester.enterText(find.byKey(const Key('date_of_birth_field')), '1999-03-15');
        await tester.enterText(find.byKey(const Key('nationality_field')), 'Jordanian');
        await tester.enterText(find.byKey(const Key('major_field')), 'Computer Science');
        await tester.enterText(find.byKey(const Key('enrollment_year_field')), '2024');
        
        // Select gender and academic level
        await tester.tap(find.byKey(const Key('gender_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Male'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.byKey(const Key('academic_level_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Undergraduate'));
        await tester.pumpAndSettle();
        
        final continueButton = find.byKey(const Key('continue_to_capture_button'));
        await tester.tap(continueButton);
        await tester.pump();
        
        // Assert
        verify(mockRegistrationProvider.startRegistrationSession(const StartRegistrationRequest(
          studentId: 'STU20240001',
          firstName: 'Ahmed',
          lastName: 'Hassan',
          email: 'ahmed.hassan@student.university.edu',
          phoneNumber: '+962781234567',
          dateOfBirth: '1999-03-15',
          gender: 'Male',
          nationality: 'Jordanian',
          major: 'Computer Science',
          enrollmentYear: 2024,
          academicLevel: 'Undergraduate',
          administratorId: any,
        ))).called(1);
      });
    });

    group('Pose Capture Integration', () {
      testWidgets('should display guided pose capture component', (WidgetTester tester) async {
        // Arrange
        final sessionInProgress = RegistrationSession(
          id: 'session-pose-capture',
          studentId: 'STU20240004',
          administratorId: 'admin-pose',
          status: SessionStatus.inProgress,
          startedAt: DateTime.now(),
          poseTargets: const [
            PoseTarget.frontalFace,
            PoseTarget.leftProfile,
            PoseTarget.rightProfile,
            PoseTarget.upwardAngle,
            PoseTarget.downwardAngle,
          ],
          capturedFrames: const [],
          qualityMetrics: QualityMetrics.initial(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        when(mockRegistrationProvider.state).thenReturn(RegistrationState.sessionStarted(sessionInProgress));
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Assert
        expect(find.byType(GuidedPoseCapture), findsOneWidget);
        expect(find.text('Face Capture'), findsOneWidget);
        expect(find.text('Please follow the on-screen instructions to capture your face from different angles'), findsOneWidget);
        
        // Should show pose progress
        expect(find.text('0 of 5 poses captured'), findsOneWidget);
      });

      testWidgets('should update pose capture progress', (WidgetTester tester) async {
        // Arrange
        final sessionWithProgress = RegistrationSession(
          id: 'session-progress',
          studentId: 'STU20240005',
          administratorId: 'admin-progress',
          status: SessionStatus.inProgress,
          startedAt: DateTime.now(),
          poseTargets: const [
            PoseTarget.frontalFace,
            PoseTarget.leftProfile,
            PoseTarget.rightProfile,
            PoseTarget.upwardAngle,
            PoseTarget.downwardAngle,
          ],
          capturedFrames: const ['frame-1', 'frame-2', 'frame-3'],
          qualityMetrics: QualityMetrics(
            averageConfidence: 0.91,
            averageSharpness: 0.84,
            averageBrightness: 0.76,
            averageContrast: 0.81,
            averageFaceVisibility: 0.93,
            overallSessionQuality: 0.85,
            completionRate: 0.6,
            processingTime: 7200,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        when(mockRegistrationProvider.state).thenReturn(RegistrationState.sessionStarted(sessionWithProgress));
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Assert
        expect(find.text('3 of 5 poses captured'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        
        // Progress should be 60%
        final progressIndicator = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
        expect(progressIndicator.value, closeTo(0.6, 0.01));
      });

      testWidgets('should show completion message when all poses captured', (WidgetTester tester) async {
        // Arrange
        final completedSession = RegistrationSession(
          id: 'session-completed',
          studentId: 'STU20240006',
          administratorId: 'admin-completed',
          status: SessionStatus.completed,
          startedAt: DateTime.now().subtract(const Duration(minutes: 10)),
          completedAt: DateTime.now(),
          poseTargets: const [
            PoseTarget.frontalFace,
            PoseTarget.leftProfile,
            PoseTarget.rightProfile,
            PoseTarget.upwardAngle,
            PoseTarget.downwardAngle,
          ],
          capturedFrames: List.generate(5, (i) => 'frame-$i'),
          qualityMetrics: QualityMetrics(
            averageConfidence: 0.94,
            averageSharpness: 0.87,
            averageBrightness: 0.78,
            averageContrast: 0.83,
            averageFaceVisibility: 0.95,
            overallSessionQuality: 0.87,
            completionRate: 1.0,
            processingTime: 9500,
          ),
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          updatedAt: DateTime.now(),
        );
        
        when(mockRegistrationProvider.state).thenReturn(RegistrationState.sessionCompleted(completedSession));
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Assert
        expect(find.text('Registration Complete!'), findsOneWidget);
        expect(find.text('All 5 poses captured successfully'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.text('New Registration'), findsOneWidget);
        expect(find.text('Back to Dashboard'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should display validation errors from registration request', (WidgetTester tester) async {
        // Arrange
        const validationError = ValidationException('Student ID already exists in the system');
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.error(validationError));
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Assert
        expect(find.text('Registration Error'), findsOneWidget);
        expect(find.text('Student ID already exists in the system'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
        expect(find.text('Try Again'), findsOneWidget);
      });

      testWidgets('should display duplicate session error', (WidgetTester tester) async {
        // Arrange
        const duplicateError = DuplicateSessionException('Active registration session already exists for this student');
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.error(duplicateError));
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Assert
        expect(find.text('Active Session Found'), findsOneWidget);
        expect(find.text('Active registration session already exists for this student'), findsOneWidget);
        expect(find.text('Resume Session'), findsOneWidget);
        expect(find.text('Cancel Previous Session'), findsOneWidget);
      });

      testWidgets('should display YOLOv7-Pose initialization error', (WidgetTester tester) async {
        // Arrange
        const poseDetectorError = PoseDetectorException('Failed to initialize YOLOv7-Pose model');
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.error(poseDetectorError));
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Assert
        expect(find.text('Camera System Error'), findsOneWidget);
        expect(find.text('Failed to initialize YOLOv7-Pose model'), findsOneWidget);
        expect(find.text('The face recognition system could not be initialized'), findsOneWidget);
        expect(find.text('Restart App'), findsOneWidget);
        expect(find.text('Contact Support'), findsOneWidget);
      });

      testWidgets('should display network connectivity error', (WidgetTester tester) async {
        // Arrange
        const networkError = NetworkException('No internet connection available');
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.error(networkError));
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Assert
        expect(find.text('Connection Error'), findsOneWidget);
        expect(find.text('No internet connection available'), findsOneWidget);
        expect(find.text('Please check your network connection and try again'), findsOneWidget);
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('should handle session timeout gracefully', (WidgetTester tester) async {
        // Arrange
        const timeoutError = SessionTimeoutException('Registration session has expired');
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.error(timeoutError));
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Assert
        expect(find.text('Session Expired'), findsOneWidget);
        expect(find.text('Registration session has expired'), findsOneWidget);
        expect(find.text('Please start a new registration session'), findsOneWidget);
        expect(find.text('Start New Session'), findsOneWidget);
      });

      testWidgets('should provide retry functionality for recoverable errors', (WidgetTester tester) async {
        // Arrange
        const networkError = NetworkException('Connection timeout');
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.error(networkError));
        when(mockRegistrationProvider.clearError()).thenReturn(null);
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        final retryButton = find.text('Retry');
        await tester.tap(retryButton);
        await tester.pump();
        
        // Assert
        verify(mockRegistrationProvider.clearError()).called(1);
      });
    });

    group('Loading States', () {
      testWidgets('should show loading indicator during session initialization', (WidgetTester tester) async {
        // Arrange
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.startingSession());
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Initializing Registration Session...'), findsOneWidget);
        expect(find.text('Setting up face recognition system'), findsOneWidget);
      });

      testWidgets('should show loading indicator during pose capture processing', (WidgetTester tester) async {
        // Arrange
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.processingCapture());
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Processing Face Capture...'), findsOneWidget);
        expect(find.text('Analyzing pose with YOLOv7-Pose model'), findsOneWidget);
      });

      testWidgets('should show loading indicator during session completion', (WidgetTester tester) async {
        // Arrange
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.completingSession());
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Finalizing Registration...'), findsOneWidget);
        expect(find.text('Generating face embeddings and saving student data'), findsOneWidget);
      });

      testWidgets('should disable form interactions during loading', (WidgetTester tester) async {
        // Arrange
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.startingSession());
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Assert
        final continueButton = find.byKey(const Key('continue_to_capture_button'));
        final buttonWidget = tester.widget<CustomButton>(continueButton);
        expect(buttonWidget.isEnabled, isFalse);
      });
    });

    group('Progress Tracking', () {
      testWidgets('should display correct step indicators', (WidgetTester tester) async {
        // Arrange - Initial state (Step 1)
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.initial());
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Assert
        expect(find.text('Step 1 of 2'), findsOneWidget);
        expect(find.text('Student Information'), findsOneWidget);
        
        // Change to capture state (Step 2)
        final sessionInProgress = RegistrationSession(
          id: 'session-step-2',
          studentId: 'STU20240007',
          administratorId: 'admin-step',
          status: SessionStatus.inProgress,
          startedAt: DateTime.now(),
          poseTargets: const [
            PoseTarget.frontalFace,
            PoseTarget.leftProfile,
            PoseTarget.rightProfile,
            PoseTarget.upwardAngle,
            PoseTarget.downwardAngle,
          ],
          capturedFrames: const [],
          qualityMetrics: QualityMetrics.initial(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        when(mockRegistrationProvider.state).thenReturn(RegistrationState.sessionStarted(sessionInProgress));
        await tester.pump();
        
        expect(find.text('Step 2 of 2'), findsOneWidget);
        expect(find.text('Face Capture'), findsOneWidget);
      });

      testWidgets('should show overall registration progress', (WidgetTester tester) async {
        // Arrange
        final sessionWithProgress = RegistrationSession(
          id: 'session-overall-progress',
          studentId: 'STU20240008',
          administratorId: 'admin-overall',
          status: SessionStatus.inProgress,
          startedAt: DateTime.now(),
          poseTargets: const [
            PoseTarget.frontalFace,
            PoseTarget.leftProfile,
            PoseTarget.rightProfile,
            PoseTarget.upwardAngle,
            PoseTarget.downwardAngle,
          ],
          capturedFrames: const ['frame-1', 'frame-2'],
          qualityMetrics: QualityMetrics(
            averageConfidence: 0.90,
            averageSharpness: 0.83,
            averageBrightness: 0.74,
            averageContrast: 0.79,
            averageFaceVisibility: 0.92,
            overallSessionQuality: 0.84,
            completionRate: 0.4,
            processingTime: 5600,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        when(mockRegistrationProvider.state).thenReturn(RegistrationState.sessionStarted(sessionWithProgress));
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Assert
        expect(find.byType(ProgressIndicatorWidget), findsOneWidget);
        expect(find.text('40% Complete'), findsOneWidget);
        
        // Should show quality metrics
        expect(find.text('Session Quality: 84%'), findsOneWidget);
        expect(find.text('Average Confidence: 90%'), findsOneWidget);
      });

      testWidgets('should update progress in real-time', (WidgetTester tester) async {
        // Arrange - Start with 2 captures
        final initialSession = RegistrationSession(
          id: 'session-realtime',
          studentId: 'STU20240009',
          administratorId: 'admin-realtime',
          status: SessionStatus.inProgress,
          startedAt: DateTime.now(),
          poseTargets: const [
            PoseTarget.frontalFace,
            PoseTarget.leftProfile,
            PoseTarget.rightProfile,
            PoseTarget.upwardAngle,
            PoseTarget.downwardAngle,
          ],
          capturedFrames: const ['frame-1', 'frame-2'],
          qualityMetrics: QualityMetrics(
            averageConfidence: 0.89,
            averageSharpness: 0.81,
            averageBrightness: 0.73,
            averageContrast: 0.77,
            averageFaceVisibility: 0.91,
            overallSessionQuality: 0.82,
            completionRate: 0.4,
            processingTime: 4200,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        when(mockRegistrationProvider.state).thenReturn(RegistrationState.sessionStarted(initialSession));
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Assert initial state
        expect(find.text('2 of 5 poses captured'), findsOneWidget);
        
        // Update to 4 captures
        final updatedSession = initialSession.copyWith(
          capturedFrames: const ['frame-1', 'frame-2', 'frame-3', 'frame-4'],
          qualityMetrics: QualityMetrics(
            averageConfidence: 0.92,
            averageSharpness: 0.85,
            averageBrightness: 0.76,
            averageContrast: 0.80,
            averageFaceVisibility: 0.94,
            overallSessionQuality: 0.85,
            completionRate: 0.8,
            processingTime: 8400,
          ),
          updatedAt: DateTime.now(),
        );
        
        when(mockRegistrationProvider.state).thenReturn(RegistrationState.sessionStarted(updatedSession));
        await tester.pump();
        
        // Assert updated state
        expect(find.text('4 of 5 poses captured'), findsOneWidget);
      });
    });

    group('Accessibility and Usability', () {
      testWidgets('should have proper accessibility labels', (WidgetTester tester) async {
        // Arrange
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.initial());
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Assert
        expect(find.bySemanticsLabel('Student ID input field'), findsOneWidget);
        expect(find.bySemanticsLabel('First name input field'), findsOneWidget);
        expect(find.bySemanticsLabel('Last name input field'), findsOneWidget);
        expect(find.bySemanticsLabel('Email address input field'), findsOneWidget);
        expect(find.bySemanticsLabel('Continue to face capture'), findsOneWidget);
      });

      testWidgets('should support keyboard navigation', (WidgetTester tester) async {
        // Arrange
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.initial());
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        final studentIdField = find.byKey(const Key('student_id_field'));
        final firstNameField = find.byKey(const Key('first_name_field'));
        
        // Focus first field and tab to next
        await tester.tap(studentIdField);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        
        // Assert
        final firstNameFocusNode = tester.widget<CustomTextField>(firstNameField).focusNode;
        expect(firstNameFocusNode?.hasFocus, isTrue);
      });

      testWidgets('should work with large font sizes', (WidgetTester tester) async {
        // Arrange
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.initial());
        
        // Act
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: createRegistrationScreen(),
          ),
        );
        
        // Assert
        expect(find.text('Student Registration'), findsOneWidget);
        expect(find.text('Student Information'), findsOneWidget);
        expect(find.byType(CustomTextField), findsWidgets);
        
        // Layout should still be functional
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('should provide clear visual feedback for form validation', (WidgetTester tester) async {
        // Arrange
        when(mockRegistrationProvider.state).thenReturn(const RegistrationState.initial());
        
        // Act
        await tester.pumpWidget(createRegistrationScreen());
        
        // Submit empty form
        final continueButton = find.byKey(const Key('continue_to_capture_button'));
        await tester.tap(continueButton);
        await tester.pump();
        
        // Assert - Error styling should be applied
        final errorText = tester.widget<Text>(find.text('Student ID is required'));
        expect(errorText.style?.color, equals(Colors.red));
        
        // Input fields should show error state
        final studentIdField = tester.widget<CustomTextField>(find.byKey(const Key('student_id_field')));
        expect(studentIdField.hasError, isTrue);
      });
    });
  });
}