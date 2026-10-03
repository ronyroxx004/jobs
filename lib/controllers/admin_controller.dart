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
    _dbService.fetchUsers();
    refreshDeletedUsers();
    refreshAccountDeletionAvailability();
  }

  int get totalJobs => _dbService.jobsList.length;
  int get activeJobs => _dbService.jobsList.where((j) => j.isActive).length;
  int get totalApplications => _dbService.applicationsList.length;
  int get totalMentors => _dbService.servicesList.length;
  int get totalCourses => _dbService.coursesList.length;

  List<UserModel> get allUsers => _dbService.usersList;

  List<UserModel> get recruiters {
    final currentAdminId = _authService.currentUser.value?.id;
    final currentAdminEmail =
        _authService.currentUser.value?.email.trim().toLowerCase();

    return _dbService.usersList.where((u) {
      if (currentAdminId != null &&
          currentAdminId.isNotEmpty &&
          u.id == currentAdminId) {
        return false;
      }
      if (currentAdminEmail != null &&
          currentAdminEmail.isNotEmpty &&
          u.email.trim().toLowerCase() == currentAdminEmail) {
        return false;
      }
      if (u.role == UserRole.admin) return false;
      final email = u.email.trim().toLowerCase();
      if (email == 'admin@gmail.com') return false;

      if (u.role == UserRole.recruiter) return true;
      final raw = u.rawRole.trim().toLowerCase();
      return raw == 'recruiter' || raw == 'hr';
    }).toList();
  }

  List<UserModel> get mentors {
    final currentAdminId = _authService.currentUser.value?.id;
    final currentAdminEmail =
        _authService.currentUser.value?.email.trim().toLowerCase();

    final userMentors = _dbService.usersList.where((u) {
      if (currentAdminId != null &&
          currentAdminId.isNotEmpty &&
          u.id == currentAdminId) {
        return false;
      }
      if (currentAdminEmail != null &&
          currentAdminEmail.isNotEmpty &&
          u.email.trim().toLowerCase() == currentAdminEmail) {
        return false;
      }
      if (u.role == UserRole.admin) return false;
      final email = u.email.trim().toLowerCase();
      if (email == 'admin@gmail.com') return false;

      if (u.role == UserRole.mentor) return true;
      final raw = u.rawRole.trim().toLowerCase();
      return raw == 'mentor';
    }).toList();

    // Also ensure any mentor who created a service is represented
    final existingIds = userMentors.map((m) => m.id).toSet();
    for (final s in _dbService.servicesList) {
      if (s.mentorId.isNotEmpty && !existingIds.contains(s.mentorId)) {
        existingIds.add(s.mentorId);
        final found = _dbService.usersList
            .firstWhereOrNull((u) => u.id == s.mentorId);
        if (found != null) {
          userMentors.add(found);
        } else {
          userMentors.add(
            UserModel(
              id: s.mentorId,
              name: s.mentorName.isNotEmpty ? s.mentorName : 'Mentor',
              email: '',
              role: UserRole.mentor,
              headline: s.mentorHeadline,
              rating: s.rating,
              totalReviews: s.reviewCount,
            ),
          );
        }
      }
    }

    return userMentors;
  }

  List<UserModel> get instructors {
    final currentAdminId = _authService.currentUser.value?.id;
    final currentAdminEmail =
        _authService.currentUser.value?.email.trim().toLowerCase();

    return _dbService.usersList.where((u) {
      if (currentAdminId != null &&
          currentAdminId.isNotEmpty &&
          u.id == currentAdminId) {
        return false;
      }
      if (currentAdminEmail != null &&
          currentAdminEmail.isNotEmpty &&
          u.email.trim().toLowerCase() == currentAdminEmail) {
        return false;
      }
      if (u.role == UserRole.admin) return false;
      final email = u.email.trim().toLowerCase();
      if (email == 'admin@gmail.com') return false;

      if (u.role == UserRole.instructor) return true;
      final raw = u.rawRole.trim().toLowerCase();
      return raw == 'instructor' ||
          raw == 'course' ||
          raw == 'trainer' ||
          raw == 'trainor';
    }).toList();
  }

  List<UserModel> get candidates {
    final currentAdminId = _authService.currentUser.value?.id;
    final currentAdminEmail =
        _authService.currentUser.value?.email.trim().toLowerCase();

    return _dbService.usersList.where((u) {
      // Exclude logged in admin account
      if (currentAdminId != null &&
          currentAdminId.isNotEmpty &&
          u.id == currentAdminId) {
        return false;
      }
      if (currentAdminEmail != null &&
          currentAdminEmail.isNotEmpty &&
          u.email.trim().toLowerCase() == currentAdminEmail) {
        return false;
      }

      // Exclude admin role or admin email
      if (u.role == UserRole.admin) {
        return false;
      }
      final email = u.email.trim().toLowerCase();
      if (email == 'admin@gmail.com') {
        return false;
      }

      if (u.role == UserRole.candidate) {
        return true;
      }

      final raw = u.rawRole.trim().toLowerCase();
      return raw == 'candidate';
    }).toList();
  }

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

  List<ApplicationModel> get allApplications => _dbService.applicationsList
      .where((a) => _dbService.jobsList.any((j) => j.id == a.jobId))
      .toList();

  Future<void> updateApplicationStage(
      String appId, ApplicationStatus status) async {
    try {
      await _dbService.updateApplicationStatus(appId, status);
      Get.snackbar(
        'Status Updated',
        'Application status updated to ${status.label}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update status: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> updateApplication(ApplicationModel app) async {
    try {
      await _dbService.updateApplication(app);
      Get.snackbar(
        'Application Updated',
        'Changes saved for ${app.candidateName}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update application: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteApplication(String appId) async {
    try {
      await _dbService.deleteApplication(appId);
      Get.snackbar(
        'Application Deleted',
        'Candidate application record has been removed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete application: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  // --- Candidate analytics -------------------------------------------------
  List<ApplicationModel> applicationsByCandidate(String candidateId, {String? email}) {
    final cId = candidateId.trim();
    final cEmail = (email ?? '').trim().toLowerCase();
    return _dbService.applicationsList.where((a) {
      if (cId.isNotEmpty && a.candidateId.trim() == cId) return true;
      if (cEmail.isNotEmpty && a.candidateEmail.trim().toLowerCase() == cEmail) return true;
      return false;
    }).toList();
  }

  int offersForCandidate(String candidateId, {String? email}) =>
      applicationsByCandidate(candidateId, email: email)
          .where((a) => a.status == ApplicationStatus.offered)
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

  Future<void> restoreJob(String jobId) async {
    try {
      await _dbService.restoreJob(jobId);
      Get.snackbar(
        'Job Restored',
        'Job listing was restored successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.secondary,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to restore job: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
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
      '"$serviceTitle" was permanently deleted by admin moderation',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }

  /// Saves an admin correction to a mentor's offering. Ownership fields are
  /// never taken from the admin, so the service stays with its mentor.
  Future<void> editMentorshipService(MentorshipServiceModel service) async {
    try {
      await _dbService.updateMentorshipService(service);
      Get.snackbar(
        'Service Updated',
        '"${service.title}" was updated by admin moderation',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Update Failed',
        'Could not update service: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> softDeleteMentorshipService(
      String serviceId, String serviceTitle) async {
    try {
      await _dbService.softDeleteMentorshipService(serviceId);
      Get.snackbar(
        'Service Soft Deleted',
        '"$serviceTitle" is hidden from candidates and public view',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[800] ?? Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to soft delete service: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> restoreMentorshipService(
      String serviceId, String serviceTitle) async {
    try {
      await _dbService.restoreMentorshipService(serviceId);
      Get.snackbar(
        'Service Restored',
        '"$serviceTitle" is now active and visible to candidates',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF059669),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to restore service: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
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

    // Ensure jobs and applications are backed up before removal
    DeletedUserModel? backupRecord;
    try {
      backupRecord = await _dbService.backupUserDataForRestore(userId);
    } catch (_) {}

    try {
      final result = await _accountAdminService.deleteAccount(userId);
      _applyLocalRemoval(userId);
      await refreshDeletedUsers();

      final isRecruiter = backupRecord?.role.toLowerCase() == 'recruiter';
      final isCandidate = backupRecord?.role.toLowerCase() == 'candidate';
      final jobsCount = backupRecord?.jobsCount ?? 0;
      final appsCount = backupRecord?.applicationsCount ?? 0;

      String details = '';
      if (isRecruiter && jobsCount > 0) {
        details = ' ($jobsCount job post${jobsCount == 1 ? '' : 's'} backed up)';
      } else if (isCandidate && appsCount > 0) {
        details = ' ($appsCount application${appsCount == 1 ? '' : 's'} backed up)';
      }

      if (result.authDeleted) {
        _notify(
          title: 'Account Deleted',
          message: '$name was removed from Firebase Authentication, '
              'Realtime Database and Firestore$details.',
          background: AppColors.secondary,
          action: backupRecord != null
              ? TextButton(
                  onPressed: () async {
                    Get.closeAllSnackbars();
                    await restoreUser(backupRecord!);
                  },
                  child: const Text('UNDO',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                )
              : TextButton(
                  onPressed: Get.closeAllSnackbars,
                  child: const Text('OK', style: TextStyle(color: Colors.white)),
                ),
        );
      } else {
        _notify(
          title: 'Data Deleted',
          message: '$name\'s data was removed$details, '
              'but the Firebase Auth account could not be deleted: '
              '${result.authError ?? 'unknown error'}. '
              'Remove it in Firebase Console > Authentication.',
          background: AppColors.warning,
          action: backupRecord != null
              ? TextButton(
                  onPressed: () async {
                    Get.closeAllSnackbars();
                    await restoreUser(backupRecord!);
                  },
                  child: const Text('UNDO',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                )
              : null,
        );
      }
      return true;
    } on AccountDeletionUnavailable catch (e) {
      debugPrint('Cloud delete unavailable: ${e.message}');
      return _deleteWithoutCloudFunction(userId, name, backupRecord: backupRecord);
    } catch (e) {
      debugPrint('Unexpected delete error: $e');
      return _deleteWithoutCloudFunction(userId, name, backupRecord: backupRecord);
    }
  }

  /// Fallback path: removes profile + related records using the client SDK.
  Future<bool> _deleteWithoutCloudFunction(String userId, String name,
      {DeletedUserModel? backupRecord}) async {
    try {
      final result = await _dbService.deleteUserCascade(userId);
      await refreshDeletedUsers();

      final record = result.deletedRecord ?? backupRecord;
      final isRecruiter = record?.role.toLowerCase() == 'recruiter';
      final isCandidate = record?.role.toLowerCase() == 'candidate';
      final jobsCount = record?.jobsCount ?? 0;
      final appsCount = record?.applicationsCount ?? 0;

      String details = '';
      if (isRecruiter && jobsCount > 0) {
        details = ' ($jobsCount job post${jobsCount == 1 ? '' : 's'} backed up for restore)';
      } else if (isCandidate && appsCount > 0) {
        details = ' ($appsCount application${appsCount == 1 ? '' : 's'} backed up for restore)';
      }

      final note = result.email.isEmpty ? '' : ' (${result.email})';
      _notify(
        title: 'User Removed',
        message: '$name$note was removed from Realtime Database$details. '
            'You can restore this account anytime with their data.',
        background: AppColors.warning,
        action: TextButton(
          onPressed: () async {
            Get.closeAllSnackbars();
            if (record != null) {
              await restoreUser(record);
            }
          },
          child: const Text('UNDO',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      final result = await _dbService.restoreUser(
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

      String extraDetails = '';
      if (result.user.role == UserRole.recruiter) {
        if (result.restoredJobsCount > 0) {
          extraDetails =
              ' along with ${result.restoredJobsCount} job post${result.restoredJobsCount == 1 ? '' : 's'}';
        }
      } else if (result.user.role == UserRole.candidate) {
        if (result.restoredApplicationsCount > 0) {
          extraDetails =
              ' along with ${result.restoredApplicationsCount} application${result.restoredApplicationsCount == 1 ? '' : 's'} (only for active jobs)';
        }
      }

      _notify(
        title: 'Account Restored',
        message:
            '$displayName has been restored$extraDetails. Profile and content are back in Realtime Database.',
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
      final result = await _dbService.restoreUser(
        cleanId,
        name: name,
        email: email,
        role: role,
      );
      final label = (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : ((email != null && email.trim().isNotEmpty)
              ? email.trim()
              : cleanId);

      String extra = '';
      if (result.user.role == UserRole.recruiter &&
          result.restoredJobsCount > 0) {
        extra =
            ' with ${result.restoredJobsCount} job post${result.restoredJobsCount == 1 ? '' : 's'}';
      } else if (result.user.role == UserRole.candidate &&
          result.restoredApplicationsCount > 0) {
        extra =
            ' with ${result.restoredApplicationsCount} application${result.restoredApplicationsCount == 1 ? '' : 's'} to active jobs';
      }

      _notify(
        title: 'Account Restored',
        message:
            '$label can now log in again$extra. Profile recreated in Realtime Database.',
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
  /// When [silent] is true, suppresses error dialogs/snackbars (useful during
  /// background login and initial page load).
  Future<bool> refreshDeletedUsers({bool silent = true}) async {
    try {
      await _dbService.refreshDeletedUsers();
      deletedUsersLoaded.value = true;
      return true;
    } catch (e) {
      deletedUsersLoaded.value = false;
      debugPrint('AdminController.refreshDeletedUsers: $e');
      if (!silent) {
        _showError(
          'Could not load deleted users',
          'The Realtime Database denied this read: ${_friendlyError(e)}',
        );
      }
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
