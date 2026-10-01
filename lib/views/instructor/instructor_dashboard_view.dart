import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/course_controller.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../core/utils/constants.dart';
import '../../core/routes/app_routes.dart';

class InstructorDashboardView extends GetView<CourseController> {
  const InstructorDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final instructor = authService.currentUser.value;

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
            // Instructor Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.cast_for_education, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            instructor?.name ?? 'Instructor',
                            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            instructor?.headline.isNotEmpty == true 
                                ? instructor?.headline ?? ''
                                : 'Expert Instructor & Educator Portal',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () => Get.toNamed(AppRoutes.postCourse),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Post Course'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Statistics Row
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.local_library_rounded, color: AppColors.primary),
                          const SizedBox(height: 8),
                          Obx(() => Text(
                                '${controller.courses.length}',
                                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
                              )),
                          const SizedBox(height: 2),
                          Text('Published Courses', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.people_rounded, color: AppColors.secondary),
                          const SizedBox(height: 8),
                          Text(
                            '1,420',
                            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text('Total Students', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'My Published Courses',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Obx(() {
              final list = controller.courses;
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No courses published yet. Tap "Post Course" to create one.',
                      style: GoogleFonts.inter(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final course = list[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          course.thumbnail,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 50,
                            height: 50,
                            color: AppColors.primary.withOpacity(0.1),
                            child: const Icon(Icons.school, color: AppColors.primary),
                          ),
                        ),
                      ),
                      title: Text(course.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('\$${course.price.toStringAsFixed(2)} • ${course.category}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
