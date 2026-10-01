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
                tooltip: 'Filter jobs',
                onPressed: () => _showFilters(context, authService),
              ),
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
                                  if (job.companyIconKey.isNotEmpty)
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
                                  else if (job.companyLogo.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        job.companyLogo,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _companyLogoFallback(),
                                      ),
                                    )
                                  else
                                    _companyLogoFallback(),
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
                                      textAlign: TextAlign.left,
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

  void _showFilters(BuildContext context, AuthService authService) {
    final isCandidate =
        authService.isLoggedIn && authService.currentRole == UserRole.candidate;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewPadding.bottom;
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomInset),
            child: Obx(() {
              final isDark =
                  Theme.of(sheetContext).brightness == Brightness.dark;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Filter jobs',
                    style: GoogleFonts.inter(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Job type',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      'All',
                      'Full-time',
                      'Remote',
                      'Senior',
                      'Contract'
                    ].map((filter) {
                      final selected =
                          controller.selectedTypeFilter.value == filter;
                      return FilterChip(
                        label: Text(filter),
                        selected: selected,
                        selectedColor: AppColors.primary.withOpacity(0.15),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.primary
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        onSelected: (_) => controller.setTypeFilter(filter),
                      );
                    }).toList(),
                  ),
                  if (isCandidate) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Application status',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: ['All', 'Applied', 'Not applied'].map((filter) {
                        final selected =
                            controller.selectedApplicationFilter.value ==
                                filter;
                        return FilterChip(
                          label: Text(
                              filter == 'All' ? 'All applications' : filter),
                          selected: selected,
                          selectedColor: AppColors.secondary.withOpacity(0.15),
                          checkmarkColor: AppColors.secondary,
                          labelStyle: TextStyle(
                            color: selected
                                ? AppColors.secondary
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          onSelected: (_) =>
                              controller.setApplicationFilter(filter),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              );
            }),
          ),
        );
      },
    );
  }
}

Widget _companyLogoFallback() => Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.business_rounded,
        color: AppColors.primary,
      ),
    );
