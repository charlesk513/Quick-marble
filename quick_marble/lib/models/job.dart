import 'package:cloud_firestore/cloud_firestore.dart';

enum JobStatus {
  scheduled,
  inProgress,
  completed,
  postponed,
  cancelled,
}

extension JobStatusX on JobStatus {
  String get label {
    switch (this) {
      case JobStatus.scheduled:
        return 'Scheduled';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.postponed:
        return 'Postponed';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }
}

DateTime _readJobDate(dynamic value, {DateTime? fallback}) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;

  return DateTime.tryParse(value?.toString() ?? '') ??
      fallback ??
      DateTime.now();
}

class Job {
  final String id;
  final String contractId;
  final String contractNumber;
  final String officeId;
  final String clientName;
  final DateTime installationDate;
  final String installer;
  final String location;
  final String notes;
  final JobStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Job({
    required this.id,
    required this.contractId,
    required this.contractNumber,
    required this.officeId,
    required this.clientName,
    required this.installationDate,
    required this.installer,
    required this.location,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Job copyWith({
    DateTime? installationDate,
    String? installer,
    String? location,
    String? notes,
    JobStatus? status,
    DateTime? updatedAt,
  }) {
    return Job(
      id: id,
      contractId: contractId,
      contractNumber: contractNumber,
      officeId: officeId,
      clientName: clientName,
      installationDate: installationDate ?? this.installationDate,
      installer: installer ?? this.installer,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Job.fromMap(String id, Map<String, dynamic> map) {
    final createdAt = _readJobDate(map['createdAt']);

    return Job(
      id: id,
      contractId: map['contractId'] as String? ?? '',
      contractNumber: map['contractNumber'] as String? ?? '',
      officeId: map['officeId'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      installationDate: _readJobDate(map['installationDate']),
      installer: map['installer'] as String? ?? '',
      location: map['location'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      status: JobStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => JobStatus.scheduled,
      ),
      createdAt: createdAt,
      updatedAt: _readJobDate(map['updatedAt'], fallback: createdAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contractId': contractId,
      'contractNumber': contractNumber,
      'officeId': officeId,
      'clientName': clientName,
      'installationDate': Timestamp.fromDate(installationDate),
      'installer': installer,
      'location': location,
      'notes': notes,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
