import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/course_controller.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../core/utils/constants.dart';
import '../../core/routes/app_routes.dart';

class CourseListView extends GetView<CourseController> {
  const CourseListView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Skill Development Marketplace',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            'Upskill with expert-led courses and earn certified badges',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          // Search Bar
          TextField(
            controller: controller.searchController,
            onChanged: controller.updateSearch,
            decoration: const InputDecoration(
              hintText: 'Search courses or instructors...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 16),

          // Course Cards List
          Expanded(
            child: Obx(() {
              final courses = controller.filteredCourses;
              if (courses.isEmpty) {
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
                              const Icon(Icons.local_library_outlined, size: 64, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                'No courses published yet',
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Instructors can publish courses once signed in.',
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
                  itemCount: courses.length + 1,
                  itemBuilder: (context, index) {
                    if (index == courses.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                "You've reached the end of courses",
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
                                    'Courses marketplace updated successfully',
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

                    final course = courses[index];
                    final isEnrolled = controller.isEnrolled(course.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.network(
                              course.thumbnail,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 150,
                                color: AppColors.primary.withOpacity(0.12),
                                child: const Icon(Icons.school_rounded, size: 48, color: AppColors.primary),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${course.rating}',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '(${course.enrolledCount} students)',
                                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '\$${course.price.toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                Text(
                                  course.title,
                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'By ${course.instructorName}',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),

                                // Lessons Expansion list
                                Text(
                                  '${course.lessons.length} Modules & Video Lessons:',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                for (final lesson in course.lessons)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    leading: const Icon(Icons.play_circle_fill, color: AppColors.primary, size: 20),
                                    title: Text(lesson.title, style: GoogleFonts.inter(fontSize: 13)),
                                    trailing: Text(lesson.duration, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                                    onTap: () {
                                      Get.snackbar(
                                        'Playing Video Lesson',
                                        'Started ${lesson.title}',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: AppColors.primary,
                                        colorText: Colors.white,
                                      );
                                    },
                                  ),
                                const SizedBox(height: 12),

                                ElevatedButton(
                                  onPressed: isEnrolled
                                      ? null
                                      : () {
                                          if (!authService.isLoggedIn) {
                                            Get.snackbar(
                                              'Sign In Required',
                                              'Please sign in to enroll in courses',
                                              snackPosition: SnackPosition.BOTTOM,
                                              backgroundColor: AppColors.primary,
                                              colorText: Colors.white,
                                            );
                                            Get.toNamed(AppRoutes.login);
                                            return;
                                          }
                                          controller.enrollInCourse(course);
                                        },
                                  child: Text(isEnrolled ? 'Enrolled ✓ Access Full Content' : 'Enroll Now (\$' + course.price.toStringAsFixed(2) + ')'),
                                ),
                              ],
                            ),
                          ),
                        ],
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
}
