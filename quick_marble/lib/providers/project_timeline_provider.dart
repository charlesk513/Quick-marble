import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project_timeline.dart';
import '../services/mock_project_timeline_service.dart';
import '../services/project_timeline_service.dart';

final projectTimelineServiceProvider = Provider<ProjectTimelineService>((ref) {
  return MockProjectTimelineService();
});

final projectTimelineEventsProvider =
    StreamProvider<List<ProjectTimelineEvent>>((ref) {
  return ref.watch(projectTimelineServiceProvider).watchEvents();
});

final contractTimelineProvider =
    Provider.family<List<ProjectTimelineEvent>, String>((ref, contractId) {
  final events = ref.watch(projectTimelineEventsProvider).valueOrNull ?? [];

  return events.where((event) => event.contractId == contractId).toList();
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
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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
