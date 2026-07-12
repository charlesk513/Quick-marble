import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/project_timeline.dart';
import 'project_timeline_service.dart';

class FirebaseProjectTimelineService implements ProjectTimelineService {
  final FirebaseFirestore _firestore;

  FirebaseProjectTimelineService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('project_timelines');

  @override
  Stream<List<ProjectTimelineEvent>> watchEvents({
    String? officeId,
  }) {
    if (officeId != null && officeId.trim().isNotEmpty) {
      return _collection
          .where('officeId', isEqualTo: officeId.trim())
          .snapshots()
          .map((snapshot) {
        final events = snapshot.docs
            .map(
              (document) => ProjectTimelineEvent.fromMap(
                document.id,
                document.data(),
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return events;
      });
    }

    return _collection
        .orderBy('createdAt', descending: true)
        .limit(300)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => ProjectTimelineEvent.fromMap(
                  document.id,
                  document.data(),
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Future<void> addEvent({
    required String contractId,
    required ProjectTimelineType type,
    required String title,
    required String description,
  }) async {
    final contractDocument =
        await _firestore.collection('contracts').doc(contractId).get();

    if (!contractDocument.exists || contractDocument.data() == null) {
      throw StateError('Contract not found for timeline event.');
    }

    final officeId = contractDocument.data()!['officeId'] as String? ?? '';

    if (officeId.trim().isEmpty) {
      throw StateError('Contract office is missing.');
    }

    final document = _collection.doc();

    await document.set({
      'contractId': contractId.trim(),
      'officeId': officeId.trim(),
      'type': type.name,
      'title': title.trim(),
      'description': description.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
