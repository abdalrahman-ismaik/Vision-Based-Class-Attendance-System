import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hadir_mobile_full/shared/domain/entities/student.dart';
import 'package:hadir_mobile_full/shared/domain/entities/registration_session.dart';
import 'package:hadir_mobile_full/features/registration/domain/use_cases/create_registration_session.dart';
import 'package:hadir_mobile_full/features/registration/domain/use_cases/process_video_frames.dart';
import 'package:hadir_mobile_full/features/registration/domain/use_cases/select_optimal_frames.dart';
import 'package:hadir_mobile_full/shared/domain/exceptions/hadir_exceptions.dart';

/// Registration workflow states
enum RegistrationStep {
  studentInfo,
  cameraPreparation,
  poseCapture,
  frameSelection,
  confirmation,
  completed,
}

/// Student information form state
class StudentInfoState {
  const StudentInfoState({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.isValid,
    this.studentIdError,
    this.firstNameError,
    this.lastNameError,
    this.emailError,
    this.phoneNumberError,
  });

  final String studentId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final bool isValid;
  final String? studentIdError;
  final String? firstNameError;
  final String? lastNameError;
  final String? emailError;
  final String? phoneNumberError;

  StudentInfoState copyWith({
    String? studentId,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    bool? isValid,
    String? studentIdError,
    String? firstNameError,
    String? lastNameError,
    String? emailError,
    String? phoneNumberError,
  }) {
    return StudentInfoState(
      studentId: studentId ?? this.studentId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isValid: isValid ?? this.isValid,
      studentIdError: studentIdError ?? this.studentIdError,
      firstNameError: firstNameError ?? this.firstNameError,
      lastNameError: lastNameError ?? this.lastNameError,
      emailError: emailError ?? this.emailError,
      phoneNumberError: phoneNumberError ?? this.phoneNumberError,
    );
  }

  factory StudentInfoState.initial() {
    return const StudentInfoState(
      studentId: '',
      firstName: '',
      lastName: '',
      email: '',
      phoneNumber: '',
      isValid: false,
    );
  }

  /// Get form data for creating a student
  Map<String, String> getFormData() {
    return {
      'studentId': studentId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
    };
  }
}

/// Registration session state
class RegistrationSessionState {
  const RegistrationSessionState({
    required this.isActive,
    required this.currentStep,
    required this.isLoading,
    this.session,
    this.student,
    this.error,
    this.progress,
  });

  final bool isActive;
  final RegistrationStep currentStep;
  final bool isLoading;
  final RegistrationSession? session;
  final Student? student;
  final HadirException? error;
  final double? progress; // 0.0 to 1.0

  RegistrationSessionState copyWith({
    bool? isActive,
    RegistrationStep? currentStep,
    bool? isLoading,
    RegistrationSession? session,
    Student? student,
    HadirException? error,
    double? progress,
  }) {
    return RegistrationSessionState(
      isActive: isActive ?? this.isActive,
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      session: session ?? this.session,
      student: student ?? this.student,
      error: error ?? this.error,
      progress: progress ?? this.progress,
    );
  }

  factory RegistrationSessionState.initial() {
    return const RegistrationSessionState(
      isActive: false,
      currentStep: RegistrationStep.studentInfo,
      isLoading: false,
    );
  }

  factory RegistrationSessionState.loading() {
    return const RegistrationSessionState(
      isActive: true,
      currentStep: RegistrationStep.studentInfo,
      isLoading: true,
    );
  }

  factory RegistrationSessionState.active({
    required RegistrationSession session,
    required Student student,
    RegistrationStep step = RegistrationStep.cameraPreparation,
  }) {
    return RegistrationSessionState(
      isActive: true,
      currentStep: step,
      isLoading: false,
      session: session,
      student: student,
      progress: _calculateProgress(step),
    );
  }

  factory RegistrationSessionState.error(HadirException error) {
    return RegistrationSessionState(
      isActive: false,
      currentStep: RegistrationStep.studentInfo,
      isLoading: false,
      error: error,
    );
  }

  factory RegistrationSessionState.completed({
    required RegistrationSession session,
    required Student student,
  }) {
    return RegistrationSessionState(
      isActive: false,
      currentStep: RegistrationStep.completed,
      isLoading: false,
      session: session,
      student: student,
      progress: 1.0,
    );
  }

