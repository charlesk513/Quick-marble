class Office {
  final String id;
  final String name;
  final String location;
  final bool isActive;
  final DateTime createdAt;

  const Office({
    required this.id,
    required this.name,
    required this.location,
    required this.isActive,
    required this.createdAt,
  });

  Office copyWith({
    String? name,
    String? location,
    bool? isActive,
  }) {
    return Office(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  factory Office.fromMap(String id, Map<String, dynamic> map) {
    return Office(
      id: id,
      name: map['name'] as String? ?? '',
      location: map['location'] as String? ?? '',
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
      'location': location,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Seed data for the four offices that exist at launch.
/// Used only for first-run Firestore seeding, not hardcoded elsewhere —
/// admins can add more offices at any time through Settings.
const List<Map<String, String>> kInitialOffices = [
  {'name': 'Nansana (Main)', 'location': 'Nansana'},
  {'name': 'Kajjansi Branch', 'location': 'Kajjansi'},
  {'name': 'Buloba Branch', 'location': 'Buloba'},
  {'name': 'Bulenga Branch', 'location': 'Bulenga'},
];
