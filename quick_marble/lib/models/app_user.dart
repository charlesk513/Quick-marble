/// The three roles supported by the system.
enum UserRole {
  administrator,
  manager,
  salesOfficer;

  static UserRole fromString(String value) {
    switch (value) {
      case 'admin':
      case 'administrator':
        return UserRole.administrator;
      case 'manager':
        return UserRole.manager;
      case 'sales_officer':
        return UserRole.salesOfficer;
      default:
        throw ArgumentError('Unknown role: $value');
    }
  }

  String toFirestoreValue() {
    switch (this) {
      case UserRole.administrator:
        return 'admin';
      case UserRole.manager:
        return 'manager';
      case UserRole.salesOfficer:
        return 'sales_officer';
    }
  }

  String get label {
    switch (this) {
      case UserRole.administrator:
        return 'Administrator';
      case UserRole.manager:
        return 'Manager';
      case UserRole.salesOfficer:
        return 'Sales Officer';
    }
  }
}

/// Represents an authenticated staff member.
///
/// `assignedOfficeId` is null only for Administrators, who operate
/// across all offices. Every Manager and Sales Officer belongs to
/// exactly one office and can only create/edit records within it.
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? assignedOfficeId;
  final bool isActive;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.assignedOfficeId,
    required this.isActive,
    required this.createdAt,
  });

  bool get isAdministrator => role == UserRole.administrator;

  /// Whether this user is allowed to create/edit a record that belongs
  /// to [officeId]. Administrators may edit any office; everyone else
  /// is restricted to their own assigned office.
  bool canEditOffice(String officeId) {
    if (isAdministrator) return true;
    return assignedOfficeId == officeId;
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? assignedOfficeId,
    bool? clearAssignedOfficeId,
    bool? isActive,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      assignedOfficeId: (clearAssignedOfficeId ?? false)
          ? null
          : (assignedOfficeId ?? this.assignedOfficeId),
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String? ?? 'sales_officer'),
      assignedOfficeId: map['assignedOfficeId'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] is DateTime)
          ? map['createdAt'] as DateTime
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.toFirestoreValue(),
      'assignedOfficeId': assignedOfficeId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
