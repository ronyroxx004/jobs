import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/job_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/constants.dart';
import '../../services/database_service.dart';

class RecruiterJobsView extends GetView<JobController> {
  const RecruiterJobsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () => Get.find<DatabaseService>().fetchAllData(),
      child: Obx(() {
        final jobs = controller.recruiterJobs;
        if (jobs.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 72),
              Icon(Icons.work_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No job posts yet',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a job post to start receiving candidate applications.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.postJob),
                  icon: const Icon(Icons.add),
                  label: const Text('Post a Job'),
                ),
              ),
            ],
          );
        }

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Job Posts',
                        style: GoogleFonts.inter(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${jobs.length} ${jobs.length == 1 ? 'position' : 'positions'}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.postJob),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Post Job'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final job in jobs)
              Card(
                color: isDark ? AppColors.cardDark : Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Get.toNamed(
                    AppRoutes.recruiterApplicants,
                    arguments: job,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.work_outline_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.title,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${job.companyName} • ${job.location}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                '${job.jobType} • ${job.salaryRange}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            Text(
                              '${controller.getApplicantCountForJob(job.id)}',
                              style: GoogleFonts.inter(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              'Applicants',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
