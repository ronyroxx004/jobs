import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../core/utils/constants.dart';

class HomeController extends GetxController {
  final RxInt currentIndex = 0.obs;

  final AuthService _authService = Get.find<AuthService>();
  final DatabaseService _dbService = Get.find<DatabaseService>();
  late final Worker _authWorker;
  late bool _wasLoggedIn;
  late UserRole _lastRole;

  @override
  void onInit() {
    super.onInit();
    _wasLoggedIn = isLoggedIn;
    _lastRole = currentRole;
    _authWorker = ever<UserModel?>(_authService.currentUser, (_) {
      final roleChanged = _wasLoggedIn != isLoggedIn || _lastRole != currentRole;
      if (!roleChanged) return;
      _wasLoggedIn = isLoggedIn;
      _lastRole = currentRole;
      // Deferred: writing an observable while another observable is notifying
      // its listeners rebuilds the home tabs mid-notification and leaves the
      // scaffold half-built, which shows up as a blank, unresponsive screen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isClosed) return;
        currentIndex.value = 0;
      });
    });
  }

  bool get isLoggedIn => _authService.isLoggedIn;
  UserRole get currentRole => _authService.currentRole;
  int get pageCount {
    if (!isLoggedIn) return 2;
    switch (currentRole) {
      case UserRole.mentor:
        return 5;
      case UserRole.admin:
        return 4;
      case UserRole.candidate:
        return 3;
      case UserRole.recruiter:
      case UserRole.instructor:
        return 2;
    }
  }

  int get selectedTabIndex => currentIndex.value;
  String get userName => _authService.currentUser.value?.name ?? 'User';

  int get totalJobsCount => _dbService.jobsList.where((j) => j.isActive).length;
  int get myApplicationsCount => _dbService.applicationsList.length;
  int get availableMentorsCount => _dbService.servicesList.length;
  int get activeCoursesCount => _dbService.coursesList.length;

  void changeTab(int index) {
    if (index >= 0 && index < pageCount) {
      currentIndex.value = index;
    }
  }

  @override
  void onClose() {
    _authWorker.dispose();
    super.onClose();
  }
}
