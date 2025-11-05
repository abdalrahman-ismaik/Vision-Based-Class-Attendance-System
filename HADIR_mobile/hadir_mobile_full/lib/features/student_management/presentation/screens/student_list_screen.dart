import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/student_list_provider.dart';
import '../widgets/student_search_bar.dart';
import '../widgets/student_filter_sheet.dart';
import '../widgets/student_sort_menu.dart';
import '../widgets/student_list_card.dart';

/// Main screen for viewing and managing registered students
class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Load students on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentListProvider.notifier).loadStudents();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(studentListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentListProvider);
    final stats = ref.watch(studentStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Students'),
        actions: [
          // Sort menu
          StudentSortMenu(
            currentSort: state.sortOption,
            onSortChanged: (sort) {
              ref.read(studentListProvider.notifier).changeSortOption(sort);
            },
          ),
          // Filter button
          IconButton(
            icon: Badge(
              isLabelVisible: state.filter.hasActiveFilters,
              label: Text('${state.filter.activeFilterCount}'),
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          StudentSearchBar(
            initialQuery: state.searchQuery,
            onSearch: (query) {
              ref.read(studentListProvider.notifier).search(query);
            },
            onClear: () {
              ref.read(studentListProvider.notifier).clearSearch();
            },
          ),
          
          // Statistics header
          stats.when(
            data: (data) => _buildStatsHeader(data),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          
          // Student list
          Expanded(
            child: _buildStudentList(state),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(Map<String, dynamic> stats) {
    final total = stats['total'] as int;
    final byStatus = stats['byStatus'] as Map<String, int>;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          _buildStatChip('Total', total, Colors.blue),
          const SizedBox(width: 8),
          _buildStatChip(
            'Registered', 
            byStatus['registered'] ?? 0, 
            Colors.green,
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            'Pending', 
            byStatus['pending'] ?? 0, 
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, MaterialColor color) {
    return Chip(
      label: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color[700],
        ),
      ),
      backgroundColor: color[100],
      side: BorderSide.none,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildStudentList(StudentListState state) {
    if (state.isLoading && state.students.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(studentListProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              state.searchQuery.isNotEmpty
                  ? 'No students found for "${state.searchQuery}"'
                  : state.filter.hasActiveFilters
                      ? 'No students match the applied filters'
                      : 'No students registered yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            if (state.searchQuery.isNotEmpty || state.filter.hasActiveFilters) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  if (state.searchQuery.isNotEmpty) {
                    ref.read(studentListProvider.notifier).clearSearch();
                  }
                  if (state.filter.hasActiveFilters) {
                    ref.read(studentListProvider.notifier).clearFilters();
                  }
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(studentListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.students.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.students.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final student = state.students[index];
          return StudentListCard(
            student: student,
            onTap: () {
              context.push('/students/${student.id}');
            },
          );
        },
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StudentFilterSheet(
        initialFilter: ref.read(studentListProvider).filter,
        onApply: (filter) {
          ref.read(studentListProvider.notifier).applyFilter(filter);
          Navigator.pop(context);
        },
      ),
    );
  }
}
