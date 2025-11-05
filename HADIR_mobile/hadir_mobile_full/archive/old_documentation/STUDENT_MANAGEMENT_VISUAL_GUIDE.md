# Student Management Module - Visual Mockups & Color Guide

**Version**: 1.0  
**Date**: October 26, 2025  
**Purpose**: Visual reference for UI implementation

---

## Color Palette

### Status Colors (WCAG AA Compliant)

```dart
// Status indicator colors
static const Color registeredGreen = Color(0xFF2E7D32);    // Green 800
static const Color pendingOrange = Color(0xFFEF6C00);      // Orange 800
static const Color incompleteRed = Color(0xFFC62828);      // Red 800
static const Color archivedGray = Color(0xFF616161);       // Gray 700

// Light variants for chips/badges
static const Color registeredLight = Color(0xFFE8F5E9);    // Green 50
static const Color pendingLight = Color(0xFFFFF3E0);       // Orange 50
static const Color incompleteLight = Color(0xFFFFEBEE);    // Red 50
static const Color archivedLight = Color(0xFFF5F5F5);      // Gray 50

// Quality score colors (gradient)
static const Color qualityExcellent = Color(0xFF2E7D32);   // > 90%
static const Color qualityGood = Color(0xFF689F38);        // 75-90%
static const Color qualityFair = Color(0xFFFBC02D);        // 60-75%
static const Color qualityPoor = Color(0xFFEF6C00);        // < 60%
```

### UI Element Colors

```dart
// Primary app colors (existing)
static const Color primaryBlue = Color(0xFF1976D2);
static const Color primaryDark = Color(0xFF0D47A1);
static const Color accent = Color(0xFF448AFF);

// Background colors
static const Color backgroundLight = Color(0xFFFAFAFA);
static const Color cardBackground = Color(0xFFFFFFFF);
static const Color divider = Color(0xFFE0E0E0);

// Text colors
static const Color textPrimary = Color(0xFF212121);
static const Color textSecondary = Color(0xFF757575);
static const Color textHint = Color(0xFF9E9E9E);
```

---

## Typography Scale

```dart
// Text styles for student management
static const TextStyle headerLarge = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: textPrimary,
);

static const TextStyle headerMedium = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  color: textPrimary,
);

static const TextStyle bodyLarge = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  color: textPrimary,
);

static const TextStyle bodyMedium = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.normal,
  color: textSecondary,
);

static const TextStyle caption = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.normal,
  color: textHint,
);

static const TextStyle labelSmall = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.5,
  color: textSecondary,
);
```

---

## Component Dimensions

```dart
// Card and spacing
static const double cardElevation = 2.0;
static const double cardBorderRadius = 12.0;
static const double cardPadding = 16.0;

// List items
static const double listItemHeight = 120.0;
static const double avatarSize = 48.0;
static const double avatarSizeLarge = 120.0;

// Touch targets
static const double minTouchTarget = 48.0;
static const double iconSize = 24.0;
static const double iconSizeSmall = 16.0;

// Spacing
static const double spacingXSmall = 4.0;
static const double spacingSmall = 8.0;
static const double spacingMedium = 16.0;
static const double spacingLarge = 24.0;
static const double spacingXLarge = 32.0;
```

---

## Detailed Screen Mockups

### 1. Student List Screen (Full Detail)

