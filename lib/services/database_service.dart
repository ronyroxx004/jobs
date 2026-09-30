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
  final RxList<MentorshipServiceModel> servicesList = <MentorshipServiceModel>[].obs;
  final RxList<BookingModel> bookingsList = <BookingModel>[].obs;
  final RxList<CourseModel> coursesList = <CourseModel>[].obs;
  final RxList<ChatRoomModel> chatRoomsList = <ChatRoomModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    await fetchJobs();
    await fetchCourses();
    await fetchServices();
  }

  // --- USER PROFILE ---
  Future<void> saveUserProfile(UserModel user) async {
    try {
      await _db?.ref(DatabaseKeys.users).child(user.id).set(user.toMap());
    } catch (_) {}
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

  Future<List<JobModel>> fetchJobs() async {
    try {
      final snapshot = await _db?.ref(DatabaseKeys.jobs).get();
      if (snapshot != null && snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> map = snapshot.value as Map;
        final list = <JobModel>[];
        map.forEach((key, value) {
          list.add(JobModel.fromMap(Map<String, dynamic>.from(value), key.toString()));
        });
        jobsList.assignAll(list);
      }
    } catch (_) {}
    return jobsList;
  }

  // --- RESUMES ---
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
  Future<void> submitApplication(ApplicationModel application) async {
    try {
      await _db?.ref(DatabaseKeys.applications).child(application.id).set(application.toMap());
    } catch (_) {}
    applicationsList.insert(0, application);

    final jobIdx = jobsList.indexWhere((j) => j.id == application.jobId);
    if (jobIdx != -1) {
      final j = jobsList[jobIdx];
      jobsList[jobIdx] = JobModel(
        id: j.id,
        title: j.title,
        companyName: j.companyName,
        companyLogo: j.companyLogo,
        location: j.location,
        jobType: j.jobType,
        experienceLevel: j.experienceLevel,
        salaryRange: j.salaryRange,
        description: j.description,
        requirements: j.requirements,
        skills: j.skills,
        recruiterId: j.recruiterId,
        recruiterName: j.recruiterName,
        applicantCount: j.applicantCount + 1,
        isFeatured: j.isFeatured,
        isActive: j.isActive,
        postedAt: j.postedAt,
      );
    }
  }

  Future<void> updateApplicationStatus(String appId, ApplicationStatus status) async {
    try {
      await _db?.ref(DatabaseKeys.applications).child(appId).update({'status': status.name});
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
      await _db?.ref(DatabaseKeys.mentorshipServices).child(service.id).set(service.toMap());
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
          list.add(MentorshipServiceModel.fromMap(Map<String, dynamic>.from(value), key.toString()));
        });
        servicesList.assignAll(list);
      }
    } catch (_) {}
    return servicesList;
  }

  Future<void> createBooking(BookingModel booking) async {
    try {
      await _db?.ref(DatabaseKeys.bookings).child(booking.id).set(booking.toMap());
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
          list.add(CourseModel.fromMap(Map<String, dynamic>.from(value), key.toString()));
        });
        coursesList.assignAll(list);
      }
    } catch (_) {}
    return coursesList;
  }

  // --- CHAT MESSAGES ---
  Future<void> sendMessage(String roomId, ChatMessageModel message) async {
    try {
      await _db?.ref(DatabaseKeys.messages).child(roomId).child(message.id).set(message.toMap());
      await _db?.ref(DatabaseKeys.chats).child(roomId).update({
        'lastMessage': message.text,
        'lastMessageTime': message.timestamp.toIso8601String(),
      });
    } catch (_) {}
  }
}
