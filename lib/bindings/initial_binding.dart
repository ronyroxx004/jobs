import 'package:get/get.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/job_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/mentorship_controller.dart';
import '../controllers/course_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/admin_controller.dart';
import '../controllers/theme_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.put<DatabaseService>(DatabaseService(), permanent: true);
    Get.put<FirestoreService>(FirestoreService(), permanent: true);
    Get.put<AuthService>(AuthService(), permanent: true);

    // Controllers
    Get.put<ThemeController>(ThemeController(), permanent: true);
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<JobController>(() => JobController(), fenix: true);
    Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
    Get.lazyPut<MentorshipController>(() => MentorshipController(), fenix: true);
    Get.lazyPut<CourseController>(() => CourseController(), fenix: true);
    Get.lazyPut<ChatController>(() => ChatController(), fenix: true);
    Get.lazyPut<AdminController>(() => AdminController(), fenix: true);
  }
}
