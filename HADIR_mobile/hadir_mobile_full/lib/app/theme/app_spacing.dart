import 'package:flutter/material.dart';

/// Global spacing constants for HADIR application
/// Ensures consistent spacing across all screens
class AppSpacing {
  AppSpacing._(); // Private constructor

  // Base spacing unit (4px)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
  
  // Padding presets
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);
  
  // Horizontal padding
  static const EdgeInsets paddingHorizontalMD = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLG = EdgeInsets.symmetric(horizontal: lg);
  
  // Vertical padding
  static const EdgeInsets paddingVerticalMD = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLG = EdgeInsets.symmetric(vertical: lg);
}

/// Global border radius constants
class AppRadius {
  AppRadius._(); // Private constructor

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 30.0;
  
  // Circular border radius presets
  static BorderRadius circularSM = BorderRadius.circular(sm);
  static BorderRadius circularMD = BorderRadius.circular(md);
  static BorderRadius circularLG = BorderRadius.circular(lg);
  static BorderRadius circularXL = BorderRadius.circular(xl);
  static BorderRadius circularXXL = BorderRadius.circular(xxl);
  static BorderRadius circularXXXL = BorderRadius.circular(xxxl);
  
  // Top-only border radius
  static BorderRadius topXXXL = const BorderRadius.only(
    topLeft: Radius.circular(xxxl),
    topRight: Radius.circular(xxxl),
  );
}

/// Global elevation/shadow constants
class AppElevation {
  AppElevation._(); // Private constructor

  // Box shadow presets
  static List<BoxShadow> shadowSM = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> shadowMD = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> shadowLG = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];
  
  // Colored shadows (for gradient cards)
  static List<BoxShadow> coloredShadow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.25),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];
}
