import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/student_list_item.dart';
import '../../data/models/student_filter.dart';
import '../../data/models/student_sort_option.dart';
import '../../domain/repositories/student_management_repository.dart';
import '../../data/repositories/local_student_management_repository.dart';
import '../../../../shared/data/data_sources/local_database_data_source.dart';

/// Provider for student management repository
final studentManagementRepositoryProvider = Provider<StudentManagementRepository>((ref) {
  return LocalStudentManagementRepository(LocalDatabaseDataSource());
});

/// State class for student list
class StudentListState {
  final List<StudentListItem> students;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final String searchQuery;
  final StudentFilter filter;
  final StudentSortOption sortOption;
  final int currentPage;

  const StudentListState({
    this.students = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.searchQuery = '',
    this.filter = const StudentFilter(),
    this.sortOption = StudentSortOption.nameAsc,
    this.currentPage = 0,
  });

  StudentListState copyWith({
    List<StudentListItem>? students,
    bool? isLoading,
    bool? hasMore,
    String? error,
    String? searchQuery,
    StudentFilter? filter,
    StudentSortOption? sortOption,
    int? currentPage,
  }) {
    return StudentListState(
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      sortOption: sortOption ?? this.sortOption,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Provider for student list with pagination, search, and filtering
class StudentListNotifier extends StateNotifier<StudentListState> {
  final StudentManagementRepository _repository;
  static const int _pageSize = 20;

  StudentListNotifier(this._repository) : super(const StudentListState());

  /// Load initial student list
  Future<void> loadStudents() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final List<dynamic> students = await _repository.getAllStudents(
        limit: _pageSize,
        offset: 0,
        sortBy: state.sortOption,
      );

      state = state.copyWith(
        students: students.cast<StudentListItem>(),
        isLoading: false,
        hasMore: students.length >= _pageSize,
        currentPage: 0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load students: ${e.toString()}',
      );
    }
  }

  /// Load more students (pagination)
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.currentPage + 1;
      final List<dynamic> newStudents;

      if (state.searchQuery.isNotEmpty) {
        newStudents = await _repository.searchStudents(
          query: state.searchQuery,
          limit: _pageSize,
        );
      } else if (state.filter.hasActiveFilters) {
        newStudents = await _repository.filterStudents(
          filter: state.filter,
          limit: _pageSize,
          offset: nextPage * _pageSize,
          sortBy: state.sortOption,
        );
      } else {
        newStudents = await _repository.getAllStudents(
          limit: _pageSize,
          offset: nextPage * _pageSize,
          sortBy: state.sortOption,
        );
      }

      state = state.copyWith(
        students: [...state.students, ...newStudents.cast<StudentListItem>()],
        isLoading: false,
        hasMore: newStudents.length >= _pageSize,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load more students: ${e.toString()}',
      );
    }
  }

  /// Search students
  Future<void> search(String query) async {
    if (state.searchQuery == query && state.students.isNotEmpty) return;

    state = state.copyWith(
      searchQuery: query,
      isLoading: true,
      error: null,
      students: [],
      currentPage: 0,
    );

    try {
      if (query.isEmpty) {
        await loadStudents();
        return;
      }

      final List<dynamic> students = await _repository.searchStudents(
        query: query,
        limit: _pageSize,
      );

      state = state.copyWith(
        students: students.cast<StudentListItem>(),
        isLoading: false,
        hasMore: students.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Search failed: ${e.toString()}',
      );
    }
  }

  /// Apply filter
  Future<void> applyFilter(StudentFilter filter) async {
    state = state.copyWith(
      filter: filter,
      isLoading: true,
      error: null,
      students: [],
      currentPage: 0,
    );

    try {
      if (!filter.hasActiveFilters) {
        await loadStudents();
        return;
      }

      final List<dynamic> students = await _repository.filterStudents(
        filter: filter,
        limit: _pageSize,
        offset: 0,
        sortBy: state.sortOption,
      );

      state = state.copyWith(
        students: students.cast<StudentListItem>(),
        isLoading: false,
        hasMore: students.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Filter failed: ${e.toString()}',
      );
    }
  }

  /// Change sort option
  Future<void> changeSortOption(StudentSortOption sortOption) async {
    if (state.sortOption == sortOption) return;

    state = state.copyWith(
      sortOption: sortOption,
      isLoading: true,
      error: null,
      students: [],
      currentPage: 0,
    );

    try {
      final List<dynamic> students;

      if (state.filter.hasActiveFilters) {
        students = await _repository.filterStudents(
          filter: state.filter,
          limit: _pageSize,
          offset: 0,
          sortBy: sortOption,
        );
      } else {
        students = await _repository.getAllStudents(
          limit: _pageSize,
          offset: 0,
          sortBy: sortOption,
        );
      }

      state = state.copyWith(
        students: students.cast<StudentListItem>(),
        isLoading: false,
        hasMore: students.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sort failed: ${e.toString()}',
      );
    }
  }

  /// Refresh student list
  Future<void> refresh() async {
    state = state.copyWith(
      students: [],
      currentPage: 0,
      hasMore: true,
      error: null,
    );
    await loadStudents();
  }

  /// Clear search
  void clearSearch() {
    if (state.searchQuery.isEmpty) return;
    state = state.copyWith(searchQuery: '', students: [], currentPage: 0);
    loadStudents();
  }

  /// Clear filters
  void clearFilters() {
    if (!state.filter.hasActiveFilters) return;
    state = state.copyWith(filter: const StudentFilter(), students: [], currentPage: 0);
    loadStudents();
  }
}

/// Provider for student list state
final studentListProvider = StateNotifierProvider<StudentListNotifier, StudentListState>((ref) {
  final repository = ref.watch(studentManagementRepositoryProvider);
  return StudentListNotifier(repository);
});

/// Provider for student statistics
final studentStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(studentManagementRepositoryProvider);
  
  final totalCount = await repository.getTotalStudentCount();
  final countByStatus = await repository.getStudentCountByStatus();
  
  return {
    'total': totalCount,
    'byStatus': countByStatus,
  };
});
