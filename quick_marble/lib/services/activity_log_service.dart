import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity_log.dart';

class ActivityLogService {
  final FirebaseFirestore _firestore;

  ActivityLogService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('activity_logs');

  Stream<List<ActivityLog>> watchLogs() {
    return _collection
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ActivityLog.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> addLog({
    required String officeId,
    required String actorName,
    required ActivityAction action,
    required String entityType,
    required String entityLabel,
    required String message,
  }) async {
    final doc = _collection.doc();

    final log = ActivityLog(
      id: doc.id,
      officeId: officeId,
      actorName: actorName,
      action: action,
      entityType: entityType,
      entityLabel: entityLabel,
      message: message,
      createdAt: DateTime.now(),
    );

    await doc.set(log.toMap());
  }
}