```
┌─────────────────────────────────────────────────────┐
│ ← HADIR Students              🔍  ⚙️  📊  ⋮         │ AppBar
│                                                      │ • Height: 56dp
│                                                      │ • Background: primaryBlue
└─────────────────────────────────────────────────────┘ • Elevation: 4dp

┌─────────────────────────────────────────────────────┐
│ 🔍 Search by name, ID, or email...                  │ Search Bar
│                                                      │ • Height: 56dp
│                                                      │ • Border radius: 28dp
└─────────────────────────────────────────────────────┘ • Padding: 16dp

┌─────────────────────────────────────────────────────┐
│ Active Filters (2)                            ×     │ Filter Chips
│ ┌─────────────┐ ┌─────────────┐                    │ • Height: 32dp
│ │ Registered ×│ │ Comp. Sci. ×│                    │ • Border radius: 16dp
│ └─────────────┘ └─────────────┘                    │ • Padding: 8dp 12dp
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                                                      │
│  ┌───────────────────────────────────────────────┐  │ Student Card 1
│  │  ┌─────┐                                      │  │ • Height: 120dp
│  │  │     │  John Smith                          │  │ • Margin: 16dp 8dp
│  │  │ 👤  │  ID: 100012345                       │  │ • Padding: 16dp
│  │  │     │  Computer Science                    │  │ • Elevation: 2dp
│  │  └─────┘                                      │  │ • Border radius: 12dp
│  │           ┌──────────┐  ┌──────┐              │  │
│  │           │Registered│  │5📷   │              │  │ Avatar:
│  │           └──────────┘  └──────┘              │  │ • Size: 48x48dp
│  │           📅 Oct 25, 2025                     │  │ • Border radius: 24dp
│  └───────────────────────────────────────────────┘  │
│                                                      │ Status Chip:
│  ┌───────────────────────────────────────────────┐  │ • Height: 24dp
│  │  ┌─────┐                                      │  │ • Padding: 8dp 12dp
│  │  │     │  Sarah Johnson                       │  │ • Border radius: 12dp
│  │  │ 👤  │  ID: 100012346                       │  │
│  │  │     │  Electrical Engineering              │  │ Frame Badge:
│  │  └─────┘                                      │  │ • Height: 24dp
│  │           ┌──────────┐  ┌──────┐              │  │ • Icon: 16x16dp
│  │           │Registered│  │5📷   │              │  │ • Padding: 4dp 8dp
│  │           └──────────┘  └──────┘              │  │
│  │           📅 Oct 24, 2025                     │  │
│  └───────────────────────────────────────────────┘  │
│                                                      │
│  ┌───────────────────────────────────────────────┐  │
│  │  ┌─────┐                                      │  │
│  │  │     │  Michael Brown                       │  │
│  │  │ 👤  │  ID: 100012347                       │  │
│  │  │     │  Mechanical Engineering              │  │
│  │  └─────┘                                      │  │
│  │           ┌──────────┐  ┌──────┐              │  │
│  │           │ Pending  │  │3📷   │              │  │
│  │           └──────────┘  └──────┘              │  │
│  │           📅 Oct 23, 2025                     │  │
│  └───────────────────────────────────────────────┘  │
│                                                      │
│              ⟳ Loading more students...             │ Infinite Scroll
│                                                      │ • Shows at 80% scroll
│                                                      │ • CircularProgressIndicator
└─────────────────────────────────────────────────────┘
```

### Student List Card - Component Breakdown

```dart
// StudentListCard Widget
Container(
  height: 120,
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: InkWell(
    onTap: () => navigateToDetail(student.id),
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          StudentAvatar(
            student: student,
            size: 48,
          ),
          SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Name
                Text(
                  student.fullName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                // Student ID
                Text(
                  'ID: ${student.studentId}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                // Department
                Text(
                  student.department ?? 'N/A',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                // Status and Frame Count
                Row(
                  children: [
                    StudentStatusChip(status: student.status),
                    SizedBox(width: 8),
                    FrameCountBadge(count: student.frameCount),
                  ],
                ),
                SizedBox(height: 4),
                // Date
                Text(
                  formatDate(student.registeredAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
)
```

---

### 2. Search Interface (Expanded)

