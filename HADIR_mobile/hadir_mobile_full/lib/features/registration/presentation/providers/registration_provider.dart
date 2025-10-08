import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hadir_mobile_full/shared/domain/entities/registration_session.dart';
import 'package:hadir_mobile_full/shared/domain/entities/selected_frame.dart';
import 'package:hadir_mobile_full/shared/domain/entities/student.dart';
import 'package:hadir_mobile_full/features/registration/domain/use_cases/registration_use_cases.dart';

/// Registration state
class RegistrationState {
  const RegistrationState({
    this.currentSession,
    this.capturedFrames = const [],
    this.student,
    this.isLoading = false,
    this.error,
    this.currentStep = 0,
  });

  final RegistrationSession? currentSession;
  final List<SelectedFrame> capturedFrames;
  final Student? student;
  final bool isLoading;
  final String? error;
  final int currentStep;

  bool get hasActiveSession => currentSession != null;
  bool get isCompleted => student != null;
  double get progress => capturedFrames.length / 5; // 5 poses required

  RegistrationState copyWith({
    RegistrationSession? currentSession,
    List<SelectedFrame>? capturedFrames,
    Student? student,
    bool? isLoading,
    String? error,
    int? currentStep,
  }) {
    return RegistrationState(
      currentSession: currentSession ?? this.currentSession,
      capturedFrames: capturedFrames ?? this.capturedFrames,
      student: student ?? this.student,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

/// Registration provider
class RegistrationNotifier extends StateNotifier<RegistrationState> {
  RegistrationNotifier(this._registrationUseCases) : super(const RegistrationState());

  final RegistrationUseCases _registrationUseCases;

  /// Start new registration session
  Future<void> startRegistrationSession(Map<String, dynamic> studentData) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _registrationUseCases.startRegistrationSession(
        StartRegistrationSessionParams(studentData: studentData),
      );

      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          error: failure.message,
        ),
        (session) => state = state.copyWith(
          currentSession: session,
          isLoading: false,
          error: null,
          currentStep: 1, // Move to pose capture step
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start registration: ${e.toString()}',
      );
    }
  }

  /// Capture frame for current pose
  Future<void> captureFrame(List<int> imageData, PoseType expectedPose) async {
    if (state.currentSession == null) {
      state = state.copyWith(error: 'No active registration session');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _registrationUseCases.captureFrame(
        CaptureFrameParams(
          sessionId: state.currentSession!.id,
          imageData: imageData,
          expectedPoseType: expectedPose,
        ),
      );

      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          error: failure.message,
        ),
        (frame) {
          final updatedFrames = [...state.capturedFrames, frame];
          state = state.copyWith(
            capturedFrames: updatedFrames,
            isLoading: false,
            error: null,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to capture frame: ${e.toString()}',
      );
    }
  }

  /// Complete registration session
  Future<void> completeRegistration() async {
    if (state.currentSession == null) {
      state = state.copyWith(error: 'No active registration session');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _registrationUseCases.completeRegistrationSession(
        CompleteRegistrationSessionParams(sessionId: state.currentSession!.id),
      );

      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          error: failure.message,
        ),
        (student) => state = state.copyWith(
          student: student,
          isLoading: false,
          error: null,
          currentStep: 2, // Move to completion step
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to complete registration: ${e.toString()}',
      );
    }
  }

  /// Reset registration state
  void reset() {
    state = const RegistrationState();
  }

  /// Update current step
  void updateStep(int step) {
    state = state.copyWith(currentStep: step);
  }
}

/// Registration provider
final registrationProvider = StateNotifierProvider<RegistrationNotifier, RegistrationState>((ref) {
  // This would be injected with actual dependencies
  throw UnimplementedError('RegistrationNotifier requires RegistrationUseCases dependency');
});