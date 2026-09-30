import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/job_controller.dart';
import '../../services/auth_service.dart';
import '../../models/job_model.dart';
import '../../core/utils/constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/company_icons.dart';
import 'apply_job_modal.dart';

class JobDetailView extends GetView<JobController> {
  const JobDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final JobModel job = Get.arguments as JobModel;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = Get.find<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(job.companyName),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded),
            onPressed: () {
              if (!authService.isLoggedIn) {
                Get.snackbar(
                  'Sign In Required',
                  'Please sign in to save job listings',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.primary,
                  colorText: Colors.white,
                );
                Get.toNamed(AppRoutes.login);
                return;
              }
              Get.snackbar(
                'Job Saved',
                'Added to your saved jobs list',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.primary,
                colorText: Colors.white,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Row(
                      children: [
                        if (job.companyIconKey.isNotEmpty)
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: companyIconForKey(job.companyIconKey)
                                  .color
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              companyIconForKey(job.companyIconKey).icon,
                              color:
                                  companyIconForKey(job.companyIconKey).color,
                              size: 32,
                            ),
                          )
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              job.companyLogo,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 64,
                                height: 64,
                                color: AppColors.primary.withOpacity(0.1),
                                child: const Icon(Icons.business_rounded,
                                    color: AppColors.primary, size: 32),
                              ),
                            ),
                          ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.title,
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                job.companyName,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Quick Specs
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.bgLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 16,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          _buildSpecItem(Icons.location_on_outlined, 'Location',
                              job.location),
                          _buildSpecItem(
                              Icons.work_outline_rounded, 'Type', job.jobType),
                          _buildSpecItem(Icons.attach_money_rounded, 'Salary',
                              job.salaryRange),
                          _buildSpecItem(
                            Icons.people_outline_rounded,
                            'Applicants',
                            '${controller.getApplicantCountForJob(job.id)}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Job Description
                    Text(
                      'Job Description',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      job.description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.6,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Requirements
                    Text(
                      'Key Requirements',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...job.requirements.map((req) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.secondary, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                req,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),

                    // Skills Required
                    Text(
                      'Required Skills',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: job.skills.map((skill) {
                        return Chip(
                          label: Text(skill),
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          side: BorderSide.none,
                          labelStyle: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Apply Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: Obx(() {
                final alreadyApplied = controller.hasAppliedForJob(job.id);
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: alreadyApplied
                        ? Colors.grey.shade400
                        : AppColors.primary,
                  ),
                  onPressed: alreadyApplied
                      ? null
                      : () {
                          if (!authService.isLoggedIn) {
                            Get.snackbar(
                              'Sign In Required',
                              'Please sign in or register to apply for jobs',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.primary,
                              colorText: Colors.white,
                            );
                            Get.toNamed(AppRoutes.login);
                            return;
                          }
                          Get.bottomSheet(
                            ApplyJobModal(job: job),
                            isScrollControlled: true,
                          );
                        },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (alreadyApplied) ...[
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(alreadyApplied ? 'Already Applied' : 'Apply Now'),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 4),
        Text(title, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value,
            style:
                GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
