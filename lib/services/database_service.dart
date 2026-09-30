import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
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
    } catch (_) {}
  }

  Future<void> fetchAllData() async {
    await fetchJobs();
    await fetchCourses();
    await fetchServices();
    await fetchResumes();
    await fetchApplications();
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
    try {
      await _db?.ref(DatabaseKeys.jobs).child(job.id).set(job.toMap());
    } catch (_) {}
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
