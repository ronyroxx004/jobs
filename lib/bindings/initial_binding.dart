import 'package:get/get.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/app_status_service.dart';
import '../services/account_admin_service.dart';
import '../services/notification_service.dart';
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
    Get.put<NotificationService>(NotificationService(), permanent: true);
    Get.put<AppStatusService>(AppStatusService(), permanent: true);
    Get.put<ThemeController>(ThemeController(), permanent: true);
    Get.put<AccountAdminService>(AccountAdminService(), permanent: true);

    // Controllers
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<HomeController>(HomeController(), permanent: true);
    Get.put<JobController>(JobController(), permanent: true);
    Get.put<ProfileController>(ProfileController(), permanent: true);

    // Remaining screen controllers can stay lazy if they are only used inside a specific flow.
    Get.lazyPut<MentorshipController>(() => MentorshipController(), fenix: true);
    Get.lazyPut<CourseController>(() => CourseController(), fenix: true);
    Get.lazyPut<ChatController>(() => ChatController(), fenix: true);
    Get.lazyPut<AdminController>(() => AdminController(), fenix: true);
  }
}
