import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_log.dart';
import '../services/activity_log_service.dart';

final activityLogServiceProvider = Provider<ActivityLogService>((ref) {
  return ActivityLogService();
});

final activityLogsProvider = StreamProvider<List<ActivityLog>>((ref) {
  return ref.watch(activityLogServiceProvider).watchLogs();
});
