import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/company_icons.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/company_profile.dart';
import '../../models/user_model.dart';
import '../../models/job_model.dart';
import '../../controllers/job_controller.dart';
import '../../core/routes/app_routes.dart';
import '../admin/admin_shared.dart';
import '../candidate_activity_view.dart';
import 'edit_profile_view.dart';

class CandidateProfileView extends StatefulWidget {
  final UserModel? candidateUser;
  final bool isAdminView;

  const CandidateProfileView({
    super.key,
    this.candidateUser,
    this.isAdminView = false,
  });

  @override
  State<CandidateProfileView> createState() => _CandidateProfileViewState();
}

class _CandidateProfileViewState extends State<CandidateProfileView> {
  UserModel? get _effectiveUser {
    final target = widget.candidateUser ??
        (Get.arguments is UserModel ? Get.arguments as UserModel : null);
    if (target != null) {
      if (Get.isRegistered<DatabaseService>()) {
        final db = Get.find<DatabaseService>();
        return db.usersList.firstWhereOrNull((u) => u.id == target.id) ??
            target;
      }
      return target;
    }
    if (Get.isRegistered<ProfileController>()) {
      return Get.find<ProfileController>().user;
    }
    return null;
  }

  bool get _isAdminView =>
      widget.isAdminView ||
      widget.candidateUser != null ||
      (Get.arguments is UserModel);

  void _openEditProfile(BuildContext context) {
    final user = _effectiveUser;
    if (user == null) return;
    Get.to(
      () => EditProfileView(targetUser: user),
      transition: Transition.rightToLeft,
    );
  }

