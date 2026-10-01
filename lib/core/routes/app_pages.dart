import 'package:get/get.dart';
import '../../models/job_model.dart';
import 'app_routes.dart';
import '../../views/splash/splash_view.dart';
import '../../views/auth/login_view.dart';
import '../../views/auth/register_view.dart';
import '../../views/home/home_view.dart';
import '../../views/jobs/job_detail_view.dart';
import '../../views/jobs/post_job_view.dart';
import '../../views/recruiter/recruiter_job_applicants_view.dart';
import '../../views/courses/post_course_view.dart';
import '../../views/profile/edit_profile_view.dart';
import '../../views/profile/resume_manager_view.dart';
import '../../views/candidate_activity_view.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
    ),
    GetPage(
      name: AppRoutes.jobDetails,
      page: () => const JobDetailView(),
    ),
    GetPage(
      name: AppRoutes.recruiterApplicants,
      page: () => RecruiterJobApplicantsView(
        job: Get.arguments as JobModel,
      ),
    ),
    GetPage(
      name: AppRoutes.postJob,
      page: () => const PostJobView(),
    ),
    GetPage(
      name: AppRoutes.postCourse,
      page: () => const PostCourseView(),
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfileView(),
    ),
    GetPage(
      name: AppRoutes.resumeManager,
      page: () => const ResumeManagerView(),
    ),
    GetPage(
      name: AppRoutes.candidateActivity,
      page: () {
        final arguments = Get.arguments is Map<String, dynamic>
            ? Get.arguments as Map<String, dynamic>
            : const <String, dynamic>{};
        final initialTab = arguments['tab'] as String? ?? 'applications';
        return CandidateActivityView(initialTab: initialTab);
      },
    ),
  ];
}
