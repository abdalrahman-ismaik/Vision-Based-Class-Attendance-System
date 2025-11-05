# Student Management Module - Design Specification

**Version**: 1.0  
**Date**: October 26, 2025  
**Status**: Ready for Implementation

---

## Overview

The Student Management Module provides comprehensive browsing, search, filtering, and detailed viewing of registered students with their captured facial recognition frames. This module is accessible from the Dashboard's "View Students" card and follows Material Design 3 principles.

---

## Architecture

### Clean Architecture Layers

```
Domain Layer (Business Logic)
├── entities/
│   └── (reuses existing Student, SelectedFrame)
├── repositories/
│   └── student_management_repository.dart (interface)
└── use_cases/
    ├── get_all_students.dart
    ├── search_students.dart
    ├── filter_students.dart
    ├── get_student_details.dart
    ├── get_student_frames.dart
    └── export_student_data.dart

Data Layer (Data Access)
├── models/
│   ├── student_list_item.dart
│   ├── student_detail.dart
│   ├── student_filter.dart
│   └── student_sort_option.dart
└── repositories/
    └── local_student_management_repository.dart (implementation)

Presentation Layer (UI)
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
    └── pose_type_label.dart
```

---

## User Flow

```
Dashboard
    ↓ (Tap "View Students")
Student List Screen
    ├─→ Search (Tap search icon)
    │   └─→ Search Results
    ├─→ Filter (Tap filter icon)
    │   └─→ Filter Bottom Sheet → Apply → Filtered Results
    ├─→ Sort (Tap sort menu)
    │   └─→ Sort Menu → Select Option → Sorted Results
    └─→ Tap Student Card
        ↓
    Student Detail Screen
        ├─→ View Student Info
        ├─→ Browse Selected Frames Grid
        ├─→ Tap Frame → Frame Gallery Viewer
        │   ├─→ Swipe between frames
        │   ├─→ Pinch to zoom
        │   └─→ View metadata
        └─→ Actions (Export, Edit, Delete)
```

---

## Screen Designs

### 1. Student List Screen

#### Layout Structure
```
┌─────────────────────────────────────┐
│ ← HADIR Students      🔍 ⚙️ 📊      │ App Bar
├─────────────────────────────────────┤
│ 🔍 Search students...                │ Search Bar (collapsed)
├─────────────────────────────────────┤
│ ≡ Status: All  ⌄  📅 Date: All  ⌄  │ Active Filters (if any)
├─────────────────────────────────────┤
│ Pull to refresh...                   │ Pull-to-refresh indicator
├─────────────────────────────────────┤
│ ┌───────────────────────────────┐   │
│ │ 👤 John Smith                 │   │
│ │ ID: 100012345                 │   │ Student Card 1
│ │ Computer Science              │   │
│ │ ✅ Registered  📷 5 frames    │   │
│ │ 📅 Oct 25, 2025               │   │
│ └───────────────────────────────┘   │
│                                      │
│ ┌───────────────────────────────┐   │
│ │ 👤 Sarah Johnson              │   │
│ │ ID: 100012346                 │   │ Student Card 2
│ │ Electrical Engineering        │   │
│ │ ✅ Registered  📷 5 frames    │   │
│ │ 📅 Oct 24, 2025               │   │
│ └───────────────────────────────┘   │
│                                      │
│ ┌───────────────────────────────┐   │
│ │ 👤 Michael Brown              │   │ Student Card 3
│ │ ...                           │   │
│ └───────────────────────────────┘   │
│                                      │
│ Loading more...                      │ Infinite scroll loader
└─────────────────────────────────────┘
```

#### Student List Card Design
```dart
// Each card shows:
- Avatar (circular, 48x48)
  * Shows initials if no photo
  * Color based on status
- Student Name (bold, 16sp)
- Student ID (gray, 14sp)
- Department/Program (gray, 12sp)
- Status Chip (colored, 12sp)
  * Green: Registered
  * Orange: Pending
  * Red: Incomplete
  * Gray: Archived
- Frame Count Badge (icon + number)
- Registration Date (light gray, 12sp)
- Card elevation: 2dp
- Padding: 16dp
- Border radius: 12dp
```

