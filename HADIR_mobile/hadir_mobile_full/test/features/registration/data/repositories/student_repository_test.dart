import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hadir_mobile_full/features/registration/data/repositories/student_repository.dart';
import 'package:hadir_mobile_full/shared/domain/entities/student.dart';
import 'package:hadir_mobile_full/features/registration/data/models/student_requests.dart';

import 'student_repository_test.mocks.dart';

// Generate mocks
@GenerateMocks([StudentRepository])
void main() {
  group('StudentRepository Contract Tests', () {
    late MockStudentRepository mockRepository;
    
    setUp(() {
      mockRepository = MockStudentRepository();
    });

    group('createStudent', () {
      test('should return Student when creation succeeds', () async {
        // Arrange
        const request = CreateStudentRequest(
          studentId: 'STU001',
          firstName: 'John',
          lastName: 'Doe',
          email: 'john.doe@university.edu',
          department: 'Computer Science',
          academicYear: 2024,
        );
        
        final expectedStudent = Student(
          id: 'student-uuid-123',
          studentId: 'STU001',
          firstName: 'John',
          lastName: 'Doe',
          email: 'john.doe@university.edu',
          department: 'Computer Science',
          academicYear: 2024,
          status: StudentStatus.active,
          registeredAt: DateTime.now(),
        );
        
        when(mockRepository.createStudent(request))
            .thenAnswer((_) async => expectedStudent);
        
        // Act
        final result = await mockRepository.createStudent(request);
        
        // Assert
        expect(result, equals(expectedStudent));
        expect(result.studentId, equals('STU001'));
        expect(result.firstName, equals('John'));
        expect(result.lastName, equals('Doe'));
        expect(result.email, equals('john.doe@university.edu'));
        expect(result.status, equals(StudentStatus.active));
        verify(mockRepository.createStudent(request)).called(1);
      });

      test('should throw exception when student ID already exists', () async {
        // Arrange
        const request = CreateStudentRequest(
          studentId: 'STU001',
          firstName: 'Jane',
          lastName: 'Smith',
          email: 'jane.smith@university.edu',
          department: 'Mathematics',
          academicYear: 2024,
        );
        
        when(mockRepository.createStudent(request))
            .thenThrow(const StudentAlreadyExistsException('Student with ID STU001 already exists'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.createStudent(request),
          throwsA(isA<StudentAlreadyExistsException>()),
        );
        verify(mockRepository.createStudent(request)).called(1);
      });

      test('should throw exception when request validation fails', () async {
        // Arrange
        const invalidRequest = CreateStudentRequest(
          studentId: '', // Invalid empty student ID
          firstName: 'Test',
          lastName: 'User',
          email: 'invalid-email', // Invalid email format
          department: 'Test Department',
          academicYear: 2024,
        );
        
        when(mockRepository.createStudent(invalidRequest))
            .thenThrow(const ValidationException('Invalid student data'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.createStudent(invalidRequest),
          throwsA(isA<ValidationException>()),
        );
        verify(mockRepository.createStudent(invalidRequest)).called(1);
      });
    });

    group('getStudentById', () {
      test('should return Student when found by ID', () async {
        // Arrange
        const studentId = 'student-uuid-123';
        final expectedStudent = Student(
          id: studentId,
          studentId: 'STU002',
          firstName: 'Alice',
          lastName: 'Johnson',
          email: 'alice.johnson@university.edu',
          department: 'Physics',
          academicYear: 2023,
          status: StudentStatus.active,
          registeredAt: DateTime.now(),
        );
        
        when(mockRepository.getStudentById(studentId))
            .thenAnswer((_) async => expectedStudent);
        
        // Act
        final result = await mockRepository.getStudentById(studentId);
        
        // Assert
        expect(result, equals(expectedStudent));
        expect(result?.id, equals(studentId));
        expect(result?.studentId, equals('STU002'));
        verify(mockRepository.getStudentById(studentId)).called(1);
      });

      test('should return null when student not found by ID', () async {
        // Arrange
        const nonExistentId = 'non-existent-uuid';
        
        when(mockRepository.getStudentById(nonExistentId))
            .thenAnswer((_) async => null);
        
        // Act
        final result = await mockRepository.getStudentById(nonExistentId);
        
        // Assert
        expect(result, isNull);
        verify(mockRepository.getStudentById(nonExistentId)).called(1);
      });

      test('should throw exception when ID format is invalid', () async {
        // Arrange
        const invalidId = '';
        
        when(mockRepository.getStudentById(invalidId))
            .thenThrow(const ArgumentException('Invalid student ID format'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.getStudentById(invalidId),
          throwsA(isA<ArgumentException>()),
        );
        verify(mockRepository.getStudentById(invalidId)).called(1);
      });
    });

    group('getStudentByStudentId', () {
      test('should return Student when found by student ID', () async {
        // Arrange
        const studentId = 'STU003';
        final expectedStudent = Student(
          id: 'student-uuid-456',
          studentId: studentId,
          firstName: 'Bob',
          lastName: 'Wilson',
          email: 'bob.wilson@university.edu',
          department: 'Chemistry',
          academicYear: 2024,
          status: StudentStatus.active,
          registeredAt: DateTime.now(),
        );
        
        when(mockRepository.getStudentByStudentId(studentId))
            .thenAnswer((_) async => expectedStudent);
        
        // Act
        final result = await mockRepository.getStudentByStudentId(studentId);
        
        // Assert
        expect(result, equals(expectedStudent));
        expect(result?.studentId, equals(studentId));
        verify(mockRepository.getStudentByStudentId(studentId)).called(1);
      });

      test('should return null when student not found by student ID', () async {
        // Arrange
        const nonExistentStudentId = 'NONEXISTENT';
        
        when(mockRepository.getStudentByStudentId(nonExistentStudentId))
            .thenAnswer((_) async => null);
        
        // Act
        final result = await mockRepository.getStudentByStudentId(nonExistentStudentId);
        
        // Assert
        expect(result, isNull);
        verify(mockRepository.getStudentByStudentId(nonExistentStudentId)).called(1);
      });
    });

    group('getAllStudents', () {
      test('should return all students when no status filter provided', () async {
        // Arrange
        final expectedStudents = [
          Student(
            id: 'student-1',
            studentId: 'STU001',
            firstName: 'John',
            lastName: 'Doe',
            email: 'john.doe@university.edu',
            department: 'Computer Science',
            academicYear: 2024,
            status: StudentStatus.active,
            registeredAt: DateTime.now(),
          ),
          Student(
            id: 'student-2',
            studentId: 'STU002',
            firstName: 'Jane',
            lastName: 'Smith',
            email: 'jane.smith@university.edu',
            department: 'Mathematics',
            academicYear: 2023,
            status: StudentStatus.pending,
            registeredAt: DateTime.now(),
          ),
        ];
        
        when(mockRepository.getAllStudents())
            .thenAnswer((_) async => expectedStudents);
        
        // Act
        final result = await mockRepository.getAllStudents();
        
        // Assert
        expect(result, equals(expectedStudents));
        expect(result, hasLength(2));
        expect(result[0].status, equals(StudentStatus.active));
        expect(result[1].status, equals(StudentStatus.pending));
        verify(mockRepository.getAllStudents()).called(1);
      });

      test('should return filtered students when status filter provided', () async {
        // Arrange
        final activeStudents = [
          Student(
            id: 'student-1',
            studentId: 'STU001',
            firstName: 'John',
            lastName: 'Doe',
            email: 'john.doe@university.edu',
            department: 'Computer Science',
            academicYear: 2024,
            status: StudentStatus.active,
            registeredAt: DateTime.now(),
          ),
        ];
        
        when(mockRepository.getAllStudents(status: StudentStatus.active))
            .thenAnswer((_) async => activeStudents);
        
        // Act
        final result = await mockRepository.getAllStudents(status: StudentStatus.active);
        
        // Assert
        expect(result, equals(activeStudents));
        expect(result, hasLength(1));
        expect(result.every((student) => student.status == StudentStatus.active), isTrue);
        verify(mockRepository.getAllStudents(status: StudentStatus.active)).called(1);
      });

      test('should return empty list when no students match filter', () async {
        // Arrange
        when(mockRepository.getAllStudents(status: StudentStatus.suspended))
            .thenAnswer((_) async => []);
        
        // Act
        final result = await mockRepository.getAllStudents(status: StudentStatus.suspended);
        
        // Assert
        expect(result, isEmpty);
        verify(mockRepository.getAllStudents(status: StudentStatus.suspended)).called(1);
      });
    });

    group('updateStudent', () {
      test('should return updated Student when update succeeds', () async {
        // Arrange
        const studentId = 'student-uuid-123';
        const updateRequest = UpdateStudentRequest(
          firstName: 'John Updated',
          lastName: 'Doe Updated',
          email: 'john.updated@university.edu',
          department: 'Computer Engineering',
          status: StudentStatus.active,
        );
        
        final expectedStudent = Student(
          id: studentId,
          studentId: 'STU001',
          firstName: 'John Updated',
          lastName: 'Doe Updated',
          email: 'john.updated@university.edu',
          department: 'Computer Engineering',
          academicYear: 2024,
          status: StudentStatus.active,
          registeredAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        );
        
        when(mockRepository.updateStudent(studentId, updateRequest))
            .thenAnswer((_) async => expectedStudent);
        
        // Act
        final result = await mockRepository.updateStudent(studentId, updateRequest);
        
        // Assert
        expect(result, equals(expectedStudent));
        expect(result.firstName, equals('John Updated'));
        expect(result.lastName, equals('Doe Updated'));
        expect(result.email, equals('john.updated@university.edu'));
        expect(result.department, equals('Computer Engineering'));
        expect(result.updatedAt, isNotNull);
        verify(mockRepository.updateStudent(studentId, updateRequest)).called(1);
      });

      test('should throw exception when student not found for update', () async {
        // Arrange
        const nonExistentId = 'non-existent-uuid';
        const updateRequest = UpdateStudentRequest(
          firstName: 'Updated Name',
        );
        
        when(mockRepository.updateStudent(nonExistentId, updateRequest))
            .thenThrow(const NotFoundException('Student not found'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.updateStudent(nonExistentId, updateRequest),
          throwsA(isA<NotFoundException>()),
        );
        verify(mockRepository.updateStudent(nonExistentId, updateRequest)).called(1);
      });

      test('should throw exception when update validation fails', () async {
        // Arrange
        const studentId = 'student-uuid-123';
        const invalidUpdateRequest = UpdateStudentRequest(
          email: 'invalid-email-format',
        );
        
        when(mockRepository.updateStudent(studentId, invalidUpdateRequest))
            .thenThrow(const ValidationException('Invalid email format'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.updateStudent(studentId, invalidUpdateRequest),
          throwsA(isA<ValidationException>()),
        );
        verify(mockRepository.updateStudent(studentId, invalidUpdateRequest)).called(1);
      });
    });

    group('deleteStudent', () {
      test('should complete successfully when student exists and can be deleted', () async {
        // Arrange
        const studentId = 'student-uuid-123';
        
        when(mockRepository.deleteStudent(studentId))
            .thenAnswer((_) async => {});
        
        // Act & Assert
        expect(
          () async => await mockRepository.deleteStudent(studentId),
          returnsNormally,
        );
        verify(mockRepository.deleteStudent(studentId)).called(1);
      });

      test('should throw exception when student not found for deletion', () async {
        // Arrange
        const nonExistentId = 'non-existent-uuid';
        
        when(mockRepository.deleteStudent(nonExistentId))
            .thenThrow(const NotFoundException('Student not found'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.deleteStudent(nonExistentId),
          throwsA(isA<NotFoundException>()),
        );
        verify(mockRepository.deleteStudent(nonExistentId)).called(1);
      });

      test('should throw exception when student has dependent records', () async {
        // Arrange
        const studentId = 'student-uuid-with-sessions';
        
        when(mockRepository.deleteStudent(studentId))
            .thenThrow(const ConflictException('Cannot delete student with existing registration sessions'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.deleteStudent(studentId),
          throwsA(isA<ConflictException>()),
        );
        verify(mockRepository.deleteStudent(studentId)).called(1);
      });
    });

    group('existsByStudentId', () {
      test('should return true when student exists with given student ID', () async {
        // Arrange
        const studentId = 'STU001';
        
        when(mockRepository.existsByStudentId(studentId))
            .thenAnswer((_) async => true);
        
        // Act
        final result = await mockRepository.existsByStudentId(studentId);
        
        // Assert
        expect(result, isTrue);
        verify(mockRepository.existsByStudentId(studentId)).called(1);
      });

      test('should return false when student does not exist with given student ID', () async {
        // Arrange
        const nonExistentStudentId = 'NONEXISTENT';
        
        when(mockRepository.existsByStudentId(nonExistentStudentId))
            .thenAnswer((_) async => false);
        
        // Act
        final result = await mockRepository.existsByStudentId(nonExistentStudentId);
        
        // Assert
        expect(result, isFalse);
        verify(mockRepository.existsByStudentId(nonExistentStudentId)).called(1);
      });

      test('should throw exception when student ID format is invalid', () async {
        // Arrange
        const invalidStudentId = '';
        
        when(mockRepository.existsByStudentId(invalidStudentId))
            .thenThrow(const ArgumentException('Invalid student ID format'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.existsByStudentId(invalidStudentId),
          throwsA(isA<ArgumentException>()),
        );
        verify(mockRepository.existsByStudentId(invalidStudentId)).called(1);
      });
    });

    group('Error Handling Contract', () {
      test('should handle network timeouts appropriately', () async {
        // Arrange
        const studentId = 'STU001';
        
        when(mockRepository.getStudentByStudentId(studentId))
            .thenThrow(const NetworkException('Connection timeout'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.getStudentByStudentId(studentId),
          throwsA(isA<NetworkException>()),
        );
        verify(mockRepository.getStudentByStudentId(studentId)).called(1);
      });

      test('should handle database connection failures', () async {
        // Arrange
        when(mockRepository.getAllStudents())
            .thenThrow(const DatabaseException('Database connection failed'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.getAllStudents(),
          throwsA(isA<DatabaseException>()),
        );
        verify(mockRepository.getAllStudents()).called(1);
      });

      test('should handle concurrent modification conflicts', () async {
        // Arrange
        const studentId = 'student-uuid-123';
        const updateRequest = UpdateStudentRequest(firstName: 'Updated');
        
        when(mockRepository.updateStudent(studentId, updateRequest))
            .thenThrow(const ConcurrencyException('Student was modified by another process'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.updateStudent(studentId, updateRequest),
          throwsA(isA<ConcurrencyException>()),
        );
        verify(mockRepository.updateStudent(studentId, updateRequest)).called(1);
      });
    });

    group('Performance Contract', () {
      test('should complete getAllStudents within reasonable timeframe', () async {
        // Arrange
        final students = List.generate(100, (index) => Student(
          id: 'student-$index',
          studentId: 'STU${index.toString().padLeft(3, '0')}',
          firstName: 'Student',
          lastName: '$index',
          email: 'student$index@university.edu',
          department: 'Test Department',
          academicYear: 2024,
          status: StudentStatus.active,
          registeredAt: DateTime.now(),
        ));
        
        when(mockRepository.getAllStudents())
            .thenAnswer((_) async => students);
        
        // Act
        final stopwatch = Stopwatch()..start();
        final result = await mockRepository.getAllStudents();
        stopwatch.stop();
        
        // Assert
        expect(result, hasLength(100));
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete within 5 seconds
        verify(mockRepository.getAllStudents()).called(1);
      });

      test('should handle batch operations efficiently', () async {
        // Arrange
        final requests = List.generate(10, (index) => CreateStudentRequest(
          studentId: 'BATCH${index.toString().padLeft(3, '0')}',
          firstName: 'Batch',
          lastName: 'Student$index',
          email: 'batch$index@university.edu',
          department: 'Batch Department',
          academicYear: 2024,
        ));
        
        // Act & Assert
        for (final request in requests) {
          final student = Student(
            id: 'student-batch-${request.studentId}',
            studentId: request.studentId,
            firstName: request.firstName,
            lastName: request.lastName,
            email: request.email,
            department: request.department,
            academicYear: request.academicYear,
            status: StudentStatus.active,
            registeredAt: DateTime.now(),
          );
          
          when(mockRepository.createStudent(request))
              .thenAnswer((_) async => student);
          
          final result = await mockRepository.createStudent(request);
          expect(result.studentId, equals(request.studentId));
        }
        
        // Verify all calls were made
        for (final request in requests) {
          verify(mockRepository.createStudent(request)).called(1);
        }
      });
    });

    group('Data Consistency Contract', () {
      test('should maintain referential integrity when creating students', () async {
        // Arrange
        const request = CreateStudentRequest(
          studentId: 'STU999',
          firstName: 'Integrity',
          lastName: 'Test',
          email: 'integrity.test@university.edu',
          department: 'Test Department',
          academicYear: 2024,
        );
        
        final createdStudent = Student(
          id: 'student-integrity-test',
          studentId: 'STU999',
          firstName: 'Integrity',
          lastName: 'Test',
          email: 'integrity.test@university.edu',
          department: 'Test Department',
          academicYear: 2024,
          status: StudentStatus.active,
          registeredAt: DateTime.now(),
        );
        
        when(mockRepository.createStudent(request))
            .thenAnswer((_) async => createdStudent);
        when(mockRepository.existsByStudentId('STU999'))
            .thenAnswer((_) async => true);
        
        // Act
        final result = await mockRepository.createStudent(request);
        final exists = await mockRepository.existsByStudentId('STU999');
        
        // Assert
        expect(result.studentId, equals('STU999'));
        expect(exists, isTrue);
        verify(mockRepository.createStudent(request)).called(1);
        verify(mockRepository.existsByStudentId('STU999')).called(1);
      });

      test('should maintain data consistency during updates', () async {
        // Arrange
        const studentId = 'student-consistency-test';
        const updateRequest = UpdateStudentRequest(
          firstName: 'Updated First',
          lastName: 'Updated Last',
          status: StudentStatus.suspended,
        );
        
        final originalStudent = Student(
          id: studentId,
          studentId: 'STU888',
          firstName: 'Original First',
          lastName: 'Original Last',
          email: 'original@university.edu',
          department: 'Original Department',
          academicYear: 2024,
          status: StudentStatus.active,
          registeredAt: DateTime.now().subtract(const Duration(days: 10)),
        );
        
        final updatedStudent = originalStudent.copyWith(
          firstName: 'Updated First',
          lastName: 'Updated Last',
          status: StudentStatus.suspended,
          updatedAt: DateTime.now(),
        );
        
        when(mockRepository.getStudentById(studentId))
            .thenAnswer((_) async => originalStudent);
        when(mockRepository.updateStudent(studentId, updateRequest))
            .thenAnswer((_) async => updatedStudent);
        
        // Act
        final original = await mockRepository.getStudentById(studentId);
        final updated = await mockRepository.updateStudent(studentId, updateRequest);
        
        // Assert
        expect(original?.firstName, equals('Original First'));
        expect(updated.firstName, equals('Updated First'));
        expect(updated.id, equals(original?.id)); // ID should remain unchanged
        expect(updated.studentId, equals(original?.studentId)); // Student ID should remain unchanged
        expect(updated.updatedAt, isNotNull);
        verify(mockRepository.getStudentById(studentId)).called(1);
        verify(mockRepository.updateStudent(studentId, updateRequest)).called(1);
      });
    });
  });
}