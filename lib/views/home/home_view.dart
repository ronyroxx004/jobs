import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/utils/constants.dart';
import '../../core/routes/app_routes.dart';
import '../jobs/job_list_view.dart';
import '../courses/course_list_view.dart';
import '../mentorship/mentor_list_view.dart';
import '../profile/candidate_profile_view.dart';
import '../admin/admin_dashboard_view.dart';
import '../admin/admin_candidates_view.dart';
import '../admin/admin_recruiters_view.dart';
import '../admin/admin_mentors_view.dart';
import '../admin/admin_instructors_view.dart';
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
          indicatorColor: AppColors.primary.withValues(alpha: 0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: tabs.asMap().entries.map((entry) {
            final tab = entry.value;
            final isSelected = selectedIndex == entry.key;

            final iconWidget = Icon(
              isSelected ? tab.selectedIcon : tab.icon,
              color: isSelected ? AppColors.primary : null,
            );

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
              Icons.person_rounded, AdminCandidatesView()),
          _HomeTab('Recruiters', Icons.business_outlined,
              Icons.business_rounded, AdminRecruitersView()),
          _HomeTab('Mentors', Icons.psychology_outlined,
              Icons.psychology_alt_rounded, AdminMentorsView()),
          _HomeTab('Instructors', Icons.school_outlined,
              Icons.school_rounded, AdminInstructorsView()),
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
