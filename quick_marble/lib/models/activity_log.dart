import 'package:cloud_firestore/cloud_firestore.dart';

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
  uploaded,
  generated,
  scheduled,
  activated,
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
        ActivityAction.uploaded => 'Uploaded',
        ActivityAction.generated => 'Generated',
        ActivityAction.scheduled => 'Scheduled',
        ActivityAction.activated => 'Activated',
      };
}

DateTime _readActivityDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;

  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
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

  factory ActivityLog.fromMap(String id, Map<String, dynamic> map) {
    return ActivityLog(
      id: id,
      officeId: map['officeId'] as String? ?? '',
      actorName: map['actorName'] as String? ?? 'System',
      action: ActivityAction.values.firstWhere(
        (action) => action.name == map['action'],
        orElse: () => ActivityAction.updated,
      ),
      entityType: map['entityType'] as String? ?? 'Record',
      entityLabel: map['entityLabel'] as String? ?? '',
      message: map['message'] as String? ?? '',
      createdAt: _readActivityDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'officeId': officeId,
      'actorName': actorName,
      'action': action.name,
      'entityType': entityType,
      'entityLabel': entityLabel,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
