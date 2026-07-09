import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/contract.dart';
import '../models/job.dart';
import '../models/project_timeline.dart';
import '../providers/project_timeline_provider.dart';
import '../services/job_service.dart';
import '../services/firebase_job_service.dart';

final jobServiceProvider = Provider<JobService>((ref) {
  return FirebaseJobService();
});

final jobsStreamProvider = StreamProvider<List<Job>>((ref) {
  return ref.watch(jobServiceProvider).watchJobs();
});

final jobsProvider = Provider<List<Job>>((ref) {
  return ref.watch(jobsStreamProvider).valueOrNull ?? [];
});

class JobController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final JobService _service;

  JobController(this._ref, this._service) : super(const AsyncValue.data(null));

  Future<void> createJob({
    required Contract contract,
    required DateTime installationDate,
    required String installer,
    required String location,
    required String notes,
  }) async {
    state = const AsyncValue.loading();

    try {
      final job = await _service.createJob(
        contract: contract,
        installationDate: installationDate,
        installer: installer,
        location: location,
        notes: notes,
      );

      await _ref.read(projectTimelineControllerProvider.notifier).addEvent(
            contractId: contract.id,
            type: ProjectTimelineType.jobScheduled,
            title: 'Job Scheduled',
            description:
                '${job.installer} scheduled for ${job.installationDate.toString().split(' ').first} at ${job.location}.',
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

      await _ref.read(projectTimelineControllerProvider.notifier).addEvent(
            contractId: job.contractId,
            type: ProjectTimelineType.jobScheduled,
            title: 'Job Updated',
            description:
                '${job.installer} updated for ${job.installationDate.toString().split(' ').first} at ${job.location}.',
          );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateStatus(String jobId, JobStatus status) async {
    state = const AsyncValue.loading();

    try {
      final jobs = _ref.read(jobsProvider);
      final job = jobs.firstWhere((item) => item.id == jobId);

      await _service.updateStatus(jobId, status);

      final type = status == JobStatus.completed
          ? ProjectTimelineType.jobCompleted
          : status == JobStatus.inProgress
              ? ProjectTimelineType.jobStarted
              : ProjectTimelineType.jobScheduled;

      await _ref.read(projectTimelineControllerProvider.notifier).addEvent(
            contractId: job.contractId,
            type: type,
            title: 'Job ${status.label}',
            description:
                'Job for ${job.clientName} changed to ${status.label}.',
          );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final jobControllerProvider =
    StateNotifierProvider<JobController, AsyncValue<void>>((ref) {
  return JobController(ref, ref.watch(jobServiceProvider));
});
