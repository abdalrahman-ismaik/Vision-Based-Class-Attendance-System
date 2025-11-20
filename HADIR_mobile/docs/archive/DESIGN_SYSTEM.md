# HADIR Mobile Design System

## Overview
This design system ensures visual consistency, proper alignment, spacing, typography, and color usage across all screens in the HADIR Mobile application.

---

## 🎨 Colors (`lib/app/theme/app_colors.dart`)

### Primary Brand Colors
```dart
AppColors.primaryIndigo    // #6366F1 - Main brand color
AppColors.primaryPurple    // #8B5CF6 - Secondary brand color
```

### Secondary Colors
```dart
AppColors.secondaryCyan    // #06B6D4 - Action/Info
AppColors.secondaryBlue    // #3B82F6 - Links/Interactive
```

### Success Colors
```dart
AppColors.successGreen     // #10B981 - Success states
AppColors.successEmerald   // #059669 - Success gradient
```

### Warning/Accent Colors
```dart
AppColors.warningAmber     // #F59E0B - Warnings
AppColors.warningRed       // #EF4444 - Alerts/Important
```

### Text Colors
```dart
AppColors.textDark         // #111827 - Primary headings
AppColors.textMedium       // #374151 - Body text
AppColors.textLight        // #6B7280 - Secondary text
AppColors.textSubtle       // #9CA3AF - Hints/disabled
```

### Background Colors
```dart
AppColors.backgroundWhite  // #FFFFFF - Main background
AppColors.backgroundLight  // #F9FAFB - Subtle background
AppColors.backgroundGray   // #F3F4F6 - Cards/containers
```

### Border Colors
```dart
AppColors.borderLight      // #E5E7EB - Dividers
AppColors.borderMedium     // #D1D5DB - Input borders
```

### Gradients
```dart
AppColors.primaryGradient    // Indigo → Purple
AppColors.secondaryGradient  // Cyan → Blue
AppColors.successGradient    // Green → Emerald
AppColors.warningGradient    // Amber → Red
```

**Usage Example:**
```dart
Container(
  decoration: BoxDecoration(
    gradient: AppColors.primaryGradient,
  ),
  child: Text(
    'HADIR',
    style: TextStyle(color: AppColors.textDark),
  ),
)
```

---

## 📏 Spacing (`lib/app/theme/app_spacing.dart`)

### Spacing Scale
```dart
AppSpacing.xs    // 4px  - Tight spacing
AppSpacing.sm    // 8px  - Small spacing
AppSpacing.md    // 16px - Default spacing
AppSpacing.lg    // 24px - Large spacing
AppSpacing.xl    // 32px - Extra large
AppSpacing.xxl   // 48px - Section spacing
AppSpacing.xxxl  // 64px - Major sections
```

### Padding Presets
```dart
AppSpacing.paddingXS                 // All sides: 4px
AppSpacing.paddingSM                 // All sides: 8px
AppSpacing.paddingMD                 // All sides: 16px
AppSpacing.paddingLG                 // All sides: 24px
AppSpacing.paddingXL                 // All sides: 32px

AppSpacing.paddingHorizontalMD      // Horizontal: 16px
AppSpacing.paddingHorizontalLG      // Horizontal: 24px

AppSpacing.paddingVerticalMD        // Vertical: 16px
AppSpacing.paddingVerticalLG        // Vertical: 24px
```

### Border Radius
```dart
AppRadius.sm         // 8px  - Small corners
AppRadius.md         // 12px - Default corners
AppRadius.lg         // 16px - Large corners
AppRadius.xl         // 20px - Extra large
AppRadius.xxl        // 24px - Very rounded
AppRadius.xxxl       // 30px - Maximum rounding

// Preset BorderRadius objects
AppRadius.circularSM
AppRadius.circularMD
AppRadius.circularLG
AppRadius.circularXL
AppRadius.circularXXL
AppRadius.circularXXXL

// Top-only border radius
AppRadius.topXXXL    // Top corners only
```

### Elevation/Shadows
```dart
AppElevation.shadowSM    // Subtle shadow
AppElevation.shadowMD    // Default shadow
AppElevation.shadowLG    // Prominent shadow

// Colored shadows for gradient cards
AppElevation.coloredShadow(AppColors.primaryIndigo)
```

**Usage Example:**
```dart
Container(
  padding: AppSpacing.paddingLG,
  decoration: BoxDecoration(
    borderRadius: AppRadius.circularXL,
    boxShadow: AppElevation.shadowMD,
  ),
  child: Column(
    children: [
      Text('Title'),
      SizedBox(height: AppSpacing.md),
      Text('Content'),
    ],
  ),
)
```

---

## 📝 Typography (`lib/app/theme/app_text_styles.dart`)

### Display Styles (Headers)
```dart
AppTextStyles.displayLarge    // 32px, w900 - Page titles
AppTextStyles.displayMedium   // 28px, w800 - Large headers
AppTextStyles.displaySmall    // 24px, w700 - Section headers
```

### Heading Styles
```dart
AppTextStyles.headingLarge    // 20px, w700 - Subsections
AppTextStyles.headingMedium   // 18px, w600 - Card titles
AppTextStyles.headingSmall    // 16px, w600 - Small headers
```

### Body Text
```dart
AppTextStyles.bodyLarge       // 16px, w400 - Large body text
AppTextStyles.bodyMedium      // 14px, w400 - Default body text
AppTextStyles.bodySmall       // 13px, w400 - Small body text
```

