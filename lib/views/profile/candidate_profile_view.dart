import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/profile_controller.dart';
import '../../controllers/job_controller.dart';
import '../../core/utils/constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/company_icons.dart';
import '../../services/database_service.dart';
import '../../models/company_profile.dart';

class CandidateProfileView extends StatefulWidget {
  const CandidateProfileView({super.key});

  @override
  State<CandidateProfileView> createState() => _CandidateProfileViewState();
}

class _CandidateProfileViewState extends State<CandidateProfileView> {
  String _selectedSection = 'applications';

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    final jobController = Get.find<JobController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        final dbService = Get.find<DatabaseService>();
        await dbService.fetchAllData();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Obx(() {
            final user = controller.user;
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
                            onPressed: () => Get.toNamed(AppRoutes.editProfile),
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
                              onTap: () => Get.toNamed(AppRoutes.editProfile),
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
                    ],
                  ),
                ),
              ),
            );
          }),

          if (controller.user?.role == UserRole.recruiter) ...[
            Obx(() {
              final user = controller.user;
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
                    onTap: () => Get.toNamed(AppRoutes.editProfile),
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
                        onPressed: () => Get.toNamed(AppRoutes.editProfile),
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
          ],

          if (controller.user?.role == UserRole.candidate) ...[
            Card(
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
                          child: InkWell(
                            onTap: () => Get.toNamed(
                              AppRoutes.candidateActivity,
                              arguments: {'tab': 'applications'},
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.assignment_rounded,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Applied',
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => Get.toNamed(
                              AppRoutes.candidateActivity,
                              arguments: {'tab': 'savedCompanies'},
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.bookmark_rounded,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Saved',
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          Obx(() {
            final bio = controller.user?.bio ?? '';
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
            final skills = controller.user?.skills ?? [];
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
                      const SizedBox(height: 10),
                      if (skills.isEmpty)
                        Text(
                          'No skills added yet. Tap Edit Profile to add skills.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        )
                      else
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
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
        ],
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
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You have not applied for any jobs yet',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

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
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assignment_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'My Job Applications',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...apps.map((app) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final statusBg = _applicationStatusBackground(app.status, isDark);
                final statusColor = _applicationStatusColor(app.status, isDark);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.work_history_rounded,
                          size: 20,
                          color: statusColor,
                        ),
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
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              app.companyName,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Applied ${app.appliedAt.day}/${app.appliedAt.month}/${app.appliedAt.year}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
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
                );
              }).toList(),
            ],
          ),
        ),
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
          child: Center(
            child: Column(
              children: [
                const Icon(
                  Icons.bookmark_border_rounded,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 10),
                Text(
                  'No saved companies yet',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bookmark_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Saved Companies',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...companies.map((company) {
              final icon = companyIconForKey(company.iconKey);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.cardDark
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: icon.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon.icon, color: icon.color),
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
                              fontSize: 14,
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
                                fontSize: 11,
                                color: Colors.grey,
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
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showAvatarPicker(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    final role = profileController.user?.role ?? UserRole.candidate;
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
                        profileController.setProfileAvatarIcon(option.key);
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
