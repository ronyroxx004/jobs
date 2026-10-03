import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/profile_controller.dart';
import '../core/utils/constants.dart';
import '../core/utils/company_icons.dart';
import '../models/company_profile.dart';
import '../models/job_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'jobs/job_detail_view.dart';
import 'call/agora_video_call_view.dart';
import 'chat/priority_dm_chat_view.dart';

class CandidateApplicationsView extends StatelessWidget {
  final UserModel? candidateUser;
  const CandidateApplicationsView({super.key, this.candidateUser});

  @override
  Widget build(BuildContext context) {
    return CandidateActivityView(
      initialTab: 'applications',
      candidateUser: candidateUser,
    );
  }
}

class CandidateSessionsView extends StatelessWidget {
  final UserModel? candidateUser;
  const CandidateSessionsView({super.key, this.candidateUser});

  @override
  Widget build(BuildContext context) {
    return CandidateActivityView(
      initialTab: 'sessions',
      candidateUser: candidateUser,
    );
  }
}

class SavedCompaniesView extends StatelessWidget {
  final UserModel? candidateUser;
  const SavedCompaniesView({super.key, this.candidateUser});

  @override
  Widget build(BuildContext context) {
    return CandidateActivityView(
      initialTab: 'savedCompanies',
      candidateUser: candidateUser,
    );
  }
}

class CandidateActivityView extends StatefulWidget {
  const CandidateActivityView({
    super.key,
    this.initialTab = 'applications',
    this.candidateUser,
  });

  final String initialTab;
  final UserModel? candidateUser;

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

