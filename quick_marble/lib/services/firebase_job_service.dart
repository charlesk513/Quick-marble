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
  Stream<List<Job>> watchJobs() {
    return _collection.orderBy('installationDate').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Job.fromMap(doc.id, doc.data()))
              .toList(),
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
    final doc = _collection.doc();

    final job = Job(
      id: doc.id,
      contractId: contract.id,
      contractNumber: contract.number,
      clientName: contract.clientName,
      installationDate: installationDate,
      installer: installer,
      location: location,
      notes: notes,
      status: JobStatus.scheduled,
    );

    await doc.set(job.toMap());
    return job;
  }

  @override
  Future<void> updateJob(Job job) async {
    await _collection.doc(job.id).update(job.toMap());
  }

  @override
  Future<void> updateStatus(String jobId, JobStatus status) async {
    await _collection.doc(jobId).update({
      'status': status.name,
    });
  }
}
