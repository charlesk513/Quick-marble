import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project_timeline.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_project_timeline_service.dart';
import '../services/project_timeline_service.dart';

final projectTimelineServiceProvider = Provider<ProjectTimelineService>((ref) {
  return FirebaseProjectTimelineService();
});

final projectTimelineEventsProvider =
    StreamProvider<List<ProjectTimelineEvent>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;

  if (user == null) {
    return Stream.value(const <ProjectTimelineEvent>[]);
  }

  final officeId = user.isAdministrator ? null : user.assignedOfficeId;

  if (!user.isAdministrator && (officeId == null || officeId.trim().isEmpty)) {
    return Stream.value(const <ProjectTimelineEvent>[]);
  }

  return ref.watch(projectTimelineServiceProvider).watchEvents(
        officeId: officeId,
      );
});

final contractTimelineProvider =
    Provider.family<List<ProjectTimelineEvent>, String>((ref, contractId) {
  final events =
      ref.watch(projectTimelineEventsProvider).valueOrNull ?? const [];

  final filtered = events
      .where((event) => event.contractId == contractId)
      .toList(growable: false)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return filtered;
});

class ProjectTimelineController extends StateNotifier<AsyncValue<void>> {
  final ProjectTimelineService _service;

  ProjectTimelineController(this._service) : super(const AsyncValue.data(null));

  Future<void> addEvent({
    required String contractId,
    required ProjectTimelineType type,
    required String title,
    required String description,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _service.addEvent(
        contractId: contractId,
        type: type,
        title: title,
        description: description,
      );

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final projectTimelineControllerProvider =
    StateNotifierProvider<ProjectTimelineController, AsyncValue<void>>((ref) {
  return ProjectTimelineController(
    ref.watch(projectTimelineServiceProvider),
  );
});
