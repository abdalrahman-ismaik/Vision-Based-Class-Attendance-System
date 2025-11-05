# Student Management Module - Quick Start Guide

## 🚀 Getting Started

### Step 1: Navigate to Students
```dart
// From anywhere in the app
context.push('/students');
```

### Step 2: View Student Details
```dart
// Tap any student card OR
context.push('/students/$studentId');
```

## 📱 User Flows

### View All Students
1. Open app → Dashboard
2. Tap "View Students" card
3. See paginated list with 20 students per page
4. Scroll down to load more automatically

### Search for Student
1. On Students screen, tap search bar
2. Type name, ID, or email
3. Results filter automatically (300ms delay)
4. Tap "X" to clear search

### Filter Students
1. Tap filter icon (top-right)
2. Select criteria:
   - Status (Registered, Pending, Incomplete, Archived)
   - Department
   - Registration date range
   - Minimum frame count (slider)
3. Tap "Apply Filters"
4. See filtered results
5. Badge shows active filter count

### Sort Students
1. Tap sort icon (top-right)
2. Choose from:
   - Name (A-Z or Z-A)
   - Student ID (Ascending/Descending)
   - Date (Newest/Oldest)
   - Department (A-Z)

### View Student Details
1. Tap student card
2. See full profile:
   - Personal info (email, phone, nationality)
   - Department & program
   - Registration date
   - Status badge
3. Scroll down to see captured frames

### View Frames Fullscreen
1. On detail screen, scroll to "Captured Frames"
2. Tap any frame thumbnail
3. Opens fullscreen gallery
4. Swipe left/right to navigate
5. Pinch to zoom
6. See frame metadata (pose, quality, confidence, timestamp)

## 🛠️ For Developers

### Add to Dashboard
```dart
// lib/features/dashboard/presentation/pages/dashboard_page.dart

DashboardCard(
  title: 'View Students',
  subtitle: 'Browse registered students',
  icon: Icons.people,
  count: stats.totalStudents, // Optional badge
  onTap: () => context.push('/students'),
)
```

### Access Providers in Code
```dart
// Get student list state
final studentList = ref.watch(studentListProvider);

// Trigger search
ref.read(studentListProvider.notifier).search('John');

// Apply filter
ref.read(studentListProvider.notifier).applyFilter(
  StudentFilter(statuses: [StudentStatus.registered])
);

// Get student detail
final student = ref.watch(studentDetailProvider('student-id-123'));

// Get student frames
final frames = ref.watch(studentFramesProvider('student-id-123'));
```

### Database Queries
```dart
// Direct repository access
final repository = ref.read(studentManagementRepositoryProvider);

// Get all students
final students = await repository.getAllStudents(limit: 20, offset: 0);

// Search
final results = await repository.searchStudents(query: 'John');

// Filter
final filtered = await repository.filterStudents(
  filter: StudentFilter(department: 'Computer Science'),
);

// Get detail
final detail = await repository.getStudentDetail('student-id');

// Statistics
final total = await repository.getTotalStudentCount();
final byStatus = await repository.getStudentCountByStatus();
```

## 🎨 Customization

### Change Page Size
```dart
// In student_list_provider.dart
static const int _pageSize = 30; // Default is 20
```

### Adjust Search Debounce
```dart
// In student_search_bar.dart
Timer(const Duration(milliseconds: 500), () { // Default is 300ms
  widget.onSearch(query);
});
```

### Modify Grid Columns
```dart
// In frame_gallery_grid.dart
crossAxisCount: 4, // Default is 3 columns
```

### Change Sort Default
```dart
// In student_list_provider.dart (StudentListState)
sortOption: StudentSortOption.dateNewest, // Default is nameAsc
```

## 🐛 Troubleshooting

### No Students Showing
- **Check:** Database has registered students
- **Fix:** Register test students via Student Registration flow

### Search Not Working
- **Check:** Verify debounce is working (wait 300ms)
- **Fix:** Check console for errors

### Frames Not Loading
- **Check:** Image file paths exist in `selected_frames` table
- **Fix:** Verify registration process saves frames correctly

### Slow Performance
- **Check:** Database indices created (version 4 migration ran)
- **Fix:** Run `flutter clean` and rebuild

### Filter/Sort Not Applying
- **Check:** Provider state is updating
- **Fix:** Use DevTools to inspect StudentListState

## 📊 Performance Tips

1. **Limit Frame Sizes** - Compress captured images before saving
2. **Use Memory Cache** - Add image_cache_manager for frames
3. **Lazy Load Images** - Already implemented (loads on scroll)
4. **Database Vacuum** - Periodically run `VACUUM` on SQLite
5. **Index Maintenance** - Ensure indices stay valid after bulk operations

## 🔐 Security Considerations

1. **No PII Exposure** - Student emails/phones only visible to admins
2. **Image Privacy** - Frames stored locally, not uploaded
3. **Access Control** - All routes protected by auth guard
4. **Audit Trail** - Consider logging who views student records

## ✅ Pre-Launch Checklist

- [ ] Add "View Students" card to dashboard
- [ ] Test with 100+ student records
- [ ] Verify search performance (<100ms)
- [ ] Test all filter combinations
- [ ] Verify frame images display correctly
- [ ] Test on both Android and iOS
- [ ] Review with stakeholders
- [ ] Write unit tests for repository
- [ ] Add error tracking (Sentry/Firebase)
- [ ] Document API for future reference

---

**Need Help?** Check `STUDENT_MANAGEMENT_IMPLEMENTATION_COMPLETE.md` for detailed architecture docs.
