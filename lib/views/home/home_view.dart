import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/utils/constants.dart';
import '../../core/routes/app_routes.dart';
import '../jobs/job_list_view.dart';
import '../courses/course_list_view.dart';
import '../mentorship/mentor_list_view.dart';
import '../chat/chat_list_view.dart';
import '../profile/candidate_profile_view.dart';
import '../admin/admin_dashboard_view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

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
              if (role == UserRole.admin) const AdminDashboardView() else const CandidateProfileView(),
            ]
          : [
              const JobListView(),
              const CourseListView(),
              const MentorListView(),
            ];

      // Ensure index is within valid bounds
      if (controller.currentIndex.value >= pages.length) {
        controller.currentIndex.value = 0;
      }

      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.work_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'JOBS',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
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
                            role == UserRole.candidate
                                ? Icons.person
                                : role == UserRole.recruiter
                                    ? Icons.business_center
                                    : role == UserRole.mentor
                                        ? Icons.school
                                        : Icons.admin_panel_settings,
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
                              r == UserRole.candidate
                                  ? Icons.person
                                  : r == UserRole.recruiter
                                      ? Icons.business_center
                                      : r == UserRole.mentor
                                          ? Icons.school
                                          : Icons.admin_panel_settings,
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

                  // Logout Action Button
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.grey, size: 22),
                    tooltip: 'Logout',
                    onPressed: authController.logout,
                  ),
                  const SizedBox(width: 8),
                ]
              : [
                  // Guest State Actions: Sign In & Register Buttons
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => Get.toNamed(AppRoutes.login),
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => Get.toNamed(AppRoutes.register),
                    child: Text(
                      'Register',
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
          destinations: isLoggedIn
              ? [
                  const NavigationDestination(
                    icon: Icon(Icons.work_outline_rounded),
                    selectedIcon: Icon(Icons.work_rounded, color: AppColors.primary),
                    label: 'Jobs',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.local_library_outlined),
                    selectedIcon: Icon(Icons.local_library_rounded, color: AppColors.primary),
                    label: 'Courses',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.groups_outlined),
                    selectedIcon: Icon(Icons.groups_rounded, color: AppColors.primary),
                    label: 'Mentors',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline_rounded),
                    selectedIcon: Icon(Icons.chat_bubble_rounded, color: AppColors.primary),
                    label: 'Messages',
                  ),
                  NavigationDestination(
                    icon: Icon(role == UserRole.admin ? Icons.dashboard_outlined : Icons.person_outline_rounded),
                    selectedIcon: Icon(role == UserRole.admin ? Icons.dashboard_rounded : Icons.person_rounded, color: AppColors.primary),
                    label: role == UserRole.admin ? 'Admin' : 'Profile',
                  ),
                ]
              : [
                  const NavigationDestination(
                    icon: Icon(Icons.work_outline_rounded),
                    selectedIcon: Icon(Icons.work_rounded, color: AppColors.primary),
                    label: 'Jobs',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.local_library_outlined),
                    selectedIcon: Icon(Icons.local_library_rounded, color: AppColors.primary),
                    label: 'Courses',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.groups_outlined),
                    selectedIcon: Icon(Icons.groups_rounded, color: AppColors.primary),
                    label: 'Mentors',
                  ),
                ],
        ),
      );
    });
  }
}
