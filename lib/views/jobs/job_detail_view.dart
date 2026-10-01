import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/job_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../services/auth_service.dart';
import '../../models/job_model.dart';
import '../../models/company_profile.dart';
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
    final profileController = Get.find<ProfileController>();
    final isFavorite = profileController.user != null &&
        profileController.user!.favoriteCompanies.any(
          (company) => company.name.toLowerCase() == job.companyName.toLowerCase(),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(job.companyName),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isFavorite ? AppColors.primary : null,
            ),
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

              final company = CompanyProfile(
                id: 'company_${job.companyName}_${job.recruiterId}',
                name: job.companyName,
                location: job.location,
                iconKey: job.companyIconKey.isNotEmpty
                    ? job.companyIconKey
                    : 'business',
              );

              final currentIsFavorite = profileController.user != null &&
                  profileController.user!.favoriteCompanies.any(
                    (item) => item.id == company.id ||
                        item.name.toLowerCase() == company.name.toLowerCase(),
                  );

              profileController.toggleFavoriteCompany(company);
              final updatedUser = authService.currentUser.value?.copyWith(
                favoriteCompanies: profileController.favoriteCompanies.toList(),
              );
              if (updatedUser != null) {
                authService.updateUserProfile(updatedUser);
              }

              Get.snackbar(
                currentIsFavorite ? 'Removed from favorites' : 'Job company saved',
                currentIsFavorite
                    ? 'Removed from your saved companies list'
                    : 'Added to your saved companies list',
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Job Header Card Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (job.companyIconKey.isNotEmpty)
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: companyIconForKey(job.companyIconKey)
                                    .color
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                companyIconForKey(job.companyIconKey).icon,
                                color:
                                    companyIconForKey(job.companyIconKey).color,
                                size: 28,
                              ),
                            )
                          else if (job.companyLogo.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                job.companyLogo,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 56,
                                  height: 56,
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  child: const Icon(Icons.business_rounded,
                                      color: AppColors.primary, size: 28),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.business_rounded,
                                  color: AppColors.primary, size: 28),
                            ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  job.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  job.companyName,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Specs Card Box (2 rows, 2 items per row)
                    Container(
                      width: double.infinity,
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
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildSpecItem(
                                  Icons.location_on_outlined,
                                  'Location',
                                  job.location,
                                ),
                              ),
                              Expanded(
                                child: _buildSpecItem(
                                  Icons.work_outline_rounded,
                                  'Type',
                                  job.jobType,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSpecItem(
                                  Icons.attach_money_rounded,
                                  'Salary',
                                  job.salaryRange,
                                ),
                              ),
                              Expanded(
                                child: _buildSpecItem(
                                  Icons.people_outline_rounded,
                                  'Applicants',
                                  '${controller.getApplicantCountForJob(job.id)}',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Job Description Card Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Job Description',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            job.description,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.6,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Key Requirements Card Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Key Requirements',
                            style: GoogleFonts.inter(
                              fontSize: 16,
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
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Required Skills Card Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Required Skills',
                            style: GoogleFonts.inter(
                              fontSize: 16,
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
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.12),
                                side: BorderSide.none,
                                labelStyle: GoogleFonts.inter(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
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
                    color: Colors.black.withValues(alpha: 0.05),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(title, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
