import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/student_list_provider.dart';
import '../widgets/student_search_bar.dart';
import '../widgets/student_filter_sheet.dart';
import '../widgets/student_sort_menu.dart';
import '../widgets/student_list_card.dart';
import '../widgets/student_bulk_upload_dialog.dart';
import '../../../../shared/data/data_sources/local_database_data_source.dart';
import '../../../../shared/domain/entities/student.dart';
import '../../data/models/student_list_item.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_spacing.dart';

/// Main screen for viewing and managing registered students
class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  final _scrollController = ScrollController();
  bool _isSelectionMode = false;
  final Set<String> _selectedStudentIds = {};

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
    final unsentStudents = state.students.where((s) => s.needsSync).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        title: Text(
          _isSelectionMode 
            ? '${_selectedStudentIds.length} selected' 
            : 'Registered Students',
          style: AppTextStyles.headingLarge.copyWith(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all, color: Colors.white),
                  onPressed: _selectAllUnsentStudents,
                  tooltip: 'Select all unsent',
                ),
                IconButton(
                  icon: const Icon(Icons.cloud_upload, color: Colors.white),
                  onPressed: _selectedStudentIds.isEmpty ? null : _uploadSelectedStudents,
                  tooltip: 'Upload selected',
                ),
              ]
            : [
                // Upload button (shows badge with count of unsent students)
                if (unsentStudents.isNotEmpty)
                  IconButton(
                    icon: Badge(
                      label: Text('${unsentStudents.length}'),
                      child: const Icon(Icons.cloud_upload, color: Colors.white),
                    ),
                    onPressed: () => _showUploadOptions(context, unsentStudents),
                    tooltip: 'Upload to backend',
                  ),
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
                    child: const Icon(Icons.filter_list, color: Colors.white),
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
      padding: AppSpacing.paddingMD,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF9FAFB), Colors.white],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Total', total, AppColors.primaryGradient, Icons.people),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard('Registered', byStatus['registered'] ?? 0, AppColors.successGradient, Icons.check_circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard('Pending', byStatus['pending'] ?? 0, AppColors.warningGradient, Icons.pending),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Gradient gradient, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppRadius.circularMD,
        boxShadow: AppElevation.shadowSM,
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: AppTextStyles.headingLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(StudentListState state) {
    if (state.isLoading && state.students.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.students.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.warningRed),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: AppSpacing.paddingHorizontalLG,
                child: Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.warningRed,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(studentListProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.students.isEmpty) {
      return SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 64, color: AppColors.textSubtle),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: AppSpacing.paddingHorizontalLG,
                  child: Text(
                    state.searchQuery.isNotEmpty
                        ? 'No students found for "${state.searchQuery}"'
                        : state.filter.hasActiveFilters
                            ? 'No students match the applied filters'
                            : 'No students registered yet',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textLight,
                    ),
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
          ),
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
            isSelectionMode: _isSelectionMode,
            isSelected: _selectedStudentIds.contains(student.id),
            onTap: () {
              if (_isSelectionMode) {
                _toggleSelection(student.id);
              } else {
                context.push('/students/${student.id}');
              }
            },
            onLongPress: () {
              if (!_isSelectionMode) {
                _enterSelectionMode(student.id);
              }
            },
          );
        },
      ),
    );
  }

  void _enterSelectionMode(String studentId) {
    setState(() {
      _isSelectionMode = true;
      _selectedStudentIds.clear();
      _selectedStudentIds.add(studentId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedStudentIds.clear();
    });
  }

  void _toggleSelection(String studentId) {
    setState(() {
      if (_selectedStudentIds.contains(studentId)) {
        _selectedStudentIds.remove(studentId);
      } else {
        _selectedStudentIds.add(studentId);
      }
    });
  }

  void _selectAllUnsentStudents() {
    final state = ref.read(studentListProvider);
    final unsentStudents = state.students.where((s) => s.needsSync);
    
    setState(() {
      _selectedStudentIds.clear();
      _selectedStudentIds.addAll(unsentStudents.map((s) => s.id));
    });
  }

  Future<void> _uploadSelectedStudents() async {
    final state = ref.read(studentListProvider);
    final selectedItems = state.students
        .where((s) => _selectedStudentIds.contains(s.id))
        .toList();

    await _performBulkUpload(selectedItems);
    
    _exitSelectionMode();
  }

  void _showUploadOptions(BuildContext context, List<StudentListItem> unsentStudents) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.topXXXL,
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.borderMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Upload Students',
                style: AppTextStyles.headingLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primaryIndigo.withOpacity(0.1),
                    borderRadius: AppRadius.circularMD,
                  ),
                  child: const Icon(
                    Icons.cloud_upload,
                    color: AppColors.primaryIndigo,
                  ),
                ),
                title: Text(
                  'Upload All (${unsentStudents.length} students)',
                  style: AppTextStyles.headingSmall,
                ),
                subtitle: Text(
                  'Upload all unsent students at once',
                  style: AppTextStyles.bodySmall,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _performBulkUpload(unsentStudents);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.warningAmber.withOpacity(0.1),
                    borderRadius: AppRadius.circularMD,
                  ),
                  child: const Icon(
                    Icons.checklist,
                    color: AppColors.warningAmber,
                  ),
                ),
                title: Text(
                  'Select Specific Students',
                  style: AppTextStyles.headingSmall,
                ),
                subtitle: Text(
                  'Choose which students to upload',
                  style: AppTextStyles.bodySmall,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _enterSelectionMode(unsentStudents.first.id);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performBulkUpload(List<StudentListItem> studentsToUpload) async {
    // Fetch full student entities from database
    final database = LocalDatabaseDataSource();
    final db = await database.database;
    
    final List<Student> fullStudents = [];
    for (var item in studentsToUpload) {
      final results = await db.query(
        'students',
        where: 'id = ?',
        whereArgs: [item.id],
      );
      
      if (results.isNotEmpty) {
        fullStudents.add(Student.fromJson(results.first));
      }
    }

    if (fullStudents.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ No students found to upload',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.warningRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.circularMD,
            ),
          ),
        );
      }
      return;
    }

    // Show upload dialog
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StudentBulkUploadDialog(
          students: studentsToUpload,
          fullStudents: fullStudents,
        ),
      );

      // Refresh the list after upload
      ref.read(studentListProvider.notifier).refresh();
    }
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
