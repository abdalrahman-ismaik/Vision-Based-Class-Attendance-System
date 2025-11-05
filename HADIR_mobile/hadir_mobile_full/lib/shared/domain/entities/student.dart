import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Enumeration for student academic levels
enum AcademicLevel {
  undergraduate,
  graduate,
  postgraduate,
  phd;

  @override
  String toString() {
    switch (this) {
      case AcademicLevel.undergraduate:
        return 'Undergraduate';
      case AcademicLevel.graduate:
        return 'Graduate';
      case AcademicLevel.postgraduate:
        return 'Postgraduate';
      case AcademicLevel.phd:
        return 'PhD';
    }
  }
}

/// Enumeration for student gender
enum Gender {
  male,
  female,
  other;

  @override
  String toString() {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }
}

/// Enumeration for student status
enum StudentStatus {
  pending,
  registered,
  incomplete,
  archived;

  @override
  String toString() {
    switch (this) {
      case StudentStatus.pending:
        return 'Pending';
      case StudentStatus.registered:
        return 'Registered';
      case StudentStatus.incomplete:
        return 'Incomplete';
      case StudentStatus.archived:
        return 'Archived';
    }
  }
}

/// Domain entity representing a student in the HADIR system
class Student extends Equatable {
  const Student({
    required this.id,
    required this.studentId,
    required this.fullName,
    required this.email,
    required this.dateOfBirth,
    required this.department,
    required this.program,
    required this.status,
    required this.createdAt,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.gender,
    this.nationality,
    this.major,
    this.enrollmentYear,
    this.academicLevel,
    this.registrationSessionId,
    this.faceEmbeddings = const [],
    this.lastUpdatedAt,
  });

  /// Unique identifier for the student
  final String id;

  /// Student ID (university identifier)
  final String studentId;

  /// Student's full name
  final String fullName;

  /// Student's department
  final String department;

  /// Student's program
  final String program;

  /// Student's first name (optional)
  final String? firstName;

  /// Student's last name (optional)
  final String? lastName;

  /// Student's email address
  final String email;

  /// Student's phone number (optional)
  final String? phoneNumber;

  /// Student's date of birth
  final DateTime dateOfBirth;

  /// Student's gender (optional)
  final Gender? gender;

  /// Student's nationality (optional)
  final String? nationality;

  /// Student's major/field of study (optional)
  final String? major;

  /// Year of enrollment (optional)
  final int? enrollmentYear;

  /// Academic level (undergraduate, graduate, etc.) (optional)
  final AcademicLevel? academicLevel;

  /// Current registration status
  final StudentStatus status;

  /// ID of the registration session used to register this student
  final String? registrationSessionId;

  /// Face embeddings generated from ML Kit Face Detection for face recognition
  final List<List<double>> faceEmbeddings;

  /// When the student record was created
  final DateTime createdAt;

  /// When the student record was last updated (optional)
  final DateTime? lastUpdatedAt;

