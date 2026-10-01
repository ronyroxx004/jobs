import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/utils/constants.dart';
import '../../core/routes/app_routes.dart';
import '../../services/database_service.dart';
import '../jobs/job_list_view.dart';
import '../courses/course_list_view.dart';
import '../mentorship/mentor_list_view.dart';
import '../profile/candidate_profile_view.dart';
import '../admin/admin_dashboard_view.dart';
import '../admin/admin_role_users_view.dart';
import '../instructor/instructor_dashboard_view.dart';
import '../recruiter/recruiter_jobs_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  HomeController get controller => Get.find<HomeController>();
  ThemeController get themeController =>
      Get.isRegistered<ThemeController>()
          ? Get.find<ThemeController>()
          : Get.put(ThemeController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Obx(() {
          final isLoggedIn = controller.isLoggedIn;
          final role = controller.currentRole;
          final tabs = _tabsFor(isLoggedIn, role);
          final selectedIndex =
              controller.selectedTabIndex.clamp(0, tabs.length - 1);
          final title = tabs[selectedIndex].title == _profileTitle
              ? controller.userName
              : tabs[selectedIndex].title;

          return Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          );
        }),
        actions: [
          Obx(() {
            final isLoggedIn = controller.isLoggedIn;
            final role = controller.currentRole;

            if (!isLoggedIn) {
              return Row(
                children: [
                  IconButton(
                    icon: Obx(() => Icon(
                          themeController.isDarkMode.value
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: AppColors.primary,
                          size: 22,
                        )),
                    tooltip: 'Toggle Light/Dark Mode',
                    onPressed: themeController.toggleTheme,
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => Get.toNamed(AppRoutes.login),
                    child: Text(
                      'Log in',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              );
            }

            return Row(
              children: [
                if (role == UserRole.instructor)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppColors.primary, size: 28),
                    tooltip: 'Post New Course',
                    onPressed: () => Get.toNamed(AppRoutes.postCourse),
                  ),
                IconButton(
                  icon: Obx(() => Icon(
                        themeController.isDarkMode.value
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: AppColors.primary,
                        size: 22,
                      )),
                  tooltip: 'Toggle Light/Dark Mode',
                  onPressed: themeController.toggleTheme,
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      color: Colors.grey, size: 22),
                  tooltip: 'Logout',
                  onPressed: authController.logout,
                ),
                const SizedBox(width: 8),
              ],
            );
          }),
        ],
      ),
      body: Obx(() {
        final isLoggedIn = controller.isLoggedIn;
        final role = controller.currentRole;
        final tabs = _tabsFor(isLoggedIn, role);
        final selectedIndex =
            controller.selectedTabIndex.clamp(0, tabs.length - 1);
        return SizedBox.expand(
          child: tabs[selectedIndex].page,
        );
      }),
      bottomNavigationBar: Obx(() {
        final isLoggedIn = controller.isLoggedIn;
        final role = controller.currentRole;
        final tabs = _tabsFor(isLoggedIn, role);
        final selectedIndex =
            controller.selectedTabIndex.clamp(0, tabs.length - 1);

        return NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            setState(() => controller.changeTab(index));
          },
          indicatorColor: AppColors.primary.withOpacity(0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final tab = entry.value;
            final isSelected = selectedIndex == index;

            Widget iconWidget;
            if (role == UserRole.admin && index < 4) {
              if (index == 0) {
                iconWidget = Icon(
                  isSelected ? Icons.person_rounded : Icons.person_outline_rounded,
                  color: isSelected ? AppColors.primary : null,
                );
              } else if (index == 1) {
                iconWidget = Icon(
                  isSelected ? Icons.business_center_rounded : Icons.business_rounded,
                  color: isSelected ? AppColors.primary : null,
                );
              } else {
                UserRole targetRole = index == 2 ? UserRole.mentor : UserRole.instructor;
                IconData fallback = index == 2 ? Icons.groups_rounded : Icons.cast_for_education_rounded;
                iconWidget = _buildRoleAvatarIcon(targetRole, fallback);
              }
            } else {
              iconWidget = Icon(isSelected ? tab.selectedIcon : tab.icon,
                  color: isSelected ? AppColors.primary : null);
            }

            return NavigationDestination(
              icon: iconWidget,
              selectedIcon: iconWidget,
              label: '',
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _buildRoleAvatarIcon(UserRole targetRole, IconData fallbackIcon) {
    try {
      final dbService = Get.find<DatabaseService>();
      final user =
          dbService.usersList.firstWhereOrNull((u) => u.role == targetRole);
      if (user != null) {
        if (user.avatarUrl.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              user.avatarUrl,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(fallbackIcon, size: 22),
            ),
          );
        } else if (user.avatarIconKey.isNotEmpty) {
          return Icon(_iconForAvatarKey(user.avatarIconKey),
              size: 22, color: AppColors.primary);
        }
      }
    } catch (_) {}
    return Icon(fallbackIcon, size: 22);
  }

  IconData _iconForAvatarKey(String key) {
    const Map<String, IconData> avatarIcons = {
      'candidate_rocket': Icons.rocket_launch_rounded,
      'candidate_code': Icons.code_rounded,
      'candidate_star': Icons.workspace_premium_rounded,
      'candidate_palette': Icons.palette_rounded,
      'candidate_explore': Icons.explore_rounded,
      'candidate_build': Icons.construction_rounded,
      'candidate_flash': Icons.bolt_rounded,
      'candidate_person': Icons.person_rounded,
      'candidate_trending': Icons.trending_up_rounded,
      'candidate_terminal': Icons.terminal_rounded,
      'candidate_trophy': Icons.emoji_events_rounded,
      'recruiter_business': Icons.business_center_rounded,
      'recruiter_groups': Icons.groups_rounded,
      'recruiter_handshake': Icons.handshake_rounded,
      'recruiter_star': Icons.stars_rounded,
      'recruiter_search': Icons.manage_search_rounded,
      'recruiter_badge': Icons.military_tech_rounded,
      'recruiter_connect': Icons.connect_without_contact_rounded,
      'recruiter_person': Icons.person_rounded,
      'recruiter_target': Icons.track_changes_rounded,
      'recruiter_verified': Icons.verified_rounded,
      'recruiter_graph': Icons.query_stats_rounded,
      'mentor_mind': Icons.psychology_rounded,
      'mentor_bulb': Icons.lightbulb_rounded,
      'mentor_school': Icons.school_rounded,
      'mentor_support': Icons.support_agent_rounded,
      'mentor_compass': Icons.explore_rounded,
      'mentor_favorite': Icons.favorite_rounded,
      'mentor_trophy': Icons.emoji_events_rounded,
      'mentor_person': Icons.person_rounded,
      'mentor_route': Icons.alt_route_rounded,
      'mentor_growth': Icons.trending_up_rounded,
      'mentor_chat': Icons.forum_rounded,
      'instructor_teach': Icons.cast_for_education_rounded,
      'instructor_book': Icons.menu_book_rounded,
      'instructor_science': Icons.science_rounded,
      'instructor_computer': Icons.computer_rounded,
      'instructor_draw': Icons.draw_rounded,
      'instructor_quiz': Icons.quiz_rounded,
      'instructor_language': Icons.translate_rounded,
      'instructor_person': Icons.person_rounded,
      'instructor_award': Icons.workspace_premium_rounded,
    };
    return avatarIcons[key] ?? Icons.person_rounded;
  }

  static const String _profileTitle = '__profile__';

  List<_HomeTab> _tabsFor(bool isLoggedIn, UserRole role) {
    if (!isLoggedIn) {
      return const [
        _HomeTab('Jobs', Icons.work_outline_rounded, Icons.work_rounded,
            JobListView()),
        _HomeTab('Mentors', Icons.groups_outlined, Icons.groups_rounded,
            MentorListView()),
        _HomeTab('Courses', Icons.local_library_outlined,
            Icons.local_library_rounded, CourseListView()),
      ];
    }
    if (role == UserRole.candidate) {
      return const [
        _HomeTab('Jobs', Icons.work_outline_rounded, Icons.work_rounded,
            JobListView()),
        _HomeTab('Mentors', Icons.groups_outlined, Icons.groups_rounded,
            MentorListView()),
        _HomeTab('Courses', Icons.local_library_outlined,
            Icons.local_library_rounded, CourseListView()),
        _HomeTab(_profileTitle, Icons.person_outline_rounded,
            Icons.person_rounded, CandidateProfileView()),
      ];
    }
    switch (role) {
      case UserRole.recruiter:
        return const [
          _HomeTab('Jobs', Icons.work_outline_rounded, Icons.work_rounded,
              RecruiterJobsView()),
          _HomeTab(_profileTitle, Icons.person_outline_rounded,
              Icons.person_rounded, CandidateProfileView()),
        ];
      case UserRole.mentor:
        return const [
          _HomeTab('Mentors', Icons.groups_outlined, Icons.groups_rounded,
              MentorListView()),
          _HomeTab(_profileTitle, Icons.person_outline_rounded,
              Icons.person_rounded, CandidateProfileView()),
        ];
      case UserRole.instructor:
        return const [
          _HomeTab('Instructor Portal', Icons.cast_for_education_outlined,
              Icons.cast_for_education_rounded, InstructorDashboardView()),
          _HomeTab(_profileTitle, Icons.person_outline_rounded,
              Icons.person_rounded, CandidateProfileView()),
        ];
      case UserRole.admin:
        return const [
          _HomeTab('Candidates', Icons.person_outline_rounded,
              Icons.person_rounded, AdminRoleUsersView(role: UserRole.candidate)),
          _HomeTab('Recruiters', Icons.business_rounded,
              Icons.business_center_rounded, AdminRoleUsersView(role: UserRole.recruiter)),
          _HomeTab('Mentors', Icons.groups_outlined,
              Icons.groups_rounded, AdminRoleUsersView(role: UserRole.mentor)),
          _HomeTab('Instructors', Icons.cast_for_education_outlined,
              Icons.cast_for_education_rounded, AdminRoleUsersView(role: UserRole.instructor)),
          _HomeTab('Dashboard', Icons.dashboard_outlined,
              Icons.dashboard_rounded, AdminDashboardView()),
        ];
      case UserRole.candidate:
        return const [
          _HomeTab('Jobs', Icons.work_outline_rounded, Icons.work_rounded,
              JobListView()),
          _HomeTab('Mentors', Icons.groups_outlined, Icons.groups_rounded,
              MentorListView()),
          _HomeTab('Courses', Icons.local_library_outlined,
              Icons.local_library_rounded, CourseListView()),
          _HomeTab(_profileTitle, Icons.person_outline_rounded,
              Icons.person_rounded, CandidateProfileView()),
        ];
    }
  }
}

class _HomeTab {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;

  const _HomeTab(this.title, this.icon, this.selectedIcon, this.page);
}
