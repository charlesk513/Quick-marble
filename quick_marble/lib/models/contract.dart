enum ContractStatus { pending, active, completed, cancelled }

extension ContractStatusX on ContractStatus {
  String get label {
    switch (this) {
      case ContractStatus.pending:
        return 'Pending';
      case ContractStatus.active:
        return 'Active';
      case ContractStatus.completed:
        return 'Completed';
      case ContractStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class Contract {
  final String id;
  final String number;
  final String quotationId;
  final String quotationNumber;
  final String officeId;
  final String clientName;
  final double value;
  final double amountPaid;
  final String documentName;
  final String notes;
  final ContractStatus status;
  final DateTime startDate;
  final DateTime? completionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Contract({
    required this.id,
    required this.number,
    required this.quotationId,
    required this.quotationNumber,
    required this.officeId,
    required this.clientName,
    required this.value,
    required this.amountPaid,
    required this.documentName,
    required this.notes,
    required this.status,
    required this.startDate,
    required this.completionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  double get balance => value - amountPaid;
  bool get isPaidFully => balance <= 0;

  Contract copyWith({
    double? amountPaid,
    String? documentName,
    String? notes,
    ContractStatus? status,
    DateTime? completionDate,
    DateTime? updatedAt,
  }) {
    return Contract(
      id: id,
      number: number,
      quotationId: quotationId,
      quotationNumber: quotationNumber,
      officeId: officeId,
      clientName: clientName,
      value: value,
      amountPaid: amountPaid ?? this.amountPaid,
      documentName: documentName ?? this.documentName,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      startDate: startDate,
      completionDate: completionDate ?? this.completionDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
