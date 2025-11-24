import 'package:flutter/material.dart';

/// Global color palette for HADIR application
/// This ensures consistent colors across all screens
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Brand Colors
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryBlue = Color(0xFF3B82F6);
  
  // Secondary Colors
  static const Color secondaryCyan = Color(0xFF06B6D4);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color secondaryPurple = Color(0xFF8B5CF6);
  
  // Success Colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color successEmerald = Color(0xFF059669);
  
  // Warning/Accent Colors
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningRed = Color(0xFFEF4444);
  static const Color accentOrange = Color(0xFFF97316);
  
  // Neutral Colors
  static const Color textDark = Color(0xFF111827);      // gray-900
  static const Color textMedium = Color(0xFF374151);    // gray-700
  static const Color textLight = Color(0xFF6B7280);     // gray-500
  static const Color textSubtle = Color(0xFF9CA3AF);    // gray-400
  static const Color textSecondary = Color(0xFF6B7280); // gray-500
  
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF9FAFB); // gray-50
  static const Color backgroundGray = Color(0xFFF3F4F6);  // gray-100
  
  static const Color borderLight = Color(0xFFE5E7EB);    // gray-200
  static const Color borderMedium = Color(0xFFD1D5DB);   // gray-300
  
  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryIndigo, primaryPurple],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryCyan, secondaryBlue],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successGreen, successEmerald],
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warningAmber, warningRed],
  );
}
