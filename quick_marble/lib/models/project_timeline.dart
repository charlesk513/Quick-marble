import 'package:cloud_firestore/cloud_firestore.dart';

enum ProjectTimelineType {
  quotationCreated,
  quotationApproved,
  contractCreated,
  paymentReceived,
  jobScheduled,
  jobStarted,
  jobCompleted,
  invoiceGenerated,
  receiptGenerated,
  deliveryNoteGenerated,
  projectCompleted,
}

extension ProjectTimelineTypeX on ProjectTimelineType {
  String get label => switch (this) {
        ProjectTimelineType.quotationCreated => 'Quotation Created',
        ProjectTimelineType.quotationApproved => 'Quotation Approved',
        ProjectTimelineType.contractCreated => 'Contract Created',
        ProjectTimelineType.paymentReceived => 'Payment Received',
        ProjectTimelineType.jobScheduled => 'Job Scheduled',
        ProjectTimelineType.jobStarted => 'Job Started',
        ProjectTimelineType.jobCompleted => 'Job Completed',
        ProjectTimelineType.invoiceGenerated => 'Invoice Generated',
        ProjectTimelineType.receiptGenerated => 'Receipt Generated',
        ProjectTimelineType.deliveryNoteGenerated => 'Delivery Note Generated',
        ProjectTimelineType.projectCompleted => 'Project Completed',
      };
}

DateTime _readTimelineDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;

  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}

class ProjectTimelineEvent {
  final String id;
  final String contractId;
  final String officeId;
  final ProjectTimelineType type;
  final String title;
  final String description;
  final DateTime createdAt;

  const ProjectTimelineEvent({
    required this.id,
    required this.contractId,
    required this.officeId,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  factory ProjectTimelineEvent.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return ProjectTimelineEvent(
      id: id,
      contractId: map['contractId'] as String? ?? '',
      officeId: map['officeId'] as String? ?? '',
      type: ProjectTimelineType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => ProjectTimelineType.contractCreated,
      ),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      createdAt: _readTimelineDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contractId': contractId,
      'officeId': officeId,
      'type': type.name,
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
