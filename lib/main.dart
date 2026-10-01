import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_pages.dart';
import 'bindings/initial_binding.dart';
import 'controllers/theme_controller.dart';
import 'controllers/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialized in mock/fallback mode: $e');
  }

  Get.put<ThemeController>(ThemeController(), permanent: true);
  InitialBinding().dependencies();

  runApp(const JobsApp());
}

class JobsApp extends StatelessWidget {
  const JobsApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ThemeController>()) {
      Get.put(ThemeController(), permanent: true);
    }
    if (!Get.isRegistered<AuthController>()) {
      InitialBinding().dependencies();
    }

    final themeController = Get.find<ThemeController>();

    return Obx(() => GetMaterialApp(
          title: 'Jobs - Professional Networking & Hiring',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.isDarkMode.value
              ? ThemeMode.dark
              : ThemeMode.light,
          initialRoute: AppPages.initial,
          getPages: AppPages.pages,
        ));
  }
}
