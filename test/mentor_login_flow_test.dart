import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jobs/controllers/admin_controller.dart';
import 'package:jobs/controllers/auth_controller.dart';
import 'package:jobs/controllers/chat_controller.dart';
import 'package:jobs/controllers/course_controller.dart';
import 'package:jobs/controllers/home_controller.dart';
import 'package:jobs/controllers/job_controller.dart';
import 'package:jobs/controllers/mentorship_controller.dart';
import 'package:jobs/controllers/profile_controller.dart';
import 'package:jobs/core/theme/app_theme.dart';
import 'package:jobs/core/utils/constants.dart';
import 'package:jobs/models/service_model.dart';
import 'package:jobs/models/user_model.dart';
import 'package:jobs/services/auth_service.dart';
import 'package:jobs/services/database_service.dart';
import 'package:jobs/services/firestore_service.dart';
import 'package:jobs/views/home/home_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late DatabaseService dbService;
  late AuthService authService;

  setUp(() {
    Get.testMode = true;
    Get.reset();
    dbService = Get.put(DatabaseService(), permanent: true);
    Get.put(FirestoreService(), permanent: true);
    authService = Get.put(AuthService(), permanent: true);
    Get.put(AuthController(), permanent: true);
    Get.put(JobController(), permanent: true);
    Get.put(ProfileController(), permanent: true);
    Get.put(CourseController(), permanent: true);
    Get.put(ChatController(), permanent: true);
    Get.put(AdminController(), permanent: true);
    Get.put(MentorshipController(), permanent: true);
    Get.put(HomeController(), permanent: true);
  });

  tearDown(Get.reset);

  void loginAsMentor({String id = 'OmFD7tA46agfcCufJJDDHowVtSJ2'}) {
    authService.currentUser.value = UserModel(
      id: id,
      name: 'mentor',
      email: 'mentor@example.com',
      role: UserRole.mentor,
    );
  }

  /// The record exactly as it exists in the Realtime Database today.
  void seedRealtimeService() {
    dbService.servicesList.assignAll([
      MentorshipServiceModel.fromMap(
        {
          'id': 'serv_1790995911467',
          'mentorId': 'OmFD7tA46agfcCufJJDDHowVtSJ2',
          'mentorName': 'mentor',
          'mentorHeadline': 'Mentor',
          'title': 'Management consulting',
          'description': 'test generator is the settings for this',
          'price': 30,
          'durationMinutes': 30,
          'category': 'Career Advice',
          'isActive': true,
          'isDeleted': false,
          'serviceType': '1:1 Call',
          'deliverable': '30 Mins 1:1 Video Call',
          'rating': 5,
          'reviewCount': 0,
          'bookedSeats': 0,
          'includedSessions': 1,
          'topics': ['system design'],
        },
        'serv_1790995911467',
      ),
    ]);
  }

  Future<void> mountHome(WidgetTester tester) async {
    // The app theme is required: it is what makes a themed ElevatedButton
    // inside a Row receive an infinite width constraint.
    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.lightTheme, home: const HomeView()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('mentor session renders the mentor tabs without exceptions',
      (tester) async {
    loginAsMentor();
    seedRealtimeService();
    await mountHome(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Storefront'), findsWidgets);
    expect(find.text('Services'), findsWidgets);
    expect(find.text('Bookings'), findsWidgets);
    expect(find.text('Earnings'), findsWidgets);
  });

  testWidgets('every mentor tab builds without exceptions', (tester) async {
    loginAsMentor();
    seedRealtimeService();
    await mountHome(tester);

    for (final label in ['Storefront', 'Services', 'Bookings', 'Earnings']) {
      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: 'tab "$label" threw');
    }
  });

  testWidgets('storefront lists the service stored in the realtime database',
      (tester) async {
    loginAsMentor();
    seedRealtimeService();
    await mountHome(tester);

    expect(find.text('Management consulting'), findsWidgets);
  });

  testWidgets('services tab lists the service owned by the auth uid',
      (tester) async {
    loginAsMentor();
    seedRealtimeService();
    await mountHome(tester);

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Services'),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('Management consulting'), findsOneWidget);
  });

  testWidgets('services tab lists the service when only the auth uid matches',
      (tester) async {
    // Profile id drifted away from the Firebase Auth uid that owns the record.
    loginAsMentor(id: 'user_1790900000000');
    seedRealtimeService();
    await mountHome(tester);

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Services'),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Management consulting'), findsOneWidget);
  });

  group('mentor login transition', () {
    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('guest to mentor switches the tabs without exceptions',
        (tester) async {
      // Guest session: only Jobs + Mentors.
      await tester.pumpWidget(GetMaterialApp(theme: AppTheme.lightTheme, home: const HomeView()));
      await tester.pump();
      expect(find.byType(NavigationBar), findsOneWidget);

      seedRealtimeService();
      loginAsMentor();
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Storefront'), findsWidgets);
      expect(find.text('Earnings'), findsWidgets);
      expect(find.text('Management consulting'), findsWidgets);
    });

    testWidgets('candidate to mentor keeps navigation usable', (tester) async {
      authService.currentUser.value = UserModel(
        id: 'c1',
        name: 'Ada',
        email: 'ada@example.com',
        role: UserRole.candidate,
      );
      seedRealtimeService();
      await mountHome(tester);

      // Move to the candidate profile tab (index 2) before the role changes.
      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profile'),
      ));
      await tester.pump();

      loginAsMentor();
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsOneWidget);

      // The bottom navigation must still respond.
      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Bookings'),
      ));
      await settle(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mentor logout and login again stays stable', (tester) async {
      loginAsMentor();
      seedRealtimeService();
      await mountHome(tester);

      authService.currentUser.value = null;
      await settle(tester);
      expect(tester.takeException(), isNull);

      loginAsMentor();
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Storefront'), findsWidgets);
    });

    testWidgets('services arriving after login still render', (tester) async {
      loginAsMentor();
      await mountHome(tester);
      expect(find.text('Management consulting'), findsNothing);

      // Realtime Database pushes the record after the mentor screen is built.
      seedRealtimeService();
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Management consulting'), findsWidgets);
    });

    testWidgets('profile arriving after the services still render',
        (tester) async {
      seedRealtimeService();
      await mountHome(tester);

      loginAsMentor();
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Management consulting'), findsWidgets);
    });
  });

  group('mentor screen for visitors', () {
    Future<void> openMentorsTab(WidgetTester tester) async {
      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Mentors'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('logged out visitors see mentor services', (tester) async {
      seedRealtimeService();
      await mountHome(tester);

      expect(find.text('Mentors'), findsOneWidget);
      await openMentorsTab(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Management consulting'), findsWidgets);
    });

    testWidgets('candidates see every mentor service', (tester) async {
      authService.currentUser.value = UserModel(
        id: 'c1',
        name: 'Ada',
        email: 'ada@example.com',
        role: UserRole.candidate,
      );
      seedRealtimeService();
      await mountHome(tester);

      await openMentorsTab(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Management consulting'), findsWidgets);
    });

    testWidgets('visitors do not see soft deleted services', (tester) async {
      seedRealtimeService();
      dbService.servicesList[0] =
          dbService.servicesList[0].copyWith(isDeleted: true, isActive: false);
      await mountHome(tester);

      await openMentorsTab(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Management consulting'), findsNothing);
    });
  });
}
