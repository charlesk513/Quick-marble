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

class ProjectTimelineEvent {
  final String id;
  final String contractId;
  final ProjectTimelineType type;
  final String title;
  final String description;
  final DateTime createdAt;

  const ProjectTimelineEvent({
    required this.id,
    required this.contractId,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
  });
}
