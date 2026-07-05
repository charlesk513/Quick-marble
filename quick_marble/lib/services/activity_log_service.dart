import 'dart:async';
import '../models/activity_log.dart';

class ActivityLogService {
  final _controller = StreamController<List<ActivityLog>>.broadcast();
  final List<ActivityLog> _logs = [];

  Stream<List<ActivityLog>> watchLogs() {
    Future.microtask(_emit);
    return _controller.stream;
  }

  Future<void> addLog({
    required String officeId,
    required String actorName,
    required String action,
    required String entityType,
    required String entityLabel,
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
        createdAt: DateTime.now(),
      ),
    );
    _emit();
  }

  void _emit() => _controller.add(List.unmodifiable(_logs));
}
