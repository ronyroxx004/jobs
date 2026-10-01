import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/account_admin_service.dart';
import '../core/utils/constants.dart';
import '../models/user_model.dart';
import '../models/deleted_user_model.dart';
import '../models/job_model.dart';
import '../models/application_model.dart';
import '../models/course_model.dart';
import '../models/service_model.dart';

class AdminController extends GetxController {
  final DatabaseService _dbService = Get.find<DatabaseService>();
  final AuthService _authService = Get.find<AuthService>();
  final AccountAdminService _accountAdminService =
      Get.isRegistered<AccountAdminService>()
          ? Get.find<AccountAdminService>()
          : Get.put(AccountAdminService(), permanent: true);

  @override
  void onInit() {
    super.onInit();
    refreshDeletedUsers();
    refreshAccountDeletionAvailability();
  }

  int get totalJobs => _dbService.jobsList.length;
  int get activeJobs => _dbService.jobsList.where((j) => j.isActive).length;
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

  Future<void> toggleJobStatus(String jobId) async {
    final idx = _dbService.jobsList.indexWhere((j) => j.id == jobId);
    if (idx != -1) {
      final j = _dbService.jobsList[idx];
      final updated = j.copyWith(isActive: !j.isActive);
      try {
        await _dbService.updateJob(updated);
        Get.snackbar(
          'Job Status Updated',
          '${j.title} is now ${updated.isActive ? "Live" : "Paused"}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to update job status: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> removeJob(String jobId) async {
    try {
      await _dbService.deleteJob(jobId);
      Get.snackbar(
        'Job Removed',
        'Job listing was deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove job: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteJob(String jobId) => removeJob(jobId);

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
  /// Prefers the `deleteUserAccount` Cloud Function, which is the only way to
  /// also remove the Firebase Auth account. If the function is not deployed it
  /// falls back to deleting everything from Realtime Database / Firestore
  /// directly, and says so.
  ///
  /// Returns true on success. On failure the reason is shown to the admin and
  /// false is returned, instead of throwing an unhandled async error.
  Future<bool> deleteUser(String userId, String name) async {
    final self = _authService.currentUser.value;
    if (self != null && self.id == userId) {
      _showError('Cannot delete', 'You cannot delete your own admin account.');
      return false;
    }

    try {
      final result = await _accountAdminService.deleteAccount(userId);
      _applyLocalRemoval(userId);
      await refreshDeletedUsers();

      if (result.authDeleted) {
        _notify(
          title: 'Account Deleted',
          message: '$name was removed from Firebase Authentication, '
              'Realtime Database and Firestore '
              '(${result.totalRemoved} records cleared).',
          background: AppColors.secondary,
          action: TextButton(
            onPressed: Get.closeAllSnackbars,
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        );
      } else {
        _notify(
          title: 'Data Deleted',
          message: '$name\'s data was removed (${result.totalRemoved} records), '
              'but the Firebase Auth account could not be deleted: '
              '${result.authError ?? 'unknown error'}. '
              'Remove it in Firebase Console > Authentication.',
          background: AppColors.warning,
        );
      }
      return true;
    } on AccountDeletionUnavailable catch (e) {
      // Cloud Function unavailable -> clean up the data ourselves.
      debugPrint('Cloud delete unavailable: ${e.message}');
      return _deleteWithoutCloudFunction(userId, name);
    } catch (e) {
      debugPrint('Unexpected delete error: $e');
      return _deleteWithoutCloudFunction(userId, name);
    }
  }

  /// Fallback path: removes profile + related records using the client SDK.
  Future<bool> _deleteWithoutCloudFunction(String userId, String name) async {
    try {
      final result = await _dbService.deleteUserCascade(userId);
      await refreshDeletedUsers();

      final note = result.email.isEmpty ? '' : ' (${result.email})';
      _notify(
        title: 'Realtime Data Deleted',
        message: '$name$note was removed from Realtime Database, but the '
            'Firebase Auth account still exists.\n\n'
            'Deleting another user\'s login requires the deleteUserAccount '
            'Cloud Function, which needs the Blaze (pay-as-you-go) plan:\n'
            '1. Upgrade: console.firebase.google.com/project/jobs-37214/usage/details\n'
            '2. Deploy: firebase deploy --only functions',
        background: AppColors.warning,
        action: TextButton(
          onPressed: () async {
            Get.closeAllSnackbars();
            await restoreUser(
              DeletedUserModel(
                id: userId,
                name: name,
                email: result.email,
                deletedAt: DateTime.now(),
              ),
            );
          },
          child: const Text('UNDO', style: TextStyle(color: Colors.white)),
        ),
      );
      return true;
    } catch (e) {
      final details = await describeAdminAccess();
      _showError(
        'Delete Failed',
        'Could not delete $name.\n\n${_friendlyError(e)}\n\n$details',
      );
      return false;
    }
  }

  /// True when Auth-account deletion is available (Cloud Function deployed).
  final RxBool canDeleteAuthAccounts = false.obs;

  /// True once the deleted-users list has loaded successfully at least once.
  final RxBool deletedUsersLoaded = false.obs;

  /// Checks once whether server-side Auth deletion is available.
  Future<void> refreshAccountDeletionAvailability() async {
    try {
      canDeleteAuthAccounts.value = await _accountAdminService.isDeployed();
    } catch (_) {
      canDeleteAuthAccounts.value = false;
    }
  }

  /// Accounts an admin has removed, newest first.
  List<DeletedUserModel> get deletedUsers => _dbService.deletedUsersList;

  /// Restores a removed account so the person can log in again.
  ///
  /// Brings back the login and profile only - deleted resumes, applications,
  /// jobs, sessions and chats are gone for good.
  Future<bool> restoreUser(DeletedUserModel deleted) async {
    try {
      await _dbService.restoreUser(
        deleted.id,
        name: deleted.name,
        email: deleted.email,
        role: UserRole.values.firstWhere(
          (r) => r.name.toLowerCase() == deleted.role.toLowerCase(),
          orElse: () => UserRole.candidate,
        ),
      );
      final displayName = deleted.name.isNotEmpty
          ? deleted.name
          : (deleted.email.isNotEmpty ? deleted.email : 'User ${deleted.id}');
      _notify(
        title: 'Account Restored',
        message: '$displayName can log in again. Their profile has been '
            're-created in Realtime Database. Previous resumes, applications '
            'and posts were deleted permanently and were not restored.',
        background: AppColors.secondary,
        action: TextButton(
          onPressed: Get.closeAllSnackbars,
          child: const Text('OK', style: TextStyle(color: Colors.white)),
        ),
      );
      return true;
    } catch (e) {
      final label = deleted.email.isNotEmpty ? deleted.email : deleted.id;
      _showError('Restore Failed', 'Could not restore $label: $e');
      return false;
    }
  }

  /// Restores a removed account directly by User ID.
  Future<bool> restoreUserById(
    String userId, {
    String? name,
    String? email,
    UserRole? role,
  }) async {
    final cleanId = userId.trim();
    if (cleanId.isEmpty) {
      _showError('Invalid ID', 'Please provide a valid User ID.');
      return false;
    }

    try {
      await _dbService.restoreUser(
        cleanId,
        name: name,
        email: email,
        role: role,
      );
      final label = (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : ((email != null && email.trim().isNotEmpty) ? email.trim() : cleanId);

      _notify(
        title: 'Account Restored',
        message: '$label can now log in again. Profile was successfully recreated in Realtime Database.',
        background: AppColors.secondary,
        action: TextButton(
          onPressed: Get.closeAllSnackbars,
          child: const Text('OK', style: TextStyle(color: Colors.white)),
        ),
      );
      return true;
    } catch (e) {
      _showError('Restore Failed', 'Could not restore user $cleanId: $e');
      return false;
    }
  }

  /// Deletes the tombstone so the account can never be restored.
  Future<bool> purgeDeletedUser(DeletedUserModel deleted) async {
    try {
      await _dbService.purgeDeletedUser(deleted.id);
      _notify(
        title: 'Record Purged',
        message: 'The restore option for '
            '${deleted.email.isEmpty ? deleted.name : deleted.email} is gone.',
        background: AppColors.error,
      );
      return true;
    } catch (e) {
      _showError('Purge Failed', 'Could not purge the record: $e');
      return false;
    }
  }

  /// Loads the list of removed accounts.
  ///
  /// Returns false and reports the reason when the read is denied, so the UI
  /// never claims "0 deleted accounts" when the list simply could not load.
  Future<bool> refreshDeletedUsers() async {
    try {
      await _dbService.refreshDeletedUsers();
      deletedUsersLoaded.value = true;
      return true;
    } catch (e) {
      _dbService.deletedUsersList.clear();
      deletedUsersLoaded.value = false;
      _showError(
        'Could not load deleted users',
        'The Realtime Database denied this read. Deploy the latest rules:\n'
        'firebase deploy --only database\n\n'
        '(${_friendlyError(e)})',
      );
      return false;
    }
  }

  /// Mirrors the server-side cleanup into the local reactive caches.
  void _applyLocalRemoval(String userId) {
    _dbService.usersList.removeWhere((u) => u.id == userId);
    _dbService.resumeList.removeWhere((r) => r.userId == userId);
    _dbService.applicationsList.removeWhere((a) => a.candidateId == userId);
    _dbService.jobsList.removeWhere((j) => j.recruiterId == userId);
    _dbService.servicesList.removeWhere((s) => s.mentorId == userId);
    _dbService.bookingsList.removeWhere(
        (b) => b.mentorId == userId || b.candidateId == userId);
    _dbService.chatRoomsList
        .removeWhere((c) => c.participantIds.contains(userId));
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

  /// Diagnostics for admin write access, surfaced from the delete error path so
  /// a `permission-denied` can be diagnosed without guessing.
Future<String> describeAdminAccess() async {
    final user = _authService.currentUser.value;
    if (user == null) {
      return 'No user is currently signed in.';
    }

    final lines = <String>[
      'Signed in as: ${user.email.isEmpty ? '(no email)' : user.email}',
      'App role: ${user.role.displayName}',
    ];

    try {
      final tokenEmail = FirebaseAuth.instance.currentUser?.email;
      lines.add('Auth email: ${tokenEmail ?? '(not signed in)' }');
      if (tokenEmail != null && tokenEmail.toLowerCase() != 'admin@gmail.com') {
        lines.add(
          'Rules expect admin@gmail.com, so writes are denied for this email.',
        );
      }
    } catch (_) {
      lines.add('Auth email: unavailable (Firebase Auth not initialised)');
    }

    final tombstone = await _dbService.isUserDeleted('__probe__');
    lines.add('Can read deleted_users: ${tombstone ? "yes" : "no/denied"}');
    return lines.join('\n');
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
      return 'Database rules denied this action.\n\n'
          'Admin deletes require your account email to be admin@gmail.com '
          '(Firebase Auth > Sign-in method > Email/Password must be enabled). '
          'Also confirm you deployed the latest rules: '
          'firebase deploy --only database,firestore';
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
