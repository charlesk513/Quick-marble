class Client {
  final String id;
  final String officeId;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Client({
    required this.id,
    required this.officeId,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Client copyWith({
    String? officeId,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id,
      officeId: officeId ?? this.officeId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Client.fromMap(String id, Map<String, dynamic> map) {
    return Client(
      id: id,
      officeId: map['officeId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'officeId': officeId,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'notes': notes,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