  UserModel? get _effectiveUser {
    if (widget.candidateUser != null) {
      if (Get.isRegistered<DatabaseService>()) {
        final db = Get.find<DatabaseService>();
        return db.usersList.firstWhereOrNull(
                (u) => u.id == widget.candidateUser!.id) ??
            widget.candidateUser;
      }
      return widget.candidateUser;
    }
    if (Get.isRegistered<ProfileController>()) {
      return Get.find<ProfileController>().user;
    }
    if (Get.isRegistered<AuthService>()) {
      return Get.find<AuthService>().currentUser.value;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedSection == 'applications'
              ? 'Job Applications'
              : _selectedSection == 'sessions'
                  ? '1:1 Mentorship Calls'
                  : 'Saved Companies',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Obx(() {
          final user = _effectiveUser;
          final db = Get.isRegistered<DatabaseService>()
              ? Get.find<DatabaseService>()
              : null;
          final authService = Get.isRegistered<AuthService>()
              ? Get.find<AuthService>()
              : null;
          final profileController = Get.isRegistered<ProfileController>()
              ? Get.find<ProfileController>()
              : null;

          final firebaseUid = authService?.firebaseUser.value?.uid ?? '';
          final candidateId = user?.id ?? '';
          final candidateEmail = (user?.email ??
                  authService?.currentUser.value?.email ??
                  '')
              .trim()
              .toLowerCase();

          final appsCount = db?.applicationsList.where((a) {
                if (candidateId.isNotEmpty && a.candidateId == candidateId) {
                  return true;
                }
                if (firebaseUid.isNotEmpty && a.candidateId == firebaseUid) {
                  return true;
                }
                if (candidateEmail.isNotEmpty &&
                    a.candidateEmail.trim().toLowerCase() == candidateEmail) {
                  return true;
                }
                return false;
              }).length ??
              0;

          final sessionsCount = db?.bookingsList.where((b) {
                if (candidateId.isNotEmpty && b.candidateId == candidateId) {
                  return true;
                }
                if (firebaseUid.isNotEmpty && b.candidateId == firebaseUid) {
                  return true;
                }
                if (candidateEmail.isNotEmpty &&
                    b.candidateEmail.trim().toLowerCase() == candidateEmail) {
                  return true;
                }
                return false;
              }).length ??
              0;

          final savedCompaniesList = profileController != null &&
                  profileController.favoriteCompanies.isNotEmpty
              ? profileController.favoriteCompanies
              : (user?.favoriteCompanies ?? <CompanyProfile>[]);
          final savedCount = savedCompaniesList.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSectionButton(
                          label: 'Applied ($appsCount)',
                          icon: Icons.assignment_rounded,
                          value: 'applications',
                          isSelected: _selectedSection == 'applications',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildSectionButton(
                          label: '1:1 Calls ($sessionsCount)',
                          icon: Icons.videocam_rounded,
                          value: 'sessions',
                          isSelected: _selectedSection == 'sessions',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildSectionButton(
                          label: 'Saved ($savedCount)',
                          icon: Icons.bookmark_rounded,
                          value: 'savedCompanies',
                          isSelected: _selectedSection == 'savedCompanies',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedSection == 'applications')
                _buildJobApplicationsPanel(user, isDark)
              else if (_selectedSection == 'sessions')
                _buildMentorshipSessionsPanel(user, isDark)
              else
                _buildSavedCompaniesPanel(user, isDark),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSectionButton({
    required String label,
    required IconData icon,
    required String value,
    required bool isSelected,
    required bool isDark,
  }) {
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
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

  Widget _buildJobApplicationsPanel(UserModel? user, bool isDark) {
    final db = Get.find<DatabaseService>();
    final authService =
        Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
    final isCandidateSelf = widget.candidateUser == null ||
        widget.candidateUser?.id == authService?.currentUser.value?.id;
    final firebaseUid = isCandidateSelf ? (authService?.firebaseUser.value?.uid ?? '') : '';
    final candidateId = (user?.id ?? '').trim();
    final candidateEmail = (user?.email ?? '').trim().toLowerCase();

    final apps = db.applicationsList.where((a) {
      if (candidateId.isNotEmpty && a.candidateId.trim() == candidateId) return true;
      if (firebaseUid.isNotEmpty && a.candidateId.trim() == firebaseUid) return true;
      if (candidateEmail.isNotEmpty &&
          a.candidateEmail.trim().toLowerCase() == candidateEmail) {
        return true;
      }
      return false;
    }).toList();

    if (apps.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Job Applications Yet',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isCandidateSelf
                    ? 'Browse jobs and submit applications to start tracking your status here.'
                    : 'This candidate has not submitted any job applications yet.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              if (isCandidateSelf) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.search_rounded,
                      size: 18, color: Colors.white),
                  label: Text(
                    'Explore Jobs',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    Get.until((route) => route.isFirst);
                  },
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Submitted Applications (${apps.length})',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ),
        ...apps.map((app) {
          final statusBg = _applicationStatusBackground(app.status, isDark);
          final statusColor = _applicationStatusColor(app.status, isDark);
          final matchingJob =
              db.jobsList.firstWhereOrNull((j) => j.id == app.jobId);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: matchingJob != null
                  ? () => Get.to(() => JobDetailView(job: matchingJob))
                  : null,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: app.status == ApplicationStatus.shortlisted ||
                            app.status == ApplicationStatus.offered
                        ? statusColor.withValues(alpha: 0.5)
                        : Colors.grey.withValues(alpha: 0.12),
                    width: app.status == ApplicationStatus.shortlisted ||
                            app.status == ApplicationStatus.offered
                        ? 1.5
                        : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            app.companyName.isNotEmpty
                                ? app.companyName
                                : 'Company',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            app.status.label,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusBg.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(_getStatusIcon(app.status),
                              size: 15, color: statusColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getStatusLine(app.status),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSavedCompaniesPanel(UserModel? user, bool isDark) {
    final profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : null;
    final db = Get.find<DatabaseService>();

    final companies = profileController != null &&
            profileController.favoriteCompanies.isNotEmpty
        ? profileController.favoriteCompanies
        : (user?.favoriteCompanies.isNotEmpty == true
            ? user!.favoriteCompanies
            : <CompanyProfile>[]);

    if (companies.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bookmark_border_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Saved Companies Yet',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bookmark companies while browsing jobs to easily access them here anytime.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.travel_explore_rounded,
                    size: 18, color: Colors.white),
                label: Text(
                  'Explore Companies',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  Get.until((route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Saved Companies (${companies.length})',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ),
        ...companies.map((company) {
          final icon = companyIconForKey(company.iconKey);
          final matchingJobs = db.jobsList
              .where((j) =>
                  j.companyName.trim().toLowerCase() ==
                  company.name.trim().toLowerCase())
              .toList();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: icon.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon.icon, color: icon.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: matchingJobs.isNotEmpty
                          ? () {
                              if (matchingJobs.length == 1) {
                                Get.to(() =>
                                    JobDetailView(job: matchingJobs.first));
                              } else {
                                Get.bottomSheet(
                                  _buildCompanyJobsSheet(company, matchingJobs),
                                  isScrollControlled: true,
                                );
                              }
                            }
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (company.location.isNotEmpty) ...[
                                Expanded(
                                  child: Text(
                                    company.location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                              if (company.location.isNotEmpty &&
                                  matchingJobs.isNotEmpty)
                                const SizedBox(width: 6),
                              if (matchingJobs.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${matchingJobs.length} active ${matchingJobs.length == 1 ? "job" : "jobs"}',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove from saved',
                    icon: const Icon(
                      Icons.bookmark_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    onPressed: () {
                      if (profileController != null) {
                        profileController.toggleFavoriteCompany(company);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCompanyJobsSheet(CompanyProfile company, List<JobModel> jobs) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Jobs at ${company.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Get.back(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: jobs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final job = jobs[index];
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side:
                        BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  title: Text(
                    job.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${job.location} • ${job.jobType}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Get.back();
                    Get.to(() => JobDetailView(job: job));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLine(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.shortlisted:
        return 'You have been shortlisted by the recruiter!';
      case ApplicationStatus.interviewing:
        return 'An interview has been scheduled for this position.';
      case ApplicationStatus.offered:
        return 'Congratulations! You received a job offer!';
      case ApplicationStatus.rejected:
        return 'Application not selected for this position.';
      case ApplicationStatus.applied:
        return 'Application submitted. Under recruiter review.';
    }
  }

  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.shortlisted:
        return Icons.auto_awesome;
      case ApplicationStatus.interviewing:
        return Icons.schedule;
      case ApplicationStatus.offered:
        return Icons.celebration;
      case ApplicationStatus.rejected:
        return Icons.cancel_outlined;
      case ApplicationStatus.applied:
        return Icons.check_circle_outline_rounded;
    }
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

  Widget _buildMentorshipSessionsPanel(UserModel? user, bool isDark) {
    final db = Get.find<DatabaseService>();
    final authService =
        Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
    final isCandidateSelf = widget.candidateUser == null ||
        widget.candidateUser?.id == authService?.currentUser.value?.id;
    final firebaseUid =
        isCandidateSelf ? (authService?.firebaseUser.value?.uid ?? '') : '';
    final candidateId = (user?.id ?? '').trim();
    final candidateEmail = (user?.email ?? '').trim().toLowerCase();

    final sessions = db.bookingsList.where((b) {
      if (candidateId.isNotEmpty && b.candidateId.trim() == candidateId) {
        return true;
      }
      if (firebaseUid.isNotEmpty && b.candidateId.trim() == firebaseUid) {
        return true;
      }
      if (candidateEmail.isNotEmpty &&
          b.candidateEmail.trim().toLowerCase() == candidateEmail) {
        return true;
      }
      if (b.status == 'Confirmed' && b.mentorId.isNotEmpty) {
        return true;
      }
      if (b.candidateId.trim().isEmpty ||
          b.candidateId.trim().startsWith('cand_') ||
          b.candidateName.trim().toLowerCase().contains('candidate') ||
          b.candidateName.trim().toLowerCase().contains('mentee')) {
        return true;
      }
      return false;
    }).toList();

    if (sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.videocam_outlined,
                size: 48,
                color: Colors.grey.withOpacity(0.6),
              ),
              const SizedBox(height: 12),
              Text(
                'No 1:1 video calls booked yet',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Explore the Mentors tab to book 1:1 sessions, mock interviews, and career guidance.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: sessions.map((booking) {
        final formattedDate =
            '${booking.scheduledAt.day}/${booking.scheduledAt.month}/${booking.scheduledAt.year} • ${booking.scheduledAt.hour > 12 ? booking.scheduledAt.hour - 12 : (booking.scheduledAt.hour == 0 ? 12 : booking.scheduledAt.hour)}:${booking.scheduledAt.minute.toString().padLeft(2, '0')} ${booking.scheduledAt.hour >= 12 ? 'PM' : 'AM'}';
        final isDm = booking.serviceType.toLowerCase().contains('priority dm') ||
            booking.serviceType.toLowerCase().contains('dm');

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mentor Info Row + Status Badge
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      booking.mentorName.isNotEmpty
                          ? booking.mentorName[0].toUpperCase()
                          : 'M',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.mentorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Expert Mentor',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: booking.status == 'Completed'
                          ? const Color(0xFFD1FAE5)
                          : (booking.status == 'Cancelled'
                              ? const Color(0xFFFEE2E2)
                              : AppColors.primary.withOpacity(0.12)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking.status,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: booking.status == 'Completed'
                            ? const Color(0xFF065F46)
                            : (booking.status == 'Cancelled'
                                ? Colors.red
                                : AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Service Title & Time
              Text(
                booking.serviceTitle,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.event_outlined,
                      size: 15, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${booking.amount.toStringAsFixed(booking.amount % 1 == 0 ? 0 : 2)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              if (booking.userQuery.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.help_outline,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          booking.userQuery,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Action Buttons
              if (booking.status == 'Completed') ...[
                if (isDm) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      onPressed: () {
                        PriorityDmChatView.openChat(
                          context,
                          booking: booking,
                          isMentor: false,
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                      label: Text(
                        'View Chat History (Preserved)',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '1:1 Session Completed',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else if (booking.status != 'Cancelled') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDm ? const Color(0xFF4F46E5) : const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    onPressed: () {
                      if (isDm) {
                        PriorityDmChatView.openChat(
                          context,
                          booking: booking,
                          isMentor: false,
                        );
                      } else {
                        AgoraVideoCallView.startCall(
                          context,
                          booking: booking,
                          isMentor: false,
                        );
                      }
                    },
                    icon: Icon(
                      isDm ? Icons.chat_bubble_rounded : Icons.videocam_rounded,
                      size: 20,
                    ),
                    label: Text(
                      isDm ? 'Open Priority DM Chat' : 'Join Agora 1:1 Video Call',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ] else if (isDm) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onPressed: () {
                      PriorityDmChatView.openChat(
                        context,
                        booking: booking,
                        isMentor: false,
                      );
                    },
                    icon: const Icon(Icons.history_rounded, size: 18, color: AppColors.primary),
                    label: Text(
                      'View Chat History (Cancelled Session)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
