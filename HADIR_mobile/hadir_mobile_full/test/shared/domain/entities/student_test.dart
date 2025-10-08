import 'package:flutter_test/flutter_test.dart';
import 'package:hadir_mobile_full/shared/domain/entities/student.dart';

void main() {
  group('Student Entity', () {
    test('should create Student instance with valid data', () {
      // Arrange
      const id = 'student-123';
      const studentId = 'STU001234';
      const fullName = 'John Doe';
      const email = 'john.doe@university.edu';
      final dateOfBirth = DateTime(2000, 1, 15);
      const department = 'Computer Science';
      const program = 'Bachelor of Science';
      const status = StudentStatus.pending;
      final createdAt = DateTime.now();
      
      // Act
      final student = Student(
        id: id,
        studentId: studentId,
        fullName: fullName,
        email: email,
        dateOfBirth: dateOfBirth,
        department: department,
        program: program,
        status: status,
        createdAt: createdAt,
      );
      
      // Assert
      expect(student.id, equals(id));
      expect(student.studentId, equals(studentId));
      expect(student.fullName, equals(fullName));
      expect(student.email, equals(email));
      expect(student.dateOfBirth, equals(dateOfBirth));
      expect(student.department, equals(department));
      expect(student.program, equals(program));
      expect(student.status, equals(status));
      expect(student.createdAt, equals(createdAt));
      expect(student.lastUpdatedAt, isNull);
    });

    test('should create Student instance with minimal required data', () {
      // Arrange
      const id = 'student-456';
      const studentId = 'STU005678';
      const fullName = 'Jane Smith';
      const status = StudentStatus.pending;
      final createdAt = DateTime.now();
      
      // Act
      final student = Student(
        id: id,
        studentId: studentId,
        fullName: fullName,
        status: status,
        createdAt: createdAt,
      );
      
      // Assert
      expect(student.id, equals(id));
      expect(student.studentId, equals(studentId));
      expect(student.fullName, equals(fullName));
      expect(student.email, isNull);
      expect(student.dateOfBirth, isNull);
      expect(student.department, isNull);
      expect(student.program, isNull);
      expect(student.status, equals(status));
      expect(student.createdAt, equals(createdAt));
      expect(student.lastUpdatedAt, isNull);
    });

    test('should support equality comparison', () {
      // Arrange
      final now = DateTime.now();
      final student1 = Student(
        id: 'student-789',
        studentId: 'STU009876',
        fullName: 'Alice Johnson',
        email: 'alice@university.edu',
        status: StudentStatus.registered,
        createdAt: now,
      );
      
      final student2 = Student(
        id: 'student-789',
        studentId: 'STU009876',
        fullName: 'Alice Johnson',
        email: 'alice@university.edu',
        status: StudentStatus.registered,
        createdAt: now,
      );
      
      // Act & Assert
      expect(student1, equals(student2));
      expect(student1.hashCode, equals(student2.hashCode));
    });

    test('should have different hash codes for different students', () {
      // Arrange
      final now = DateTime.now();
      final student1 = Student(
        id: 'student-111',
        studentId: 'STU001111',
        fullName: 'Bob Wilson',
        status: StudentStatus.pending,
        createdAt: now,
      );
      
      final student2 = Student(
        id: 'student-222',
        studentId: 'STU002222',
        fullName: 'Carol Brown',
        status: StudentStatus.registered,
        createdAt: now,
      );
      
      // Act & Assert
      expect(student1, isNot(equals(student2)));
      expect(student1.hashCode, isNot(equals(student2.hashCode)));
    });

    test('should validate StudentStatus enum values', () {
      // Assert
      expect(StudentStatus.values, hasLength(4));
      expect(StudentStatus.values, contains(StudentStatus.pending));
      expect(StudentStatus.values, contains(StudentStatus.registered));
      expect(StudentStatus.values, contains(StudentStatus.incomplete));
      expect(StudentStatus.values, contains(StudentStatus.archived));
    });

    test('should handle lastUpdatedAt as optional field', () {
      // Arrange
      final updateTime = DateTime.now();
      final student = Student(
        id: 'student-333',
        studentId: 'STU003333',
        fullName: 'David Miller',
        status: StudentStatus.registered,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        lastUpdatedAt: updateTime,
      );
      
      // Act & Assert
      expect(student.lastUpdatedAt, equals(updateTime));
    });

    test('should create copyWith method for immutable updates', () {
      // Arrange
      final original = Student(
        id: 'student-444',
        studentId: 'STU004444',
        fullName: 'Eva Davis',
        email: 'eva@university.edu',
        status: StudentStatus.pending,
        createdAt: DateTime.now(),
      );
      
      final newUpdateTime = DateTime.now();
      
      // Act
      final updated = original.copyWith(
        status: StudentStatus.registered,
        lastUpdatedAt: newUpdateTime,
        department: 'Engineering',
      );
      
      // Assert
      expect(updated.id, equals(original.id));
      expect(updated.studentId, equals(original.studentId));
      expect(updated.fullName, equals(original.fullName));
      expect(updated.email, equals(original.email));
      expect(updated.createdAt, equals(original.createdAt));
      expect(updated.status, equals(StudentStatus.registered));
      expect(updated.lastUpdatedAt, equals(newUpdateTime));
      expect(updated.department, equals('Engineering'));
      
      // Original should remain unchanged
      expect(original.status, equals(StudentStatus.pending));
      expect(original.lastUpdatedAt, isNull);
      expect(original.department, isNull);
    });

    test('should support JSON serialization', () {
      // Arrange
      final student = Student(
        id: 'student-555',
        studentId: 'STU005555',
        fullName: 'Frank Garcia',
        email: 'frank@university.edu',
        dateOfBirth: DateTime.parse('1999-05-20'),
        department: 'Mathematics',
        program: 'Master of Science',
        status: StudentStatus.registered,
        createdAt: DateTime.parse('2025-01-01T12:00:00Z'),
        lastUpdatedAt: DateTime.parse('2025-01-02T14:30:00Z'),
      );
      
      // Act
      final json = student.toJson();
      final fromJson = Student.fromJson(json);
      
      // Assert
      expect(fromJson, equals(student));
      expect(json['id'], equals('student-555'));
      expect(json['studentId'], equals('STU005555'));
      expect(json['fullName'], equals('Frank Garcia'));
      expect(json['status'], equals('registered'));
      expect(json['department'], equals('Mathematics'));
    });

    test('should validate student ID format constraints', () {
      // Arrange
      final now = DateTime.now();
      
      // Test valid student ID lengths (5-20 characters)
      final validStudentIds = ['STU01', 'STU123456789012345678'];
      
      for (String validId in validStudentIds) {
        // Act & Assert - should not throw
        expect(
          () => Student(
            id: 'student-test',
            studentId: validId,
            fullName: 'Test Student',
            status: StudentStatus.pending,
            createdAt: now,
          ),
          returnsNormally,
        );
      }
    });

    test('should validate full name length constraints', () {
      // Arrange
      final now = DateTime.now();
      
      // Test valid full name lengths (2-100 characters)
      const validShortName = 'Jo';
      final validLongName = 'A' * 100;
      
      // Act & Assert - should not throw
      expect(
        () => Student(
          id: 'student-short',
          studentId: 'STU001',
          fullName: validShortName,
          status: StudentStatus.pending,
          createdAt: now,
        ),
        returnsNormally,
      );
      
      expect(
        () => Student(
          id: 'student-long',
          studentId: 'STU002',
          fullName: validLongName,
          status: StudentStatus.pending,
          createdAt: now,
        ),
        returnsNormally,
      );
    });

    test('should handle date of birth validation', () {
      // Arrange
      final now = DateTime.now();
      final validPastDate = DateTime(1990, 6, 15);
      
      // Act
      final student = Student(
        id: 'student-dob',
        studentId: 'STU006666',
        fullName: 'Grace Wilson',
        dateOfBirth: validPastDate,
        status: StudentStatus.pending,
        createdAt: now,
      );
      
      // Assert
      expect(student.dateOfBirth, equals(validPastDate));
      expect(student.dateOfBirth!.isBefore(now), isTrue);
    });

    test('should support state transitions validation', () {
      // Arrange
      final now = DateTime.now();
      final student = Student(
        id: 'student-transition',
        studentId: 'STU007777',
        fullName: 'Henry Clark',
        status: StudentStatus.pending,
        createdAt: now,
      );
      
      // Act - Test valid state transitions
      final registered = student.copyWith(
        status: StudentStatus.registered,
        lastUpdatedAt: now,
      );
      
      final incomplete = student.copyWith(
        status: StudentStatus.incomplete,
        lastUpdatedAt: now,
      );
      
      final archived = registered.copyWith(
        status: StudentStatus.archived,
        lastUpdatedAt: now,
      );
      
      // Assert
      expect(registered.status, equals(StudentStatus.registered));
      expect(incomplete.status, equals(StudentStatus.incomplete));
      expect(archived.status, equals(StudentStatus.archived));
      
      // Verify original state is preserved
      expect(student.status, equals(StudentStatus.pending));
    });

    test('should handle email validation when provided', () {
      // Arrange
      final now = DateTime.now();
      const validEmail = 'student@university.edu';
      
      // Act
      final student = Student(
        id: 'student-email',
        studentId: 'STU008888',
        fullName: 'Ivy Taylor',
        email: validEmail,
        status: StudentStatus.pending,
        createdAt: now,
      );
      
      // Assert
      expect(student.email, equals(validEmail));
      expect(student.email!.contains('@'), isTrue);
      expect(student.email!.contains('.'), isTrue);
    });
  });
}