  Future<void> _confirmDeleteJob(BuildContext context, JobModel job) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete job post?'),
        content: Text(
          '“${job.title}” will be removed from job listings. Existing application records will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      if (Get.isRegistered<JobController>()) {
        await Get.find<JobController>().deleteJob(job);
      } else {
        await Get.find<DatabaseService>().deleteJob(job.id);
      }
      Get.snackbar(
        'Job post deleted',
        '“${job.title}” has been removed.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Could not delete job post',
        'Please try again. $error',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = RefreshIndicator(
      onRefresh: () async {
        final dbService = Get.find<DatabaseService>();
        await dbService.fetchAllData();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Obx(() {
            final user = _effectiveUser;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                                backgroundImage:
                                    user?.avatarUrl.isNotEmpty == true
                                        ? NetworkImage(user?.avatarUrl ?? '')
                                        : null,
                                child: user?.avatarUrl.isNotEmpty == true
                                    ? null
                                    : user?.avatarIconKey.isNotEmpty == true
                                        ? Icon(
                                            _iconForAvatarKey(
                                                user?.avatarIconKey ?? ''),
                                            size: 38,
                                            color: AppColors.primary,
                                          )
                                        : Text(
                                            user?.name.isNotEmpty == true
                                                ? user!.name[0]
                                                : 'U',
                                            style: GoogleFonts.inter(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: () => _showAvatarPicker(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'User',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.headline.isNotEmpty == true
                                      ? user?.headline ?? ''
                                      : 'Add a headline to describe your professional role',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        user?.location.isNotEmpty == true
                                            ? user?.location ?? ''
                                            : 'Set location',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if ((user?.experienceYears ?? 0) > 0) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.work_outline,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          '${user?.experienceYears ?? 0} years experience',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit profile and manage resumes',
                            onPressed: () => _openEditProfile(context),
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 18,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (user?.email.isNotEmpty == true)
                            _ProfileContact(
                              icon: Icons.email_outlined,
                              text: user?.email ?? '',
                            ),
                          if (user?.phone.isNotEmpty == true)
                            _ProfileContact(
                              icon: Icons.phone_outlined,
                              text: user?.phone ?? '',
                            )
                          else
                            InkWell(
                              onTap: () => _openEditProfile(context),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add_ic_call_outlined,
                                        size: 15, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Add mobile number',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  user?.role.displayName ?? 'Role',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Active Mode',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          PopupMenuButton<UserRole>(
                            tooltip: 'Switch Active Role',
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.4)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.swap_horiz_rounded,
                                      size: 16, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Switch Role',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onSelected: (newRole) {
                              if (Get.isRegistered<AuthController>()) {
                                Get.find<AuthController>()
                                    .switchRoleAndNavigate(newRole);
                              }
                            },
                            itemBuilder: (context) => [
                              UserRole.candidate,
                              UserRole.mentor,
                              UserRole.recruiter,
                              UserRole.admin,
                            ].map((r) {
                              final isCurrent = user?.role == r;
                              return PopupMenuItem<UserRole>(
                                value: r,
                                child: Row(
                                  children: [
                                    Icon(
                                      isCurrent
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked,
                                      size: 16,
                                      color: isCurrent
                                          ? AppColors.primary
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      r.displayName,
                                      style: GoogleFonts.inter(
                                        fontWeight: isCurrent
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color:
                                            isCurrent ? AppColors.primary : null,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          Obx(() {
            final user = _effectiveUser;
            if (user?.role != UserRole.recruiter) return const SizedBox.shrink();

            final companies = user?.companies.isNotEmpty == true
                ? user?.companies ?? []
                : (user?.companyName.isNotEmpty == true
                    ? [
                        CompanyProfile(
                          id: 'company_${user?.id ?? ''}',
                          name: user?.companyName ?? '',
                          location: user?.companyLocation ?? '',
                          iconKey: user?.companyIconKey.isNotEmpty == true
                              ? user?.companyIconKey ?? ''
                              : 'business',
                        ),
                      ]
                    : <CompanyProfile>[]);

            if (companies.isEmpty) {
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.add_business_outlined,
                      color: AppColors.primary),
                  title: const Text('Add your companies'),
                  subtitle:
                      const Text('Manage the companies you recruit for.'),
                  onTap: () => _openEditProfile(context),
                ),
              );
            }

            return Column(
              children: companies.map((company) {
                final icon = companyIconForKey(company.iconKey);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: icon.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon.icon, color: icon.color),
                    ),
                    title: Text(
                      company.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      company.location.isEmpty
                          ? 'Company place not added'
                          : company.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: 'Edit companies',
                      onPressed: () => _openEditProfile(context),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }),

          Obx(() {
            final user = _effectiveUser;
            if (user?.role != UserRole.recruiter) return const SizedBox.shrink();

            final db = Get.find<DatabaseService>();
            final currentUserId = user?.id ?? '';
            final recruiterJobs = db.jobsList.where((j) {
              if (j.isDeleted) return false;
              if (j.recruiterId == currentUserId) return true;
              if (currentUserId.isNotEmpty && j.recruiterId.startsWith('rec_')) return true;
              if (user != null &&
                  user.companies.any((c) =>
                      c.name.trim().toLowerCase() ==
                      j.companyName.trim().toLowerCase())) {
                return true;
              }
              if (user != null &&
                  user.companyName.isNotEmpty &&
                  user.companyName.trim().toLowerCase() ==
                      j.companyName.trim().toLowerCase()) {
                return true;
              }
              return false;
            }).toList();

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Posted Jobs (${recruiterJobs.length})',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (recruiterJobs.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${recruiterJobs.where((j) => j.isActive).length} Live',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (recruiterJobs.isEmpty)
                      Text(
                        'No jobs posted yet.',
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                      )
                    else
                      Column(
                        children: recruiterJobs.map((job) {
                          return InkWell(
                            onTap: () => Get.toNamed(
                              AppRoutes.recruiterApplicants,
                              arguments: job,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.work_outline_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          job.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${job.companyName.isNotEmpty ? job.companyName : "Company"} • ${job.location}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (job.isActive
                                              ? AppColors.secondary
                                              : AppColors.warning)
                                          .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      job.isActive ? 'Live' : 'Paused',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: job.isActive
                                            ? AppColors.secondary
                                            : AppColors.warning,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    tooltip: 'Delete job post',
                                    onPressed: () => _confirmDeleteJob(context, job),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            );
          }),

          Obx(() {
            final user = _effectiveUser;
            if ((user?.role ?? UserRole.candidate) != UserRole.candidate) {
              return const SizedBox.shrink();
            }

            final db = Get.find<DatabaseService>();
            final authService = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
            final candidateId = (user?.id ?? '').trim();
            final candidateEmail = (user?.email ?? '').trim().toLowerCase();
            final myFirebaseUid = !_isAdminView ? (authService?.firebaseUser.value?.uid ?? '').trim() : '';

            final appsCount = db.applicationsList.where((a) {
              if (candidateId.isNotEmpty && a.candidateId.trim() == candidateId) return true;
              if (myFirebaseUid.isNotEmpty && a.candidateId.trim() == myFirebaseUid) return true;
              if (candidateEmail.isNotEmpty && a.candidateEmail.trim().toLowerCase() == candidateEmail) return true;
              return false;
            }).length;

            final profileController = Get.isRegistered<ProfileController>() ? Get.find<ProfileController>() : null;
            final savedCompaniesList = profileController != null && profileController.favoriteCompanies.isNotEmpty
                ? profileController.favoriteCompanies
                : (user?.favoriteCompanies ?? <CompanyProfile>[]);
            final savedCount = savedCompaniesList.length;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildOverviewNavButton(
                            label: 'Applied',
                            count: appsCount,
                            icon: Icons.assignment_rounded,
                            value: 'applications',
                            onTap: () {
                              Get.to(() => CandidateApplicationsView(candidateUser: user));
                            },
                            isSelected: false,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildOverviewNavButton(
                            label: 'Saved',
                            count: savedCount,
                            icon: Icons.bookmark_rounded,
                            value: 'savedCompanies',
                            onTap: () {
                              Get.to(() => SavedCompaniesView(candidateUser: user));
                            },
                            isSelected: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          Obx(() {
            final bio = _effectiveUser?.bio ?? '';
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bio.isNotEmpty
                            ? bio
                            : 'Add a short professional summary to introduce your background and goals.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.5,
                          color: bio.isEmpty ? Colors.grey : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          Obx(() {
            final skills = _effectiveUser?.skills ?? [];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Technical Skills',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (skills.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: skills.map((s) {
                            return Chip(
                              label: Text(s),
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
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
        ],
      ),
    );

    if (_isAdminView) {
      return Scaffold(
        appBar: AppBar(
          title: Obx(() => Text(
                _effectiveUser?.name.isNotEmpty == true
                    ? _effectiveUser!.name
                    : (_effectiveUser?.role == UserRole.recruiter
                        ? 'Recruiter Profile'
                        : 'Candidate Profile'),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              )),
          actions: [
            IconButton(
              tooltip: 'Edit Profile',
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: () => _openEditProfile(context),
            ),
            IconButton(
              tooltip: _effectiveUser?.role == UserRole.recruiter
                  ? 'Delete Recruiter'
                  : 'Delete Candidate',
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                final user = _effectiveUser;
                if (user != null) {
                  adminConfirmDeleteUser(user);
                }
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(child: content),
      );
    }

    return content;
  }

  Widget _buildOverviewNavButton({
    required String label,
    required int count,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isSelected
          ? AppColors.primary
          : isDark
              ? AppColors.cardDark
              : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Colors.grey.withValues(alpha: isDark ? 0.2 : 0.15),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        icon,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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

  void _showAvatarPicker(BuildContext context) {
    final user = _effectiveUser;
    final role = user?.role ?? UserRole.candidate;
    final options = _avatarOptionsFor(role);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.bottomSheet(
      SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Choose your profile icon',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    return InkWell(
                      onTap: () {
                        if (_isAdminView && user != null) {
                          final updated = user.copyWith(
                            avatarIconKey: option.key,
                            avatarUrl: '',
                          );
                          final dbService = Get.find<DatabaseService>();
                          dbService.saveUserProfile(updated);
                          final idx = dbService.usersList
                              .indexWhere((u) => u.id == updated.id);
                          if (idx != -1) {
                            dbService.usersList[idx] = updated;
                          }
                          if (Get.isRegistered<AdminController>()) {
                            Get.find<AdminController>().updateUserProfile(updated);
                          }
                        } else {
                          Get.find<ProfileController>()
                              .setProfileAvatarIcon(option.key);
                        }
                        Get.back();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _iconForAvatarKey(option.key),
                          size: 30,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  IconData _iconForAvatarKey(String key) {
     for (final options in _roleAvatarOptions.values) {
       for (final option in options) {
         if (option.key == key) return option.icon;
       }
     }
     return Icons.person_rounded;
   }

  List<_AvatarOption> _avatarOptionsFor(UserRole role) =>
      _roleAvatarOptions[role] ?? _roleAvatarOptions[UserRole.candidate]!;

  final Map<UserRole, List<_AvatarOption>> _roleAvatarOptions = {
    UserRole.candidate: [
      _AvatarOption('candidate_rocket', 'Rocket', Icons.rocket_launch_rounded,
          const Color(0xFF7C3AED)),
      _AvatarOption('candidate_code', 'Developer', Icons.code_rounded,
          const Color(0xFF2563EB)),
      _AvatarOption('candidate_star', 'Achiever', Icons.workspace_premium_rounded,
          const Color(0xFFF59E0B)),
      _AvatarOption('candidate_palette', 'Creative', Icons.palette_rounded,
          const Color(0xFFEC4899)),
      _AvatarOption('candidate_explore', 'Explorer', Icons.explore_rounded,
          const Color(0xFF0F766E)),
      _AvatarOption('candidate_build', 'Builder', Icons.construction_rounded,
          const Color(0xFFEA580C)),
      _AvatarOption('candidate_flash', 'Quick Learner', Icons.bolt_rounded,
          const Color(0xFFD97706)),
      _AvatarOption('candidate_person', 'Professional', Icons.person_rounded,
          const Color(0xFF475569)),
      _AvatarOption('candidate_trending', 'Rising Star',
          Icons.trending_up_rounded, const Color(0xFF16A34A)),
      _AvatarOption('candidate_terminal', 'Tech Pro', Icons.terminal_rounded,
          const Color(0xFF4F46E5)),
      _AvatarOption('candidate_trophy', 'Top Talent', Icons.emoji_events_rounded,
          const Color(0xFFCA8A04)),
    ],
    UserRole.recruiter: [
      _AvatarOption('recruiter_business', 'Business',
          Icons.business_center_rounded, const Color(0xFF2563EB)),
      _AvatarOption('recruiter_groups', 'People', Icons.groups_rounded,
          const Color(0xFF0891B2)),
      _AvatarOption('recruiter_handshake', 'Partner', Icons.handshake_rounded,
          const Color(0xFF10B981)),
      _AvatarOption('recruiter_star', 'Leader', Icons.stars_rounded,
          const Color(0xFFF59E0B)),
      _AvatarOption('recruiter_search', 'Talent Scout',
          Icons.manage_search_rounded, const Color(0xFF7C3AED)),
      _AvatarOption('recruiter_badge', 'Executive', Icons.military_tech_rounded,
          const Color(0xFFDC2626)),
      _AvatarOption('recruiter_connect', 'Connector',
          Icons.connect_without_contact_rounded, const Color(0xFF0F766E)),
      _AvatarOption('recruiter_person', 'Professional', Icons.person_rounded,
          const Color(0xFF475569)),
      _AvatarOption('recruiter_target', 'Goal Setter',
          Icons.track_changes_rounded, const Color(0xFFEA580C)),
      _AvatarOption('recruiter_verified', 'Trusted', Icons.verified_rounded,
          const Color(0xFF0284C7)),
      _AvatarOption('recruiter_graph', 'Strategist', Icons.query_stats_rounded,
          const Color(0xFF4F46E5)),
    ],
    UserRole.mentor: [
      _AvatarOption('mentor_mind', 'Mentor', Icons.psychology_rounded,
          const Color(0xFF7C3AED)),
      _AvatarOption('mentor_bulb', 'Ideas', Icons.lightbulb_rounded,
          const Color(0xFFF59E0B)),
      _AvatarOption('mentor_school', 'Guide', Icons.school_rounded,
          const Color(0xFF2563EB)),
      _AvatarOption('mentor_support', 'Support', Icons.support_agent_rounded,
          const Color(0xFF10B981)),
      _AvatarOption('mentor_compass', 'Advisor', Icons.explore_rounded,
          const Color(0xFF0F766E)),
      _AvatarOption('mentor_favorite', 'Encourager', Icons.favorite_rounded,
          const Color(0xFFDB2777)),
      _AvatarOption('mentor_trophy', 'Motivator', Icons.emoji_events_rounded,
          const Color(0xFFCA8A04)),
      _AvatarOption('mentor_person', 'Professional', Icons.person_rounded,
          const Color(0xFF475569)),
      _AvatarOption('mentor_route', 'Pathfinder', Icons.alt_route_rounded,
          const Color(0xFF0284C7)),
      _AvatarOption('mentor_growth', 'Growth Guide', Icons.trending_up_rounded,
          const Color(0xFF16A34A)),
      _AvatarOption('mentor_chat', 'Listener', Icons.forum_rounded,
          const Color(0xFF7C3AED)),
    ],
    UserRole.instructor: [
      _AvatarOption('instructor_teach', 'Instructor',
          Icons.cast_for_education_rounded, const Color(0xFF2563EB)),
      _AvatarOption('instructor_book', 'Learning', Icons.menu_book_rounded,
          const Color(0xFF0891B2)),
      _AvatarOption('instructor_science', 'Science', Icons.science_rounded,
          const Color(0xFF7C3AED)),
      _AvatarOption('instructor_computer', 'Technology', Icons.computer_rounded,
          const Color(0xFF10B981)),
      _AvatarOption('instructor_draw', 'Creative', Icons.draw_rounded,
          const Color(0xFFDB2777)),
      _AvatarOption('instructor_quiz', 'Quiz Master', Icons.quiz_rounded,
          const Color(0xFFEA580C)),
      _AvatarOption('instructor_language', 'Languages', Icons.translate_rounded,
          const Color(0xFF0F766E)),
      _AvatarOption('instructor_person', 'Professional', Icons.person_rounded,
          const Color(0xFF475569)),
      _AvatarOption('instructor_award', 'Expert', Icons.workspace_premium_rounded,
          const Color(0xFFCA8A04)),
      _AvatarOption('instructor_video', 'Presenter',
          Icons.video_camera_front_rounded, const Color(0xFF0284C7)),
      _AvatarOption('instructor_idea', 'Innovator',
          Icons.tips_and_updates_rounded, const Color(0xFF4F46E5)),
    ],
  };
}

class _AvatarOption {
  const _AvatarOption(this.key, this.label, this.icon, this.color);

  final String key;
  final String label;
  final IconData icon;
  final Color color;
}

class _ProfileContact extends StatelessWidget {
  const _ProfileContact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
