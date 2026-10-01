import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/job_controller.dart';
import '../controllers/profile_controller.dart';
import '../core/routes/app_routes.dart';
import '../core/utils/constants.dart';
import '../core/utils/company_icons.dart';
import '../models/company_profile.dart';

class CandidateActivityView extends StatefulWidget {
  const CandidateActivityView({super.key, this.initialTab = 'applications'});

  final String initialTab;

  @override
  State<CandidateActivityView> createState() => _CandidateActivityViewState();
}

class _CandidateActivityViewState extends State<CandidateActivityView> {
  late String _selectedSection;

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    final jobController = Get.find<JobController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Engagement',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSectionButton(
                        label: 'Applied',
                        icon: Icons.assignment_rounded,
                        value: 'applications',
                        isSelected: _selectedSection == 'applications',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSectionButton(
                        label: 'Saved',
                        icon: Icons.bookmark_rounded,
                        value: 'savedCompanies',
                        isSelected: _selectedSection == 'savedCompanies',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _selectedSection == 'applications'
                ? _buildJobApplicationsPanel(jobController)
                : _buildSavedCompaniesPanel(profileController),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionButton({
    required String label,
    required IconData icon,
    required String value,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isSelected
          ? AppColors.primary
          : isDark
              ? AppColors.cardDark
              : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => setState(() => _selectedSection = value),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobApplicationsPanel(JobController jobController) {
    return Obx(() {
      final apps = jobController.myApplications;

      if (apps.isEmpty) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.assignment_outlined, size: 52, color: Colors.grey),
                const SizedBox(height: 10),
                Text(
                  'No job applications yet',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: [
          Text(
            'Applied Jobs',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...apps.map((app) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final statusBg = _applicationStatusBackground(app.status, isDark);
            final statusColor = _applicationStatusColor(app.status, isDark);
            final matchingJob = jobController.allJobs.firstWhereOrNull(
              (job) => job.id == app.jobId ||
                  (job.companyName.toLowerCase() == app.companyName.toLowerCase() &&
                      job.title.toLowerCase() == app.jobTitle.toLowerCase()),
            );
            final icon = matchingJob != null && matchingJob.companyIconKey.isNotEmpty
                ? companyIconForKey(matchingJob.companyIconKey)
                : companyIconForKey('business');

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: matchingJob != null
                    ? () => Get.toNamed(AppRoutes.jobDetails, arguments: matchingJob)
                    : null,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: icon.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon.icon, color: icon.color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.jobTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              app.companyName,
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
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          app.status.label,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      );
    });
  }

  Widget _buildSavedCompaniesPanel(ProfileController controller) {
    final user = controller.user;
    final companies = user?.favoriteCompanies.isNotEmpty == true
        ? user?.favoriteCompanies ?? []
        : <CompanyProfile>[];

    if (companies.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.bookmark_border_rounded, size: 52, color: Colors.grey),
              const SizedBox(height: 10),
              Text(
                'No saved companies yet',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Companies',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...companies.map((company) {
          final icon = companyIconForKey(company.iconKey);
          final matchingJob = Get.find<JobController>().allJobs.firstWhereOrNull(
            (job) => job.companyName.toLowerCase() == company.name.toLowerCase(),
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () {
                if (matchingJob != null) {
                  Get.toNamed(AppRoutes.jobDetails, arguments: matchingJob);
                } else {
                  Get.snackbar(
                    'No listing found',
                    'There is no job listing for ${company.name} right now.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.primary,
                    colorText: Colors.white,
                  );
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: icon.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon.icon, color: icon.color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (company.location.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              company.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.bookmark_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Color _applicationStatusBackground(ApplicationStatus status, bool isDark) {
    switch (status) {
      case ApplicationStatus.applied:
        return isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE0F2FE);
      case ApplicationStatus.shortlisted:
        return isDark ? const Color(0xFF2E2A5F) : const Color(0xFFEDE9FE);
      case ApplicationStatus.interviewing:
        return isDark ? const Color(0xFF3F2A1A) : const Color(0xFFFEF3C7);
      case ApplicationStatus.offered:
        return isDark ? const Color(0xFF123C2D) : const Color(0xFFDCFCE7);
      case ApplicationStatus.rejected:
        return isDark ? const Color(0xFF4A1D1D) : const Color(0xFFFEE2E2);
    }
  }

  Color _applicationStatusColor(ApplicationStatus status, bool isDark) {
    switch (status) {
      case ApplicationStatus.applied:
        return isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8);
      case ApplicationStatus.shortlisted:
        return isDark ? const Color(0xFFC4B5FD) : const Color(0xFF6D28D9);
      case ApplicationStatus.interviewing:
        return isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309);
      case ApplicationStatus.offered:
        return isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D);
      case ApplicationStatus.rejected:
        return isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
    }
  }
}
