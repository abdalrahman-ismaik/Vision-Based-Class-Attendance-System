# Student Management Module - Quick Reference

**Ready-to-use code snippets and task checklist**

---

## 📋 Task Checklist (27 Tasks)

### Week 1-2: Foundation ✅
- [ ] **T063** - Domain use cases (get_all_students, search_students, filter_students, get_student_details, get_student_frames, export_student_data)
- [ ] **T064** - More use cases (frames and export)
- [ ] **T065** - Repository interface
- [ ] **T066** - Repository implementation
- [ ] **T067** - Data models (student_list_item, student_detail, student_filter, student_sort_option)
- [ ] **T080** - Database optimization (indices + FTS)
- [ ] **T081** - Use case unit tests
- [ ] **T082** - Repository unit tests

### Week 3-4: Core UI ✅
- [ ] **T070** - StudentListScreen
- [ ] **T071** - Search UI (student_search_bar)
- [ ] **T072** - Filter UI (student_filter_sheet)
- [ ] **T073** - Sort UI (student_sort_menu)
- [ ] **T076** - Reusable widgets (cards, avatars, chips, badges)
- [ ] **T077** - Empty/error states
- [ ] **T083** - Widget tests

### Week 5-6: Detail & Gallery ✅
- [ ] **T074** - StudentDetailScreen
- [ ] **T075** - FrameGalleryViewer
- [ ] **T068** - StudentListProvider (Riverpod)
- [ ] **T069** - StudentDetailProvider (Riverpod)
- [ ] **T084** - Integration tests

### Week 7: Integration & Polish ✅
- [ ] **T078** - Router updates
- [ ] **T079** - Dashboard integration
- [ ] **T085** - Design system polish
- [ ] **T086** - Accessibility
- [ ] **T087** - Performance optimization
- [ ] **T088** - Search/filter performance
- [ ] **T089** - Documentation

---

## 🚀 Quick Start Commands

```bash
# Create directory structure
cd lib/features
mkdir -p student_management/{domain/{repositories,use_cases},data/{models,repositories},presentation/{providers,screens,widgets}}

# Create test directories
cd ../../../test/features
mkdir -p student_management/{domain/use_cases,data/repositories,presentation/widgets}

# Create integration test
cd ../../../integration_test
touch student_management_flow_test.dart
```

---

## 📁 File Structure Template

```
lib/features/student_management/
├── domain/
│   ├── repositories/
│   │   └── student_management_repository.dart
│   └── use_cases/
│       ├── get_all_students.dart
│       ├── search_students.dart
│       ├── filter_students.dart
│       ├── get_student_details.dart
│       ├── get_student_frames.dart
│       └── export_student_data.dart
├── data/
│   ├── models/
│   │   ├── student_list_item.dart
│   │   ├── student_detail.dart
│   │   ├── student_filter.dart
│   │   └── student_sort_option.dart
│   └── repositories/
│       └── local_student_management_repository.dart
└── presentation/
    ├── providers/
    │   ├── student_list_provider.dart
    │   └── student_detail_provider.dart
    ├── screens/
    │   ├── student_list_screen.dart
    │   └── student_detail_screen.dart
    └── widgets/
        ├── student_list_card.dart
        ├── student_search_bar.dart
        ├── student_filter_sheet.dart
        ├── student_sort_menu.dart
        ├── frame_gallery_viewer.dart
        ├── student_avatar.dart
        ├── student_status_chip.dart
        ├── frame_thumbnail.dart
        ├── quality_score_badge.dart
        ├── pose_type_label.dart
        ├── students_empty_state.dart
        ├── students_error_state.dart
        └── no_results_state.dart
```

---

## 💻 Code Templates

### 1. Use Case Template
```dart
// lib/features/student_management/domain/use_cases/get_all_students.dart

import 'package:dartz/dartz.dart';
import '../repositories/student_management_repository.dart';
import '../../data/models/student_list_item.dart';
import '../../../../shared/error/failures.dart';

class GetAllStudents {
  final StudentManagementRepository repository;

  GetAllStudents(this.repository);

  Future<Either<Failure, List<StudentListItem>>> call({
    int limit = 20,
    int offset = 0,
    StudentSortOption? sortBy,
  }) async {
    return await repository.getAllStudents(
      limit: limit,
      offset: offset,
      sortBy: sortBy,
    );
  }
}
```

