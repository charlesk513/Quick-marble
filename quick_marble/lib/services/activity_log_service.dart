import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity_log.dart';

class ActivityLogService {
  final FirebaseFirestore _firestore;

  ActivityLogService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('activity_logs');

  Stream<List<ActivityLog>> watchLogs({String? officeId}) {
    Query<Map<String, dynamic>> query = _collection;

    if (officeId != null && officeId.trim().isNotEmpty) {
      query = query.where('officeId', isEqualTo: officeId.trim());
    }

    query = query.orderBy('createdAt', descending: true).limit(150);

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((document) =>
                  ActivityLog.fromMap(document.id, document.data()))
              .toList(growable: false),
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
    final document = _collection.doc();

    await document.set({
      'officeId': officeId.trim(),
      'actorName': actorName.trim().isEmpty ? 'System' : actorName.trim(),
      'action': action.name,
      'entityType': entityType.trim().isEmpty ? 'Record' : entityType.trim(),
      'entityLabel': entityLabel.trim(),
      'message': message.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
