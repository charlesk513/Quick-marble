import '../models/contract.dart';
import '../models/job.dart';

abstract class JobService {
  Stream<List<Job>> watchJobs();

  Future<Job> createJob({
    required Contract contract,
    required DateTime installationDate,
    required String installer,
    required String location,
    required String notes,
  });

  Future<void> updateJob(Job job);
  Future<void> updateStatus(String jobId, JobStatus status);
}
