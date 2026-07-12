import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/contract.dart';
import '../models/job.dart';
import 'job_service.dart';

class FirebaseJobService implements JobService {
  final FirebaseFirestore _firestore;

  FirebaseJobService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('jobs');

  @override
  Stream<List<Job>> watchJobs({
    String? officeId,
  }) {
    Query<Map<String, dynamic>> query = _collection;

    if (officeId != null && officeId.trim().isNotEmpty) {
      query = query.where(
        'officeId',
        isEqualTo: officeId.trim(),
      );
    }

    query = query.orderBy('installationDate');

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (document) => Job.fromMap(
                  document.id,
                  document.data(),
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Future<Job> createJob({
    required Contract contract,
    required DateTime installationDate,
    required String installer,
    required String location,
    required String notes,
  }) async {
    final document = _collection.doc();
    final now = DateTime.now();

    final job = Job(
      id: document.id,
      contractId: contract.id,
      contractNumber: contract.number,
      officeId: contract.officeId,
      clientName: contract.clientName,
      installationDate: installationDate,
      installer: installer.trim(),
      location: location.trim(),
      notes: notes.trim(),
      status: JobStatus.scheduled,
      createdAt: now,
      updatedAt: now,
    );

    await document.set(job.toMap());
    return job;
  }

  @override
  Future<void> updateJob(Job job) async {
    final updated = job.copyWith(
      updatedAt: DateTime.now(),
    );

    await _collection.doc(job.id).set(
          updated.toMap(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> updateStatus(
    String jobId,
    JobStatus status,
  ) async {
    await _collection.doc(jobId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
