import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/project_timeline.dart';
import 'project_timeline_service.dart';

class FirebaseProjectTimelineService implements ProjectTimelineService {
  final FirebaseFirestore _firestore;

  FirebaseProjectTimelineService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('project_timeline_events');

  @override
  Stream<List<ProjectTimelineEvent>> watchEvents() {
    return _collection.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ProjectTimelineEvent.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> addEvent({
    required String contractId,
    required ProjectTimelineType type,
    required String title,
    required String description,
  }) async {
    final doc = _collection.doc();

    final event = ProjectTimelineEvent(
      id: doc.id,
      contractId: contractId,
      type: type,
      title: title,
      description: description,
      createdAt: DateTime.now(),
    );

    await doc.set(event.toMap());
  }
}
