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
}
