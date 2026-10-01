import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/job_controller.dart';
import '../../services/auth_service.dart';
import '../../core/utils/constants.dart';
import '../../core/routes/app_routes.dart';
import '../../models/application_model.dart';
import '../../services/database_service.dart';

class RecruiterDashboardView extends GetView<JobController> {
  final bool jobsOnly;

  const RecruiterDashboardView({super.key, this.jobsOnly = false});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recruiter = authService.currentUser.value;

    return RefreshIndicator(
      onRefresh: () async {
        final dbService = Get.find<DatabaseService>();
        await dbService.fetchAllData();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Recruiter Welcome Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.business_center,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recruiter?.name ?? 'Recruiter',
                          style: GoogleFonts.inter(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          recruiter?.companyName.isNotEmpty == true
                              ? recruiter?.companyName ?? ''
                              : 'Employer & Recruiter Portal',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Post Job'),
                    onPressed: () => Get.toNamed(AppRoutes.postJob),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Job Postings & Applicants Section
          Obx(() => _buildJobPostingsSection(context, isDark)),

          if (!jobsOnly) ...[
            // Applicants Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Candidate Applications Portal',
                  style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Obx(() => Text(
                      '${controller.recruiterApplicants.length} Applications',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold),
                    )),
              ],
            ),
            const SizedBox(height: 12),

            // Applicants List
            Obx(() => _buildApplicantsList(context, isDark)),

            const SizedBox(height: 24),
          ],
          // End of page refresh section
          if (!jobsOnly)
            Center(
              child: Column(
                children: [
                  Text(
                    "You've reached the end of recruiter portal",
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJobPostingsSection(BuildContext context, bool isDark) {
    final jobs = controller.recruiterJobs;
    if (jobs.isEmpty) {
      if (jobsOnly) {
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'You have not posted any jobs yet.',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              jobsOnly ? 'My Job Posts' : 'My Job Postings & Applicants',
              style:
                  GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${jobs.length} Posted',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            final applicantCount = controller.getApplicantCountForJob(job.id);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  Get.toNamed(
                    AppRoutes.recruiterApplicants,
                    arguments: job,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.work_rounded,
                            color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              style: GoogleFonts.inter(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${job.companyName} • ${job.location}',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${job.jobType} • ${job.salaryRange}',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Applicant Count Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$applicantCount',
                              style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary),
                            ),
                            Text(
                              applicantCount == 1 ? 'Applicant' : 'Applicants',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildApplicantsList(BuildContext context, bool isDark) {
    final applicants = controller.recruiterApplicants;
    if (applicants.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.people_outline_rounded,
                    size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'No candidate applications received yet',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Text(
                  'When job seekers apply for your posted jobs, their applications and details will appear here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: applicants.length,
      itemBuilder: (context, index) {
        final app = applicants[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Candidate Avatar, Name, Email, Job Applied To & Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: app.candidateAvatar.isNotEmpty
                          ? NetworkImage(app.candidateAvatar)
                          : null,
                      child: app.candidateAvatar.isEmpty
                          ? Text(
                              app.candidateName.isNotEmpty
                                  ? app.candidateName[0]
                                  : 'C',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold, fontSize: 16))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.candidateName,
                            style: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            app.candidateEmail,
                            style: GoogleFonts.inter(
                                fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Applied For: ${app.jobTitle}',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: app.status.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        app.status.label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: app.status.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 8),

                // Cover Letter Section
                if (app.coverLetter.isNotEmpty) ...[
                  Text(
                    'Candidate Cover Letter / Note:',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgDark : AppColors.bgLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight),
                    ),
                    child: Text(
                      app.coverLetter,
                      style: GoogleFonts.inter(fontSize: 13, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Resume & Application Timestamp Details
                Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Resume: ${app.resumeName}',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                    ),
                    const Spacer(),
                    Text(
                      'Applied on: ${app.appliedAt.day}/${app.appliedAt.month}/${app.appliedAt.year}',
                      style:
                          GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Action Row: View Details Dialog & Status Dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: Size.zero,
                      ),
                      icon: const Icon(Icons.visibility_outlined,
                          size: 16, color: AppColors.primary),
                      label: Text('Full Details',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                      onPressed: () {
                        _showCandidateDetailsDialog(context, app, isDark);
                      },
                    ),
                    Row(
                      children: [
                        Text('Stage:',
                            style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        PopupMenuButton<ApplicationStatus>(
                          tooltip: 'Change Stage',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.4)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text('Update',
                                    style: GoogleFonts.inter(fontSize: 12)),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down, size: 16),
                              ],
                            ),
                          ),
                          onSelected: (ApplicationStatus newStatus) {
                            controller.updateApplicantStage(app.id, newStatus);
                          },
                          itemBuilder: (context) {
                            return <PopupMenuEntry<ApplicationStatus>>[
                              const PopupMenuItem<ApplicationStatus>(
                                value: ApplicationStatus.applied,
                                child: Text('Applied'),
                              ),
                              const PopupMenuItem<ApplicationStatus>(
                                value: ApplicationStatus.shortlisted,
                                child: Text('Shortlisted'),
                              ),
                              const PopupMenuItem<ApplicationStatus>(
                                value: ApplicationStatus.interviewing,
                                child: Text('Interview Scheduled'),
                              ),
                              const PopupMenuItem<ApplicationStatus>(
                                value: ApplicationStatus.offered,
                                child: Text('Job Offered'),
                              ),
                              const PopupMenuItem<ApplicationStatus>(
                                value: ApplicationStatus.rejected,
                                child: Text('Not Selected'),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCandidateDetailsDialog(
      BuildContext context, ApplicationModel app, bool isDark) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 450,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: app.candidateAvatar.isNotEmpty
                          ? NetworkImage(app.candidateAvatar)
                          : null,
                      child: app.candidateAvatar.isEmpty
                          ? Text(
                              app.candidateName.isNotEmpty
                                  ? app.candidateName[0]
                                  : 'C',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold, fontSize: 18))
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.candidateName,
                            style: GoogleFonts.inter(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          if (app.candidateHeadline.isNotEmpty)
                            Text(
                              app.candidateHeadline,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            app.candidateEmail,
                            style: GoogleFonts.inter(
                                fontSize: 13, color: Colors.grey),
                          ),
                          if (app.candidatePhone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              app.candidatePhone,
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 10),

                // Location & Experience
                Row(
                  children: [
                    if (app.candidateLocation.isNotEmpty) ...[
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(app.candidateLocation,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: Colors.grey)),
                      const SizedBox(width: 16),
                    ],
                    const Icon(Icons.work_outline,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${app.candidateExperienceYears} years exp',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 14),

                if (app.candidateBio.isNotEmpty) ...[
                  Text('Candidate Bio:',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(app.candidateBio,
                      style: GoogleFonts.inter(fontSize: 13, height: 1.4)),
                  const SizedBox(height: 12),
                ],

                if (app.candidateSkills.isNotEmpty) ...[
                  Text('Candidate Skills:',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: app.candidateSkills
                        .map((skill) => Chip(
                              label: Text(skill,
                                  style: GoogleFonts.inter(fontSize: 11)),
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.1),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                ],

                Text('Job Position Applied For:',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 4),
                Text(app.jobTitle,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
                const SizedBox(height: 12),

                Text('Application Status:',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: app.status.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(app.status.label,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: app.status.color)),
                ),
                const SizedBox(height: 12),

                if (app.coverLetter.isNotEmpty) ...[
                  Text('Cover Letter / Note:',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(app.coverLetter,
                      style: GoogleFonts.inter(fontSize: 13, height: 1.4)),
                  const SizedBox(height: 12),
                ],

                Text('Submitted Resume:',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.picture_as_pdf,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(app.resumeName,
                            style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w600))),
                  ],
                ),
                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