```
┌─────────────────────────────────────────────────────┐
│ ← 🔍 Search students...                        ×    │ Search AppBar
│                                                      │ • Height: 56dp
└─────────────────────────────────────────────────────┘ • Auto-focus on open

┌─────────────────────────────────────────────────────┐
│ Recent Searches                                      │ Section Header
├─────────────────────────────────────────────────────┤ • Font: 12sp, bold
│ 🕐 John Smith                                   ×   │ • Color: textHint
│ 🕐 100012345                                    ×   │ • Padding: 16dp 8dp
│ 🕐 Computer Science                             ×   │
├─────────────────────────────────────────────────────┤
│ Suggestions                                          │ Recent Items:
├─────────────────────────────────────────────────────┤ • Tappable
│ 👤 Jane Smith                                       │ • X to remove
│    ID: 100012347 • Computer Science                │ • Icon: 🕐
│                                                      │
│ 👤 John Doe                                         │ Suggestions:
│    ID: 100012348 • Electrical Engineering          │ • Live from DB
│                                                      │ • Show as you type
│ 👤 Jennifer Brown                                   │ • Max 5 results
│    ID: 100012349 • Mechanical Engineering          │ • Highlight match
└─────────────────────────────────────────────────────┘
```

---

### 3. Filter Bottom Sheet (Detailed)

```
┌─────────────────────────────────────────────────────┐
│                                                      │ Drag Handle
│          ━━━━━━━━━━━                                │ • Width: 40dp
│                                                      │ • Height: 4dp
│      Filter Students                           ×    │ • Top: 8dp
│                                                      │
├─────────────────────────────────────────────────────┤
│ Status                                               │ Section: Status
│ ┌───────┐ ┌────────────┐ ┌──────────┐ ┌─────────┐ │ • Multi-select chips
│ │ All ✓ │ │Registered  │ │ Pending  │ │Incomp. │ │ • Toggle selection
│ └───────┘ └────────────┘ └──────────┘ └─────────┘ │ • Color by status
│ ┌──────────┐                                        │
│ │ Archived │                                        │ Chip Dimensions:
│ └──────────┘                                        │ • Height: 36dp
│                                                      │ • Padding: 12dp 16dp
├─────────────────────────────────────────────────────┤ • Border radius: 18dp
│ Department                                           │ • Border: 1dp when unselected
│ ┌─────────────────────────────────────────────┐    │ • Fill when selected
│ │ All Departments                         ⌄  │    │
│ └─────────────────────────────────────────────┘    │ Section: Department
│                                                      │ • Dropdown menu
├─────────────────────────────────────────────────────┤ • Height: 56dp
│ Registration Date Range                              │
│ ┌─────────────────────┐ ┌─────────────────────┐    │ Section: Date Range
│ │ 📅 Oct 1, 2025      │ │ 📅 Oct 26, 2025     │    │ • Date pickers
│ └─────────────────────┘ └─────────────────────┘    │ • Height: 56dp each
│ ┌─────┐ ┌─────────┐ ┌──────────┐ ┌──────┐         │
│ │Today│ │Last 7d  │ │ Last 30d │ │ All  │         │ Preset Chips:
│ └─────┘ └─────────┘ └──────────┘ └──────┘         │ • Quick select
│                                                      │ • Height: 32dp
├─────────────────────────────────────────────────────┤
│ Minimum Frame Count                                  │ Section: Frame Count
│ ├───────────●────────────────────┤                  │ • Slider
│ 0                3                5                  │ • Divisions: 5
│                                                      │ • Current: 3
├─────────────────────────────────────────────────────┤
│                                                      │
│ ┌─────────────────┐          ┌─────────────────┐   │ Actions
│ │     Reset       │          │  Apply (12)     │   │ • Height: 48dp
│ └─────────────────┘          └─────────────────┘   │ • Full width
│                                                      │ • Apply shows count
└─────────────────────────────────────────────────────┘
```

---

### 4. Student Detail Screen (Complete Layout)

