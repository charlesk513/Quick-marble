enum ActivityAction {
  created,
  updated,
  submitted,
  approved,
  rejected,
  cancelled,
  completed,
  payment,
  login,
}

extension ActivityActionX on ActivityAction {
  String get label => switch (this) {
        ActivityAction.created => 'Created',
        ActivityAction.updated => 'Updated',
        ActivityAction.submitted => 'Submitted',
        ActivityAction.approved => 'Approved',
        ActivityAction.rejected => 'Rejected',
        ActivityAction.cancelled => 'Cancelled',
        ActivityAction.completed => 'Completed',
        ActivityAction.payment => 'Payment',
        ActivityAction.login => 'Login',
      };
}

class ActivityLog {
  final String id;
  final String officeId;
  final String actorName;
  final ActivityAction action;
  final String entityType;
  final String entityLabel;
  final String message;
  final DateTime createdAt;

  const ActivityLog({
    required this.id,
    required this.officeId,
    required this.actorName,
    required this.action,
    required this.entityType,
    required this.entityLabel,
    required this.message,
    required this.createdAt,
  });
}
