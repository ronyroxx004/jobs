import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/utils/constants.dart';
import '../../core/routes/app_routes.dart';
import '../jobs/job_list_view.dart';
import '../mentorship/mentor_list_view.dart';
import '../profile/candidate_profile_view.dart';
import '../admin/admin_dashboard_view.dart';
import '../admin/admin_candidates_view.dart';
import '../admin/admin_recruiters_view.dart';
import '../admin/admin_mentors_view.dart';
import '../recruiter/recruiter_jobs_view.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/service_model.dart';
import '../mentorship/mentor_storefront_view.dart';
import '../mentorship/mentor_services_view.dart';
import '../mentorship/mentor_bookings_view.dart';
import '../mentorship/mentor_earnings_view.dart';
import '../call/agora_video_call_view.dart';

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
            controller.currentIndex.value.clamp(0, tabs.length - 1);
        final activeBooking = _findActiveBooking(isLoggedIn, role);

        return Column(
          children: [
            if (activeBooking != null)
              _buildLiveCallBanner(context, activeBooking, role == UserRole.mentor),
            Expanded(child: tabs[selectedIndex].page),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        final isLoggedIn = controller.isLoggedIn;
        final role = controller.currentRole;
        final tabs = _tabsFor(isLoggedIn, role);
        final selectedIndex =
            controller.currentIndex.value.clamp(0, tabs.length - 1);

        final hideLabels =
            isLoggedIn && (role == UserRole.mentor || role == UserRole.admin);

        return NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            controller.changeTab(index);
          },
          indicatorColor: AppColors.primary.withValues(alpha: 0.15),
          labelBehavior: hideLabels
              ? NavigationDestinationLabelBehavior.alwaysHide
              : NavigationDestinationLabelBehavior.alwaysShow,
          destinations: tabs.map((tab) {
            final title = tab.title == _profileTitle ? 'Profile' : tab.title;
            return NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon, color: AppColors.primary),
              label: title,
              tooltip: title,
            );
          }).toList(),
        );
      }),
      floatingActionButton: Obx(() {
        final isLoggedIn = controller.isLoggedIn;
        final role = controller.currentRole;
        if (isLoggedIn && role == UserRole.mentor) {
          return FloatingActionButton(
            key: const ValueKey('mentor_fab_add_post'),
            heroTag: 'mentor_fab_add_post',
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            tooltip: 'Add Post',
            onPressed: () =>
                MentorStorefrontView.showAddOfferingSelector(context),
            child: const Icon(Icons.add_rounded, size: 32),
          );
        }
        return const SizedBox.shrink();
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
      ];
    }
    if (role == UserRole.candidate) {
      return const [
        _HomeTab('Jobs', Icons.work_outline_rounded, Icons.work_rounded,
            JobListView()),
        _HomeTab('Mentors', Icons.groups_outlined, Icons.groups_rounded,
            MentorListView()),
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
          _HomeTab('Storefront', Icons.storefront_outlined,
              Icons.storefront_rounded, MentorStorefrontView()),
          _HomeTab('Services', Icons.grid_view_outlined,
              Icons.grid_view_rounded, MentorServicesView()),
          _HomeTab('Bookings', Icons.calendar_month_outlined,
              Icons.calendar_month_rounded, MentorBookingsView()),
          _HomeTab('Earnings', Icons.payments_outlined,
              Icons.payments_rounded, MentorEarningsView()),
          _HomeTab(_profileTitle, Icons.person_outline_rounded,
              Icons.person_rounded, CandidateProfileView()),
        ];
      case UserRole.instructor:
        return const [
          _HomeTab('Jobs', Icons.work_outline_rounded, Icons.work_rounded,
              JobListView()),
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
          _HomeTab('Dashboard', Icons.dashboard_outlined,
              Icons.dashboard_rounded, AdminDashboardView()),
        ];
      case UserRole.candidate:
        return const [
          _HomeTab('Jobs', Icons.work_outline_rounded, Icons.work_rounded,
              JobListView()),
          _HomeTab('Mentors', Icons.groups_outlined, Icons.groups_rounded,
              MentorListView()),
          _HomeTab(_profileTitle, Icons.person_outline_rounded,
              Icons.person_rounded, CandidateProfileView()),
        ];
    }
  }

  BookingModel? _findActiveBooking(bool isLoggedIn, UserRole role) {
    if (!isLoggedIn) return null;
    if (!Get.isRegistered<DatabaseService>()) return null;
    final db = Get.find<DatabaseService>();
    final allBookings = db.bookingsList.toList();
    if (allBookings.isEmpty) return null;

    final authService = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
    final myUid = (authService?.currentUser.value?.id ?? '').trim();
    final myFirebaseUid = (authService?.firebaseUser.value?.uid ?? '').trim();
    final myEmail = (authService?.currentUser.value?.email ?? '').trim().toLowerCase();

    final now = DateTime.now();

    BookingModel? bestBooking;
    int bestDiffSeconds = 999999999;

    for (final b in allBookings) {
      final status = b.status.trim().toLowerCase();
      // If service 1:1 video call is marked or completed, remove it from top
      if (status == 'cancelled' || status == 'completed' || status == 'complete') {
        continue;
      }

      bool isMyCall = false;
      if (role == UserRole.mentor) {
        // Only show live banner if mentor has started the call session
        if (status != 'started' && status != 'in progress') {
          continue;
        }
        if (myUid.isNotEmpty && b.mentorId.trim() == myUid) {
          isMyCall = true;
        } else if (myFirebaseUid.isNotEmpty && b.mentorId.trim() == myFirebaseUid) {
          isMyCall = true;
        } else if (myEmail.isNotEmpty &&
            b.mentorName.trim().toLowerCase().contains(myEmail)) {
          isMyCall = true;
        } else if (myUid.isEmpty && myFirebaseUid.isEmpty && myEmail.isEmpty) {
          isMyCall = true;
        }
      } else if (role == UserRole.candidate) {
        // Only show top live call banner for candidate when mentor has started the video call
        if (status != 'started' && status != 'in progress') {
          continue;
        }

        if (myUid.isNotEmpty && b.candidateId.trim() == myUid) {
          isMyCall = true;
        } else if (myFirebaseUid.isNotEmpty && b.candidateId.trim() == myFirebaseUid) {
          isMyCall = true;
        } else if (myEmail.isNotEmpty &&
            b.candidateEmail.trim().toLowerCase() == myEmail) {
          isMyCall = true;
        } else if (b.candidateId.trim().isEmpty ||
            b.candidateEmail.trim().isEmpty ||
            b.candidateId.trim().startsWith('cand_') ||
            b.candidateName.trim().toLowerCase().contains('candidate') ||
            b.candidateName.trim().toLowerCase().contains('mentee')) {
          // Open / on-demand 1:1 call started by mentor for candidate
          isMyCall = true;
        } else if (myUid.isEmpty && myFirebaseUid.isEmpty && myEmail.isEmpty) {
          isMyCall = true;
        }
      }

      if (isMyCall) {
        // Active if scheduled within today or past 24 hours to next 48 hours
        final diff = b.scheduledAt.difference(now);
        if (diff.inHours >= -24 && diff.inHours <= 48) {
          final diffSec = diff.inSeconds.abs();
          if (diffSec < bestDiffSeconds) {
            bestDiffSeconds = diffSec;
            bestBooking = b;
          }
        }
      }
    }
    return bestBooking;
  }

  Widget _buildLiveCallBanner(BuildContext context, BookingModel booking, bool isMentor) {
    final otherName = isMentor
        ? (booking.candidateName.trim().isNotEmpty ? booking.candidateName : 'Candidate')
        : (booking.mentorName.trim().isNotEmpty ? booking.mentorName : 'Mentor');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF047857)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '1:1 Call with $otherName',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  booking.serviceTitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.85),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isMentor) ...[
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.white70, size: 22),
              tooltip: 'Mark Complete & Dismiss',
              onPressed: () async {
                final db = Get.find<DatabaseService>();
                await db.updateBookingStatus(booking.id, 'Completed');
                Get.snackbar(
                  '1:1 Call Completed',
                  'Live session marked complete and banner removed from top.',
                  backgroundColor: const Color(0xFF065F46),
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP,
                );
              },
            ),
            const SizedBox(width: 4),
          ],
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF065F46),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              AgoraVideoCallView.startCall(
                context,
                booking: booking,
                isMentor: isMentor,
              );
            },
            child: Text(
              'Join Call',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTab {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;

  const _HomeTab(this.title, this.icon, this.selectedIcon, this.page);
}
