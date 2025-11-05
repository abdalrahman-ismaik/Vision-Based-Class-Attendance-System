/// Business logic validation services for HADIR mobile app
/// Provides reusable validation logic for use cases and business operations
library;

class ValidationService {
  const ValidationService._();
  
  static const ValidationService instance = ValidationService._();

  /// Validate student ID format
  /// Student ID should be alphanumeric, 6-12 characters
  ValidationResult validateStudentId(String studentId) {
    if (studentId.trim().isEmpty) {
      return ValidationResult.error('Student ID is required');
    }
    
    if (studentId.length < 6 || studentId.length > 12) {
      return ValidationResult.error('Student ID must be 6-12 characters long');
    }
    
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(studentId)) {
      return ValidationResult.error('Student ID can only contain letters and numbers');
    }
    
    return ValidationResult.valid();
  }

  /// Validate full name
  ValidationResult validateFullName(String fullName) {
    if (fullName.trim().isEmpty) {
      return ValidationResult.error('Full name is required');
    }
    
    if (fullName.trim().length < 2) {
      return ValidationResult.error('Full name must be at least 2 characters');
    }
    
    if (fullName.trim().length > 100) {
      return ValidationResult.error('Full name cannot exceed 100 characters');
    }
    
    // Allow letters, spaces, hyphens, and apostrophes
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(fullName.trim())) {
      return ValidationResult.error('Full name can only contain letters, spaces, hyphens, and apostrophes');
    }
    
    return ValidationResult.valid();
  }

  /// Validate email address
  ValidationResult validateEmail(String email) {
    if (email.trim().isEmpty) {
      return ValidationResult.error('Email is required');
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(email.trim())) {
      return ValidationResult.error('Please enter a valid email address');
    }
    
    return ValidationResult.valid();
  }

  /// Validate phone number
  ValidationResult validatePhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return ValidationResult.valid(); // Phone number is optional
    }
    
    // Remove all non-digit characters for validation
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return ValidationResult.error('Phone number must be 10-15 digits');
    }
    
    return ValidationResult.valid();
  }

  /// Validate date of birth
  ValidationResult validateDateOfBirth(DateTime dateOfBirth) {
    final now = DateTime.now();
    final age = now.year - dateOfBirth.year;
    
    if (dateOfBirth.isAfter(now)) {
      return ValidationResult.error('Date of birth cannot be in the future');
    }
    
    if (age < 16) {
      return ValidationResult.error('Student must be at least 16 years old');
    }
    
    if (age > 100) {
      return ValidationResult.error('Please enter a valid date of birth');
    }
    
    return ValidationResult.valid();
  }

  /// Validate department name
  ValidationResult validateDepartment(String department) {
    if (department.trim().isEmpty) {
      return ValidationResult.error('Department is required');
    }
    
    if (department.trim().length < 2) {
      return ValidationResult.error('Department name must be at least 2 characters');
    }
    
    if (department.trim().length > 100) {
      return ValidationResult.error('Department name cannot exceed 100 characters');
    }
    
    return ValidationResult.valid();
  }

  /// Validate program name
  ValidationResult validateProgram(String program) {
    if (program.trim().isEmpty) {
      return ValidationResult.error('Program is required');
    }
    
    if (program.trim().length < 2) {
      return ValidationResult.error('Program name must be at least 2 characters');
    }
    
    if (program.trim().length > 100) {
      return ValidationResult.error('Program name cannot exceed 100 characters');
    }
    
    return ValidationResult.valid();
  }

  /// Validate enrollment year
  ValidationResult validateEnrollmentYear(int? enrollmentYear) {
    if (enrollmentYear == null) {
      return ValidationResult.valid(); // Enrollment year is optional
    }
    
    final currentYear = DateTime.now().year;
    
    if (enrollmentYear < 1900 || enrollmentYear > currentYear + 1) {
      return ValidationResult.error('Please enter a valid enrollment year');
    }
    
    return ValidationResult.valid();
  }

  /// Validate username for administrators
  ValidationResult validateUsername(String username) {
    if (username.trim().isEmpty) {
      return ValidationResult.error('Username is required');
    }
    
    if (username.length < 3 || username.length > 30) {
      return ValidationResult.error('Username must be 3-30 characters long');
    }
    
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return ValidationResult.error('Username can only contain letters, numbers, and underscores');
    }
    
    return ValidationResult.valid();
  }

  /// Validate password strength
  ValidationResult validatePassword(String password) {
    if (password.isEmpty) {
      return ValidationResult.error('Password is required');
    }
    
    if (password.length < 8) {
      return ValidationResult.error('Password must be at least 8 characters long');
    }
    
    if (password.length > 128) {
      return ValidationResult.error('Password cannot exceed 128 characters');
    }
    
    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return ValidationResult.error('Password must contain at least one uppercase letter');
    }
    
    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return ValidationResult.error('Password must contain at least one lowercase letter');
    }
    
    // Check for at least one digit
    if (!RegExp(r'\d').hasMatch(password)) {
      return ValidationResult.error('Password must contain at least one number');
    }
    
    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return ValidationResult.error('Password must contain at least one special character (!@#\$%^&*(),.?":{}|<>)');
    }
    
    return ValidationResult.valid();
  }

  /// Validate session ID format
  ValidationResult validateSessionId(String sessionId) {
    if (sessionId.trim().isEmpty) {
      return ValidationResult.error('Session ID is required');
    }
    
    if (!RegExp(r'^REG\d{8,}$').hasMatch(sessionId)) {
      return ValidationResult.error('Invalid session ID format');
    }
    
    return ValidationResult.valid();
  }

  /// Validate frame quality score
  ValidationResult validateQualityScore(double qualityScore) {
    if (qualityScore < 0.0 || qualityScore > 1.0) {
      return ValidationResult.error('Quality score must be between 0.0 and 1.0');
    }
    
    return ValidationResult.valid();
  }

  /// Validate confidence score
  ValidationResult validateConfidenceScore(double confidenceScore) {
    if (confidenceScore < 0.0 || confidenceScore > 1.0) {
      return ValidationResult.error('Confidence score must be between 0.0 and 1.0');
    }
    
    return ValidationResult.valid();
  }
}

/// Result of a validation operation
class ValidationResult {
  const ValidationResult._({
    required this.isValid,
    this.errorMessage,
  });

  const ValidationResult._valid() : this._(isValid: true);
  
  const ValidationResult._error(String message) : this._(
    isValid: false,
    errorMessage: message,
  );

  final bool isValid;
  final String? errorMessage;

  /// Create a valid result
  factory ValidationResult.valid() => const ValidationResult._valid();

  /// Create an error result
  factory ValidationResult.error(String message) => ValidationResult._error(message);

  /// Get error message or empty string if valid
  String get message => errorMessage ?? '';

  @override
  String toString() => isValid ? 'Valid' : 'Invalid: $errorMessage';
}