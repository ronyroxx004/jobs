import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import '../models/job_model.dart';
import '../models/resume_model.dart';
import '../models/application_model.dart';
import '../models/service_model.dart';
import '../models/course_model.dart';
import '../models/chat_model.dart';
import '../core/utils/constants.dart';

class DatabaseService extends GetxService {
  FirebaseDatabase? _dbInstance;

  FirebaseDatabase? get _db {
    try {
      _dbInstance ??= FirebaseDatabase.instance;
      return _dbInstance;
    } catch (_) {
      return null;
    }
  }

  // Real-time reactive data lists initialized empty (no demo data)
  final RxList<JobModel> jobsList = <JobModel>[].obs;
  final RxList<ResumeModel> resumeList = <ResumeModel>[].obs;
  final RxList<ApplicationModel> applicationsList = <ApplicationModel>[].obs;
  final RxList<MentorshipServiceModel> servicesList =
      <MentorshipServiceModel>[].obs;
  final RxList<BookingModel> bookingsList = <BookingModel>[].obs;
  final RxList<CourseModel> coursesList = <CourseModel>[].obs;
  final RxList<ChatRoomModel> chatRoomsList = <ChatRoomModel>[].obs;
  final RxList<UserModel> usersList = <UserModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllData();
    _setupRealtimeListeners();
  }

  void _setupRealtimeListeners() {
    try {
      _db?.ref(DatabaseKeys.jobs).onValue.listen((event) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final Map<dynamic, dynamic> map = event.snapshot.value as Map;
          final list = <JobModel>[];
          map.forEach((key, value) {
            list.add(JobModel.fromMap(
                Map<String, dynamic>.from(value), key.toString()));
          });
          jobsList.assignAll(list);
        }
      });

      _db?.ref(DatabaseKeys.applications).onValue.listen((event) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final Map<dynamic, dynamic> map = event.snapshot.value as Map;
          final list = <ApplicationModel>[];
          map.forEach((key, value) {
            list.add(ApplicationModel.fromMap(
                Map<String, dynamic>.from(value), key.toString()));
          });
          applicationsList.assignAll(list);
        }
      });

      _db?.ref(DatabaseKeys.users).onValue.listen((event) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final Map<dynamic, dynamic> map = event.snapshot.value as Map;
          final list = <UserModel>[];
          map.forEach((key, value) {
            list.add(UserModel.fromMap(
                Map<String, dynamic>.from(value), key.toString()));
          });
          usersList.assignAll(list);
        }
      });
    } catch (_) {}
  }

  Future<void> fetchAllData() async {
    await fetchJobs();
    await fetchCourses();
    await fetchServices();
    await fetchResumes();
    await fetchApplications();
    await fetchUsers();
  }

  Future<List<UserModel>> fetchUsers() async {
    try {
      final snapshot = await _db?.ref(DatabaseKeys.users).get();
      if (snapshot != null && snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> map = snapshot.value as Map;
        final list = <UserModel>[];
        map.forEach((key, value) {
          list.add(UserModel.fromMap(
              Map<String, dynamic>.from(value), key.toString()));
        });
        usersList.assignAll(list);
      }
    } catch (_) {}
    return usersList;
  }

  /// Removes a user and every record that belongs to them, then leaves a
  /// tombstone so the account cannot silently be recreated on next login.
  ///
  /// Throws a [StateError] when the Realtime Database is unreachable so callers
  /// can surface the real reason instead of failing silently.
  Future<UserDeleteResult> deleteUserCascade(String userId) async {
    final db = _db;
    if (db == null) {
      throw StateError(
        'Firebase Realtime Database is not available. '
        'Check your internet connection and try again.',
      );
    }

    if (userId.isEmpty) {
      throw StateError('Invalid user id.');
    }

    final user = usersList.firstWhereOrNull((u) => u.id == userId);

    // Preserve a tombstone BEFORE clearing the profile, so an in-flight login
    // cannot recreate the account from the deleted profile document.
    await db.ref(DatabaseKeys.deletedUsers).child(userId).set({
      'email': user?.email ?? '',
      'name': user?.name ?? '',
      'role': user?.role.name ?? '',
      'deletedAt': DateTime.now().toIso8601String(),
    });

    await Future.wait([
      db.ref(DatabaseKeys.users).child(userId).remove(),
      _purgeResumes(db, userId),
      _purgeApplications(db, userId),
      _purgeJobs(db, userId),
      _purgeMentorshipServices(db, userId),
      _purgeBookings(db, userId),
      _purgeChats(db, userId),
      _purgeFirestoreRecords(userId),
    ]);

    // Mirror the removal into the local reactive caches so the UI updates
    // immediately even if a listener has not fired yet.
    usersList.removeWhere((u) => u.id == userId);
    resumeList.removeWhere((r) => r.userId == userId);
    applicationsList.removeWhere((a) => a.candidateId == userId);
    jobsList.removeWhere((j) => j.recruiterId == userId);
    servicesList.removeWhere((s) => s.mentorId == userId);
    bookingsList.removeWhere(
        (b) => b.mentorId == userId || b.candidateId == userId);
    chatRoomsList.removeWhere(
        (c) => c.participantIds.contains(userId));

    return UserDeleteResult(
      removedFirestoreRecords: true,
      email: user?.email ?? '',
    );
  }

  /// Returns true when an admin has previously removed this account.
  Future<bool> isUserDeleted(String userId) async {
    try {
      final snapshot = await _db?.ref(DatabaseKeys.deletedUsers).child(userId).get();
      return snapshot?.exists == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _purgeResumes(FirebaseDatabase db, String userId) async {
    final snapshot = await db.ref(DatabaseKeys.resumes).get();
    final data = snapshot.value;
    if (data is! Map) return;
    for (final entry in data.entries) {
      final map = Map<String, dynamic>.from(entry.value as Map);
      if (map['userId'] == userId) {
        await db.ref(DatabaseKeys.resumes).child('${entry.key}').remove();
      }
    }
  }

  Future<void> _purgeApplications(FirebaseDatabase db, String userId) async {
    final snapshot = await db.ref(DatabaseKeys.applications).get();
    final data = snapshot.value;
    if (data is! Map) return;
    for (final entry in data.entries) {
      final map = Map<String, dynamic>.from(entry.value as Map);
      if (map['candidateId'] == userId) {
        await db.ref(DatabaseKeys.applications).child('${entry.key}').remove();
      }
    }
  }

  Future<void> _purgeJobs(FirebaseDatabase db, String userId) async {
    final snapshot = await db.ref(DatabaseKeys.jobs).get();
    final data = snapshot.value;
    if (data is! Map) return;
    for (final entry in data.entries) {
      final map = Map<String, dynamic>.from(entry.value as Map);
      if (map['recruiterId'] == userId) {
        await db.ref(DatabaseKeys.jobs).child('${entry.key}').remove();
      }
    }
  }

  Future<void> _purgeMentorshipServices(
      FirebaseDatabase db, String userId) async {
    final snapshot = await db.ref(DatabaseKeys.mentorshipServices).get();
    final data = snapshot.value;
    if (data is! Map) return;
    for (final entry in data.entries) {
      final map = Map<String, dynamic>.from(entry.value as Map);
      if (map['mentorId'] == userId) {
        await db
            .ref(DatabaseKeys.mentorshipServices)
            .child('${entry.key}')
            .remove();
      }
    }
  }

  Future<void> _purgeBookings(FirebaseDatabase db, String userId) async {
    final snapshot = await db.ref(DatabaseKeys.bookings).get();
    final data = snapshot.value;
    if (data is! Map) return;
    for (final entry in data.entries) {
      final map = Map<String, dynamic>.from(entry.value as Map);
      if (map['mentorId'] == userId || map['candidateId'] == userId) {
        await db.ref(DatabaseKeys.bookings).child('${entry.key}').remove();
      }
    }
  }

  Future<void> _purgeChats(FirebaseDatabase db, String userId) async {
    final snapshot = await db.ref(DatabaseKeys.chats).get();
    final data = snapshot.value;
    if (data is! Map) return;
    for (final entry in data.entries) {
      final map = Map<String, dynamic>.from(entry.value as Map);
      final participants = List<String>.from(map['participantIds'] ?? const []);
      if (participants.contains(userId)) {
        await db.ref(DatabaseKeys.chats).child('${entry.key}').remove();
        await db.ref(DatabaseKeys.messages).child('${entry.key}').remove();
      }
    }
  }

  /// Removes the Firestore image/media documents owned by the user.
  Future<void> _purgeFirestoreRecords(String userId) async {
    final firestore = Get.find<FirestoreService>();
    for (final collection in [
      DatabaseKeys.userImages,
      DatabaseKeys.portfolioImages,
    ]) {
      try {
        await firestore.deleteImageRecords(collection: collection, userId: userId);
      } catch (_) {}
    }
  }

  // --- USER PROFILE ---
  Future<void> saveUserProfile(UserModel user) async {
    try {
      if (_db != null) {
        await _db!.ref(DatabaseKeys.users).child(user.id).set(user.toMap());
      } else {
        throw Exception('Firebase Realtime Database is not connected');
      }
    } catch (e) {
      debugPrint('Error saving user profile: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final snapshot = await _db?.ref(DatabaseKeys.users).child(userId).get();
      if (snapshot != null && snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return UserModel.fromMap(data, userId);
      }
    } catch (_) {}
    return null;
  }

  // --- JOBS ---
  Future<void> createJob(JobModel job) async {
    final db = _db;
    if (db == null) {
      throw StateError('Firebase Realtime Database is not available');
    }

    await db.ref(DatabaseKeys.jobs).child(job.id).set(job.toMap());
    jobsList.removeWhere((existing) => existing.id == job.id);
    jobsList.insert(0, job);
  }

  Future<void> updateJob(JobModel job) async {
    final db = _db;
    if (db == null) {
      throw StateError('Firebase Realtime Database is not available');
    }

    await db.ref(DatabaseKeys.jobs).child(job.id).update(job.toMap());
    final index = jobsList.indexWhere((item) => item.id == job.id);
    if (index == -1) {
      jobsList.insert(0, job);
    } else {
      jobsList[index] = job;
    }
  }

  Future<void> deleteJob(String jobId) async {
    final db = _db;
    if (db == null) {
      throw StateError('Firebase Realtime Database is not available');
    }

    await db.ref(DatabaseKeys.jobs).child(jobId).remove();
    jobsList.removeWhere((job) => job.id == jobId);
  }

  Future<List<JobModel>> fetchJobs() async {
    try {
      final snapshot = await _db?.ref(DatabaseKeys.jobs).get();
      if (snapshot != null && snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> map = snapshot.value as Map;
        final list = <JobModel>[];
        map.forEach((key, value) {
          list.add(JobModel.fromMap(
              Map<String, dynamic>.from(value), key.toString()));
        });
        jobsList.assignAll(list);
      }
    } catch (_) {}
    return jobsList;
  }

  // --- RESUMES ---
  Future<List<ResumeModel>> fetchResumes() async {
    try {
      final snapshot = await _db?.ref(DatabaseKeys.resumes).get();
      if (snapshot != null && snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> map = snapshot.value as Map;
        final list = <ResumeModel>[];
        map.forEach((key, value) {
          list.add(ResumeModel.fromMap(
              Map<String, dynamic>.from(value), key.toString()));
        });
        resumeList.assignAll(list);
      }
    } catch (_) {}
    return resumeList;
  }

  Future<void> addResume(ResumeModel resume) async {
    try {
      await _db?.ref(DatabaseKeys.resumes).child(resume.id).set(resume.toMap());
    } catch (_) {}

    if (resume.isPrimary) {
      for (int i = 0; i < resumeList.length; i++) {
        final r = resumeList[i];
        if (r.id != resume.id && r.isPrimary) {
          final updated = ResumeModel(
            id: r.id,
            userId: r.userId,
            fileName: r.fileName,
            fileUrl: r.fileUrl,
            fileSize: r.fileSize,
            isPrimary: false,
            extractedSkills: r.extractedSkills,
            uploadedAt: r.uploadedAt,
          );
          resumeList[i] = updated;
        }
      }
    }
    resumeList.insert(0, resume);
  }

  Future<void> deleteResume(String resumeId) async {
    try {
      await _db?.ref(DatabaseKeys.resumes).child(resumeId).remove();
    } catch (_) {}
    resumeList.removeWhere((r) => r.id == resumeId);
  }

  // --- APPLICATIONS ---
  Future<List<ApplicationModel>> fetchApplications() async {
    try {
      final snapshot = await _db?.ref(DatabaseKeys.applications).get();
      if (snapshot != null && snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> map = snapshot.value as Map;
        final list = <ApplicationModel>[];
        map.forEach((key, value) {
          list.add(ApplicationModel.fromMap(
              Map<String, dynamic>.from(value), key.toString()));
        });
        applicationsList.assignAll(list);
      }
    } catch (_) {}
    return applicationsList;
  }

  Future<void> submitApplication(ApplicationModel application) async {
    final db = _db;
    if (db == null) {
      throw StateError('Firebase Realtime Database is not available');
    }

    final jobRef = db.ref(DatabaseKeys.jobs).child(application.jobId);
    final jobSnapshot = await jobRef.get();
    if (!jobSnapshot.exists) {
      throw StateError('The job listing could not be found');
    }

    final applicationRef =
        db.ref(DatabaseKeys.applications).child(application.id);
    final applicationResult =
        await applicationRef.runTransaction((currentData) {
      if (currentData != null) {
        return Transaction.abort();
      }
      return Transaction.success(application.toMap());
    });
    if (!applicationResult.committed) {
      throw StateError('An application for this job already exists');
    }

    final countResult =
        await jobRef.child('applicantCount').runTransaction((value) {
      final currentCount = (value as num?)?.toInt() ?? 0;
      return Transaction.success(currentCount + 1);
    });
    if (!countResult.committed) {
      throw StateError('The applicant count could not be updated');
    }

    applicationsList.removeWhere((item) => item.id == application.id);
    applicationsList.insert(0, application);
  }

  Future<void> updateApplicationStatus(
      String appId, ApplicationStatus status) async {
    try {
      await _db
          ?.ref(DatabaseKeys.applications)
          .child(appId)
          .update({'status': status.name});
    } catch (_) {}
    final idx = applicationsList.indexWhere((a) => a.id == appId);
    if (idx != -1) {
      final a = applicationsList[idx];
      applicationsList[idx] = ApplicationModel(
        id: a.id,
        jobId: a.jobId,
        jobTitle: a.jobTitle,
        companyName: a.companyName,
        candidateId: a.candidateId,
        candidateName: a.candidateName,
        candidateEmail: a.candidateEmail,
        candidatePhone: a.candidatePhone,
        candidateHeadline: a.candidateHeadline,
        candidateBio: a.candidateBio,
        candidateLocation: a.candidateLocation,
        candidateExperienceYears: a.candidateExperienceYears,
        candidateSkills: a.candidateSkills,
        candidateAvatar: a.candidateAvatar,
        resumeUrl: a.resumeUrl,
        resumeName: a.resumeName,
        coverLetter: a.coverLetter,
        status: status,
        appliedAt: a.appliedAt,
      );
    }
  }

  // --- MENTORSHIP SERVICES & BOOKINGS ---
  Future<void> createMentorshipService(MentorshipServiceModel service) async {
    try {
      await _db
          ?.ref(DatabaseKeys.mentorshipServices)
          .child(service.id)
          .set(service.toMap());
    } catch (_) {}
    servicesList.insert(0, service);
  }

  Future<List<MentorshipServiceModel>> fetchServices() async {
    try {
      final snapshot = await _db?.ref(DatabaseKeys.mentorshipServices).get();
      if (snapshot != null && snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> map = snapshot.value as Map;
        final list = <MentorshipServiceModel>[];
        map.forEach((key, value) {
          list.add(MentorshipServiceModel.fromMap(
              Map<String, dynamic>.from(value), key.toString()));
        });
        servicesList.assignAll(list);
      }
    } catch (_) {}
    return servicesList;
  }

  Future<void> deleteMentorshipService(String serviceId) async {
    try {
      await _db
          ?.ref(DatabaseKeys.mentorshipServices)
          .child(serviceId)
          .remove();
    } catch (_) {}
    servicesList.removeWhere((s) => s.id == serviceId);
  }

  Future<void> createBooking(BookingModel booking) async {
    try {
      await _db
          ?.ref(DatabaseKeys.bookings)
          .child(booking.id)
          .set(booking.toMap());
    } catch (_) {}
    bookingsList.insert(0, booking);
  }

  // --- COURSES ---
  Future<void> createCourse(CourseModel course) async {
    try {
      await _db?.ref(DatabaseKeys.courses).child(course.id).set(course.toMap());
    } catch (_) {}
    coursesList.insert(0, course);
  }

  Future<List<CourseModel>> fetchCourses() async {
    try {
      final snapshot = await _db?.ref(DatabaseKeys.courses).get();
      if (snapshot != null && snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> map = snapshot.value as Map;
        final list = <CourseModel>[];
        map.forEach((key, value) {
          list.add(CourseModel.fromMap(
              Map<String, dynamic>.from(value), key.toString()));
        });
        coursesList.assignAll(list);
      }
    } catch (_) {}
    return coursesList;
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      await _db?.ref(DatabaseKeys.courses).child(courseId).remove();
    } catch (_) {}
    coursesList.removeWhere((c) => c.id == courseId);
  }

  // --- CHAT MESSAGES ---
  Future<void> sendMessage(String roomId, ChatMessageModel message) async {
    try {
      await _db
          ?.ref(DatabaseKeys.messages)
          .child(roomId)
          .child(message.id)
          .set(message.toMap());
      await _db?.ref(DatabaseKeys.chats).child(roomId).update({
        'lastMessage': message.text,
        'lastMessageTime': message.timestamp.toIso8601String(),
      });
    } catch (_) {}
  }
}

/// Outcome of a cascading admin user deletion.
class UserDeleteResult {
  /// Whether the profile + related Realtime Database records were removed.
  final bool removedFirestoreRecords;

  /// Email captured from the tombstone, used to explain the auth side effect.
  final String email;

  const UserDeleteResult({
    required this.removedFirestoreRecords,
    required this.email,
  });
}
