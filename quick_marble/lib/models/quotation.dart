enum QuotationStatus { draft, pendingApproval, approved, rejected }

extension QuotationStatusX on QuotationStatus {
  String get label {
    switch (this) {
      case QuotationStatus.draft:
        return 'Draft';
      case QuotationStatus.pendingApproval:
        return 'Pending Approval';
      case QuotationStatus.approved:
        return 'Approved';
      case QuotationStatus.rejected:
        return 'Rejected';
    }
  }

  String get value => name;

  static QuotationStatus fromString(String value) {
    return QuotationStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => QuotationStatus.draft,
    );
  }
}

enum QuotationItemType { manual, material }

class QuotationItem {
  final String description;
  final double quantity;
  final double unitPrice;

  final QuotationItemType type;
  final String? materialId;
  final String? materialName;
  final double? widthCm;
  final double? lengthCm;

  const QuotationItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.type = QuotationItemType.manual,
    this.materialId,
    this.materialName,
    this.widthCm,
    this.lengthCm,
  });

  double get subtotal => quantity * unitPrice;

  static double granitePrice({
    required double widthCm,
    required double lengthCm,
    required double cost,
  }) {
    return ((widthCm / 100) * (lengthCm / 100)) / (60 / 100) * cost;
  }

  QuotationItem copyWith({
    String? description,
    double? quantity,
    double? unitPrice,
    QuotationItemType? type,
    String? materialId,
    String? materialName,
    double? widthCm,
    double? lengthCm,
  }) {
    return QuotationItem(
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      type: type ?? this.type,
      materialId: materialId ?? this.materialId,
      materialName: materialName ?? this.materialName,
      widthCm: widthCm ?? this.widthCm,
      lengthCm: lengthCm ?? this.lengthCm,
    );
  }

  factory QuotationItem.fromMap(Map<String, dynamic> map) => QuotationItem(
        description: map['description'] as String? ?? '',
        quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
        unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
        type: map['type'] == 'material'
            ? QuotationItemType.material
            : QuotationItemType.manual,
        materialId: map['materialId'] as String?,
        materialName: map['materialName'] as String?,
        widthCm: (map['widthCm'] as num?)?.toDouble(),
        lengthCm: (map['lengthCm'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'type': type.name,
        'materialId': materialId,
        'materialName': materialName,
        'widthCm': widthCm,
        'lengthCm': lengthCm,
      };
}

class Quotation {
  static const double vatRate = 0.18;

  final String id;
  final String number;
  final String officeId;
  final String clientId;
  final String clientName;
  final List<QuotationItem> items;
  final QuotationStatus status;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Quotation({
    required this.id,
    required this.number,
    required this.officeId,
    required this.clientId,
    required this.clientName,
    required this.items,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get vat => subtotal * vatRate;
  double get total => subtotal + vat;

  Quotation copyWith({
    String? officeId,
    String? clientId,
    String? clientName,
    List<QuotationItem>? items,
    QuotationStatus? status,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Quotation(
      id: id,
      number: number,
      officeId: officeId ?? this.officeId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      items: items ?? this.items,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
