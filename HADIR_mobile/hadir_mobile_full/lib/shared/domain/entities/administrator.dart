import 'package:equatable/equatable.dart';

/// Enumeration for administrator roles
enum AdminRole {
  superAdmin,
  admin,
  moderator;

  @override
  String toString() {
    switch (this) {
      case AdminRole.superAdmin:
        return 'Super Admin';
      case AdminRole.admin:
        return 'Admin';  
      case AdminRole.moderator:
        return 'Moderator';
    }
  }

  /// Get role description
  String get description {
    switch (this) {
      case AdminRole.superAdmin:
        return 'Full system access and management';
      case AdminRole.admin:
        return 'System administration and user management';
      case AdminRole.moderator:
        return 'Limited administrative access';
    }
  }

  /// Get permissions for this role
  List<Permission> get permissions {
    switch (this) {
      case AdminRole.superAdmin:
        return Permission.values;
      case AdminRole.admin:
        return [
          Permission.viewStudents,
          Permission.editStudents,
          Permission.deleteStudents,
          Permission.exportData,
          Permission.viewRegistrations,
          Permission.manageRegistrations,
          Permission.viewReports,
          Permission.manageSystem,
        ];
      case AdminRole.moderator:
        return [
          Permission.viewStudents,
          Permission.editStudents,
          Permission.viewRegistrations,
          Permission.viewReports,
        ];
    }
  }
}

/// Enumeration for administrator permissions
enum Permission {
  viewStudents,
  editStudents,
  deleteStudents,
  exportData,
  viewRegistrations,
  manageRegistrations,
  viewReports,
  manageSystem,
  manageAdmins;

  @override
  String toString() {
    switch (this) {
      case Permission.viewStudents:
        return 'View Students';
      case Permission.editStudents:
        return 'Edit Students';
      case Permission.deleteStudents:
        return 'Delete Students';
      case Permission.exportData:
        return 'Export Data';
      case Permission.viewRegistrations:
        return 'View Registrations';
      case Permission.manageRegistrations:
        return 'Manage Registrations';
      case Permission.viewReports:
        return 'View Reports';
      case Permission.manageSystem:
        return 'Manage System';
      case Permission.manageAdmins:
        return 'Manage Administrators';
    }
  }
}

/// Enumeration for administrator status
enum AdminStatus {
  active,
  inactive,
  suspended,
  pending;

  @override
  String toString() {
    switch (this) {
      case AdminStatus.active:
        return 'Active';
      case AdminStatus.inactive:
        return 'Inactive';
      case AdminStatus.suspended:
        return 'Suspended';
      case AdminStatus.pending:
        return 'Pending';
    }
  }
}

