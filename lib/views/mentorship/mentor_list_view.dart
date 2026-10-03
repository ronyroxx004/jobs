import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/mentorship_controller.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/service_model.dart';
import '../../core/utils/constants.dart';
import '../../core/routes/app_routes.dart';
import 'mentor_booking_dialog.dart';

class MentorListView extends GetView<MentorshipController> {
  const MentorListView({super.key});

  void _handlePostTap(BuildContext context, MentorshipServiceModel service,
      AuthService authService) {
    if (!authService.isLoggedIn) {
      Get.snackbar(
        'Sign In Required',
        'Please sign in to book or view "${service.title}"',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
      Get.toNamed(AppRoutes.login);
      return;
    }
    MentorBookingDialog.show(context, service);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = Get.find<AuthService>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expert Career Guidance',
                    style: GoogleFonts.inter(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Book 1:1 sessions, mock interviews & guidance',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              if (!authService.isLoggedIn)
                TextButton.icon(
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: const Text('Sign in'),
                  onPressed: () => Get.toNamed(AppRoutes.login),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Categories Chips (Job Post / Topmate style filter row)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'All',
                '1:1 Call',
                'Mock Interview',
                'Resume Review',
                'Priority DM',
                'Webinar',
                'Package',
              ].map((cat) {
                return Obx(() {
                  final isSelected = controller.selectedCategory.value == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      labelStyle: GoogleFonts.inter(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                      onSelected: (_) => controller.selectCategory(cat),
                    ),
                  );
                });
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Services Feed
          Expanded(
            child: Obx(() {
              final services = controller.filteredServices;
              if (services.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async {
                    final dbService = Get.find<DatabaseService>();
                    await dbService.fetchAllData();
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.45,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.psychology_outlined,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  'No mentorship posts available yet',
                                  style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Mentors can sign in to publish 1:1 sessions, mock interviews, and digital guidance.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                      fontSize: 13, color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                if (!authService.isLoggedIn)
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.login),
                                    label: const Text('Log in to Book'),
                                    onPressed: () =>
                                        Get.toNamed(AppRoutes.login),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  final dbService = Get.find<DatabaseService>();
                  await dbService.fetchAllData();
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: services.length + 1,
                  itemBuilder: (context, index) {
                    if (index == services.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            "You've viewed all available mentorship posts",
                            style: GoogleFonts.inter(
                                fontSize: 13, color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    final service = services[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () =>
                            _handlePostTap(context, service, authService),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Mentor Header Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor:
                                        AppColors.primary.withValues(alpha: 0.12),
                                    child: Text(
                                      service.mentorName.isNotEmpty
                                          ? service.mentorName[0].toUpperCase()
                                          : 'M',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                service.mentorName,
                                                style: GoogleFonts.inter(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.white
                                                      : AppColors
                                                          .textPrimaryLight,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.verified_rounded,
                                              size: 15,
                                              color: AppColors.secondary,
                                            ),
                                          ],
                                        ),
                                        if (service.mentorHeadline.isNotEmpty)
                                          Text(
                                            service.mentorHeadline,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Service Type Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _badgeColor(service.serviceType)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      service.serviceType,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            _badgeColor(service.serviceType),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Post Title
                              Text(
                                service.title,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimaryLight,
                                ),
                              ),

                              const SizedBox(height: 6),

                              // Deliverable line
                              if (service.deliverable.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Icon(
                                      _serviceIcon(service.serviceType),
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        service.deliverable,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],

                              // Description Snippet
                              if (service.description.isNotEmpty)
                                Text(
                                  service.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),

                              const SizedBox(height: 10),

                              // Topics Chips (styled like Job skills)
                              if (service.topics.isNotEmpty) ...[
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: service.topics.take(4).map((topic) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.bgDark
                                            : AppColors.bgLight,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.borderDark
                                              : AppColors.borderLight,
                                        ),
                                      ),
                                      child: Text(
                                        topic,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                              ],

                              const Divider(height: 1),
                              const SizedBox(height: 10),

                              // Footer Row: Duration & Price & CTA
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      if (service.durationMinutes > 0) ...[
                                        const Icon(Icons.schedule_rounded,
                                            size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${service.durationMinutes}m',
                                          style: GoogleFonts.inter(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                      Text(
                                        service.price > 0
                                            ? '\$${service.price.toStringAsFixed(service.price % 1 == 0 ? 0 : 2)}'
                                            : 'Free',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 6),
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      minimumSize: Size.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: Icon(
                                      authService.isLoggedIn
                                          ? Icons.calendar_month_rounded
                                          : Icons.login_rounded,
                                      size: 14,
                                    ),
                                    label: Text(
                                      authService.isLoggedIn
                                          ? 'Book Slot'
                                          : 'Log in to Book',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () => _handlePostTap(
                                        context, service, authService),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _badgeColor(String type) {
    switch (type) {
      case '1:1 Call':
        return AppColors.primary;
      case 'Mock Interview':
        return const Color(0xFFEA580C);
      case 'Webinar':
        return const Color(0xFF7C3AED);
      case 'Priority DM':
        return const Color(0xFF0284C7);
      case 'Digital Product':
        return const Color(0xFF16A34A);
      case 'Package':
        return const Color(0xFFDB2777);
      default:
        return AppColors.secondary;
    }
  }

  IconData _serviceIcon(String type) {
    switch (type) {
      case '1:1 Call':
        return Icons.videocam_rounded;
      case 'Mock Interview':
        return Icons.code_rounded;
      case 'Webinar':
        return Icons.groups_rounded;
      case 'Priority DM':
        return Icons.chat_rounded;
      case 'Digital Product':
        return Icons.download_rounded;
      case 'Package':
        return Icons.all_inclusive_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}
