import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/admin_controller.dart';
import '../../core/utils/constants.dart';
import '../../models/user_model.dart';
import '../../models/course_model.dart';
import '../../services/database_service.dart';
import 'admin_shared.dart';

/// Admin screen for instructors. Each instructor is shown with the courses they
/// publish, curriculum depth, learner reach and estimated revenue.
class AdminInstructorsView extends StatefulWidget {
  const AdminInstructorsView({super.key});

  @override
  State<AdminInstructorsView> createState() => _AdminInstructorsViewState();
}

class _AdminInstructorsViewState extends State<AdminInstructorsView> {
  final TextEditingController _searchController = TextEditingController();
  final RxString _query = ''.obs;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    return RefreshIndicator(
      onRefresh: () => Get.find<DatabaseService>().fetchAllData(),
      child: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Course Instructors header + 3 buttons scroll upward when scrolling on trainer cards
            SliverToBoxAdapter(
              child: _buildCollapsibleHeader(controller),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: AdminPinnedHeaderDelegate(
                height: 56,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: _buildSearch(),
                ),
              ),
            ),
            _buildInstructorList(controller),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleHeader(AdminController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.warning],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course Academy',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Oversee instructors and their published curriculum',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: AdminStatTile(
                    label: 'Instructors',
                    value: '${controller.instructors.length}',
                    icon: Icons.cast_for_education_rounded,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AdminStatTile(
                    label: 'Courses',
                    value: '${controller.totalCourses}',
                    icon: Icons.local_library_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AdminStatTile(
                    label: 'Learners',
                    value: '${controller.totalEnrollments}',
                    icon: Icons.people_alt_rounded,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: AdminSearchField(
        controller: _searchController,
        hint: 'Search instructor or course title...',
        onChanged: (value) => _query.value = value,
        onClear: () {
          _searchController.clear();
          _query.value = '';
        },
      ),
    );
  }

Widget _buildInstructorList(AdminController controller) {
    return Obx(() {
      final instructors = controller.instructors.where((user) {
        final courses = controller.coursesByInstructor(user.name);
        return adminMatchesQuery(_query.value, [
          user.name,
          user.email,
          user.headline,
          ...courses.map((c) => c.title),
        ]);
      }).toList();

      if (instructors.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: AdminEmptyState(
            icon: Icons.school_outlined,
            title: 'No instructors found',
            subtitle:
                'Instructors who register will appear here with their courses.',
            color: AppColors.accent,
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index.isOdd) return const SizedBox(height: 12);
              final itemIndex = index ~/ 2;
              return _InstructorCard(
                instructor: instructors[itemIndex],
                controller: controller,
              );
            },
            childCount: instructors.isEmpty ? 0 : instructors.length * 2 - 1,
          ),
        ),
      );
    });
  }
}

class _InstructorCard extends StatelessWidget {
  final UserModel instructor;
  final AdminController controller;

  const _InstructorCard({
    required this.instructor,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final courses = controller.coursesByInstructor(instructor.name);
    final lessons = controller.lessonsForInstructor(instructor.name);
    final learners = controller.enrollmentsForInstructor(instructor.name);
    final revenue = controller.revenueForInstructor(instructor.name);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => adminShowUserActions(
          context,
          instructor,
          accent: AppColors.accent,
          extraActions: [
            _InstructorStats(
              courses: courses.length,
              lessons: lessons,
              learners: learners,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AdminUserAvatar(
                    user: instructor,
                    size: 52,
                    accent: AppColors.accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          instructor.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          instructor.headline.isNotEmpty
                              ? instructor.headline
                              : 'Course Instructor',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _MiniStat(
                              icon: Icons.local_library_rounded,
                              value: '${courses.length}',
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            _MiniStat(
                              icon: Icons.playlist_play_rounded,
                              value: '$lessons lessons',
                              color: AppColors.secondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${revenue.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                      Text(
                        '$learners learners',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
const SizedBox(height: 12),
              if (courses.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No courses published by this instructor yet.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              else
                for (final course in courses)
                  _CourseRow(course: course, controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseRow extends StatelessWidget {
  final CourseModel course;
  final AdminController controller;

  const _CourseRow({required this.course, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 40,
              height: 40,
              child: course.thumbnail.isNotEmpty
                  ? Image.network(
                      course.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbnailFallback(),
                    )
                  : _thumbnailFallback(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${course.category} • ${course.lessons.length} lessons • '
                  '${course.enrolledCount} enrolled',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
              const SizedBox(width: 2),
              Text(
                course.rating.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            '\$${course.price.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
            ),
          ),
          IconButton(
            tooltip: 'Remove course',
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 19,
              color: Colors.redAccent,
            ),
            onPressed: () => controller.removeCourse(course.id, course.title),
          ),
        ],
      ),
    );
  }

  Widget _thumbnailFallback() {
    return Container(
      color: AppColors.accent.withValues(alpha: 0.15),
      child: const Icon(
        Icons.menu_book_rounded,
        size: 20,
        color: AppColors.accent,
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

class _InstructorStats extends StatelessWidget {
  final int courses;
  final int lessons;
  final int learners;

  const _InstructorStats({
    required this.courses,
    required this.lessons,
    required this.learners,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatBlock(value: '$courses', label: 'Courses', color: AppColors.accent),
              ),
              Expanded(
                child: _StatBlock(value: '$lessons', label: 'Lessons', color: AppColors.secondary),
              ),
              Expanded(
                child: _StatBlock(value: '$learners', label: 'Learners', color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatBlock({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }
}