/// Domain entity representing an administrator in the HADIR system
class Administrator extends Equatable {
  const Administrator({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.status,
    this.lastLoginAt,
    this.passwordChangedAt,
    this.failedLoginAttempts = 0,
    this.isAccountLocked = false,
    this.accountLockedUntil,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier for the administrator
  final String id;

  /// Unique username for login
  final String username;

  /// Administrator's email address
  final String email;

  /// Administrator's first name
  final String firstName;

  /// Administrator's last name
  final String lastName;

  /// Administrator's role determining permissions
  final AdminRole role;

  /// Current status of the administrator account
  final AdminStatus status;

  /// When the administrator last logged in
  final DateTime? lastLoginAt;

  /// When the administrator last changed their password
  final DateTime? passwordChangedAt;

  /// Number of consecutive failed login attempts
  final int failedLoginAttempts;

  /// Whether the account is currently locked
  final bool isAccountLocked;

  /// When the account lock expires (if locked)
  final DateTime? accountLockedUntil;

  /// Additional metadata for the administrator
  final Map<String, dynamic> metadata;

  /// When the administrator record was created
  final DateTime createdAt;

  /// When the administrator record was last updated
  final DateTime updatedAt;

  /// Get administrator's full name
  String get fullName => '$firstName $lastName';

  /// Get list of permissions for this administrator
  List<Permission> get permissions => role.permissions;

  /// Check if administrator has a specific permission
  bool hasPermission(Permission permission) {
    return permissions.contains(permission);
  }

  /// Check if administrator can perform an action requiring multiple permissions
  bool hasAllPermissions(List<Permission> requiredPermissions) {
    return requiredPermissions.every((permission) => hasPermission(permission));
  }

  /// Check if administrator can perform an action requiring any of the permissions
  bool hasAnyPermission(List<Permission> requiredPermissions) {
    return requiredPermissions.any((permission) => hasPermission(permission));
  }

  /// Check if account is currently accessible
  bool get canLogin {
    return status == AdminStatus.active && 
           !isAccountLocked && 
           (accountLockedUntil == null || DateTime.now().isAfter(accountLockedUntil!));
  }

  /// Check if account needs password change (older than 90 days)
  bool get needsPasswordChange {
    if (passwordChangedAt == null) return true;
    
    final daysSinceChange = DateTime.now().difference(passwordChangedAt!).inDays;
    return daysSinceChange > 90;
  }

  /// Check if account has been inactive for too long (no login in 30 days)
  bool get isInactive {
    if (lastLoginAt == null) return true;
    
    final daysSinceLogin = DateTime.now().difference(lastLoginAt!).inDays;
    return daysSinceLogin > 30;
  }

  /// Get time until account unlock (if locked)
  Duration? get timeUntilUnlock {
    if (!isAccountLocked || accountLockedUntil == null) return null;
    
    final now = DateTime.now();
    if (now.isAfter(accountLockedUntil!)) return null;
    
    return accountLockedUntil!.difference(now);
  }

  /// Create a copy of this administrator with updated fields
  Administrator copyWith({
    String? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    AdminRole? role,
    AdminStatus? status,
    DateTime? lastLoginAt,
    DateTime? passwordChangedAt,
    int? failedLoginAttempts,
    bool? isAccountLocked,
    DateTime? accountLockedUntil,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Administrator(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      status: status ?? this.status,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      passwordChangedAt: passwordChangedAt ?? this.passwordChangedAt,
      failedLoginAttempts: failedLoginAttempts ?? this.failedLoginAttempts,
      isAccountLocked: isAccountLocked ?? this.isAccountLocked,
      accountLockedUntil: accountLockedUntil ?? this.accountLockedUntil,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Record successful login
  Administrator recordSuccessfulLogin() {
    return copyWith(
      lastLoginAt: DateTime.now(),
      failedLoginAttempts: 0,
      isAccountLocked: false,
      accountLockedUntil: null,
    );
  }

  /// Record failed login attempt
  Administrator recordFailedLogin() {
    final newAttempts = failedLoginAttempts + 1;
    final shouldLock = newAttempts >= 5;
    
    return copyWith(
      failedLoginAttempts: newAttempts,
      isAccountLocked: shouldLock,
      accountLockedUntil: shouldLock 
          ? DateTime.now().add(const Duration(minutes: 15))
          : null,
    );
  }

  /// Lock account manually
  Administrator lockAccount({Duration? duration}) {
    final lockDuration = duration ?? const Duration(hours: 24);
    return copyWith(
      isAccountLocked: true,
      accountLockedUntil: DateTime.now().add(lockDuration),
    );
  }

  /// Unlock account manually
  Administrator unlockAccount() {
    return copyWith(
      isAccountLocked: false,
      accountLockedUntil: null,
      failedLoginAttempts: 0,
    );
  }

  /// Update password
  Administrator updatePassword() {
    return copyWith(
      passwordChangedAt: DateTime.now(),
      failedLoginAttempts: 0,
      isAccountLocked: false,
      accountLockedUntil: null,
    );
  }

  /// Convert administrator to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role.name,
      'status': status.name,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'passwordChangedAt': passwordChangedAt?.toIso8601String(),
      'failedLoginAttempts': failedLoginAttempts,
      'isAccountLocked': isAccountLocked,
      'accountLockedUntil': accountLockedUntil?.toIso8601String(),
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create administrator from JSON
  factory Administrator.fromJson(Map<String, dynamic> json) {
    return Administrator(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: AdminRole.values.firstWhere((e) => e.name == json['role']),
      status: AdminStatus.values.firstWhere((e) => e.name == json['status']),
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt'] as String) 
          : null,
      passwordChangedAt: json['passwordChangedAt'] != null 
          ? DateTime.parse(json['passwordChangedAt'] as String) 
          : null,
      failedLoginAttempts: json['failedLoginAttempts'] as int? ?? 0,
      isAccountLocked: json['isAccountLocked'] as bool? ?? false,
      accountLockedUntil: json['accountLockedUntil'] != null 
          ? DateTime.parse(json['accountLockedUntil'] as String) 
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Validate administrator data
  static void validate({
    required String id,
    required String username,
    required String email,
    required String firstName,
    required String lastName,
  }) {
    // Validate ID format (ADM followed by 8 digits)
    if (!RegExp(r'^ADM\d{8}$').hasMatch(id)) {
      throw ArgumentError('Administrator ID must follow format: ADM########');
    }

    // Validate username (3-30 characters, alphanumeric and underscore)
    if (!RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(username)) {
      throw ArgumentError('Username must be 3-30 characters, alphanumeric and underscore only');
    }

    // Validate email format
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      throw ArgumentError('Invalid email format');
    }

    // Validate names
    if (firstName.trim().isEmpty) {
      throw ArgumentError('First name cannot be empty');
    }
    if (lastName.trim().isEmpty) {
      throw ArgumentError('Last name cannot be empty');
    }
  }

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    firstName,
    lastName,
    role,
    status,
    lastLoginAt,
    passwordChangedAt,
    failedLoginAttempts,
    isAccountLocked,
    accountLockedUntil,
    metadata,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'Administrator(id: $id, username: $username, fullName: $fullName, role: $role, status: $status)';
  }
}