  /// Get student's age based on date of birth
  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    
    return age;
  }

  /// Check if student has face embeddings
  bool get hasFaceEmbeddings => faceEmbeddings.isNotEmpty;

  /// Check if student is fully registered
  bool get isFullyRegistered => status == StudentStatus.registered && hasFaceEmbeddings;

  /// Check if student can be used for face recognition
  bool get canPerformFaceRecognition => isFullyRegistered && faceEmbeddings.length >= 3;

  /// Create a copy of this student with updated fields
  Student copyWith({
    String? id,
    String? studentId,
    String? fullName,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    DateTime? dateOfBirth,
    Gender? gender,
    String? nationality,
    String? major,
    int? enrollmentYear,
    AcademicLevel? academicLevel,
    StudentStatus? status,
    String? registrationSessionId,
    List<List<double>>? faceEmbeddings,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    String? department,
    String? program,
  }) {
    return Student(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      fullName: fullName ?? this.fullName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      nationality: nationality ?? this.nationality,
      major: major ?? this.major,
      enrollmentYear: enrollmentYear ?? this.enrollmentYear,
      academicLevel: academicLevel ?? this.academicLevel,
      status: status ?? this.status,
      registrationSessionId: registrationSessionId ?? this.registrationSessionId,
      faceEmbeddings: faceEmbeddings ?? this.faceEmbeddings,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? DateTime.now(),
      department: department ?? this.department,
      program: program ?? this.program,
    );
  }

  /// Convert student to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'fullName': fullName,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender?.name,
      'nationality': nationality,
      'major': major,
      'enrollmentYear': enrollmentYear,
      'academicLevel': academicLevel?.name,
      'department': department,
      'program': program,
      'status': status.name,
      'registrationSessionId': registrationSessionId,
      'faceEmbeddings': faceEmbeddings,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
    };
  }

  /// Create student from JSON
  factory Student.fromJson(Map<String, dynamic> json) {
    // Support both camelCase (for API) and snake_case (for database)
    return Student(
      id: json['id'] as String,
      studentId: (json['student_id'] ?? json['studentId']) as String,
      fullName: (json['full_name'] ?? json['fullName']) as String,
      department: (json['department']) as String,
      program: (json['program']) as String,
      firstName: (json['first_name'] ?? json['firstName']) as String?,
      lastName: (json['last_name'] ?? json['lastName']) as String?,
      email: json['email'] as String,
      phoneNumber: (json['phone_number'] ?? json['phoneNumber']) as String?,
      dateOfBirth: DateTime.parse((json['date_of_birth'] ?? json['dateOfBirth']) as String),
      gender: json['gender'] != null 
          ? Gender.values.firstWhere((e) => e.name == json['gender'])
          : null,
      nationality: json['nationality'] as String?,
      major: json['major'] as String?,
      enrollmentYear: (json['enrollment_year'] ?? json['enrollmentYear']) as int?,
      academicLevel: (json['academic_level'] ?? json['academicLevel']) != null
          ? AcademicLevel.values.firstWhere((e) => e.name == (json['academic_level'] ?? json['academicLevel']))
          : null,
      status: StudentStatus.values.firstWhere((e) => e.name == json['status']),
      registrationSessionId: (json['registration_session_id'] ?? json['registrationSessionId']) as String?,
      faceEmbeddings: _parseFaceEmbeddings(json['face_embeddings'] ?? json['faceEmbeddings']),
      createdAt: DateTime.parse((json['created_at'] ?? json['createdAt']) as String),
      lastUpdatedAt: (json['last_updated_at'] ?? json['lastUpdatedAt']) != null 
          ? DateTime.parse((json['last_updated_at'] ?? json['lastUpdatedAt']) as String)
          : null,
    );
  }

  /// Parse face embeddings from database string or JSON
  static List<List<double>> _parseFaceEmbeddings(dynamic value) {
    if (value == null) return [];
    
    if (value is String) {
      try {
        final decoded = jsonDecode(value) as List<dynamic>;
        return decoded
            .map((e) => (e as List<dynamic>).map((v) => (v as num).toDouble()).toList())
            .toList();
      } catch (e) {
        return [];
      }
    }
    
    if (value is List) {
      return (value)
          .map((e) => (e as List<dynamic>).map((v) => (v as num).toDouble()).toList())
          .toList();
    }
    
    return [];
  }

  /// Validate student data
  static void validate({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required DateTime dateOfBirth,
    required int enrollmentYear,
  }) {
    // Validate ID format (STU followed by 8 digits)
    if (!RegExp(r'^STU\d{8}$').hasMatch(id)) {
      throw ArgumentError('Student ID must follow format: STU########');
    }

    // Validate names
    if (firstName.trim().isEmpty) {
      throw ArgumentError('First name cannot be empty');
    }
    if (lastName.trim().isEmpty) {
      throw ArgumentError('Last name cannot be empty');
    }

    // Validate email format
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      throw ArgumentError('Invalid email format');
    }

    // Validate phone number (basic international format)
    if (!RegExp(r'^\+\d{10,15}$').hasMatch(phoneNumber)) {
      throw ArgumentError('Invalid phone number format');
    }

    // Validate age (must be at least 16, not more than 65)
    final age = DateTime.now().year - dateOfBirth.year;
    if (age < 16 || age > 65) {
      throw ArgumentError('Student age must be between 16 and 65');
    }

    // Validate enrollment year
    final currentYear = DateTime.now().year;
    if (enrollmentYear < 2000 || enrollmentYear > currentYear + 1) {
      throw ArgumentError('Enrollment year must be between 2000 and ${currentYear + 1}');
    }
  }

  @override
  List<Object?> get props => [
    id,
    studentId,
    fullName,
    email,
    department,
    program,
    firstName,
    lastName,
    phoneNumber,
    dateOfBirth,
    gender,
    nationality,
    major,
    enrollmentYear,
    academicLevel,
    status,
    registrationSessionId,
    faceEmbeddings,
    createdAt,
    lastUpdatedAt,
  ];

  @override
  String toString() {
    return 'Student(id: $id, fullName: $fullName, email: $email, status: $status)';
  }
}