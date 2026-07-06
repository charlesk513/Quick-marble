import 'dart:async';

import '../models/activity_log.dart';

class ActivityLogService {
  final _controller = StreamController<List<ActivityLog>>.broadcast();

  final List<ActivityLog> _logs = [
    ActivityLog(
      id: 'activity-1',
      officeId: 'nansana',
      actorName: 'Owner Admin',
      action: ActivityAction.approved,
      entityType: 'Quotation',
      entityLabel: 'QM-2026-000001',
      message: 'Approved quotation for Mugisha Apartments.',
      createdAt: DateTime(2026, 7, 5, 10, 30),
    ),
  ];

  Stream<List<ActivityLog>> watchLogs() {
    Future.microtask(_emit);
    return _controller.stream;
  }

  Future<void> addLog({
    required String officeId,
    required String actorName,
    required ActivityAction action,
    required String entityType,
    required String entityLabel,
    required String message,
  }) async {
    _logs.insert(
      0,
      ActivityLog(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        officeId: officeId,
        actorName: actorName,
        action: action,
        entityType: entityType,
        entityLabel: entityLabel,
        message: message,
        createdAt: DateTime.now(),
      ),
    );
    _emit();
  }

  void _emit() => _controller.add(List.unmodifiable(_logs));
}