```
┌─────────────────────────────────────────────────────┐
│ ←  John Smith                      ⋮  📤  🗑️       │ AppBar
│                                                      │ • Title: Student name
│                                                      │ • Actions: Menu, Export, Delete
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                  ┌─────────────┐                     │ Hero Section
│                  │             │                     │ • Background: Light gradient
│                  │     👤      │                     │ • Height: 240dp
│                  │             │                     │
│                  └─────────────┘                     │ Avatar:
│                                                      │ • Size: 120x120dp
│               John Smith                             │ • Border: 4dp white
│              ID: 100012345                           │ • Shadow
│                                                      │
│         ┌──────────────────────┐                    │ Status Chip:
│         │  ✅  Registered      │                    │ • Large variant
│         └──────────────────────┘                    │ • Height: 36dp
│                                                      │ • Font: 14sp
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  Student Information                                 │ Section Card
│  ━━━━━━━━━━━━━━━━━━                                │ • Margin: 16dp
├─────────────────────────────────────────────────────┤ • Padding: 16dp
│  📧 Email                                            │ • Elevation: 1dp
│     john.smith@university.edu                        │
│                                                      │ Info Row:
│  🎓 Department                                       │ • Icon: 24x24dp
│     Computer Science                                 │ • Label: 12sp, gray
│                                                      │ • Value: 14sp, dark
│  📚 Program                                          │ • Spacing: 12dp
│     Bachelor of Science                              │
│                                                      │
│  🎂 Date of Birth                                    │
│     January 15, 2000                                 │
│                                                      │
│  📅 Registered On                                    │
│     October 25, 2025 at 2:45 PM                     │
│                                                      │
│  👤 Registered By                                    │
│     Admin User (admin001)                            │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  Captured Poses (5 frames)                           │ Section Header
│  ━━━━━━━━━━━━━━━━━━━━━━━━                          │ • Font: 18sp, bold
├─────────────────────────────────────────────────────┤ • Margin: 16dp top
│                                                      │
│  ┌────────────────────┐  ┌────────────────────┐    │ Frame Grid
│  │                    │  │                    │    │ • 2 columns
│  │                    │  │                    │    │ • Aspect ratio: 3:4
│  │      Image 1       │  │      Image 2       │    │ • Gap: 12dp
│  │                    │  │                    │    │ • Border radius: 8dp
│  │                    │  │                    │    │
│  └────────────────────┘  └────────────────────┘    │ Image:
│  Frontal                 Left Profile               │ • Cached loading
│  ┌───────────┐           ┌───────────┐             │ • Progressive blur
│  │ ⭐ 92%    │           │ ⭐ 88%    │             │ • Tap to expand
│  └───────────┘           └───────────┘             │
│  Oct 25, 2:45 PM         Oct 25, 2:45 PM           │ Pose Label:
│                                                      │ • Font: 12sp, bold
│  ┌────────────────────┐  ┌────────────────────┐    │ • Color: textPrimary
│  │                    │  │                    │    │
│  │                    │  │                    │    │ Quality Badge:
│  │      Image 3       │  │      Image 4       │    │ • Background: Green
│  │                    │  │                    │    │ • Icon: ⭐
│  │                    │  │                    │    │ • Font: 11sp, white
│  └────────────────────┘  └────────────────────┘    │ • Padding: 4dp 8dp
│  Right Profile           Looking Up                 │ • Border radius: 12dp
│  ┌───────────┐           ┌───────────┐             │
│  │ ⭐ 85%    │           │ ⭐ 90%    │             │ Timestamp:
│  └───────────┘           └───────────┘             │ • Font: 11sp
│  Oct 25, 2:46 PM         Oct 25, 2:46 PM           │ • Color: textHint
│                                                      │
│  ┌────────────────────┐                             │
│  │                    │                             │
│  │                    │                             │
│  │      Image 5       │                             │
│  │                    │                             │
│  │                    │                             │
│  └────────────────────┘                             │
│  Looking Down                                        │
│  ┌───────────┐                                      │
│  │ ⭐ 87%    │                                      │
│  └───────────┘                                      │
│  Oct 25, 2:46 PM                                    │
│                                                      │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                                                      │ Bottom Padding
│                                                      │ • Height: 24dp
└─────────────────────────────────────────────────────┘
```

---

### 5. Frame Gallery Viewer (Full Screen)