  static double _calculateProgress(RegistrationStep step) {
    switch (step) {
      case RegistrationStep.studentInfo:
        return 0.1;
      case RegistrationStep.cameraPreparation:
        return 0.2;
      case RegistrationStep.poseCapture:
        return 0.6;
      case RegistrationStep.frameSelection:
        return 0.8;
      case RegistrationStep.confirmation:
        return 0.9;
      case RegistrationStep.completed:
        return 1.0;
    }
  }
}

/// Student information form controller
class StudentInfoController extends StateNotifier<StudentInfoState> {
  StudentInfoController() : super(StudentInfoState.initial());

  /// Update student ID
  void updateStudentId(String studentId) {
    state = state.copyWith(studentId: studentId);
    _validateForm();
  }

  /// Update first name
  void updateFirstName(String firstName) {
    state = state.copyWith(firstName: firstName);
    _validateForm();
  }

  /// Update last name
  void updateLastName(String lastName) {
    state = state.copyWith(lastName: lastName);
    _validateForm();
  }

  /// Update email
  void updateEmail(String email) {
    state = state.copyWith(email: email);
    _validateForm();
  }

  /// Update phone number
  void updatePhoneNumber(String phoneNumber) {
    state = state.copyWith(phoneNumber: phoneNumber);
    _validateForm();
  }

  /// Validate the entire form
  void _validateForm() {
    String? studentIdError;
    String? firstNameError;
    String? lastNameError;
    String? emailError;
    String? phoneNumberError;

    // Student ID validation
    if (state.studentId.trim().isEmpty) {
      studentIdError = 'Student ID is required';
    } else if (!RegExp(r'^[0-9]{8,12}$').hasMatch(state.studentId)) {
      studentIdError = 'Student ID must be 8-12 digits';
    }

    // First name validation
    if (state.firstName.trim().isEmpty) {
      firstNameError = 'First name is required';
    } else if (state.firstName.trim().length < 2) {
      firstNameError = 'First name must be at least 2 characters';
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(state.firstName)) {
      firstNameError = 'First name can only contain letters and spaces';
    }

    // Last name validation
    if (state.lastName.trim().isEmpty) {
      lastNameError = 'Last name is required';
    } else if (state.lastName.trim().length < 2) {
      lastNameError = 'Last name must be at least 2 characters';
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(state.lastName)) {
      lastNameError = 'Last name can only contain letters and spaces';
    }

    // Email validation
    if (state.email.trim().isEmpty) {
      emailError = 'Email is required';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(state.email)) {
      emailError = 'Please enter a valid email address';
    }

    // Phone number validation
    if (state.phoneNumber.trim().isEmpty) {
      phoneNumberError = 'Phone number is required';
    } else if (!RegExp(r'^[\+]?[0-9\-\(\)\s]{10,15}$').hasMatch(state.phoneNumber)) {
      phoneNumberError = 'Please enter a valid phone number';
    }

    final isValid = studentIdError == null &&
        firstNameError == null &&
        lastNameError == null &&
        emailError == null &&
        phoneNumberError == null;

    state = state.copyWith(
      isValid: isValid,
      studentIdError: studentIdError,
      firstNameError: firstNameError,
      lastNameError: lastNameError,
      emailError: emailError,
      phoneNumberError: phoneNumberError,
    );
  }

  /// Clear form and reset to initial state
  void clearForm() {
    state = StudentInfoState.initial();
  }

  /// Load student data (for editing existing registration)
  void loadStudentData(Student student) {
    state = StudentInfoState(
      studentId: student.studentId,
      firstName: student.firstName ?? '',
      lastName: student.lastName ?? '',
      email: student.email,
      phoneNumber: student.phoneNumber ?? '',
      isValid: true, // Assume loaded data is valid
    );
  }
}

/// Registration session controller
class RegistrationSessionController extends StateNotifier<RegistrationSessionState> {
  RegistrationSessionController({
    required this.createRegistrationSessionUseCase,
    required this.processVideoFramesUseCase,
    required this.selectOptimalFramesUseCase,
  }) : super(RegistrationSessionState.initial());

  final CreateRegistrationSessionUseCase createRegistrationSessionUseCase;
  final ProcessVideoFramesUseCase processVideoFramesUseCase;
  final SelectOptimalFramesUseCase selectOptimalFramesUseCase;

