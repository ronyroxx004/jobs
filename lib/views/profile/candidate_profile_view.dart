import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/job_controller.dart';
import '../../core/utils/constants.dart';
import '../../core/routes/app_routes.dart';
import '../../services/database_service.dart';

class CandidateProfileView extends GetView<ProfileController> {
  const CandidateProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final jobController = Get.find<JobController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        final dbService = Get.find<DatabaseService>();
        await dbService.fetchAllData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Card
            Obx(() {
              final user = controller.user;
              return Card(
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
                                    AppColors.primary.withOpacity(0.1),
                                backgroundImage:
                                    user?.avatarUrl.isNotEmpty == true
                                        ? NetworkImage(user!.avatarUrl)
                                        : null,
                                child: user?.avatarUrl.isNotEmpty == true
                                    ? null
                                    : user?.avatarIconKey.isNotEmpty == true
                                        ? Icon(
                                            _iconForAvatarKey(
                                                user!.avatarIconKey),
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
                                    child: const Icon(Icons.camera_alt,
                                        color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'User',
                                  style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.headline.isNotEmpty == true
                                      ? user!.headline
                                      : 'Add a headline to describe your professional role',
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
                                    const Icon(Icons.location_on_outlined,
                                        size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      user?.location.isNotEmpty == true
                                          ? user!.location
                                          : 'Set location',
                                      style: GoogleFonts.inter(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                if ((user?.experienceYears ?? 0) > 0) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.work_outline,
                                          size: 14, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${user!.experienceYears} years experience',
                                        style: GoogleFonts.inter(
                                            fontSize: 11, color: Colors.grey),
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
                            icon: const Icon(Icons.edit_outlined,
                                color: AppColors.primary),
                          ),
                        ],
                      ),
                      if (user?.email.isNotEmpty == true ||
                          user?.phone.isNotEmpty == true) ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 18,
                          runSpacing: 10,
                          children: [
                            if (user?.email.isNotEmpty == true)
                              _ProfileContact(
                                icon: Icons.email_outlined,
                                text: user!.email,
                              ),
                            if (user?.phone.isNotEmpty == true)
                              _ProfileContact(
                                icon: Icons.phone_outlined,
                                text: user!.phone,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            Obx(() {
              final bio = controller.user?.bio ?? '';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.bold),
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
              );
            }),

            const SizedBox(height: 16),

            // Skills Card
            Obx(() {
              final skills = controller.user?.skills ?? [];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Technical Skills',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      if (skills.isEmpty)
                        Text(
                          'No skills added yet. Tap Edit Profile to add skills.',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: skills.map((s) {
                            return Chip(
                              label: Text(s),
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.12),
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
              );
            }),

            if (controller.user?.role == UserRole.candidate) ...[
              const SizedBox(height: 16),

              // My Applications Pipeline
              Text(
                'My Job Applications',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Obx(() {
                final apps = jobController.myApplications;
                if (apps.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.assignment_outlined,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              'You have not applied for any jobs yet',
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: Colors.grey),
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
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: app.status.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:
                              Icon(Icons.work_history, color: app.status.color),
                        ),
                        title: Text(app.jobTitle,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text(
                            '${app.companyName} • Applied ${app.appliedAt.day}/${app.appliedAt.month}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
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
                      ),
                    );
                  },
                );
              }),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
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
        child: Column(
          mainAxisSize: MainAxisSize.max,
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
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick an icon for your ${role.displayName.toLowerCase()} profile.',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.builder(
                itemCount: options.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.9,
                  mainAxisExtent: 86,
                ),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected =
                      profileController.user?.avatarIconKey == option.key;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () =>
                        profileController.setProfileAvatarIcon(option.key),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                option.color.withValues(alpha: 0.22),
                                option.color.withValues(alpha: 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? option.color
                                  : option.color.withValues(alpha: 0.25),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            option.icon,
                            color: option.color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          option.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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

class _AvatarOption {
  const _AvatarOption(this.key, this.label, this.icon, this.color);

  final String key;
  final String label;
  final IconData icon;
  final Color color;
}

class _ProfileContact extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ProfileContact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.inter(fontSize: 12)),
      ],
    );
  }
}
