import 'dart:io';
import 'dart:async';

/// Utility class for basic helper functions used throughout the app
class AppHelpers {
  /// Format file size in human readable format
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (bytes.bitLength - 1) ~/ 10;
    if (i >= suffixes.length) i = suffixes.length - 1;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// Format duration in human readable format
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  /// Generate unique filename with timestamp
  static String generateFileName({
    required String prefix,
    String extension = 'jpg',
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$timestamp.$extension';
  }

  /// Calculate image file size
  static Future<int> getImageSize(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      print('Error calculating image size: $e');
      return 0;
    }
  }

  /// Check if network is available
  static Future<bool> isNetworkAvailable() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Validate student ID format
  static bool isValidStudentId(String studentId) {
    // Basic validation - adjust based on your institution's format
    if (studentId.isEmpty || studentId.length < 6) return false;
    // Check if contains only numbers and letters
    final regex = RegExp(r'^[a-zA-Z0-9]+$');
    return regex.hasMatch(studentId);
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  /// Capitalize first letter of each word
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Get initials from full name
  static String getInitials(String fullName) {
    if (fullName.isEmpty) return '';
    final names = fullName.trim().split(' ');
    if (names.length == 1) {
      return names[0][0].toUpperCase();
    }
    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }

  /// Generate a simple UUID-like string
  static String generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (1000 + (9000 * (timestamp % 1000) / 1000)).floor();
    return '${timestamp}_$random';
  }

  /// Sanitize filename to be filesystem safe
  static String sanitizeFilename(String filename) {
    // Replace invalid characters with underscores
    return filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  /// Check if string is empty or null
  static bool isNullOrEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// Safe string conversion
  static String safeString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString();
  }
}