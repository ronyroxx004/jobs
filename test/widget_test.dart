import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jobs/controllers/admin_controller.dart';
import 'package:jobs/core/utils/constants.dart';
import 'package:jobs/models/course_model.dart';
import 'package:jobs/models/job_model.dart';
import 'package:jobs/models/service_model.dart';
import 'package:jobs/models/user_model.dart';
import 'package:jobs/models/deleted_user_model.dart';
import 'package:jobs/services/auth_service.dart';
import 'package:jobs/services/database_service.dart';
import 'package:jobs/services/firestore_service.dart';
import 'package:jobs/views/admin/admin_candidates_view.dart';
import 'package:jobs/views/admin/admin_instructors_view.dart';
import 'package:jobs/views/admin/admin_mentors_view.dart';
import 'package:jobs/views/admin/admin_recruiters_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService dbService;

  setUp(() {
    Get.testMode = true;
    Get.reset();
    dbService = Get.put(DatabaseService(), permanent: true);
    Get.put(FirestoreService(), permanent: true);
    Get.put(AuthService(), permanent: true);
    Get.put(AdminController(), permanent: true);
  });

  tearDown(Get.reset);

  void seed() {
    dbService.usersList.assignAll([
      UserModel(
        id: 'c1',
        name: 'Ada Candidate',
        email: 'ada@example.com',
        role: UserRole.candidate,
        headline: 'Frontend Engineer',
        skills: ['Flutter', 'Dart'],
        experienceYears: 4,
        isVerified: true,
      ),
      UserModel(
        id: 'r1',
        name: 'Rex Recruiter',
        email: 'rex@example.com',
        role: UserRole.recruiter,
        companyName: 'Acme Corp',
      ),
      UserModel(
        id: 'm1',
        name: 'Mia Mentor',
        email: 'mia@example.com',
        role: UserRole.mentor,
        headline: 'Career Coach',
        rating: 4.9,
        totalReviews: 12,
      ),
      UserModel(
        id: 'i1',
        name: 'Ian Instructor',
        email: 'ian@example.com',
        role: UserRole.instructor,
        headline: 'Data Science Educator',
      ),
    ]);

    dbService.servicesList.assignAll([
      MentorshipServiceModel(
        id: 's1',
        mentorId: 'm1',
        mentorName: 'Mia Mentor',
        title: 'Resume Review',
        description: 'A focused resume review session.',
        price: 29.99,
        durationMinutes: 45,
        category: 'Resume Review',
      ),
    ]);

    dbService.coursesList.assignAll([
      CourseModel(
        id: 'crs1',
        title: 'Dart Fundamentals',
        instructorName: 'Ian Instructor',
        thumbnail: '',
        description: 'Learn Dart from scratch.',
        price: 49,
        category: 'Programming',
        lessons: const [],
      ),
    ]);
  }

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(
      GetMaterialApp(home: Scaffold(body: screen)),
    );
    await tester.pump();
  }

  testWidgets('Admin candidates screen renders candidates', (tester) async {
    seed();
    await pumpScreen(tester, const AdminCandidatesView());

    expect(find.text('Talent Pipeline'), findsOneWidget);
    expect(find.text('Ada Candidate'), findsOneWidget);
    expect(find.text('Rex Recruiter'), findsNothing);
  });

  testWidgets('Admin candidates search filters the grid', (tester) async {
    seed();
    await pumpScreen(tester, const AdminCandidatesView());

    await tester.enterText(find.byType(TextField).first, 'zzz-no-match');
    await tester.pump();

    expect(find.text('Ada Candidate'), findsNothing);
    expect(find.text('No candidates found'), findsOneWidget);
  });

  testWidgets('Admin recruiters screen renders recruiters only', (tester) async {
    seed();
    await pumpScreen(tester, const AdminRecruitersView());

    expect(find.text('Hiring Partners'), findsOneWidget);
    expect(find.text('Rex Recruiter'), findsOneWidget);
    expect(find.text('Ada Candidate'), findsNothing);
  });

  testWidgets('Admin mentors screen renders mentor services', (tester) async {
    seed();
    await pumpScreen(tester, const AdminMentorsView());

    expect(find.text('Mentorship Management'), findsOneWidget);
    expect(find.text('Mia Mentor'), findsOneWidget);
    expect(find.text('Resume Review'), findsOneWidget);
  });

  testWidgets('Admin instructors screen renders instructor courses',
      (tester) async {
    seed();
    await pumpScreen(tester, const AdminInstructorsView());

    expect(find.text('Course Academy'), findsOneWidget);
    expect(find.text('Ian Instructor'), findsOneWidget);
    expect(find.text('Dart Fundamentals'), findsOneWidget);
  });

  testWidgets('Each admin role screen shows its own heading, not a shared one',
      (tester) async {
    seed();

    await pumpScreen(tester, const AdminCandidatesView());
    expect(find.text('Talent Pipeline'), findsOneWidget);
    expect(find.text('Hiring Partners'), findsNothing);
    expect(find.text('Course Academy'), findsNothing);
  });

  testWidgets('Candidates filter chips reactively re-filter the grid',
      (tester) async {
    seed();
    await pumpScreen(tester, const AdminCandidatesView());

    expect(find.text('Ada Candidate'), findsOneWidget);

    // "Deleted Candidates" -> shows deleted candidates view (initially empty)
    await tester.tap(find.widgetWithText(ChoiceChip, 'Deleted Candidates'));
    await tester.pumpAndSettle();
    expect(find.text('Ada Candidate'), findsNothing);
    expect(find.text('No deleted candidates'), findsOneWidget);

    // Switch back to "All"
    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    expect(find.text('Ada Candidate'), findsOneWidget);
  });

  testWidgets('Recruiter row expands to reveal job postings', (tester) async {
    seed();
    dbService.jobsList.assignAll([
      JobModel(
        id: 'j1',
        title: 'Senior Flutter Dev',
        companyName: 'Acme Corp',
        location: 'Remote',
        jobType: 'Full-time',
        experienceLevel: 'Senior',
        salaryRange: '\$100k',
        description: 'Build great apps.',
        requirements: const [],
        skills: const [],
        recruiterId: 'r1',
        recruiterName: 'Rex Recruiter',
      ),
    ]);

    await pumpScreen(tester, const AdminRecruitersView());
    expect(find.text('Senior Flutter Dev'), findsNothing);

    await tester.tap(find.text('Rex Recruiter'));
    await tester.pumpAndSettle();
    expect(find.text('Senior Flutter Dev'), findsOneWidget);
  });

  testWidgets('Mentor screen shows empty state when list is empty',
      (tester) async {
    dbService.usersList.assignAll([]);
    await pumpScreen(tester, const AdminMentorsView());

    expect(find.text('No mentors found'), findsOneWidget);
  });

  group('admin user deletion', () {
    // Mounted with a GetMaterialApp so GetX snackbars have an overlay.
    Future<void> mountApp(WidgetTester tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
      await tester.pump();
    }

    /// Dismisses any snackbar so its timer/animation does not outlive the test.
    Future<void> settleSnackbars(WidgetTester tester) async {
      Get.closeAllSnackbars();
      await tester.pumpAndSettle();
    }

    testWidgets('reports failure instead of throwing when DB is unavailable',
        (tester) async {
      await mountApp(tester);
      seed();
      final controller = Get.find<AdminController>();

      // No Firebase app in tests -> _db is null -> deleteUserCascade throws.
      // deleteUser must absorb it and return false rather than propagate.
      final ok = await controller.deleteUser('c1', 'Ada Candidate');
      await settleSnackbars(tester);

      expect(ok, isFalse);
      expect(dbService.usersList.any((u) => u.id == 'c1'), isTrue,
          reason: 'user must remain listed when the delete failed');
    });

    testWidgets('refuses to delete the signed-in admin account',
        (tester) async {
      await mountApp(tester);
      final authService = Get.find<AuthService>();
      authService.currentUser.value = UserModel(
        id: 'admin1',
        name: 'Admin',
        email: 'admin@gmail.com',
        role: UserRole.admin,
      );

      final controller = Get.find<AdminController>();
      final ok = await controller.deleteUser('admin1', 'Admin');
      await settleSnackbars(tester);

      expect(ok, isFalse);
    });
  });

  test('isUserDeleted is false when no tombstone exists', () async {
    final db = Get.find<DatabaseService>();
    expect(await db.isUserDeleted('c1'), isFalse);
  });

  group('deleted users restore', () {
    testWidgets('restore reports failure instead of throwing', (tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
      await tester.pump();
      seed();
      final controller = Get.find<AdminController>();

      // Simulate a tombstone left by a previous admin deletion.
      dbService.deletedUsersList.assignAll([
        DeletedUserModel(
          id: 'c1',
          name: 'Ada Candidate',
          email: 'ada@example.com',
          role: 'candidate',
          deletedAt: _testDate,
        ),
      ]);
      expect(controller.deletedUsers.length, 1);

      // Without Firebase we cannot write, so restore must report failure
      // rather than pretending it worked or throwing.
      final ok = await controller.restoreUser(controller.deletedUsers.first);
      Get.closeAllSnackbars();
      await tester.pumpAndSettle();

      expect(ok, isFalse);
      expect(controller.deletedUsers.length, 1,
          reason: 'record must remain when the restore failed');
    });

    test('deletedUsers exposes tombstones newest first', () {
      final older = DeletedUserModel(
        id: 'a',
        email: 'a@x.com',
        deletedAt: DateTime(2024, 1, 1),
      );
      final newer = DeletedUserModel(
        id: 'b',
        email: 'b@x.com',
        deletedAt: DateTime(2024, 6, 1),
      );
      final list = <DeletedUserModel>[older, newer]..sort(
          (x, y) => y.deletedAt.compareTo(x.deletedAt));

      expect(list.first.id, 'b');
    });

    test('tombstone round-trips through a map', () {
      final model = DeletedUserModel(
        id: 'u1',
        name: 'Rex Recruiter',
        email: 'rex@example.com',
        role: 'recruiter',
        deletedAt: _testDate,
      );
      final restored =
          DeletedUserModel.fromMap(model.toMap(), 'u1');

      expect(restored.id, 'u1');
      expect(restored.email, 'rex@example.com');
      expect(restored.role, 'recruiter');
      expect(restored.name, 'Rex Recruiter');
    });
  });
}

final _testDate = DateTime.utc(2024, 5, 5, 12);
