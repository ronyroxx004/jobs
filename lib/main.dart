import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_pages.dart';
import 'bindings/initial_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialized in mock/fallback mode: $e');
  }

  runApp(const JobsApp());
}

SystemUiOverlayStyle _systemUiOverlayStyle(bool isDark) {
  final background = isDark ? const Color(0xFF0F172A) : Colors.white;
  final iconBrightness = isDark ? Brightness.light : Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: background,
    statusBarIconBrightness: iconBrightness,
    statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: background,
    systemNavigationBarIconBrightness: iconBrightness,
  );
}

class JobsApp extends StatefulWidget {
  const JobsApp({super.key});

  @override
  State<JobsApp> createState() => _JobsAppState();
}

class _JobsAppState extends State<JobsApp> {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Jobs - Professional Networking & Hiring',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _systemUiOverlayStyle(isDark),
          child: SafeArea(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