  /// Start a new registration session
  Future<void> startSession(String studentId, String administratorId, String videoFilePath) async {
    try {
      state = RegistrationSessionState.loading();

      final result = await createRegistrationSessionUseCase.call(
        CreateRegistrationSessionParams(
          studentId: studentId,
          administratorId: administratorId,
          videoFilePath: videoFilePath,
        ),
      );

      result.fold(
        (error) => state = RegistrationSessionState.error(error),
        (session) {
          // For now, we'll set state without student and load it separately
          state = state.copyWith(
            isActive: true,
            currentStep: RegistrationStep.cameraPreparation,
            isLoading: false,
            session: session,
            progress: RegistrationSessionState._calculateProgress(RegistrationStep.cameraPreparation),
          );
        },
      );
    } catch (e) {
      final exception = e is HadirException ? e : GenericHadirException(e.toString());
      state = RegistrationSessionState.error(exception);
    }
  }

  /// Move to the next step in the registration workflow
  void nextStep() {
    if (!state.isActive || state.session == null) return;

    final currentStep = state.currentStep;
    RegistrationStep? nextStep;

    switch (currentStep) {
      case RegistrationStep.studentInfo:
        nextStep = RegistrationStep.cameraPreparation;
        break;
      case RegistrationStep.cameraPreparation:
        nextStep = RegistrationStep.poseCapture;
        break;
      case RegistrationStep.poseCapture:
        nextStep = RegistrationStep.frameSelection;
        break;
      case RegistrationStep.frameSelection:
        nextStep = RegistrationStep.confirmation;
        break;
      case RegistrationStep.confirmation:
        nextStep = RegistrationStep.completed;
        break;
      case RegistrationStep.completed:
        // Already completed
        return;
    }

    state = state.copyWith(
      currentStep: nextStep,
      progress: RegistrationSessionState._calculateProgress(nextStep),
    );
  }

  /// Move to the previous step in the registration workflow
  void previousStep() {
    if (!state.isActive) return;

    final currentStep = state.currentStep;
    RegistrationStep? previousStep;

    switch (currentStep) {
      case RegistrationStep.cameraPreparation:
        previousStep = RegistrationStep.studentInfo;
        break;
      case RegistrationStep.poseCapture:
        previousStep = RegistrationStep.cameraPreparation;
        break;
      case RegistrationStep.frameSelection:
        previousStep = RegistrationStep.poseCapture;
        break;
      case RegistrationStep.confirmation:
        previousStep = RegistrationStep.frameSelection;
        break;
      case RegistrationStep.studentInfo:
      case RegistrationStep.completed:
        // Can't go back from these states
        return;
    }

    state = state.copyWith(
      currentStep: previousStep,
      progress: RegistrationSessionState._calculateProgress(previousStep),
    );
  }

  /// Jump to a specific step (if allowed)
  void goToStep(RegistrationStep step) {
    if (!state.isActive) return;

    // Only allow going to steps that have been reached or are next
    final currentStepIndex = RegistrationStep.values.indexOf(state.currentStep);
    final targetStepIndex = RegistrationStep.values.indexOf(step);

    if (targetStepIndex <= currentStepIndex + 1) {
      state = state.copyWith(
        currentStep: step,
        progress: RegistrationSessionState._calculateProgress(step),
      );
    }
  }

  /// Complete the registration session
  Future<void> completeSession() async {
    if (!state.isActive || state.session == null || state.student == null) return;

    try {
      state = state.copyWith(isLoading: true);

      // In a real implementation, this would finalize the registration
      await Future.delayed(const Duration(seconds: 2)); // Simulate processing

      state = RegistrationSessionState.completed(
        session: state.session!,
        student: state.student!,
      );
    } catch (e) {
      final exception = e is HadirException ? e : GenericHadirException(e.toString());
      state = state.copyWith(
        error: exception,
        isLoading: false,
      );
    }
  }

  /// Cancel the registration session
  void cancelSession() {
    state = RegistrationSessionState.initial();
  }

  /// Reset any errors
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  /// Update session progress manually
  void updateProgress(double progress) {
    state = state.copyWith(progress: progress.clamp(0.0, 1.0));
  }
}

/// Registration workflow helper state
class RegistrationWorkflowState {
  const RegistrationWorkflowState({
    required this.canGoNext,
    required this.canGoPrevious,
    required this.currentStepLabel,
    required this.nextStepLabel,
    required this.isFirstStep,
    required this.isLastStep,
  });

  final bool canGoNext;
  final bool canGoPrevious;
  final String currentStepLabel;
  final String? nextStepLabel;
  final bool isFirstStep;
  final bool isLastStep;