### Labels
```dart
AppTextStyles.labelLarge      // 14px, w600 - Form labels
AppTextStyles.labelMedium     // 13px, w500 - Secondary labels
AppTextStyles.labelSmall      // 12px, w500 - Captions/hints
```

### Buttons
```dart
AppTextStyles.button          // 16px, w600 - Default buttons
AppTextStyles.buttonSmall     // 14px, w600 - Small buttons
```

### Special Card Styles
```dart
AppTextStyles.cardTitle       // 20px, w900, white - Action card titles
AppTextStyles.cardDescription // 14px, w600, white - Action card descriptions
AppTextStyles.statValue       // 36px, w900 - Stat numbers
AppTextStyles.statLabel       // 14px, w700 - Stat labels
```

**Usage Example:**
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('Page Title', style: AppTextStyles.displayLarge),
    SizedBox(height: AppSpacing.sm),
    Text('Subtitle', style: AppTextStyles.bodyMedium),
  ],
)
```

---

## 🏗️ Layout Patterns

### Screen Structure
```dart
Scaffold(
  body: Container(
    decoration: BoxDecoration(
      gradient: AppColors.primaryGradient, // Header gradient
    ),
    child: SafeArea(
      child: Column(
        children: [
          // Header section
          Padding(
            padding: AppSpacing.paddingLG,
            child: // Header content
          ),
          
          // Main content with white background
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: AppRadius.topXXXL,
              ),
              child: SingleChildScrollView(
                padding: AppSpacing.paddingLG,
                child: // Main content
              ),
            ),
          ),
        ],
      ),
    ),
  ),
)
```

### Card Layout
```dart
// Action Card (Gradient background)
Container(
  height: 180,
  decoration: BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: AppRadius.circularXL,
    boxShadow: AppElevation.coloredShadow(AppColors.primaryIndigo),
  ),
  padding: AppSpacing.paddingLG,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Icon container
      // Title and description
    ],
  ),
)

// Stat Card (White background)
Container(
  height: 130,
  decoration: BoxDecoration(
    color: AppColors.backgroundWhite,
    borderRadius: AppRadius.circularXL,
    boxShadow: AppElevation.shadowMD,
  ),
  padding: AppSpacing.paddingLG,
  child: // Card content
)
```

### Grid Layout (2 columns)
```dart
Row(
  children: [
    Expanded(child: Card1()),
    SizedBox(width: AppSpacing.md),
    Expanded(child: Card2()),
  ],
)
```

---

## ✅ Best Practices

### 1. **Always Use Design System Constants**
❌ Don't:
```dart
Container(
  padding: EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: Color(0xFF6366F1),
    borderRadius: BorderRadius.circular(20),
  ),
)
```

✅ Do:
```dart
Container(
  padding: AppSpacing.paddingLG,
  decoration: BoxDecoration(
    color: AppColors.primaryIndigo,
    borderRadius: AppRadius.circularXL,
  ),
)
```

### 2. **Text Contrast**
- White text on colored backgrounds: Use `AppTextStyles.cardTitle` and `AppTextStyles.cardDescription`
- Dark text on white: Use `AppColors.textDark` or `AppColors.textMedium`
- Always ensure WCAG AA compliance (4.5:1 contrast ratio minimum)

### 3. **Spacing Consistency**
- Between sections: `AppSpacing.xl` (32px)
- Between elements: `AppSpacing.md` (16px)
- Within elements: `AppSpacing.sm` (8px)
- Micro spacing: `AppSpacing.xs` (4px)

### 4. **Shadow Usage**
- Cards on white background: `AppElevation.shadowMD`
- Gradient cards: `AppElevation.coloredShadow(color)`
- Floating elements: `AppElevation.shadowLG`

### 5. **Border Radius Consistency**
- Small elements (icons, buttons): `AppRadius.circularMD` (12px)
- Cards: `AppRadius.circularXL` (20px)
- Large containers: `AppRadius.circularXXXL` (30px)

---

## 🎯 Implementation Checklist

When creating a new screen, ensure:

- [ ] Import design system files:
  ```dart
  import '../../../../app/theme/app_colors.dart';
  import '../../../../app/theme/app_spacing.dart';
  import '../../../../app/theme/app_text_styles.dart';
  ```

- [ ] Use `AppColors` for all colors
- [ ] Use `AppSpacing` for all spacing/padding
- [ ] Use `AppRadius` for all border radius
- [ ] Use `AppTextStyles` for all text
- [ ] Use `AppElevation` for all shadows
- [ ] Follow the standard layout pattern
- [ ] Test contrast ratios
- [ ] Ensure responsive behavior
- [ ] Test on different screen sizes

---

## 📱 Example: Full Screen Implementation

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

class ExamplePage extends StatelessWidget {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: AppSpacing.paddingLG,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Page Title',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: AppSpacing.lg),
              
              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: AppRadius.topXXXL,
                  ),
                  child: SingleChildScrollView(
                    padding: AppSpacing.paddingLG,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Section Title', style: AppTextStyles.headingLarge),
                        SizedBox(height: AppSpacing.md),
                        Text('Content goes here', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
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

## 🔄 Updates and Maintenance

- All design system updates should be made in the `lib/app/theme/` directory
- Document any additions to this file
- Maintain backward compatibility when updating
- Version control all design system changes
- Communicate changes to the team

---

**Last Updated:** October 27, 2025  
**Version:** 1.0.0  
**Maintained by:** HADIR Development Team