#### Empty State
```
┌─────────────────────────────────────┐
│                                      │
│           📋                         │
│      (Empty illustration)            │
│                                      │
│      No Students Found               │
│                                      │
│   No registered students yet.        │
│   Start by registering your          │
│   first student!                     │
│                                      │
│   ┌─────────────────────┐           │
│   │ Register Student    │           │
│   └─────────────────────┘           │
│                                      │
└─────────────────────────────────────┘
```

#### Search Results (No Match)
```
┌─────────────────────────────────────┐
│ ← Search: "nonexistent"    ×        │
├─────────────────────────────────────┤
│                                      │
│           🔍                         │
│      (Search illustration)           │
│                                      │
│    No Results Found                  │
│                                      │
│   No students match your search.     │
│   Try a different search term.       │
│                                      │
└─────────────────────────────────────┘
```

---

### 2. Search Interface

#### Search Bar (Expanded)
```
┌─────────────────────────────────────┐
│ ← 🔍 Search students...        ×    │
├─────────────────────────────────────┤
│ Recent Searches                      │
│ • John Smith                         │
│ • 100012345                          │
│ • Computer Science                   │
├─────────────────────────────────────┤
│ Suggestions                          │
│ • Jane Smith (100012347)             │
│ • John Doe (100012348)               │
└─────────────────────────────────────┘
```

#### Search Features
- **Real-time search** with 300ms debounce
- **Search by**:
  * Student name (full or partial)
  * Student ID (full or partial)
  * Email address
  * Department
- **Highlighted matches** in results
- **Recent searches** (last 10)
- **Search suggestions** as you type

---

### 3. Filter Bottom Sheet

```
┌─────────────────────────────────────┐
│          Filter Students             │
│                                 ×    │
├─────────────────────────────────────┤
│ Status                               │
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐   │
│ │ All │ │Reg'd│ │Pend.│ │Inc. │   │ Chips
│ └─────┘ └─────┘ └─────┘ └─────┘   │
│                                      │
│ Department                           │
│ ┌───────────────────────────────┐   │
│ │ All Departments          ⌄   │   │ Dropdown
│ └───────────────────────────────┘   │
│                                      │
│ Registration Date                    │
│ ┌──────────────┐ ┌──────────────┐  │
│ │ Oct 1, 2025  │ │ Oct 26, 2025 │  │ Date Range
│ └──────────────┘ └──────────────┘  │
│                                      │
│ Frame Count                          │
│ ├─────●──────────────────┤          │ Slider
│ 3+ frames                            │
│                                      │
├─────────────────────────────────────┤
│ ┌─────────┐          ┌─────────┐   │
│ │  Reset  │          │  Apply  │   │ Actions
│ └─────────┘          └─────────┘   │
└─────────────────────────────────────┘
```

#### Filter Options
1. **Status** (Multi-select chips)
   - All
   - Registered ✅
   - Pending ⏳
   - Incomplete ❌
   - Archived 📦

2. **Department** (Dropdown)
   - All Departments
   - Computer Science
   - Electrical Engineering
   - Mechanical Engineering
   - etc.

3. **Registration Date** (Date Range Picker)
   - Start date
   - End date
   - Presets: Today, Last 7 days, Last 30 days, All time

4. **Frame Count** (Slider)
   - Minimum frames: 0-5
   - Shows students with at least X frames

---

### 4. Sort Menu

```
┌─────────────────────────────────────┐
│ Sort By                              │
├─────────────────────────────────────┤
│ ○ Name (A-Z)                         │
│ ● Name (Z-A)                    ✓   │
│ ○ Student ID (Ascending)             │
│ ○ Student ID (Descending)            │
│ ○ Date (Newest First)                │
│ ○ Date (Oldest First)                │
│ ○ Department (A-Z)                   │
└─────────────────────────────────────┘
```

