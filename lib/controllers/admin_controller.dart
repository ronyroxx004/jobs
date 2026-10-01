import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../core/utils/constants.dart';
import '../models/user_model.dart';
import '../models/job_model.dart';
import '../models/application_model.dart';
import '../models/course_model.dart';
import '../models/service_model.dart';

class AdminController extends GetxController {
  final DatabaseService _dbService = Get.find<DatabaseService>();
  final AuthService _authService = Get.find<AuthService>();

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

  // --- Recruiter analytics -------------------------------------------------
  List<JobModel> jobsByRecruiter(String recruiterId) =>
      _dbService.jobsList.where((j) => j.recruiterId == recruiterId).toList();

  int applicationsForRecruiter(String recruiterId) {
    final jobIds = jobsByRecruiter(recruiterId).map((j) => j.id).toSet();
    return _dbService.applicationsList
        .where((a) => jobIds.contains(a.jobId))
        .length;
  }

  int get totalJobsByRecruiters =>
      _dbService.jobsList.where((j) => j.recruiterId.isNotEmpty).length;

  // --- Candidate analytics -------------------------------------------------
  List<ApplicationModel> applicationsByCandidate(String candidateId) =>
      _dbService.applicationsList
          .where((a) => a.candidateId == candidateId)
          .toList();

  int offersForCandidate(String candidateId) => _dbService.applicationsList
      .where((a) =>
          a.candidateId == candidateId && a.status == ApplicationStatus.offered)
      .length;

  int get verifiedCandidates => candidates.where((u) => u.isVerified).length;

  int get candidatesWithExperience =>
      candidates.where((u) => u.experienceYears > 0).length;

  // --- Mentor analytics ----------------------------------------------------
  List<MentorshipServiceModel> servicesByMentor(String mentorId) =>
      _dbService.servicesList.where((s) => s.mentorId == mentorId).toList();

  List<BookingModel> bookingsByMentor(String mentorId) =>
      _dbService.bookingsList.where((b) => b.mentorId == mentorId).toList();

  double mentorEarnings(String mentorId) => _dbService.bookingsList
      .where((b) => b.mentorId == mentorId)
      .fold(0.0, (sum, b) => sum + b.amount);

  int get activeServices =>
      _dbService.servicesList.where((s) => s.isActive).length;

  int get totalBookings => _dbService.bookingsList.length;

  double get totalMentorshipRevenue =>
      _dbService.bookingsList.fold(0.0, (sum, b) => sum + b.amount);

  int get totalJobOffers => _dbService.applicationsList
      .where((a) => a.status == ApplicationStatus.offered)
      .length;

  // --- Instructor analytics ------------------------------------------------
  /// Courses carry only the instructor name, so match on that field.
  List<CourseModel> coursesByInstructor(String instructorName) {
    final target = instructorName.trim().toLowerCase();
    return _dbService.coursesList
        .where((c) => c.instructorName.trim().toLowerCase() == target)
        .toList();
  }

  int lessonsForInstructor(String instructorName) =>
      coursesByInstructor(instructorName)
          .fold(0, (sum, c) => sum + c.lessons.length);

  int enrollmentsForInstructor(String instructorName) =>
      coursesByInstructor(instructorName)
          .fold(0, (sum, c) => sum + c.enrolledCount);

  double revenueForInstructor(String instructorName) =>
      coursesByInstructor(instructorName)
          .fold(0.0, (sum, c) => sum + (c.price * c.enrolledCount));

  double get totalCourseRevenue => _dbService.coursesList.fold(
        0.0,
        (sum, c) => sum + (c.price * c.enrolledCount),
      );

  int get totalLessons =>
      _dbService.coursesList.fold(0, (sum, c) => sum + c.lessons.length);

  int get totalEnrollments =>
      _dbService.coursesList.fold(0, (sum, c) => sum + c.enrolledCount);

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

  Future<void> removeCourse(String courseId, String courseTitle) async {
    await _dbService.deleteCourse(courseId);
    Get.snackbar(
      'Course Removed',
      '"$courseTitle" was taken down by admin moderation',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }

  Future<void> removeMentorshipService(
      String serviceId, String serviceTitle) async {
    await _dbService.deleteMentorshipService(serviceId);
    Get.snackbar(
      'Service Removed',
      '"$serviceTitle" was taken down by admin moderation',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }

  /// Deletes a user and all of their data.
  ///
  /// Returns true on success. On failure the reason is shown to the admin and
  /// false is returned, instead of throwing an unhandled async error that used
  /// to make the delete look like a silent no-op.
  Future<bool> deleteUser(String userId, String name) async {
    final self = _authService.currentUser.value;
    if (self != null && self.id == userId) {
      _showError('Cannot delete', 'You cannot delete your own admin account.');
      return false;
    }

    try {
      final result = await _dbService.deleteUserCascade(userId);

      // Firebase Auth accounts can only be deleted by the account owner from a
      // client SDK, so flag it explicitly instead of silently leaving it alive.
      final note = result.email.isEmpty ? '' : ' (${result.email})';

      _notify(
        title: 'User Removed',
        message: 'Deleted $name$note. Their login account must also be removed '
            'in Firebase Console > Authentication.',
        background: AppColors.secondary,
        action: TextButton(
          onPressed: Get.closeAllSnackbars,
          child: const Text('OK', style: TextStyle(color: Colors.white)),
        ),
      );
      return true;
    } catch (e) {
      _showError(
        'Delete Failed',
        'Could not delete $name. ${_friendlyError(e)}',
      );
      return false;
    }
  }

  /// Shows a snackbar without ever throwing. Snackbars need a mounted overlay,
  /// which is not always available (tests, background calls), and a failed
  /// notification must never break the underlying data operation.
  void _notify({
    required String title,
    required String message,
    required Color background,
    TextButton? action,
  }) {
    try {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: background,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        mainButton: action,
      );
    } catch (_) {
      debugPrint('$title: $message');
    }
  }

  void _showError(String title, String message) {
    _notify(
      title: title,
      message: message,
      background: Colors.red.shade700,
    );
  }

  String _friendlyError(Object error) {
    final raw = error.toString();
    if (raw.contains('permission-denied') ||
        raw.contains('PERMISSION_DENIED')) {
      return 'Database rules denied this action. Check your Firebase rules '
          'allow admins to write to the users collection.';
    }
    if (raw.contains('not available') || raw.contains('not connected')) {
      return 'No Firebase connection. Check your internet connection.';
    }
    return raw.replaceAll(RegExp(r'\[.*?\]'), '').trim();
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
