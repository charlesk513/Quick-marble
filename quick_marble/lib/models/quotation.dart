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

enum FixingMode { sellingOnly, supplyAndFix }

extension FixingModeX on FixingMode {
  String get label => switch (this) {
        FixingMode.sellingOnly => 'Selling only',
        FixingMode.supplyAndFix => 'Supply & fix',
      };
}

enum FixingPlaceType { furniture, concrete }

extension FixingPlaceTypeX on FixingPlaceType {
  String get label => switch (this) {
        FixingPlaceType.furniture => 'Furniture',
        FixingPlaceType.concrete => 'Concrete',
      };

  String get requiredMaterials => switch (this) {
        FixingPlaceType.furniture => 'Silicon and aradite',
        FixingPlaceType.concrete => 'Sand, cement, adhesive and aradite',
      };
}

enum FixingMaterialPayment { clientProvides, quickMarbleSupplies }

extension FixingMaterialPaymentX on FixingMaterialPayment {
  String get label => switch (this) {
        FixingMaterialPayment.clientProvides => 'Client provides materials',
        FixingMaterialPayment.quickMarbleSupplies =>
          'Quick Marble supplies materials',
      };
}

class QuotationItem {
  static const double mainLabourPerMeter = 30000;
  static const double skirtingLabourPerMeter = 5000;

  final String description;
  final double quantity;
  final double unitPrice;

  final QuotationItemType type;
  final String? materialId;
  final String? materialName;
  final double? widthCm;
  final double? lengthCm;

  final FixingMode fixingMode;
  final FixingPlaceType? fixingPlaceType;
  final FixingMaterialPayment fixingMaterialPayment;
  final double fixingMaterialsAmount;
  final double transportAmount;

  final bool hasSkirting;
  final double skirtingMeters;
  final double skirtingUnitPrice;

  const QuotationItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.type = QuotationItemType.manual,
    this.materialId,
    this.materialName,
    this.widthCm,
    this.lengthCm,
    this.fixingMode = FixingMode.sellingOnly,
    this.fixingPlaceType,
    this.fixingMaterialPayment = FixingMaterialPayment.clientProvides,
    this.fixingMaterialsAmount = 0,
    this.transportAmount = 0,
    this.hasSkirting = false,
    this.skirtingMeters = 0,
    this.skirtingUnitPrice = 0,
  });

  bool get isSupplyAndFix => fixingMode == FixingMode.supplyAndFix;

  double get materialAmount => quantity * unitPrice;

  double get mainLabourAmount =>
      isSupplyAndFix ? quantity * mainLabourPerMeter : 0;

  double get skirtingAmount =>
      hasSkirting ? skirtingMeters * skirtingUnitPrice : 0;

  double get skirtingLabourAmount => hasSkirting && isSupplyAndFix
      ? skirtingMeters * skirtingLabourPerMeter
      : 0;

  double get chargeableFixingMaterialsAmount => isSupplyAndFix &&
          fixingMaterialPayment == FixingMaterialPayment.quickMarbleSupplies
      ? fixingMaterialsAmount
      : 0;

  double get subtotal =>
      materialAmount +
      mainLabourAmount +
      skirtingAmount +
      skirtingLabourAmount +
      chargeableFixingMaterialsAmount +
      transportAmount;

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
    FixingMode? fixingMode,
    FixingPlaceType? fixingPlaceType,
    FixingMaterialPayment? fixingMaterialPayment,
    double? fixingMaterialsAmount,
    double? transportAmount,
    bool? hasSkirting,
    double? skirtingMeters,
    double? skirtingUnitPrice,
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
      fixingMode: fixingMode ?? this.fixingMode,
      fixingPlaceType: fixingPlaceType ?? this.fixingPlaceType,
      fixingMaterialPayment:
          fixingMaterialPayment ?? this.fixingMaterialPayment,
      fixingMaterialsAmount:
          fixingMaterialsAmount ?? this.fixingMaterialsAmount,
      transportAmount: transportAmount ?? this.transportAmount,
      hasSkirting: hasSkirting ?? this.hasSkirting,
      skirtingMeters: skirtingMeters ?? this.skirtingMeters,
      skirtingUnitPrice: skirtingUnitPrice ?? this.skirtingUnitPrice,
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
        fixingMode: map['fixingMode'] == 'supplyAndFix'
            ? FixingMode.supplyAndFix
            : FixingMode.sellingOnly,
        fixingPlaceType: map['fixingPlaceType'] == 'concrete'
            ? FixingPlaceType.concrete
            : map['fixingPlaceType'] == 'furniture'
                ? FixingPlaceType.furniture
                : null,
        fixingMaterialPayment:
            map['fixingMaterialPayment'] == 'quickMarbleSupplies'
                ? FixingMaterialPayment.quickMarbleSupplies
                : FixingMaterialPayment.clientProvides,
        fixingMaterialsAmount:
            (map['fixingMaterialsAmount'] as num?)?.toDouble() ?? 0,
        transportAmount: (map['transportAmount'] as num?)?.toDouble() ?? 0,
        hasSkirting: map['hasSkirting'] as bool? ?? false,
        skirtingMeters: (map['skirtingMeters'] as num?)?.toDouble() ?? 0,
        skirtingUnitPrice: (map['skirtingUnitPrice'] as num?)?.toDouble() ?? 0,
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
        'fixingMode': fixingMode.name,
        'fixingPlaceType': fixingPlaceType?.name,
        'fixingMaterialPayment': fixingMaterialPayment.name,
        'fixingMaterialsAmount': fixingMaterialsAmount,
        'transportAmount': transportAmount,
        'hasSkirting': hasSkirting,
        'skirtingMeters': skirtingMeters,
        'skirtingUnitPrice': skirtingUnitPrice,
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
