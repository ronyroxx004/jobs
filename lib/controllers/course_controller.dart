import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/database_service.dart';
import '../models/course_model.dart';
import '../core/utils/constants.dart';

class CourseController extends GetxController {
  final DatabaseService _dbService = Get.find<DatabaseService>();

  final searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'All'.obs;
  
  final Rx<LessonModel?> activeLesson = Rx<LessonModel?>(null);
  final RxSet<String> completedLessonIds = <String>{}.obs;
  final RxSet<String> enrolledCourseIds = <String>{'crs_1'}.obs; // default enrolled in course 1

  List<CourseModel> get courses => _dbService.coursesList;

  List<CourseModel> get filteredCourses {
    return courses.where((c) {
      final matchesSearch = searchQuery.value.isEmpty ||
          c.title.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          c.instructorName.toLowerCase().contains(searchQuery.value.toLowerCase());

      final matchesCat = selectedCategory.value == 'All' || c.category == selectedCategory.value;

      return matchesSearch && matchesCat;
    }).toList();
  }

  void updateSearch(String query) {
    searchQuery.value = query;
  }

  void setCategory(String cat) {
    selectedCategory.value = cat;
  }

  void playLesson(LessonModel lesson) {
    activeLesson.value = lesson;
  }

  void toggleLessonCompletion(String lessonId) {
    if (completedLessonIds.contains(lessonId)) {
      completedLessonIds.remove(lessonId);
    } else {
      completedLessonIds.add(lessonId);
    }
  }

  bool isEnrolled(String courseId) {
    return enrolledCourseIds.contains(courseId);
  }

  void enrollInCourse(CourseModel course) {
    enrolledCourseIds.add(course.id);
    Get.snackbar(
      'Enrolled Successfully! 🎓',
      'You now have full access to ${course.title}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.secondary,
      colorText: Colors.white,
    );
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
