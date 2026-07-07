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

class Job {
  final String id;
  final String contractId;
  final String contractNumber;

  final String clientName;

  final DateTime installationDate;

  final String installer;

  final String location;

  final String notes;

  final JobStatus status;

  const Job({
    required this.id,
    required this.contractId,
    required this.contractNumber,
    required this.clientName,
    required this.installationDate,
    required this.installer,
    required this.location,
    required this.notes,
    required this.status,
  });

  Job copyWith({
    DateTime? installationDate,
    String? installer,
    String? location,
    String? notes,
    JobStatus? status,
  }) {
    return Job(
      id: id,
      contractId: contractId,
      contractNumber: contractNumber,
      clientName: clientName,
      installationDate: installationDate ?? this.installationDate,
      installer: installer ?? this.installer,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }
}