### 2. Repository Interface Template
```dart
// lib/features/student_management/domain/repositories/student_management_repository.dart

import 'package:dartz/dartz.dart';
import '../../data/models/student_list_item.dart';
import '../../data/models/student_detail.dart';
import '../../data/models/student_filter.dart';
import '../../../../shared/error/failures.dart';

abstract class StudentManagementRepository {
  Future<Either<Failure, List<StudentListItem>>> getAllStudents({
    int limit = 20,
    int offset = 0,
    StudentSortOption? sortBy,
  });

  Future<Either<Failure, List<StudentListItem>>> searchStudents({
    required String query,
    int limit = 20,
  });

  Future<Either<Failure, List<StudentListItem>>> filterStudents({
    required StudentFilter filter,
    int limit = 20,
    int offset = 0,
  });

  Future<Either<Failure, StudentDetail>> getStudentDetail(String studentId);
  
  Future<Either<Failure, List<SelectedFrameWithMetadata>>> getStudentFrames(
    String studentId,
  );
}
```

### 3. Riverpod Provider Template
```dart
// lib/features/student_management/presentation/providers/student_list_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/student_list_item.dart';
import '../../data/models/student_filter.dart';
import '../../domain/use_cases/get_all_students.dart';
import '../../domain/use_cases/search_students.dart';
import '../../domain/use_cases/filter_students.dart';

part 'student_list_provider.g.dart';

@riverpod
class StudentList extends _$StudentList {
  static const int _pageSize = 20;
  
  List<StudentListItem> _students = [];
  int _currentPage = 0;
  bool _hasMore = true;
  String? _searchQuery;
  StudentFilter? _filter;

  @override
  Future<AsyncValue<List<StudentListItem>>> build() async {
    return await AsyncValue.guard(() => _loadStudents());
  }

  Future<List<StudentListItem>> _loadStudents() async {
    final result = await ref.read(getAllStudentsProvider).call(
      limit: _pageSize,
      offset: _currentPage * _pageSize,
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (students) {
        _students = students;
        _hasMore = students.length == _pageSize;
        return students;
      },
    );
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;

    _currentPage++;
    final result = await ref.read(getAllStudentsProvider).call(
      limit: _pageSize,
      offset: _currentPage * _pageSize,
    );

    result.fold(
      (failure) => throw Exception(failure.message),
      (students) {
        _students.addAll(students);
        _hasMore = students.length == _pageSize;
        state = AsyncValue.data(_students);
      },
    );
  }

  Future<void> refresh() async {
    _currentPage = 0;
    _hasMore = true;
    _students.clear();
    state = await AsyncValue.guard(() => _loadStudents());
  }

  Future<void> search(String query) async {
    // Debounce logic here
    _searchQuery = query;
    _currentPage = 0;
    
    final result = await ref.read(searchStudentsProvider).call(query: query);
    
    result.fold(
      (failure) => throw Exception(failure.message),
      (students) {
        _students = students;
        state = AsyncValue.data(students);
      },
    );
  }

  Future<void> applyFilter(StudentFilter filter) async {
    _filter = filter;
    _currentPage = 0;
    
    final result = await ref.read(filterStudentsProvider).call(filter: filter);
    
    result.fold(
      (failure) => throw Exception(failure.message),
      (students) {
        _students = students;
        state = AsyncValue.data(students);
      },
    );
  }
}
```

### 4. Screen Template
```dart
// lib/features/student_management/presentation/screens/student_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/student_list_provider.dart';
import '../widgets/student_list_card.dart';
import '../widgets/student_search_bar.dart';
import '../widgets/student_filter_sheet.dart';
import '../widgets/students_empty_state.dart';
import '../widgets/students_error_state.dart';

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(studentListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilters(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(studentListProvider.notifier).refresh(),
        child: studentsAsync.when(
          data: (students) {
            if (students.isEmpty) {
              return const StudentsEmptyState();
            }

            return ListView.builder(
              controller: _scrollController,
              itemCount: students.length + 1,
              itemBuilder: (context, index) {
                if (index == students.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final student = students[index];
                return StudentListCard(
                  student: student,
                  onTap: () => context.go('/students/${student.id}'),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => StudentsErrorState(
            error: error.toString(),
            onRetry: () => ref.invalidate(studentListProvider),
          ),
        ),
      ),
    );
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: StudentSearchDelegate(ref),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const StudentFilterSheet(),
    );
  }
}
```

