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

class QuotationItem {
  final String description;
  final double quantity;
  final double unitPrice;

  const QuotationItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  double get subtotal => quantity * unitPrice;

  QuotationItem copyWith({String? description, double? quantity, double? unitPrice}) {
    return QuotationItem(
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  factory QuotationItem.fromMap(Map<String, dynamic> map) => QuotationItem(
        description: map['description'] as String? ?? '',
        quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
        unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
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
    List<QuotationItem>? items,
    QuotationStatus? status,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Quotation(
      id: id,
      number: number,
      officeId: officeId,
      clientId: clientId,
      clientName: clientName,
      items: items ?? this.items,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
