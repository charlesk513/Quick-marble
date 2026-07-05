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
  final ContractStatus status;
  final DateTime startDate;
  final DateTime? completionDate;
  final DateTime createdAt;

  const Contract({
    required this.id,
    required this.number,
    required this.quotationId,
    required this.quotationNumber,
    required this.officeId,
    required this.clientName,
    required this.value,
    required this.status,
    required this.startDate,
    required this.completionDate,
    required this.createdAt,
  });

  Contract copyWith({ContractStatus? status, DateTime? completionDate}) {
    return Contract(
      id: id,
      number: number,
      quotationId: quotationId,
      quotationNumber: quotationNumber,
      officeId: officeId,
      clientName: clientName,
      value: value,
      status: status ?? this.status,
      startDate: startDate,
      completionDate: completionDate ?? this.completionDate,
      createdAt: createdAt,
    );
  }
}
