# HADIR Design System - Quick Reference

## 🎯 Import This in Every Screen

```dart
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
```

## 🎨 Colors - Most Common

| Usage | Code |
|-------|------|
| Primary gradient | `AppColors.primaryGradient` |
| White background | `AppColors.backgroundWhite` |
| Dark text | `AppColors.textDark` |
| Medium text | `AppColors.textMedium` |
| Light text | `AppColors.textLight` |

## 📏 Spacing - Most Common

| Size | Code | Value |
|------|------|-------|
| Small gap | `AppSpacing.sm` | 8px |
| Default gap | `AppSpacing.md` | 16px |
| Large gap | `AppSpacing.lg` | 24px |
| Extra large | `AppSpacing.xl` | 32px |
| Section spacing | `AppSpacing.xxl` | 48px |

**Padding:**
```dart
padding: AppSpacing.paddingLG    // 24px all sides
padding: AppSpacing.paddingMD    // 16px all sides
```

**Border Radius:**
```dart
borderRadius: AppRadius.circularXL     // 20px - Cards
borderRadius: AppRadius.circularXXXL   // 30px - Large containers
```

## 📝 Text Styles - Most Common

| Usage | Code |
|-------|------|
| Page title | `AppTextStyles.displayLarge` |
| Section header | `AppTextStyles.displaySmall` |
| Subsection | `AppTextStyles.headingLarge` |
| Card title | `AppTextStyles.headingMedium` |
| Body text | `AppTextStyles.bodyMedium` |
| Small text | `AppTextStyles.bodySmall` |
| White card title | `AppTextStyles.cardTitle` |
| White description | `AppTextStyles.cardDescription` |

## 🏗️ Standard Layout Pattern

```dart
Scaffold(
  body: Container(
    decoration: BoxDecoration(gradient: AppColors.primaryGradient),
    child: SafeArea(
      child: Column(
        children: [
          // Header with gradient background
          Padding(
            padding: AppSpacing.paddingLG,
            child: /* Header content */
          ),
          
          SizedBox(height: AppSpacing.lg),
          
          // White content area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: AppRadius.topXXXL,
              ),
              child: SingleChildScrollView(
                padding: AppSpacing.paddingLG,
                child: /* Main content */
              ),
            ),
          ),
        ],
      ),
    ),
  ),
)
```

## 🎴 Card Pattern

### Gradient Action Card
```dart
Container(
  height: 180,
  decoration: BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: AppRadius.circularXL,
    boxShadow: AppElevation.coloredShadow(AppColors.primaryIndigo),
  ),
  padding: AppSpacing.paddingLG,
  child: /* Card content */
)
```

### White Stat Card
```dart
Container(
  height: 130,
  decoration: BoxDecoration(
    color: AppColors.backgroundWhite,
    borderRadius: AppRadius.circularXL,
    boxShadow: AppElevation.shadowMD,
  ),
  padding: AppSpacing.paddingLG,
  child: /* Card content */
)
```

## ✅ Quick Checklist

Before committing code, ensure:
- [ ] No hardcoded colors
- [ ] No hardcoded spacing values
- [ ] No hardcoded text styles
- [ ] Proper contrast (dark text on white, white text on colors)
- [ ] Consistent spacing (md between items, xl between sections)
- [ ] Consistent border radius (xl for cards)

## 🚀 Common Patterns

**Spacing between sections:**
```dart
SizedBox(height: AppSpacing.xl)  // 32px
```

**Spacing between items:**
```dart
SizedBox(height: AppSpacing.md)  // 16px
```

**Two-column layout:**
```dart
Row(
  children: [
    Expanded(child: Widget1()),
    SizedBox(width: AppSpacing.md),
    Expanded(child: Widget2()),
  ],
)
```

**White text on gradient:**
```dart
Text(
  'Title',
  style: AppTextStyles.cardTitle,  // Already white
)
```

**Dark text on white:**
```dart
Text(
  'Title',
  style: AppTextStyles.displayLarge,  // Already dark
)
```

---

**Pro Tip**: Keep this reference open while coding!

**Full Documentation**: See `DESIGN_SYSTEM.md`
