import '../models/project_timeline.dart';

abstract class ProjectTimelineService {
  Stream<List<ProjectTimelineEvent>> watchEvents({
    String? officeId,
  });

  Future<void> addEvent({
    required String contractId,
    required ProjectTimelineType type,
    required String title,
    required String description,
  });
}
