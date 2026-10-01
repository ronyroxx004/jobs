import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/constants.dart';

class ThemeController extends GetxController {
  final RxBool isDarkMode = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadThemeFromPrefs();
  }

  void loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_mode') ?? true;
    isDarkMode.value = isDark;
    updateSystemOverlay(isDark);
  }

  void toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    final isDark = isDarkMode.value;
    updateSystemOverlay(isDark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
  }

  void updateSystemOverlay(bool isDark) {
    final background = isDark ? AppColors.bgDark : AppColors.bgLight;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: background,
        systemNavigationBarIconBrightness: iconBrightness,
      ),
    );
  }
}