---

### 5. Student Detail Screen

```
┌─────────────────────────────────────┐
│ ← John Smith        ⋮  📤  🗑️       │ App Bar
├─────────────────────────────────────┤
│                                      │
│        ┌─────────────┐               │
│        │             │               │ Large Avatar
│        │     👤      │               │ (120x120)
│        │             │               │
│        └─────────────┘               │
│                                      │
│       John Smith                     │ Name (24sp, bold)
│       ID: 100012345                  │ Student ID (16sp)
│       ✅ Registered                  │ Status Chip
│                                      │
├─────────────────────────────────────┤
│ Student Information                  │ Section Header
├─────────────────────────────────────┤
│ 📧 Email                             │
│    john.smith@university.edu         │
│                                      │
│ 🎓 Department                        │
│    Computer Science                  │
│                                      │
│ 📚 Program                           │
│    Bachelor of Science               │
│                                      │
│ 📅 Registered On                     │
│    October 25, 2025                  │
│                                      │
├─────────────────────────────────────┤
│ Captured Poses (5 frames)            │ Section Header
├─────────────────────────────────────┤
│ ┌──────────┐  ┌──────────┐          │
│ │          │  │          │          │
│ │  Image   │  │  Image   │          │ Frame Grid
│ │          │  │          │          │ (2 columns)
│ └──────────┘  └──────────┘          │
│ Frontal       Left Profile           │ Pose Labels
│ Quality: 92%  Quality: 88%           │ Quality Badges
│                                      │
│ ┌──────────┐  ┌──────────┐          │
│ │          │  │          │          │
│ │  Image   │  │  Image   │          │
│ │          │  │          │          │
│ └──────────┘  └──────────┘          │
│ Right Profile Looking Up             │
│ Quality: 85%  Quality: 90%           │
│                                      │
│ ┌──────────┐                         │
│ │          │                         │
│ │  Image   │                         │
│ │          │                         │
│ └──────────┘                         │
│ Looking Down                         │
│ Quality: 87%                         │
│                                      │
└─────────────────────────────────────┘
```

#### Action Menu (⋮)
```
┌─────────────────────────────────────┐
│ Edit Student Info                    │
│ Export Data (PDF)                    │
│ Export Data (JSON)                   │
│ Re-register Student                  │
│ Archive Student                      │
│ Delete Student                       │
└─────────────────────────────────────┘
```

---

### 6. Frame Gallery Viewer

```
┌─────────────────────────────────────┐
│ ×                              ⋮    │ Overlay (auto-hide)
│                                      │
│                                      │
│                                      │
│            Full Image                │
│         (Zoomable)                   │
│                                      │
│                                      │
│                                      │
│ ○ ○ ● ○ ○                           │ Page Indicator
│                                      │ (1 of 5)
│ ┌────────────────────────────────┐  │
│ │ Frontal Pose                   │  │ Metadata Overlay
│ │ Quality Score: 92%             │  │ (bottom)
│ │ Captured: Oct 25, 2025 2:45 PM │  │
│ └────────────────────────────────┘  │
└─────────────────────────────────────┘
```

#### Gallery Features
- **Gestures**:
  * Swipe left/right to navigate frames
  * Pinch to zoom (1x - 5x)
  * Double-tap to zoom to fit
  * Drag to pan when zoomed
- **Overlay Controls** (auto-hide after 3s):
  * Close button (×)
  * Menu button (⋮) for share/export
  * Page indicator (1 of 5)
- **Metadata Overlay** (bottom, toggleable):
  * Pose type
  * Quality score with color indicator
  * Timestamp
  * Frame dimensions

---

## Data Models

### StudentListItem (Lightweight)
```dart
class StudentListItem {
  final String id;
  final String studentId;
  final String fullName;
  final String? department;
  final StudentStatus status;
  final int frameCount;
  final DateTime registeredAt;
  final String? avatarUrl;
}
```

