import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/job_controller.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../core/utils/constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/company_icons.dart';

class JobListView extends GetView<JobController> {
  const JobListView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = Get.find<AuthService>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Search Input
          TextField(
            controller: controller.searchController,
            onChanged: controller.updateSearch,
            decoration: InputDecoration(
              hintText: 'Search title, skills, or company...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: () {},
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Full-time', 'Remote', 'Senior', 'Contract']
                  .map((filter) {
                return Obx(() {
                  final isSelected =
                      controller.selectedTypeFilter.value == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      checkmarkColor: AppColors.primary,
                      labelStyle: GoogleFonts.inter(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => controller.setTypeFilter(filter),
                    ),
                  );
                });
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Job List
          Expanded(
            child: Obx(() {
              final jobs = controller.filteredJobs;
              if (jobs.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async {
                    final dbService = Get.find<DatabaseService>();
                    await dbService.fetchAllData();
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.work_off_outlined,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  'No job listings available',
                                  style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Recruiters can log in to publish active job postings.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                      fontSize: 13, color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                if (!authService.isLoggedIn)
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.login),
                                    label: const Text('Log in'),
                                    onPressed: () =>
                                        Get.toNamed(AppRoutes.login),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  final dbService = Get.find<DatabaseService>();
                  await dbService.fetchAllData();
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    final application = controller.getApplicationForJob(job.id);
                    final showCandidateApplicationState =
                        authService.isLoggedIn &&
                            authService.currentRole == UserRole.candidate;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          if (authService.currentRole == UserRole.recruiter) {
                            Get.toNamed(
                              AppRoutes.recruiterApplicants,
                              arguments: job,
                            );
                          } else {
                            Get.toNamed(AppRoutes.jobDetails, arguments: job);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showCandidateApplicationState)
                                    Container(
                                      constraints:
                                          const BoxConstraints(minWidth: 48),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (application?.status.color ??
                                                Colors.blueGrey)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            application?.status ==
                                                    ApplicationStatus.applied
                                                ? Icons.check_circle_rounded
                                                : application == null
                                                    ? Icons
                                                        .radio_button_unchecked_rounded
                                                    : Icons
                                                        .pending_actions_rounded,
                                            color: application?.status.color ??
                                                Colors.blueGrey,
                                            size: 19,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            application?.status.label ??
                                                'Not applied',
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color:
                                                  application?.status.color ??
                                                      Colors.blueGrey,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (job.companyIconKey.isNotEmpty)
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: companyIconForKey(
                                          job.companyIconKey,
                                        ).color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        companyIconForKey(job.companyIconKey)
                                            .icon,
                                        color: companyIconForKey(
                                                job.companyIconKey)
                                            .color,
                                      ),
                                    )
                                  else
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        job.companyLogo,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 48,
                                          height: 48,
                                          color: AppColors.primary
                                              .withValues(alpha: 0.1),
                                          child: const Icon(
                                            Icons.business_rounded,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          job.title,
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${job.companyName} • ${job.location}',
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
                                  if (job.isFeatured)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Featured',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: job.skills
                                            .map(
                                              (skill) => Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 6),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? AppColors.bgDark
                                                        : AppColors.bgLight,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                      color: isDark
                                                          ? AppColors.borderDark
                                                          : AppColors
                                                              .borderLight,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    skill,
                                                    maxLines: 1,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: isDark
                                                          ? AppColors
                                                              .textSecondaryDark
                                                          : AppColors
                                                              .textSecondaryLight,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.4,
                                    ),
                                    child: Text(
                                      job.salaryRange,
                                      textAlign: TextAlign.right,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
