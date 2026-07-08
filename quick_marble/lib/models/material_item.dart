class MaterialItem {
  final String id;
  final String name;
  final String category;
  final double costPerUnit;
  final double sellingPricePerUnit;
  final String unitLabel;
  final bool isActive;

  const MaterialItem({
    required this.id,
    required this.name,
    required this.category,
    required this.costPerUnit,
    required this.sellingPricePerUnit,
    required this.unitLabel,
    required this.isActive,
  });

  MaterialItem copyWith({
    String? name,
    String? category,
    double? costPerUnit,
    double? sellingPricePerUnit,
    String? unitLabel,
    bool? isActive,
  }) {
    return MaterialItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      sellingPricePerUnit: sellingPricePerUnit ?? this.sellingPricePerUnit,
      unitLabel: unitLabel ?? this.unitLabel,
      isActive: isActive ?? this.isActive,
    );
  }

  factory MaterialItem.fromMap(String id, Map<String, dynamic> map) {
    return MaterialItem(
      id: id,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      costPerUnit: (map['costPerUnit'] as num?)?.toDouble() ?? 0,
      sellingPricePerUnit:
          (map['sellingPricePerUnit'] as num?)?.toDouble() ?? 0,
      unitLabel: map['unitLabel'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'costPerUnit': costPerUnit,
      'sellingPricePerUnit': sellingPricePerUnit,
      'unitLabel': unitLabel,
      'isActive': isActive,
    };
  }
}
