import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/contract.dart';
import '../models/job.dart';
import '../services/job_service.dart';
import '../services/mock_job_service.dart';

final jobServiceProvider = Provider<JobService>((ref) {
  return MockJobService();
});

final jobsStreamProvider = StreamProvider<List<Job>>((ref) {
  return ref.watch(jobServiceProvider).watchJobs();
});

final jobsProvider = Provider<List<Job>>((ref) {
  return ref.watch(jobsStreamProvider).valueOrNull ?? [];
});

class JobController extends StateNotifier<AsyncValue<void>> {
  final JobService _service;

  JobController(this._service) : super(const AsyncValue.data(null));

  Future<void> createJob({
    required Contract contract,
    required DateTime installationDate,
    required String installer,
    required String location,
    required String notes,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _service.createJob(
        contract: contract,
        installationDate: installationDate,
        installer: installer,
        location: location,
        notes: notes,
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateJob(Job job) async {
    state = const AsyncValue.loading();

    try {
      await _service.updateJob(job);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateStatus(String jobId, JobStatus status) async {
    state = const AsyncValue.loading();

    try {
      await _service.updateStatus(jobId, status);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final jobControllerProvider =
    StateNotifierProvider<JobController, AsyncValue<void>>((ref) {
  return JobController(ref.watch(jobServiceProvider));
});
