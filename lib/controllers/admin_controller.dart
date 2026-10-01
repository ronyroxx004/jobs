import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/database_service.dart';
import '../core/utils/constants.dart';
import '../models/user_model.dart';

class AdminController extends GetxController {
  final DatabaseService _dbService = Get.find<DatabaseService>();

  int get totalJobs => _dbService.jobsList.length;
  int get totalApplications => _dbService.applicationsList.length;
  int get totalMentors => _dbService.servicesList.length;
  int get totalCourses => _dbService.coursesList.length;

  List<UserModel> get allUsers => _dbService.usersList;
  List<UserModel> get recruiters => _dbService.usersList.where((u) => u.role == UserRole.recruiter).toList();
  List<UserModel> get mentors => _dbService.usersList.where((u) => u.role == UserRole.mentor).toList();
  List<UserModel> get instructors => _dbService.usersList.where((u) => u.role == UserRole.instructor).toList();
  List<UserModel> get candidates => _dbService.usersList.where((u) => u.role == UserRole.candidate).toList();

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

  Future<void> deleteUser(String userId, String name) async {
    await _dbService.deleteUser(userId);
    Get.snackbar(
      'User Removed',
      'Deleted user $name',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _dbService.saveUserProfile(user);
    final idx = _dbService.usersList.indexWhere((u) => u.id == user.id);
    if (idx != -1) {
      _dbService.usersList[idx] = user;
    }
    Get.snackbar(
      'User Updated',
      'Updated details for ${user.name}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );
  }
}
