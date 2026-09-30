import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/mentorship_controller.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/service_model.dart';
import '../../core/utils/constants.dart';
import '../../core/routes/app_routes.dart';

class MentorListView extends GetView<MentorshipController> {
  const MentorListView({super.key});

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
          Text(
            'Expert Career Guidance',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            'Book top tech experts for resume reviews, mock interviews & career guidance',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 14),

          // Categories Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Resume Review', 'Mock Interview', 'Career Advice'].map((cat) {
                return Obx(() {
                  final isSelected = controller.selectedCategory.value == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: GoogleFonts.inter(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => controller.selectCategory(cat),
                    ),
                  );
                });
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Services List
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
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                'No mentorship services listed yet',
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mentors can create services once signed in.',
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                              ),
                            ],
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
                        child: Column(
                          children: [
                            Text(
                              "You've reached the end of mentorship services",
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: () async {
                                final dbService = Get.find<DatabaseService>();
                                await dbService.fetchAllData();
                                Get.snackbar(
                                  'Page Refreshed',
                                  'Mentorship services updated successfully',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.primary,
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 2),
                                );
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.primary),
                              label: Text(
                                'Refresh Page',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final service = services[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: const Icon(Icons.person, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service.mentorName,
                                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      service.mentorHeadline,
                                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '\$${service.price.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          Text(
                            service.title,
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            service.description,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 14),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${service.durationMinutes} mins',
                                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(120, 38),
                                ),
                                onPressed: () {
                                  if (!authService.isLoggedIn) {
                                    Get.snackbar(
                                      'Sign In Required',
                                      'Please sign in to book mentorship sessions',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: AppColors.primary,
                                      colorText: Colors.white,
                                    );
                                    Get.toNamed(AppRoutes.login);
                                    return;
                                  }
                                  _showBookingDialog(context, service);
                                },
                                child: const Text('Book Slot'),
                              ),
                            ],
                          ),
                        ],
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

  void _showBookingDialog(BuildContext context, MentorshipServiceModel service) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Book ${service.title}', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Mentor: ${service.mentorName}', style: GoogleFonts.inter(color: AppColors.primary)),
            const SizedBox(height: 16),
            Text('Select Available Time Slot', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: ['10:00 AM EST', '02:00 PM EST', '05:00 PM EST', '08:00 PM EST'].map((slot) {
                return Obx(() {
                  final isSelected = controller.selectedTimeSlot.value == slot;
                  return ChoiceChip(
                    label: Text(slot),
                    selected: isSelected,
                    onSelected: (_) => controller.selectSlot(slot),
                  );
                });
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => controller.bookMentorshipSession(service),
              child: Text('Confirm Booking (\$${service.price.toStringAsFixed(2)})'),
            ),
          ],
        ),
      ),
    );
  }
}
