import 'package:cloud_firestore/cloud_firestore.dart';

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

enum PaymentMethod { cash, mobileMoney, bankTransfer, cheque, other }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.mobileMoney => 'Mobile Money',
        PaymentMethod.bankTransfer => 'Bank Transfer',
        PaymentMethod.cheque => 'Cheque',
        PaymentMethod.other => 'Other',
      };
}

DateTime _readDate(dynamic value, {DateTime? fallback}) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '') ??
      fallback ??
      DateTime.now();
}

class ContractPayment {
  final String id;
  final double amount;
  final PaymentMethod method;
  final String reference;
  final String notes;
  final DateTime paidAt;

  const ContractPayment({
    required this.id,
    required this.amount,
    required this.method,
    required this.reference,
    required this.notes,
    required this.paidAt,
  });

  factory ContractPayment.fromMap(Map<String, dynamic> map) {
    return ContractPayment(
      id: map['id'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      method: PaymentMethod.values.firstWhere(
        (method) => method.name == map['method'],
        orElse: () => PaymentMethod.cash,
      ),
      reference: map['reference'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      paidAt: _readDate(map['paidAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'method': method.name,
      'reference': reference,
      'notes': notes,
      'paidAt': Timestamp.fromDate(paidAt),
    };
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
  final String documentUrl;
  final String documentStoragePath;
  final String notes;
  final ContractStatus status;
  final DateTime startDate;
  final DateTime? completionDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ContractPayment> payments;

  const Contract({
    required this.id,
    required this.number,
    required this.quotationId,
    required this.quotationNumber,
    required this.officeId,
    required this.payments,
    required this.clientName,
    required this.value,
    required this.amountPaid,
    required this.documentName,
    required this.documentUrl,
    required this.documentStoragePath,
    required this.notes,
    required this.status,
    required this.startDate,
    required this.completionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalPaid =>
      // ignore: avoid_types_as_parameter_names
      payments.fold<double>(amountPaid, (sum, payment) => sum + payment.amount);

  double get balance {
    final remaining = value - totalPaid;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isPaidFully => totalPaid >= value;

  Contract copyWith({
    double? amountPaid,
    String? documentName,
    String? documentUrl,
    String? documentStoragePath,
    String? notes,
    ContractStatus? status,
    DateTime? completionDate,
    bool clearCompletionDate = false,
    DateTime? updatedAt,
    List<ContractPayment>? payments,
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
      documentUrl: documentUrl ?? this.documentUrl,
      documentStoragePath: documentStoragePath ?? this.documentStoragePath,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      startDate: startDate,
      completionDate:
          clearCompletionDate ? null : completionDate ?? this.completionDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      payments: payments ?? this.payments,
    );
  }

  factory Contract.fromMap(String id, Map<String, dynamic> map) {
    final rawPayments = map['payments'];

    return Contract(
      id: id,
      number: map['number'] as String? ?? '',
      quotationId: map['quotationId'] as String? ?? '',
      quotationNumber: map['quotationNumber'] as String? ?? '',
      officeId: map['officeId'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      value: (map['value'] as num?)?.toDouble() ?? 0,
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0,
      documentName: map['documentName'] as String? ?? '',
      documentUrl: map['documentUrl'] as String? ?? '',
      documentStoragePath: map['documentStoragePath'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      status: ContractStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => ContractStatus.pending,
      ),
      startDate: _readDate(map['startDate']),
      completionDate: map['completionDate'] == null
          ? null
          : _readDate(map['completionDate']),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
      payments: rawPayments is List
          ? rawPayments
              .whereType<Map>()
              .map(
                (payment) => ContractPayment.fromMap(
                  Map<String, dynamic>.from(payment),
                ),
              )
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'quotationId': quotationId,
      'quotationNumber': quotationNumber,
      'officeId': officeId,
      'clientName': clientName,
      'value': value,
      'amountPaid': amountPaid,
      'documentName': documentName,
      'documentUrl': documentUrl,
      'documentStoragePath': documentStoragePath,
      'notes': notes,
      'status': status.name,
      'startDate': Timestamp.fromDate(startDate),
      'completionDate':
          completionDate == null ? null : Timestamp.fromDate(completionDate!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'payments': payments.map((payment) => payment.toMap()).toList(),
    };
  }
}
