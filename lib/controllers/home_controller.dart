import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../core/utils/constants.dart';

class HomeController extends GetxController {
  final RxInt currentIndex = 0.obs;

  final AuthService _authService = Get.find<AuthService>();
  final DatabaseService _dbService = Get.find<DatabaseService>();

  bool get isLoggedIn => _authService.isLoggedIn;
  UserRole get currentRole => _authService.currentRole;
  String get userName => _authService.currentUser.value?.name ?? 'User';

  int get totalJobsCount => _dbService.jobsList.length;
  int get myApplicationsCount => _dbService.applicationsList.length;
  int get availableMentorsCount => _dbService.servicesList.length;
  int get activeCoursesCount => _dbService.coursesList.length;

  void changeTab(int index) {
    currentIndex.value = index;
  }
}