```
┌─────────────────────────────────────────────────────┐
│ ×                                              ⋮    │ Overlay Controls
│                                                      │ • Auto-hide: 3s
│                                                      │ • Black bg: 80% opacity
│                                                      │ • Tap to toggle
│                                                      │
│                                                      │
│                                                      │
│                                                      │
│                                                      │
│                  Full-Size Image                     │ Image Viewer
│                  (Pinch to Zoom)                     │ • PageView
│                                                      │ • Min zoom: 1x
│                                                      │ • Max zoom: 5x
│                                                      │ • Double-tap: Toggle fit/zoom
│                                                      │ • Drag to pan when zoomed
│                                                      │
│                                                      │
│                                                      │
│                                                      │
│              ○ ○ ● ○ ○                              │ Page Indicator
│                                                      │ • Active: Larger dot
│              Frame 3 of 5                            │ • Inactive: Small dots
│                                                      │ • Color: White 80%
│  ┌───────────────────────────────────────────────┐  │
│  │  Right Profile Pose                           │  │ Metadata Overlay
│  │  ⭐ Quality Score: 85%                        │  │ • Background: Black 60%
│  │  📅 October 25, 2025 at 2:46 PM              │  │ • Padding: 16dp
│  │  📏 Dimensions: 1080 × 1440                   │  │ • Border radius: 12dp top
│  └───────────────────────────────────────────────┘  │ • Slide up gesture
│                                                      │
└─────────────────────────────────────────────────────┘

Gestures:
• Swipe ← → : Navigate frames
• Pinch: Zoom in/out
• Double-tap: Toggle zoom
• Drag: Pan when zoomed
• Tap: Toggle overlays
• Swipe down: Close viewer (if not zoomed)
```

---

### 6. Empty States

#### No Students
```
┌─────────────────────────────────────────────────────┐
│                                                      │
│                      📋                              │ Illustration
│              (Empty clipboard icon)                  │ • Size: 120x120dp
│                                                      │ • Color: Gray 300
│              No Students Found                       │
│                                                      │ Title:
│       No registered students yet.                    │ • Font: 18sp, bold
│     Start by registering your first student!         │ • Color: textPrimary
│                                                      │
│       ┌─────────────────────────────┐               │ Message:
│       │   📷 Register First Student │               │ • Font: 14sp
│       └─────────────────────────────┘               │ • Color: textSecondary
│                                                      │
│                                                      │ Button:
│                                                      │ • Height: 48dp
│                                                      │ • Border radius: 24dp
│                                                      │ • Background: primaryBlue
└─────────────────────────────────────────────────────┘
```

#### No Search Results
```
┌─────────────────────────────────────────────────────┐
│                                                      │
│                      🔍                              │ Illustration
│              (Magnifying glass icon)                 │ • Size: 120x120dp
│                                                      │ • Color: Gray 300
│            No Results Found                          │
│                                                      │ Title:
│     No students match your search for:               │ • Font: 18sp, bold
│              "nonexistent"                           │
│                                                      │ Search Term:
│     Try searching with a different term.             │ • Font: 16sp, italic
│                                                      │ • Color: primaryBlue
│       ┌─────────────────────────────┐               │
│       │      Clear Search           │               │ Message:
│       └─────────────────────────────┘               │ • Font: 14sp
│                                                      │ • Color: textSecondary
└─────────────────────────────────────────────────────┘
```

---

## Widget Component Specifications

### StudentAvatar
```dart
Widget StudentAvatar({
  required Student student,
  double size = 48.0,
  bool showStatus = false,
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: _getAvatarColor(student),
      border: Border.all(
        color: Colors.white,
        width: size > 100 ? 4 : 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Stack(
      children: [
        // Avatar content (initials or image)
        Center(
          child: Text(
            _getInitials(student.fullName),
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        // Status indicator (optional)
        if (showStatus)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: _getStatusColor(student.status),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

// Helper: Get avatar background color from name
Color _getAvatarColor(Student student) {
  final colors = [
    Color(0xFF1976D2), // Blue
    Color(0xFF388E3C), // Green
    Color(0xFFD32F2F), // Red
    Color(0xFFF57C00), // Orange
    Color(0xFF7B1FA2), // Purple
    Color(0xFF0097A7), // Cyan
  ];
  return colors[student.fullName.hashCode % colors.length];
}

// Helper: Extract initials
String _getInitials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return parts[0][0].toUpperCase();
}
```

