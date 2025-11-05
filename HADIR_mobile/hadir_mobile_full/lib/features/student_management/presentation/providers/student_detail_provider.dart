import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/student_detail.dart';
import 'student_list_provider.dart';
import '../../../../shared/domain/entities/selected_frame.dart';

/// Provider for student detail
final studentDetailProvider = FutureProvider.family<StudentDetail?, String>((ref, studentId) async {
  final repository = ref.watch(studentManagementRepositoryProvider);
  return await repository.getStudentDetail(studentId);
});

/// Provider for student frames
final studentFramesProvider = FutureProvider.family<List<SelectedFrame>, String>((ref, studentId) async {
  final repository = ref.watch(studentManagementRepositoryProvider);
  final frames = await repository.getStudentFrames(studentId);
  return frames.cast<SelectedFrame>();
});

/// State class for frame gallery
class FrameGalleryState {
  final int currentIndex;
  final bool isFullscreen;

  const FrameGalleryState({
    this.currentIndex = 0,
    this.isFullscreen = false,
  });

  FrameGalleryState copyWith({
    int? currentIndex,
    bool? isFullscreen,
  }) {
    return FrameGalleryState(
      currentIndex: currentIndex ?? this.currentIndex,
      isFullscreen: isFullscreen ?? this.isFullscreen,
    );
  }
}

/// Provider for frame gallery state
class FrameGalleryNotifier extends StateNotifier<FrameGalleryState> {
  FrameGalleryNotifier() : super(const FrameGalleryState());

  void setCurrentIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }

  void toggleFullscreen() {
    state = state.copyWith(isFullscreen: !state.isFullscreen);
  }

  void exitFullscreen() {
    state = state.copyWith(isFullscreen: false);
  }

  void reset() {
    state = const FrameGalleryState();
  }
}

/// Provider for frame gallery state (scoped per student)
final frameGalleryProvider = StateNotifierProvider.family<FrameGalleryNotifier, FrameGalleryState, String>(
  (ref, studentId) => FrameGalleryNotifier(),
);
