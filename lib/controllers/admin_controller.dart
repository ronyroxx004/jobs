import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/database_service.dart';
import '../core/utils/constants.dart';

class AdminController extends GetxController {
  final DatabaseService _dbService = Get.find<DatabaseService>();

  int get totalJobs => _dbService.jobsList.length;
  int get totalApplications => _dbService.applicationsList.length;
  int get totalMentors => _dbService.servicesList.length;
  int get totalCourses => _dbService.coursesList.length;

  final RxDouble platformRevenue = 12450.00.obs;

  void toggleJobStatus(String jobId) {
    final idx = _dbService.jobsList.indexWhere((j) => j.id == jobId);
    if (idx != -1) {
      final j = _dbService.jobsList[idx];
      _dbService.jobsList[idx] = j;
      Get.snackbar(
        'Job Moderated',
        'Updated status for ${j.title}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    }
  }

  void removeJob(String jobId) {
    _dbService.jobsList.removeWhere((j) => j.id == jobId);
    Get.snackbar(
      'Job Removed',
      'Job listing removed by admin moderation',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }
}