### StudentStatusChip
```dart
Widget StudentStatusChip({required StudentStatus status}) {
  final config = _getStatusConfig(status);
  
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: config.backgroundColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          config.icon,
          size: 14,
          color: config.textColor,
        ),
        SizedBox(width: 4),
        Text(
          config.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: config.textColor,
          ),
        ),
      ],
    ),
  );
}

class _StatusConfig {
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final String label;
  
  _StatusConfig(this.backgroundColor, this.textColor, this.icon, this.label);
}

_StatusConfig _getStatusConfig(StudentStatus status) {
  switch (status) {
    case StudentStatus.registered:
      return _StatusConfig(
        Color(0xFFE8F5E9), // Light green
        Color(0xFF2E7D32), // Dark green
        Icons.check_circle,
        'Registered',
      );
    case StudentStatus.pending:
      return _StatusConfig(
        Color(0xFFFFF3E0), // Light orange
        Color(0xFFEF6C00), // Dark orange
        Icons.schedule,
        'Pending',
      );
    case StudentStatus.incomplete:
      return _StatusConfig(
        Color(0xFFFFEBEE), // Light red
        Color(0xFFC62828), // Dark red
        Icons.error,
        'Incomplete',
      );
    case StudentStatus.archived:
      return _StatusConfig(
        Color(0xFFF5F5F5), // Light gray
        Color(0xFF616161), // Dark gray
        Icons.archive,
        'Archived',
      );
  }
}
```

### QualityScoreBadge
```dart
Widget QualityScoreBadge({required double score}) {
  final color = _getQualityColor(score);
  final percentage = (score * 100).toInt();
  
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          size: 14,
          color: Colors.white,
        ),
        SizedBox(width: 4),
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

Color _getQualityColor(double score) {
  if (score >= 0.9) return Color(0xFF2E7D32);  // Excellent: Green
  if (score >= 0.75) return Color(0xFF689F38); // Good: Light green
  if (score >= 0.6) return Color(0xFFFBC02D);  // Fair: Yellow
  return Color(0xFFEF6C00);                     // Poor: Orange
}
```

---

## Animation Specifications

### Page Transitions
```dart
// Student list → Student detail
PageRouteBuilder(
  transitionDuration: Duration(milliseconds: 300),
  pageBuilder: (context, animation, secondaryAnimation) {
    return StudentDetailScreen(studentId: id);
  },
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: child,
    );
  },
);
```

### Hero Animation (Frame Thumbnail → Gallery)
```dart
// In StudentDetailScreen
Hero(
  tag: 'frame_${frame.id}',
  child: FrameThumbnail(frame: frame),
)

// In FrameGalleryViewer
Hero(
  tag: 'frame_${frame.id}',
  child: Image.file(File(frame.imageFilePath)),
)
```

### Skeleton Loader
```dart
Shimmer.fromColors(
  baseColor: Colors.grey[300]!,
  highlightColor: Colors.grey[100]!,
  child: Column(
    children: List.generate(5, (index) => 
      Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  ),
)
```

---

## Responsive Breakpoints

```dart
class ResponsiveBreakpoints {
  // Phone: < 600dp
  static const double phone = 600;
  
  // Tablet: 600dp - 840dp
  static const double tablet = 840;
  
  // Desktop: > 840dp
  static const double desktop = 840;
  
  static bool isPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < phone;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= phone && width < desktop;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }
  
  // Grid columns based on screen size
  static int getGridColumns(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 3;
    return 2;
  }
}
```

---

## Summary

This visual mockup guide provides:
- ✅ Complete color palette with hex codes
- ✅ Typography scale with font sizes and weights
- ✅ Component dimensions and spacing
- ✅ Detailed ASCII mockups for all screens
- ✅ Widget implementation code
- ✅ Animation specifications
- ✅ Responsive design guidelines

**Use this document alongside `STUDENT_MANAGEMENT_MODULE_DESIGN.md` for implementation.**

Ready to build beautiful, consistent UIs! 🎨
