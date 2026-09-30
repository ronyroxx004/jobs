import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../services/database_service.dart';
import '../../core/utils/constants.dart';
import '../../core/routes/app_routes.dart';
import '../jobs/job_list_view.dart';
import '../courses/course_list_view.dart';
import '../mentorship/mentor_list_view.dart';
import '../chat/chat_list_view.dart';
import '../profile/candidate_profile_view.dart';
import '../admin/admin_dashboard_view.dart';
import '../recruiter/recruiter_dashboard_view.dart';
import '../instructor/instructor_dashboard_view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  IconData _getRoleIcon(UserRole r) {
    switch (r) {
      case UserRole.candidate:
        return Icons.person;
      case UserRole.recruiter:
        return Icons.business_center;
      case UserRole.instructor:
        return Icons.cast_for_education;
      case UserRole.mentor:
        return Icons.school;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final authController = Get.find<AuthController>();
      final isLoggedIn = controller.isLoggedIn;
      final role = controller.currentRole;

      // Define pages depending on auth state
      final pages = isLoggedIn
          ? [
              const JobListView(),
              const CourseListView(),
              const MentorListView(),
              const ChatListView(),
              if (role == UserRole.admin)
                const AdminDashboardView()
              else if (role == UserRole.recruiter)
                const RecruiterDashboardView()
              else if (role == UserRole.instructor)
                const InstructorDashboardView()
              else
                const CandidateProfileView(),
            ]
          : [
              const JobListView(),
              const RecruiterDashboardView(),
              const InstructorDashboardView(),
              const MentorListView(),
            ];

      // Ensure index is within valid bounds
      if (controller.currentIndex.value >= pages.length) {
        controller.currentIndex.value = 0;
      }

      final currentIndex = controller.currentIndex.value;
      String getTitle() {
        if (isLoggedIn) {
          if (currentIndex == 0) return 'Jobs';
          if (currentIndex == 1) return 'Courses';
          if (currentIndex == 2) return 'Mentors';
          if (currentIndex == 3) return 'Chats';
          if (currentIndex == 4) {
            if (role == UserRole.admin) return 'Admin Dashboard';
            if (role == UserRole.recruiter) return 'Recruiter Portal';
            if (role == UserRole.instructor) return 'Instructor Portal';
            return 'Candidate Profile';
          }
        } else {
          if (currentIndex == 0) return 'Candidate Portal';
          if (currentIndex == 1) return 'Recruiter Portal';
          if (currentIndex == 2) return 'Instructor Portal';
          if (currentIndex == 3) return 'Mentor Portal';
        }
        return 'Jobs';
      }

      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            getTitle(),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          actions: isLoggedIn
              ? [
                  // Role Switcher Menu Button
                  PopupMenuButton<UserRole>(
                    tooltip: 'Switch Mode',
                    icon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getRoleIcon(role),
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            role.name.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 18),
                        ],
                      ),
                    ),
                    onSelected: (UserRole selectedRole) {
                      authController.switchRoleAndNavigate(selectedRole);
                    },
                    itemBuilder: (context) => UserRole.values.map((r) {
                      return PopupMenuItem<UserRole>(
                        value: r,
                        child: Row(
                          children: [
                            Icon(
                              _getRoleIcon(r),
                              size: 18,
                              color: r == role ? AppColors.primary : Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            Text(r.displayName, style: GoogleFonts.inter(fontSize: 13)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(width: 8),

                  // Post Job Button for Recruiters
                  if (role == UserRole.recruiter)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 28),
                      tooltip: 'Post New Job',
                      onPressed: () => Get.toNamed(AppRoutes.postJob),
                    ),

                  // Post Course Button for Instructors
                  if (role == UserRole.instructor)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 28),
                      tooltip: 'Post New Course',
                      onPressed: () => Get.toNamed(AppRoutes.postCourse),
                    ),

                  // Manual Page Refresh Action Button
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 22),
                    tooltip: 'Refresh Page',
                    onPressed: () async {
                      final dbService = Get.find<DatabaseService>();
                      await dbService.fetchAllData();
                      Get.snackbar(
                        'Page Refreshed',
                        'Page data updated successfully',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.primary,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                    },
                  ),
                  const SizedBox(width: 4),

                  // Theme Toggle Button (Light / Dark Mode) placed on the left side of Logout button
                  IconButton(
                    icon: Obx(() => Icon(
                          Get.find<ThemeController>().isDarkMode.value
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: AppColors.primary,
                          size: 22,
                        )),
                    tooltip: 'Toggle Light/Dark Mode',
                    onPressed: () => Get.find<ThemeController>().toggleTheme(),
                  ),
                  const SizedBox(width: 4),

                  // Logout Action Button
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.grey, size: 22),
                    tooltip: 'Logout',
                    onPressed: authController.logout,
                  ),
                  const SizedBox(width: 8),
                ]
              : [
                  // Manual Page Refresh Action Button for Guest
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 22),
                    tooltip: 'Refresh Page',
                    onPressed: () async {
                      final dbService = Get.find<DatabaseService>();
                      await dbService.fetchAllData();
                      Get.snackbar(
                        'Page Refreshed',
                        'Page data updated successfully',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.primary,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                    },
                  ),
                  const SizedBox(width: 4),

                  // Theme Toggle Button for Guest
                  IconButton(
                    icon: Obx(() => Icon(
                          Get.find<ThemeController>().isDarkMode.value
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: AppColors.primary,
                          size: 22,
                        )),
                    tooltip: 'Toggle Light/Dark Mode',
                    onPressed: () => Get.find<ThemeController>().toggleTheme(),
                  ),
                  const SizedBox(width: 4),

                  // Guest State Action: Log in Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
        ),
        body: pages[controller.currentIndex.value],
        bottomNavigationBar: NavigationBar(
          selectedIndex: controller.currentIndex.value,
          onDestinationSelected: controller.changeTab,
          indicatorColor: AppColors.primary.withOpacity(0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: isLoggedIn
              ? [
                  const NavigationDestination(
                    icon: Icon(Icons.work_outline_rounded),
                    selectedIcon: Icon(Icons.work_rounded, color: AppColors.primary),
                    label: '',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.local_library_outlined),
                    selectedIcon: Icon(Icons.local_library_rounded, color: AppColors.primary),
                    label: '',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.groups_outlined),
                    selectedIcon: Icon(Icons.groups_rounded, color: AppColors.primary),
                    label: '',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline_rounded),
                    selectedIcon: Icon(Icons.chat_bubble_rounded, color: AppColors.primary),
                    label: '',
                  ),
                  NavigationDestination(
                    icon: Icon(role == UserRole.admin 
                        ? Icons.dashboard_outlined 
                        : role == UserRole.recruiter 
                            ? Icons.business_center_outlined 
                            : role == UserRole.instructor
                                ? Icons.cast_for_education_outlined
                                : Icons.person_outline_rounded),
                    selectedIcon: Icon(role == UserRole.admin 
                        ? Icons.dashboard_rounded 
                        : role == UserRole.recruiter 
                            ? Icons.business_center_rounded 
                            : role == UserRole.instructor
                                ? Icons.cast_for_education_rounded
                                : Icons.person_rounded, color: AppColors.primary),
                    label: '',
                  ),
                ]
              : [
                  const NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
                    label: '',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.business_center_outlined),
                    selectedIcon: Icon(Icons.business_center_rounded, color: AppColors.primary),
                    label: '',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.cast_for_education_outlined),
                    selectedIcon: Icon(Icons.cast_for_education_rounded, color: AppColors.primary),
                    label: '',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.groups_outlined),
                    selectedIcon: Icon(Icons.groups_rounded, color: AppColors.primary),
                    label: '',
                  ),
                ],
        ),
      );
    });
  }
}