### 5. Database Migration Template
```dart
// Update lib/shared/data/data_sources/local_database_data_source.dart

Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
  // Existing migrations...
  
  // Add student management indices (version 4)
  if (oldVersion < 4 && newVersion >= 4) {
    // Status + date compound index
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_students_status_created 
      ON students(status, created_at DESC)
    ''');
    
    // Name search index (case-insensitive)
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_students_name 
      ON students(full_name COLLATE NOCASE)
    ''');
    
    // Department filter index
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_students_department 
      ON students(department)
    ''');
    
    // Frame queries index
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_frames_student 
      ON selected_frames(student_id, pose_type)
    ''');
    
    // Full-text search virtual table
    await db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS students_fts 
      USING fts5(
        student_id,
        full_name,
        email,
        content=students,
        content_rowid=rowid
      )
    ''');
    
    // Populate FTS table
    await db.execute('''
      INSERT INTO students_fts(student_id, full_name, email)
      SELECT student_id, full_name, email FROM students
    ''');
  }
}
```

---

## 🎨 Widget Code Snippets

### StudentListCard
```dart
class StudentListCard extends StatelessWidget {
  final StudentListItem student;
  final VoidCallback onTap;

  const StudentListCard({
    super.key,
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              StudentAvatar(student: student, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${student.studentId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student.department ?? 'N/A',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StudentStatusChip(status: student.status),
                        const SizedBox(width: 8),
                        FrameCountBadge(count: student.frameCount),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 🔍 SQL Query Examples

### Search Students (FTS)
```sql
SELECT s.* 
FROM students s
JOIN students_fts fts ON s.rowid = fts.rowid
WHERE students_fts MATCH ?
ORDER BY rank
LIMIT ?;
```

### Filter with Multiple Criteria
```sql
SELECT 
  s.*,
  COUNT(f.id) as frame_count
FROM students s
LEFT JOIN selected_frames f ON s.id = f.student_id
WHERE 
  (? IS NULL OR s.status = ?) AND
  (? IS NULL OR s.department = ?) AND
  (? IS NULL OR s.created_at >= ?) AND
  (? IS NULL OR s.created_at <= ?)
GROUP BY s.id
HAVING (? IS NULL OR COUNT(f.id) >= ?)
ORDER BY s.created_at DESC
LIMIT ? OFFSET ?;
```

---

## 📊 Performance Checklist

### Load Time Targets
- [ ] Student list (20 items): < 100ms
- [ ] Search results: < 200ms
- [ ] Student detail: < 300ms
- [ ] Frame gallery: < 500ms

### Optimization Techniques
- [ ] Database indices created
- [ ] FTS5 virtual table for search
- [ ] Image caching enabled
- [ ] Infinite scroll implemented
- [ ] Debounced search (300ms)
- [ ] Lazy loading frames
- [ ] Skeleton loaders during load

---

## 🧪 Testing Commands

```bash
# Run unit tests
flutter test test/features/student_management/

# Run widget tests
flutter test test/features/student_management/presentation/widgets/

# Run integration tests
flutter test integration_test/student_management_flow_test.dart

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 📝 Documentation Files

1. ✅ `STUDENT_MANAGEMENT_MODULE_DESIGN.md` - Complete architecture and design
2. ✅ `STUDENT_MANAGEMENT_IMPLEMENTATION_SUMMARY.md` - Implementation overview
3. ✅ `STUDENT_MANAGEMENT_VISUAL_GUIDE.md` - Visual mockups and colors
4. ✅ `STUDENT_MANAGEMENT_QUICK_REFERENCE.md` - This file (code snippets)

---

## 🚦 Implementation Order

1. **Start with Domain Layer** (T063-T065)
   - Define use cases and repository interface
   - No dependencies, easy to test

2. **Add Data Layer** (T066-T067)
   - Implement repository
   - Create data models
   - Add database indices

3. **Build State Management** (T068-T069)
   - Create Riverpod providers
   - Handle loading/error states

4. **Implement UI** (T070-T077)
   - Build screens
   - Create reusable widgets
   - Add empty/error states

5. **Integrate Navigation** (T078-T079)
   - Update router
   - Wire up dashboard

6. **Polish & Optimize** (T085-T088)
   - Add animations
   - Optimize performance
   - Improve accessibility

7. **Test Everything** (T081-T084)
   - Unit tests
   - Widget tests
   - Integration tests

---

## ✨ Key Features Implemented

- ✅ Infinite scroll pagination
- ✅ Real-time search with FTS
- ✅ Multi-criteria filtering
- ✅ Multiple sort options
- ✅ Student detail with frames
- ✅ Full-screen frame gallery
- ✅ Pull-to-refresh
- ✅ Empty and error states
- ✅ Skeleton loaders
- ✅ Hero animations
- ✅ Responsive design

---

**Ready to implement! Start with T063 and work sequentially through the tasks.** 🚀