  static String getStepLabel(RegistrationStep step) {
    switch (step) {
      case RegistrationStep.studentInfo:
        return 'Student Information';
      case RegistrationStep.cameraPreparation:
        return 'Camera Setup';
      case RegistrationStep.poseCapture:
        return 'Pose Capture';
      case RegistrationStep.frameSelection:
        return 'Frame Selection';
      case RegistrationStep.confirmation:
        return 'Confirmation';
      case RegistrationStep.completed:
        return 'Completed';
    }
  }
}

// =============================================================================
// PROVIDERS
// =============================================================================

/// Provider for CreateRegistrationSessionUseCase
final createRegistrationSessionUseCaseProvider = Provider<CreateRegistrationSessionUseCase>((ref) {
  // This would be injected from a service locator in a real implementation
  throw UnimplementedError('CreateRegistrationSessionUseCase provider not implemented yet');
});

/// Provider for ProcessVideoFramesUseCase
final processVideoFramesUseCaseProvider = Provider<ProcessVideoFramesUseCase>((ref) {
  // This would be injected from a service locator in a real implementation
  throw UnimplementedError('ProcessVideoFramesUseCase provider not implemented yet');
});

/// Provider for SelectOptimalFramesUseCase
final selectOptimalFramesUseCaseProvider = Provider<SelectOptimalFramesUseCase>((ref) {
  // This would be injected from a service locator in a real implementation
  throw UnimplementedError('SelectOptimalFramesUseCase provider not implemented yet');
});

/// Provider for student information form controller
final studentInfoControllerProvider = StateNotifierProvider<StudentInfoController, StudentInfoState>((ref) {
  return StudentInfoController();
});

/// Provider for registration session controller
final registrationSessionControllerProvider = StateNotifierProvider<RegistrationSessionController, RegistrationSessionState>((ref) {
  return RegistrationSessionController(
    createRegistrationSessionUseCase: ref.watch(createRegistrationSessionUseCaseProvider),
    processVideoFramesUseCase: ref.watch(processVideoFramesUseCaseProvider),
    selectOptimalFramesUseCase: ref.watch(selectOptimalFramesUseCaseProvider),
  );
});

/// Provider for student information form validity
final isStudentInfoValidProvider = Provider<bool>((ref) {
  return ref.watch(studentInfoControllerProvider).isValid;
});

/// Provider for current registration step
final currentRegistrationStepProvider = Provider<RegistrationStep>((ref) {
  return ref.watch(registrationSessionControllerProvider).currentStep;
});

/// Provider for registration session active state
final isRegistrationActiveProvider = Provider<bool>((ref) {
  return ref.watch(registrationSessionControllerProvider).isActive;
});

/// Provider for registration loading state
final isRegistrationLoadingProvider = Provider<bool>((ref) {
  return ref.watch(registrationSessionControllerProvider).isLoading;
});

/// Provider for registration error
final registrationErrorProvider = Provider<HadirException?>((ref) {
  return ref.watch(registrationSessionControllerProvider).error;
});

/// Provider for registration progress
final registrationProgressProvider = Provider<double>((ref) {
  return ref.watch(registrationSessionControllerProvider).progress ?? 0.0;
});

/// Provider for current student
final currentStudentProvider = Provider<Student?>((ref) {
  return ref.watch(registrationSessionControllerProvider).student;
});

/// Provider for current registration session
final currentRegistrationSessionProvider = Provider<RegistrationSession?>((ref) {
  return ref.watch(registrationSessionControllerProvider).session;
});

/// Provider for registration workflow state
final registrationWorkflowProvider = Provider<RegistrationWorkflowState>((ref) {
  final sessionState = ref.watch(registrationSessionControllerProvider);
  final step = sessionState.currentStep;
  final steps = RegistrationStep.values;
  final currentIndex = steps.indexOf(step);
  
  return RegistrationWorkflowState(
    canGoNext: currentIndex < steps.length - 1 && sessionState.isActive,
    canGoPrevious: currentIndex > 0 && sessionState.isActive,
    currentStepLabel: RegistrationWorkflowState.getStepLabel(step),
    nextStepLabel: currentIndex < steps.length - 1 
        ? RegistrationWorkflowState.getStepLabel(steps[currentIndex + 1])
        : null,
    isFirstStep: currentIndex == 0,
    isLastStep: currentIndex == steps.length - 1,
  );
});

/// Provider for step completion status
final stepCompletionProvider = Provider.family<bool, RegistrationStep>((ref, step) {
  final currentStep = ref.watch(currentRegistrationStepProvider);
  final steps = RegistrationStep.values;
  final currentIndex = steps.indexOf(currentStep);
  final stepIndex = steps.indexOf(step);
  
  return stepIndex < currentIndex;
});