### StudentDetail (Full)
```dart
class StudentDetail {
  final String id;
  final String studentId;
  final String fullName;
  final String? email;
  final String? department;
  final String? program;
  final DateTime? dateOfBirth;
  final StudentStatus status;
  final DateTime registeredAt;
  final DateTime? lastUpdatedAt;
  final List<SelectedFrameWithMetadata> frames;
  final String? avatarUrl;
}
```

### SelectedFrameWithMetadata
```dart
class SelectedFrameWithMetadata {
  final String id;
  final String imageFilePath;
  final PoseType poseType;
  final double qualityScore;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
}
```

### StudentFilter
```dart
class StudentFilter {
  final List<StudentStatus>? statuses;
  final String? department;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? minFrameCount;
  
  bool get hasActiveFilters => 
    statuses != null || 
    department != null || 
    startDate != null || 
    endDate != null ||
    minFrameCount != null;
}
```

### StudentSortOption
```dart
enum StudentSortOption {
  nameAsc('Name (A-Z)'),
  nameDesc('Name (Z-A)'),
  studentIdAsc('Student ID (Ascending)'),
  studentIdDesc('Student ID (Descending)'),
  dateNewest('Date (Newest First)'),
  dateOldest('Date (Oldest First)'),
  departmentAsc('Department (A-Z)');
  
  final String label;
  const StudentSortOption(this.label);
}
```

---

## Database Optimization

### New Indices
```sql
-- Compound index for status + date sorting
CREATE INDEX idx_students_status_created 
ON students(status, created_at DESC);

-- Index for case-insensitive name search
CREATE INDEX idx_students_name 
ON students(full_name COLLATE NOCASE);

-- Index for department filtering
CREATE INDEX idx_students_department 
ON students(department);

-- Index for efficient frame queries
CREATE INDEX idx_frames_student 
ON selected_frames(student_id, pose_type);

-- Full-text search virtual table
CREATE VIRTUAL TABLE students_fts 
USING fts5(student_id, full_name, email, content=students);
```

### Query Examples

#### Paginated Student List with Filter
```sql
SELECT 
  s.id,
  s.student_id,
  s.full_name,
  s.department,
  s.status,
  s.created_at,
  COUNT(f.id) as frame_count
FROM students s
LEFT JOIN selected_frames f ON s.id = f.student_id
WHERE 
  (? IS NULL OR s.status = ?) AND
  (? IS NULL OR s.department = ?) AND
  (? IS NULL OR s.created_at >= ?) AND
  (? IS NULL OR s.created_at <= ?)
GROUP BY s.id
ORDER BY s.created_at DESC
LIMIT ? OFFSET ?;
```

#### Full-Text Search
```sql
SELECT s.*
FROM students s
JOIN students_fts fts ON s.id = fts.rowid
WHERE students_fts MATCH ?
ORDER BY rank;
```

---

## State Management

### StudentListProvider (Riverpod)
```dart
@riverpod
class StudentList extends _$StudentList {
  int _currentPage = 0;
  final int _pageSize = 20;
  
  @override
  Future<List<StudentListItem>> build() async {
    return _loadStudents();
  }
  
  Future<void> loadMore() async {
    // Infinite scroll logic
  }
  
  Future<void> refresh() async {
    // Pull-to-refresh logic
  }
  
  Future<void> search(String query) async {
    // Debounced search
  }
  
  Future<void> applyFilter(StudentFilter filter) async {
    // Filter logic
  }
  
  Future<void> sort(StudentSortOption option) async {
    // Sorting logic
  }
}
```

### StudentDetailProvider (Riverpod)
```dart
@riverpod
Future<StudentDetail> studentDetail(
  StudentDetailRef ref,
  String studentId,
) async {
  final repository = ref.watch(studentManagementRepositoryProvider);
  return repository.getStudentDetail(studentId);
}
```

---

## Performance Considerations

