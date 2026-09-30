import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/job_controller.dart';
import '../../services/auth_service.dart';
import '../../core/utils/constants.dart';
import '../../core/routes/app_routes.dart';

class RecruiterDashboardView extends GetView<JobController> {
  const RecruiterDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recruiter = authService.currentUser.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: const Icon(Icons.business_center, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recruiter?.name ?? 'Recruiter',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          recruiter?.companyName.isNotEmpty == true 
                              ? recruiter!.companyName 
                              : 'Employer Dashboard',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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

          // Applicants Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Candidate Applications',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Obx(() => Text(
                    '${controller.recruiterApplicants.length} Total',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold),
                  )),
            ],
          ),
          const SizedBox(height: 12),

          // Applicants List
          Obx(() => _buildApplicantsList(context, isDark)),
        ],
      ),
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
                const Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'No candidate applications received yet',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Text(
                  'Applications submitted by job seekers will appear here in real-time.',
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
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: app.candidateAvatar.isNotEmpty 
                          ? NetworkImage(app.candidateAvatar) 
                          : null,
                      child: app.candidateAvatar.isEmpty 
                          ? Text(app.candidateName.isNotEmpty ? app.candidateName[0] : 'C',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.candidateName,
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            app.candidateEmail,
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Applied for: ${app.jobTitle}',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

                // Candidate Info Given (Cover Letter & Resume)
                if (app.coverLetter.isNotEmpty) ...[
                  Text(
                    'Cover Letter:',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgDark : AppColors.bgLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      app.coverLetter,
                      style: GoogleFonts.inter(fontSize: 13, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      app.resumeName,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                    const Spacer(),
                    Text(
                      'Applied: ${app.appliedAt.day}/${app.appliedAt.month}/${app.appliedAt.year}',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Action buttons to update status
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Update Status:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    PopupMenuButton<ApplicationStatus>(
                      tooltip: 'Change Stage',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text('Change Stage', style: GoogleFonts.inter(fontSize: 12)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 16),
                          ],
                        ),
                      ),
                      onSelected: (ApplicationStatus newStatus) {
                        controller.updateApplicantStage(app.id, newStatus);
                      },
                      itemBuilder: (context) {
                        return [
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
          ),
        );
      },
    );
  }
}
