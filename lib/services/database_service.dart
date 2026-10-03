import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/deleted_user_model.dart';
import 'firestore_service.dart';
import '../models/job_model.dart';
import '../models/resume_model.dart';
import '../models/application_model.dart';
import '../models/service_model.dart';
import '../models/course_model.dart';
import '../models/chat_model.dart';
import '../core/utils/constants.dart';

class DatabaseService extends GetxService {
  /// Window for a Realtime Database read. Mobile connections frequently need
  /// well over a few seconds to establish the socket, and a short window makes
  /// the app look empty instead of loading late.
  static const Duration readTimeout = Duration(seconds: 20);

  FirebaseDatabase? _dbInstance;

  FirebaseDatabase? get _db {
    try {
      _dbInstance ??= FirebaseDatabase.instance;
      return _dbInstance;
    } catch (e) {
      try {
        _dbInstance ??= FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: 'https://jobs-37214-default-rtdb.firebaseio.com',
        );
        return _dbInstance;
      } catch (err) {
        debugPrint('FirebaseDatabase initialization error: $err');
        return null;
      }
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

  /// Admin-removed accounts kept as tombstones so they can be restored.
  final RxList<DeletedUserModel> deletedUsersList = <DeletedUserModel>[].obs;
  StreamSubscription? _deletedUsersSubscription;
  StreamSubscription? _jobsSubscription;
  StreamSubscription? _servicesSubscription;

  @override
  void onInit() {
    super.onInit();
    fetchAllData();
    _setupRealtimeListeners();
    _setupDeletedUsersListener();
  }

  @override
  void onClose() {
    _deletedUsersSubscription?.cancel();
    _jobsSubscription?.cancel();
    _servicesSubscription?.cancel();
    super.onClose();
  }

  List<JobModel> _parseJobs(dynamic value) {
    final list = <JobModel>[];
    if (value is Map) {
      value.forEach((key, val) {
        if (val != null && val is Map) {
          try {
            final map = Map<String, dynamic>.from(val);
            list.add(JobModel.fromMap(map, key.toString()));
          } catch (e) {
            debugPrint('Failed to parse job $key: $e');
          }
        }
      });
    } else if (value is List) {
      for (int i = 0; i < value.length; i++) {
        final val = value[i];
        if (val != null && val is Map) {
          try {
            final map = Map<String, dynamic>.from(val);
            list.add(JobModel.fromMap(map, i.toString()));
          } catch (e) {
            debugPrint('Failed to parse job at index $i: $e');
          }
        }
      }
    }
    list.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return list;
  }

  void _setupRealtimeListeners() {
    try {
      _jobsSubscription?.cancel();
      _jobsSubscription = _db?.ref(DatabaseKeys.jobs).onValue.listen((event) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final list = _parseJobs(event.snapshot.value);
          jobsList.assignAll(list);
        } else {
          jobsList.clear();
        }
      }, onError: (err) {
        debugPrint('Jobs listener: $err');
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
      }, onError: (err) {
        debugPrint('Applications listener: $err');
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
      }, onError: (err) {
        debugPrint('Users listener: $err');
      });

      _db?.ref(DatabaseKeys.bookings).onValue.listen((event) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final Map<dynamic, dynamic> map = event.snapshot.value as Map;
          final list = <BookingModel>[];
          map.forEach((key, value) {
            list.add(BookingModel.fromMap(
                Map<String, dynamic>.from(value), key.toString()));
          });
          list.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
          bookingsList.assignAll(list);
        } else {
          bookingsList.clear();
        }
      }, onError: (err) {
        debugPrint('Bookings listener: $err');
      });

      _servicesSubscription?.cancel();
      _servicesSubscription = _db
          ?.ref(DatabaseKeys.mentorshipServices)
          .onValue
          .listen((event) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final list = _parseServices(event.snapshot.value);
          servicesList.assignAll(list);
        }
      }, onError: (err) {
        debugPrint('Mentorship services listener: $err');
      });
    } catch (_) {}
  }

  void _setupDeletedUsersListener() {
    try {
      _deletedUsersSubscription?.cancel();
      _deletedUsersSubscription =
          _db?.ref(DatabaseKeys.deletedUsers).onValue.listen(
        (event) {
          if (event.snapshot.exists && event.snapshot.value != null) {
            final parsed = _parseDeletedUsers(event.snapshot.value);
            deletedUsersList.assignAll(parsed);
          } else {
            deletedUsersList.clear();
          }
        },
        onError: (err) {
          debugPrint('Deleted users listener: $err');
        },
      );
    } catch (_) {}
  }

  List<DeletedUserModel> _parseDeletedUsers(dynamic value) {
    final deleted = <DeletedUserModel>[];
    if (value is Map) {
      value.forEach((key, entry) {
        if (entry != null) {
          deleted.add(DeletedUserModel.fromRaw(entry, key.toString()));
        }
      });
    } else if (value is List) {
      for (int i = 0; i < value.length; i++) {
        final entry = value[i];
        if (entry != null) {
          deleted.add(DeletedUserModel.fromRaw(entry, i.toString()));
        }
      }
    }
    deleted.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return deleted;
  }

  Future<void> fetchAllData() async {
    try {
      await Future.wait([
        fetchJobs().timeout(readTimeout, onTimeout: () => jobsList),
        fetchCourses().timeout(readTimeout, onTimeout: () => coursesList),
        fetchServices().timeout(readTimeout, onTimeout: () => servicesList),
        fetchBookings().timeout(readTimeout, onTimeout: () => bookingsList),
        fetchResumes().timeout(readTimeout, onTimeout: () => resumeList),
        fetchApplications().timeout(readTimeout, onTimeout: () => applicationsList),
        fetchUsers().timeout(readTimeout, onTimeout: () => usersList),
        fetchDeletedUsers().timeout(readTimeout, onTimeout: () => deletedUsersList),
      ]);
    } catch (_) {}
    _scheduleMentorshipDataRetry();
  }

  bool _mentorshipRetryPending = false;

  /// A cold Realtime Database socket regularly needs more than a couple of
  /// seconds on mobile data, which leaves the mentor screens empty after login.
  /// One deferred retry recovers the offerings without blocking the UI.
  void _scheduleMentorshipDataRetry() {
    if (_mentorshipRetryPending) return;
    if (servicesList.isNotEmpty && bookingsList.isNotEmpty) return;
    _mentorshipRetryPending = true;
    Future<void>.delayed(const Duration(seconds: 3), () async {
      _mentorshipRetryPending = false;
      try {
        await Future.wait([fetchServices(), fetchBookings()]);
      } catch (e) {
        debugPrint('Mentorship data retry failed: $e');
      }
    });
  }

  Future<List<UserModel>> fetchUsers() async {
    try {
      final snapshot = await _db
          ?.ref(DatabaseKeys.users)
          .get()
          .timeout(readTimeout);
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

  /// Backs up a user's jobs, applications, and profile to `deleted_users/{userId}`
  /// before deletion so they can be restored later.
  Future<DeletedUserModel> backupUserDataForRestore(String userId) async {
    final db = _db;
    final user = usersList.firstWhereOrNull((u) => u.id == userId);

    final Map<String, dynamic> jobsBackup = {};
    for (final j in jobsList.where((j) => j.recruiterId == userId)) {
      jobsBackup[j.id] = j.toMap();
    }
    if (db != null) {
      try {
        final snap = await db.ref(DatabaseKeys.jobs).get();
        if (snap.exists && snap.value is Map) {
          final map = Map<String, dynamic>.from(snap.value as Map);
          map.forEach((k, v) {
            if (v is Map && v['recruiterId'] == userId) {
              jobsBackup[k.toString()] = Map<String, dynamic>.from(v);
            }
          });
        }
      } catch (_) {}
    }

    final Map<String, dynamic> appsBackup = {};
    for (final a in applicationsList.where((a) => a.candidateId == userId)) {
      appsBackup[a.id] = a.toMap();
    }
    if (db != null) {
      try {
        final snap = await db.ref(DatabaseKeys.applications).get();
        if (snap.exists && snap.value is Map) {
          final map = Map<String, dynamic>.from(snap.value as Map);
          map.forEach((k, v) {
            if (v is Map && v['candidateId'] == userId) {
              appsBackup[k.toString()] = Map<String, dynamic>.from(v);
            }
          });
        }
      } catch (_) {}
    }

    final deletedRecord = DeletedUserModel(
      id: userId,
      email: user?.email ?? '',
      name: user?.name ?? '',
      role: user?.role.name ?? UserRole.candidate.name,
      deletedAt: DateTime.now(),
      deletedBy: _currentAdminId(),
      backedUpJobs: jobsBackup,
      backedUpApplications: appsBackup,
      backedUpProfile: user?.toMap() ?? {},
    );

    if (db != null) {
      await db
          .ref(DatabaseKeys.deletedUsers)
          .child(userId)
          .set(deletedRecord.toMap());
    }
    deletedUsersList.removeWhere((u) => u.id == userId);
    deletedUsersList.insert(0, deletedRecord);

    return deletedRecord;
  }

  /// Removes a user and every record that belongs to them, then leaves a
  /// tombstone with backed up jobs and applications so they can be restored.
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

    // Back up user jobs, applications, and profile before purging
    final deletedRecord = await backupUserDataForRestore(userId);

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
      deletedRecord: deletedRecord,
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

  /// All accounts removed by an admin, newest first.
  ///
  /// Throws a [StateError] when the read is denied so the UI can report the
  /// real problem instead of silently showing an empty list.
  Future<List<DeletedUserModel>> fetchDeletedUsers() async {
    final db = _db;
    if (db == null) {
      return <DeletedUserModel>[];
    }

    try {
      final snapshot = await db.ref(DatabaseKeys.deletedUsers).get();
      if (!snapshot.exists || snapshot.value == null) {
        deletedUsersList.clear();
        return <DeletedUserModel>[];
      }

      final deleted = _parseDeletedUsers(snapshot.value);
      deletedUsersList.assignAll(deleted);
      return deleted;
    } catch (e) {
      debugPrint('DatabaseService.fetchDeletedUsers: $e');
      return deletedUsersList;
    }
  }

  /// Restores a removed account's login + profile, along with their job posts
  /// (if recruiter) and applications (if candidate, only for existing job posts).
  Future<UserRestoreResult> restoreUser(
    String userId, {
    String? name,
    String? email,
    UserRole? role,
  }) async {
    final db = _db;
    if (db == null) {
      throw StateError('Firebase Realtime Database is not available.');
    }

    final cleanId = userId.trim();
    if (cleanId.isEmpty) {
      throw ArgumentError('User ID cannot be empty.');
    }

    final snapshot =
        await db.ref(DatabaseKeys.deletedUsers).child(cleanId).get();
    final raw = snapshot.value;
    Map<String, dynamic> record = {};
    if (snapshot.exists && raw != null) {
      if (raw is Map) {
        record = Map<String, dynamic>.from(raw);
      } else if (raw is String && raw.contains('@')) {
        record['email'] = raw;
      }
    }

    final finalEmail = email?.trim().isNotEmpty == true
        ? email!.trim()
        : (record['email']?.toString() ?? '');

    final finalName = name?.trim().isNotEmpty == true
        ? name!.trim()
        : (record['name']?.toString().trim().isNotEmpty == true
            ? record['name']!.toString().trim()
            : (finalEmail.isNotEmpty
                ? finalEmail.split('@')[0]
                : 'User_${cleanId.length > 6 ? cleanId.substring(0, 6) : cleanId}'));

    final roleName = record['role']?.toString() ?? UserRole.candidate.name;
    final finalRole = role ??
        UserRole.values.firstWhere(
          (r) => r.name.toLowerCase() == roleName.toLowerCase(),
          orElse: () => UserRole.candidate,
        );

    // 1. Re-create the profile (prefer full backed-up profile if present)
    UserModel restoredUser;
    if (record['profile'] is Map) {
      final profMap = Map<String, dynamic>.from(record['profile'] as Map);
      restoredUser = UserModel.fromMap(profMap, cleanId);
    } else {
      restoredUser = UserModel(
        id: cleanId,
        name: finalName,
        email: finalEmail,
        role: finalRole,
      );
    }

    await db.ref(DatabaseKeys.users).child(cleanId).set(restoredUser.toMap());

    int restoredJobsCount = 0;
    int restoredAppsCount = 0;

    // 2. If recruiter: restore their job posts if any
    if (finalRole == UserRole.recruiter && record['jobs'] is Map) {
      final jobsMap = Map<String, dynamic>.from(record['jobs'] as Map);
      for (final entry in jobsMap.entries) {
        if (entry.value is Map) {
          final jobData = Map<String, dynamic>.from(entry.value as Map);
          final jobId = entry.key.toString();
          final job = JobModel.fromMap(jobData, jobId);
          await db.ref(DatabaseKeys.jobs).child(jobId).set(job.toMap());
          jobsList.removeWhere((j) => j.id == jobId);
          jobsList.add(job);
          restoredJobsCount++;
        }
      }
    }

    // 3. If candidate: restore applications to any job post IF the job post exists.
    // If the job post doesn't exist, do not show or restore it!
    if (finalRole == UserRole.candidate && record['applications'] is Map) {
      await fetchJobs();
      final existingJobIds = jobsList.map((j) => j.id).toSet();

      final appsMap = Map<String, dynamic>.from(record['applications'] as Map);
      for (final entry in appsMap.entries) {
        if (entry.value is Map) {
          final appData = Map<String, dynamic>.from(entry.value as Map);
          final appId = entry.key.toString();
          final app = ApplicationModel.fromMap(appData, appId);

          if (existingJobIds.contains(app.jobId)) {
            await db
                .ref(DatabaseKeys.applications)
                .child(appId)
                .set(app.toMap());
            applicationsList.removeWhere((a) => a.id == appId);
            applicationsList.add(app);
            restoredAppsCount++;
          }
        }
      }
    }

    // 4. Drop the tombstone
    await db.ref(DatabaseKeys.deletedUsers).child(cleanId).remove();
    deletedUsersList.removeWhere((u) => u.id == cleanId);
    usersList.removeWhere((u) => u.id == cleanId);
    usersList.add(restoredUser);

    await fetchAllData();

    return UserRestoreResult(
      user: restoredUser,
      restoredJobsCount: restoredJobsCount,
      restoredApplicationsCount: restoredAppsCount,
    );
  }

  /// Removes the tombstone permanently - the account can never be restored.
  Future<void> purgeDeletedUser(String userId) async {
    final db = _db;
    if (db == null) {
      throw StateError('Firebase Realtime Database is not available.');
    }
    await db.ref(DatabaseKeys.deletedUsers).child(userId).remove();
    deletedUsersList.removeWhere((u) => u.id == userId);
  }

  /// Best-effort id of the signed-in admin, recorded on the tombstone.
  String _currentAdminId() {
    try {
      // Read from Firebase Auth directly to avoid a circular dependency on
      // AuthService (which itself depends on this service).
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Refreshes the local list of admin-removed accounts.
  Future<void> refreshDeletedUsers() async {
    deletedUsersList.assignAll(await fetchDeletedUsers());
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
      final idx = usersList.indexWhere((u) => u.id == user.id);
      if (idx != -1) {
        usersList[idx] = user;
      } else {
        usersList.add(user);
      }

      if (_db != null) {
        await _db!
            .ref(DatabaseKeys.users)
            .child(user.id)
            .set(user.toMap())
            .timeout(readTimeout, onTimeout: () {
          debugPrint('saveUserProfile: Database write timed out; saved in-memory');
        });
      }
    } catch (e) {
      debugPrint('Warning saving user profile: $e');
    }
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final snapshot = await _db
          ?.ref(DatabaseKeys.users)
          .child(userId)
          .get()
          .timeout(readTimeout);
      if (snapshot != null && snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return UserModel.fromMap(data, userId);
      }
    } catch (_) {}

    // Check in-memory list
    final inMemory = usersList.firstWhereOrNull((u) => u.id == userId);
    if (inMemory != null) return inMemory;

    return null;
  }

  Future<UserModel?> getUserProfileByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return null;

    // Check in-memory list first
    final inMemory = usersList.firstWhereOrNull(
      (u) => u.email.trim().toLowerCase() == cleanEmail,
    );
    if (inMemory != null) return inMemory;

    try {
      final snapshot = await _db
          ?.ref(DatabaseKeys.users)
          .get()
          .timeout(readTimeout);
      if (snapshot != null && snapshot.exists && snapshot.value is Map) {
        final map = snapshot.value as Map;
        for (final entry in map.entries) {
          if (entry.value is Map) {
            final data = Map<String, dynamic>.from(entry.value as Map);
            final userEmail = data['email']?.toString().trim().toLowerCase();
            if (userEmail == cleanEmail) {
              return UserModel.fromMap(data, entry.key.toString());
            }
          }
        }
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

  Future<void> softDeleteJob(JobModel job) async {
    final updated = job.copyWith(isDeleted: true, isActive: false);
    final index = jobsList.indexWhere((item) => item.id == job.id);
    if (index != -1) {
      jobsList[index] = updated;
    }

    final db = _db;
    if (db != null) {
      try {
        await db.ref(DatabaseKeys.jobs).child(job.id).update({
          'isDeleted': true,
          'isActive': false,
        });
      } catch (_) {}
    }
  }

  Future<void> restoreJob(String jobId) async {
    final index = jobsList.indexWhere((item) => item.id == jobId);
    if (index == -1) return;

    final restored = jobsList[index].copyWith(isDeleted: false, isActive: true);
    jobsList[index] = restored;

    final db = _db;
    if (db != null) {
      try {
        await db.ref(DatabaseKeys.jobs).child(jobId).update({
          'isDeleted': false,
          'isActive': true,
        });
      } catch (_) {}
    }
  }

  Future<void> deleteJob(String jobId) async {
    final job = jobsList.firstWhereOrNull((item) => item.id == jobId);
    if (job != null) {
      await softDeleteJob(job);
    } else {
      jobsList.removeWhere((item) => item.id == jobId);
      final db = _db;
      if (db != null) {
        try {
          await db.ref(DatabaseKeys.jobs).child(jobId).remove();
        } catch (_) {}
      }
    }
  }

  Future<List<JobModel>> fetchJobs() async {
    try {
      final snapshot = await _db?.ref(DatabaseKeys.jobs).get();
      if (snapshot != null && snapshot.exists && snapshot.value != null) {
        final list = _parseJobs(snapshot.value);
        jobsList.assignAll(list);
      }
    } catch (e) {
      debugPrint('fetchJobs error: $e');
    }
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

    final applicationRef =
        db.ref(DatabaseKeys.applications).child(application.id);

    // Save application directly
    await applicationRef.set(application.toMap());

    // Best-effort increment of applicant count on the job
    try {
      final jobRef = db.ref(DatabaseKeys.jobs).child(application.jobId);
      await jobRef.child('applicantCount').runTransaction((value) {
        final currentCount = (value as num?)?.toInt() ?? 0;
        return Transaction.success(currentCount + 1);
      });
    } catch (e) {
      debugPrint('Non-critical applicant count update: $e');
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

  Future<void> updateApplication(ApplicationModel application) async {
    final db = _db;
    if (db == null) {
      throw StateError('Firebase Realtime Database is not available');
    }
    await db
        .ref(DatabaseKeys.applications)
        .child(application.id)
        .update(application.toMap());
    final idx = applicationsList.indexWhere((a) => a.id == application.id);
    if (idx != -1) {
      applicationsList[idx] = application;
    } else {
      applicationsList.insert(0, application);
    }
  }

  Future<void> deleteApplication(String appId) async {
    final db = _db;
    if (db == null) {
      throw StateError('Firebase Realtime Database is not available');
    }
    final application =
        applicationsList.firstWhereOrNull((a) => a.id == appId);
    await db.ref(DatabaseKeys.applications).child(appId).remove();
    applicationsList.removeWhere((a) => a.id == appId);

    if (application != null && application.jobId.isNotEmpty) {
      final jobRef = db.ref(DatabaseKeys.jobs).child(application.jobId);
      try {
        await jobRef.child('applicantCount').runTransaction((value) {
          final currentCount = (value as num?)?.toInt() ?? 0;
          return Transaction.success(currentCount > 0 ? currentCount - 1 : 0);
        });
      } catch (_) {}
    }
  }

  // --- MENTORSHIP SERVICES & BOOKINGS ---
  List<MentorshipServiceModel> _parseServices(dynamic value) {
    final list = <MentorshipServiceModel>[];
    if (value is Map) {
      value.forEach((key, val) {
        if (val != null && val is Map) {
          try {
            final map = Map<String, dynamic>.from(val);
            list.add(MentorshipServiceModel.fromMap(map, key.toString()));
          } catch (e) {
            debugPrint('Failed to parse mentorship service $key: $e');
          }
        }
      });
    } else if (value is List) {
      for (int i = 0; i < value.length; i++) {
        final val = value[i];
        if (val != null && val is Map) {
          try {
            final map = Map<String, dynamic>.from(val);
            list.add(MentorshipServiceModel.fromMap(map, i.toString()));
          } catch (e) {
            debugPrint('Failed to parse mentorship service at index $i: $e');
          }
        }
      }
    }
    return list;
  }

  // --- MENTORSHIP SERVICES & BOOKINGS ---
  Future<void> createMentorshipService(MentorshipServiceModel service) async {
    // 1. Instantly mirror to local reactive state so UI reflects post with 0ms latency
    servicesList.removeWhere((s) => s.id == service.id);
    servicesList.insert(0, service);

    // 2. Persist directly to Firebase Realtime Database with timeout protection
    final db = _db;
    if (db != null) {
      try {
        final data = service.toMap();
        data.removeWhere((key, value) => value == null);
        await db
            .ref(DatabaseKeys.mentorshipServices)
            .child(service.id)
            .set(data)
            .timeout(readTimeout);
        debugPrint('Stored mentorship service ${service.id} in Realtime Database');
      } catch (e) {
        debugPrint('Error storing mentorship service in Realtime Database: $e');
      }
    } else {
      debugPrint('Realtime Database is null, service cached in memory');
    }
  }

  Future<List<MentorshipServiceModel>> fetchServices() async {
    try {
      final snapshot = await _db
          ?.ref(DatabaseKeys.mentorshipServices)
          .get()
          .timeout(readTimeout);
      if (snapshot != null && snapshot.exists && snapshot.value != null) {
        final list = _parseServices(snapshot.value);
        servicesList.assignAll(list);
      }
    } catch (e) {
      debugPrint('Error fetching mentorship services: $e');
    }
    return servicesList;
  }

  Future<void> deleteMentorshipService(String serviceId) async {
    servicesList.removeWhere((s) => s.id == serviceId);
    final db = _db;
    if (db != null) {
      try {
        await db
            .ref(DatabaseKeys.mentorshipServices)
            .child(serviceId)
            .remove()
            .timeout(readTimeout);
        debugPrint('Deleted service $serviceId from Realtime Database');
      } catch (e) {
        debugPrint('Error deleting service from Realtime Database: $e');
      }
    }
  }

  Future<void> updateMentorshipService(MentorshipServiceModel service) async {
    final idx = servicesList.indexWhere((s) => s.id == service.id);
    if (idx != -1) {
      servicesList[idx] = service;
    } else {
      servicesList.insert(0, service);
    }
    final db = _db;
    if (db != null) {
      try {
        final data = service.toMap();
        data.removeWhere((key, value) => value == null);
        await db
            .ref(DatabaseKeys.mentorshipServices)
            .child(service.id)
            .update(data);
      } catch (e) {
        debugPrint('Error updating service in Realtime Database: $e');
        rethrow;
      }
    }
  }

  Future<void> softDeleteMentorshipService(String serviceId) async {
    final idx = servicesList.indexWhere((s) => s.id == serviceId);
    if (idx != -1) {
      final updated =
          servicesList[idx].copyWith(isDeleted: true, isActive: false);
      servicesList[idx] = updated;
    }
    try {
      await _db
          ?.ref(DatabaseKeys.mentorshipServices)
          .child(serviceId)
          .update({
        'isDeleted': true,
        'isActive': false,
      });
    } catch (_) {}
  }

  Future<void> restoreMentorshipService(String serviceId) async {
    final idx = servicesList.indexWhere((s) => s.id == serviceId);
    if (idx != -1) {
      final updated =
          servicesList[idx].copyWith(isDeleted: false, isActive: true);
      servicesList[idx] = updated;
    }
    try {
      await _db
          ?.ref(DatabaseKeys.mentorshipServices)
          .child(serviceId)
          .update({
        'isDeleted': false,
        'isActive': true,
      });
    } catch (_) {}
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

  Future<List<BookingModel>> fetchBookings() async {
    try {
      final snapshot = await _db
          ?.ref(DatabaseKeys.bookings)
          .get()
          .timeout(readTimeout);
      if (snapshot != null && snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> map = snapshot.value as Map;
        final list = <BookingModel>[];
        map.forEach((key, value) {
          list.add(BookingModel.fromMap(
              Map<String, dynamic>.from(value), key.toString()));
        });
        list.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        bookingsList.assignAll(list);
      }
    } catch (_) {}
    return bookingsList;
  }

  Future<void> deleteBooking(String bookingId) async {
    try {
      await _db
          ?.ref(DatabaseKeys.bookings)
          .child(bookingId)
          .remove()
          .timeout(readTimeout);
    } catch (_) {}
    bookingsList.removeWhere((b) => b.id == bookingId);
  }

  Future<void> updateBookingStatus(
    String bookingId,
    String status, {
    String? mentorNotes,
    DateTime? rescheduledAt,
  }) async {
    try {
      final updates = <String, dynamic>{'status': status};
      if (mentorNotes != null) updates['mentorNotes'] = mentorNotes;
      if (rescheduledAt != null) {
        updates['scheduledAt'] = rescheduledAt.toIso8601String();
      }
      await _db?.ref(DatabaseKeys.bookings).child(bookingId).update(updates);
    } catch (_) {}
    final idx = bookingsList.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final current = bookingsList[idx];
      bookingsList[idx] = current.copyWith(
        status: status,
        mentorNotes: mentorNotes ?? current.mentorNotes,
        scheduledAt: rescheduledAt ?? current.scheduledAt,
      );
    }
  }

  Future<void> updateBooking(BookingModel booking) async {
    try {
      await _db
          ?.ref(DatabaseKeys.bookings)
          .child(booking.id)
          .update(booking.toMap());
    } catch (_) {}
    final idx = bookingsList.indexWhere((b) => b.id == booking.id);
    if (idx != -1) {
      bookingsList[idx] = booking;
    }
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

  /// The backed-up record created before deletion.
  final DeletedUserModel? deletedRecord;

  const UserDeleteResult({
    required this.removedFirestoreRecords,
    required this.email,
    this.deletedRecord,
  });
}

/// Outcome of restoring a user account and their associated content.
class UserRestoreResult {
  final UserModel user;
  final int restoredJobsCount;
  final int restoredApplicationsCount;

  const UserRestoreResult({
    required this.user,
    this.restoredJobsCount = 0,
    this.restoredApplicationsCount = 0,
  });
}