### Image Loading Strategy
1. **Thumbnails**:
   - Generate 150x150 thumbnails on save
   - Cache thumbnails in memory (LRU cache)
   - Use `cached_network_image` or `flutter_cache_manager`

2. **Full-Size Images**:
   - Lazy load on detail screen
   - Progressive loading (blur → full)
   - Cache on disk

3. **Gallery Viewer**:
   - Preload adjacent frames (±1)
   - Dispose off-screen images

### List Performance
1. **Infinite Scroll**:
   - Load 20 items per page
   - Trigger next load at 80% scroll
   - Show shimmer skeleton during load

2. **Search Optimization**:
   - 300ms debounce on input
   - Cancel previous requests
   - Cache recent results (5 minutes)

3. **List Optimization**:
   - Use `AutomaticKeepAliveClientMixin` for scroll position
   - Implement `addAutomaticKeepAlives: true`
   - Use `const` constructors where possible

---

## Accessibility

### Screen Reader Support
```dart
Semantics(
  label: 'Student: ${student.fullName}',
  hint: 'Tap to view details',
  child: StudentListCard(student: student),
)
```

### Color Contrast
- **Status Colors** (WCAG AA compliant):
  * Registered: `Color(0xFF2E7D32)` (Green 800)
  * Pending: `Color(0xFFEF6C00)` (Orange 800)
  * Incomplete: `Color(0xFFC62828)` (Red 800)
  * Archived: `Color(0xFF616161)` (Gray 700)

### Keyboard Navigation
- Tab order: Search → Filter → Sort → List items
- Enter key to activate
- Arrow keys for list navigation

---

## Error Handling

### Network Errors
```dart
if (error is SocketException) {
  return ErrorWidget(
    message: 'No internet connection',
    action: 'Retry',
    onAction: () => retry(),
  );
}
```

### Database Errors
```dart
if (error is DatabaseException) {
  return ErrorWidget(
    message: 'Database error occurred',
    action: 'Report Issue',
    onAction: () => reportError(error),
  );
}
```

### Empty States
- No students: Show "Register Student" CTA
- No search results: Suggest trying different terms
- No frames: Show "Frames not captured" message

---

## Testing Strategy

### Unit Tests
- Repository search/filter logic
- Use case business rules
- Data model serialization

### Widget Tests
- Student list rendering
- Search bar functionality
- Filter sheet interactions
- Sort menu selection

### Integration Tests
- Complete navigation flow
- Search → Filter → Detail workflow
- Frame gallery interaction
- Pagination behavior

---

## Future Enhancements

### Phase 2 Features
- [ ] Bulk export (CSV, Excel)
- [ ] Advanced analytics dashboard
- [ ] Student comparison view
- [ ] Frame quality history chart
- [ ] Batch operations (archive, delete)
- [ ] Student notes/comments
- [ ] Audit log viewer

### Phase 3 Features
- [ ] Cloud sync for students
- [ ] Facial recognition search
- [ ] Duplicate detection
- [ ] OCR for ID card scanning
- [ ] Biometric template export
- [ ] Integration with university systems

---

## Implementation Timeline

### Week 1-2: Foundation
- T063-T067: Domain and data layers
- T080: Database optimization
- T081-T082: Unit tests

### Week 3-4: UI Core
- T070: Student list screen
- T071-T073: Search, filter, sort
- T076-T077: Reusable widgets
- T083: Widget tests

### Week 5-6: Detail & Gallery
- T074: Student detail screen
- T075: Frame gallery viewer
- T068-T069: State management
- T084: Integration tests

### Week 7: Polish
- T078-T079: Navigation integration
- T085-T088: UI/UX polish and performance
- T089: Documentation

---

## Conclusion

This student management module provides a comprehensive, user-friendly interface for viewing and managing registered students. It follows Flutter best practices, Material Design 3 guidelines, and maintains clean architecture principles throughout.

**Ready for implementation**: All 27 tasks (T063-T089) are defined, dependencies mapped, and design specifications complete.
