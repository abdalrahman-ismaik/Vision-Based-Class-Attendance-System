import 'package:flutter_test/flutter_test.dart';
import 'package:hadir_mobile_full/shared/domain/entities/administrator.dart';

void main() {
  group('Administrator Entity', () {
    test('should create Administrator instance with valid data', () {
      // Arrange
      const id = 'admin-123';
      const username = 'admin_user';
      const fullName = 'John Admin';
      const email = 'admin@university.edu';
      const role = AdministratorRole.operator;
      final createdAt = DateTime.now();
      final updatedAt = DateTime.now();
      
      // Act
      final administrator = Administrator(
        id: id,
        username: username,
        fullName: fullName,
        email: email,
        role: role,
        status: AdminStatus.active,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      
      // Assert
      expect(administrator.id, equals(id));
      expect(administrator.username, equals(username));
      expect(administrator.fullName, equals(fullName));
      expect(administrator.email, equals(email));
      expect(administrator.role, equals(role));
      expect(administrator.status, equals(AdminStatus.active));
      expect(administrator.createdAt, equals(createdAt));
      expect(administrator.updatedAt, equals(updatedAt));
      expect(administrator.lastLoginAt, isNull);
    });

    test('should support equality comparison', () {
      // Arrange
      final now = DateTime.now();
      final admin1 = Administrator(
        id: 'admin-123',
        username: 'admin_user',
        fullName: 'John Admin',
        email: 'admin@university.edu',
        role: AdministratorRole.operator,
        createdAt: now,
        status: AdminStatus.active,
      );
      
      final admin2 = Administrator(
        id: 'admin-123',
        username: 'admin_user',
        fullName: 'John Admin',
        email: 'admin@university.edu',
        role: AdministratorRole.operator,
        createdAt: now,
        status: AdminStatus.active,
      );
      
      // Act & Assert
      expect(admin1, equals(admin2));
      expect(admin1.hashCode, equals(admin2.hashCode));
    });

    test('should have different hash codes for different administrators', () {
      // Arrange
      final now = DateTime.now();
      final admin1 = Administrator(
        id: 'admin-123',
        username: 'admin_user1',
        fullName: 'John Admin',
        email: 'admin1@university.edu',
        role: AdministratorRole.operator,
        createdAt: now,
        status: AdminStatus.active,
      );
      
      final admin2 = Administrator(
        id: 'admin-456',
        username: 'admin_user2',
        fullName: 'Jane Admin',
        email: 'admin2@university.edu',
        role: AdministratorRole.supervisor,
        createdAt: now,
        status: AdminStatus.active,
      );
      
      // Act & Assert
      expect(admin1, isNot(equals(admin2)));
      expect(admin1.hashCode, isNot(equals(admin2.hashCode)));
    });

    test('should validate AdministratorRole enum values', () {
      // Assert
      expect(AdministratorRole.values, hasLength(3));
      expect(AdministratorRole.values, contains(AdministratorRole.operator));
      expect(AdministratorRole.values, contains(AdministratorRole.supervisor));
      expect(AdministratorRole.values, contains(AdministratorRole.admin));
    });

    test('should handle lastLoginAt as optional field', () {
      // Arrange
      final loginTime = DateTime.now();
      final administrator = Administrator(
        id: 'admin-123',
        username: 'admin_user',
        fullName: 'John Admin',
        email: 'admin@university.edu',
        role: AdministratorRole.operator,
        createdAt: DateTime.now(),
        lastLoginAt: loginTime,
        status: AdminStatus.active,
      );
      
      // Act & Assert
      expect(administrator.lastLoginAt, equals(loginTime));
    });

    test('should create copyWith method for immutable updates', () {
      // Arrange
      final original = Administrator(
        id: 'admin-123',
        username: 'admin_user',
        fullName: 'John Admin',
        email: 'admin@university.edu',
        role: AdministratorRole.operator,
        createdAt: DateTime.now(),
        status: AdminStatus.active,
      );
      
      final newLoginTime = DateTime.now();
      
      // Act
      final updated = original.copyWith(
        lastLoginAt: newLoginTime,
        status: AdminStatus.inactive,
      );
      
      // Assert
      expect(updated.id, equals(original.id));
      expect(updated.username, equals(original.username));
      expect(updated.fullName, equals(original.fullName));
      expect(updated.email, equals(original.email));
      expect(updated.role, equals(original.role));
      expect(updated.createdAt, equals(original.createdAt));
      expect(updated.lastLoginAt, equals(newLoginTime));
      expect(updated.status, isFalse);
      
      // Original should remain unchanged
      expect(original.lastLoginAt, isNull);
      expect(original.status, isTrue);
    });

    test('should support JSON serialization', () {
      // Arrange
      final administrator = Administrator(
        id: 'admin-123',
        username: 'admin_user',
        fullName: 'John Admin',
        email: 'admin@university.edu',
        role: AdministratorRole.operator,
        createdAt: DateTime.parse('2025-01-01T12:00:00Z'),
        status: AdminStatus.active,
      );
      
      // Act
      final json = administrator.toJson();
      final fromJson = Administrator.fromJson(json);
      
      // Assert
      expect(fromJson, equals(administrator));
      expect(json['id'], equals('admin-123'));
      expect(json['username'], equals('admin_user'));
      expect(json['role'], equals('operator'));
      expect(json['isActive'], isTrue);
    });
  });
}
