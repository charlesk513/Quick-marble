import 'dart:async';

import '../models/project_timeline.dart';
import 'project_timeline_service.dart';

class MockProjectTimelineService implements ProjectTimelineService {
  final _controller = StreamController<List<ProjectTimelineEvent>>.broadcast();

  final List<ProjectTimelineEvent> _events = [];

  @override
  Stream<List<ProjectTimelineEvent>> watchEvents() {
    Future.microtask(_emit);
    return _controller.stream;
  }

  @override
  Future<void> addEvent({
    required String contractId,
    required ProjectTimelineType type,
    required String title,
    required String description,
  }) async {
    _events.insert(
      0,
      ProjectTimelineEvent(
        id: 'timeline-${DateTime.now().microsecondsSinceEpoch}',
        contractId: contractId,
        type: type,
        title: title,
        description: description,
        createdAt: DateTime.now(),
      ),
    );

    _emit();
  }

  void _emit() {
    final copy = [..._events]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _controller.add(List.unmodifiable(copy));
  }
}
