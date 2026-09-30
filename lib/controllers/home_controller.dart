import 'package:get/get.dart';
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
    _authWorker = ever(_authService.currentUser, (_) {
      if (_wasLoggedIn != isLoggedIn || _lastRole != currentRole) {
        currentIndex.value = 0;
        _wasLoggedIn = isLoggedIn;
        _lastRole = currentRole;
      }
    });
  }

  bool get isLoggedIn => _authService.isLoggedIn;
  UserRole get currentRole => _authService.currentRole;
  int get pageCount {
    if (!isLoggedIn) {
      return 3;
    }
    if (currentRole == UserRole.candidate) {
      return 4;
    }
    if (currentRole == UserRole.admin) {
      return 5;
    }
    return 2;
  }

  int get selectedTabIndex => currentIndex.value.clamp(0, pageCount - 1);
  String get userName => _authService.currentUser.value?.name ?? 'User';

  int get totalJobsCount => _dbService.jobsList.length;
  int get myApplicationsCount => _dbService.applicationsList.length;
  int get availableMentorsCount => _dbService.servicesList.length;
  int get activeCoursesCount => _dbService.coursesList.length;

  void changeTab(int index) {
    currentIndex.value = index.clamp(0, pageCount - 1);
  }

  @override
  void onClose() {
    _authWorker.dispose();
    super.onClose();
  }
}
