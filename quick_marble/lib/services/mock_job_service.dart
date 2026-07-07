import 'dart:async';

import '../models/contract.dart';
import '../models/job.dart';
import 'job_service.dart';

class MockJobService implements JobService {
  final _controller = StreamController<List<Job>>.broadcast();

  final List<Job> _jobs = [];

  @override
  Stream<List<Job>> watchJobs() {
    Future.microtask(_emit);
    return _controller.stream;
  }

  @override
  Future<Job> createJob({
    required Contract contract,
    required DateTime installationDate,
    required String installer,
    required String location,
    required String notes,
  }) async {
    final job = Job(
      id: 'job-${DateTime.now().microsecondsSinceEpoch}',
      contractId: contract.id,
      contractNumber: contract.number,
      clientName: contract.clientName,
      installationDate: installationDate,
      installer: installer,
      location: location,
      notes: notes,
      status: JobStatus.scheduled,
    );

    _jobs.insert(0, job);
    _emit();
    return job;
  }

  @override
  Future<void> updateJob(Job job) async {
    final index = _jobs.indexWhere((item) => item.id == job.id);
    if (index == -1) return;

    _jobs[index] = job;
    _emit();
  }

  @override
  Future<void> updateStatus(String jobId, JobStatus status) async {
    final index = _jobs.indexWhere((item) => item.id == jobId);
    if (index == -1) return;

    _jobs[index] = _jobs[index].copyWith(status: status);
    _emit();
  }

  void _emit() {
    final copy = [..._jobs]
      ..sort((a, b) => a.installationDate.compareTo(b.installationDate));

    _controller.add(List.unmodifiable(copy));
  }
}
