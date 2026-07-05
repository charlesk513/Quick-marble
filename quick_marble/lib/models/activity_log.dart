class ActivityLog {
  final String id;
  final String officeId;
  final String actorName;
  final String action;
  final String entityType;
  final String entityLabel;
  final DateTime createdAt;

  const ActivityLog({
    required this.id,
    required this.officeId,
    required this.actorName,
    required this.action,
    required this.entityType,
    required this.entityLabel,
    required this.createdAt,
  });
}
