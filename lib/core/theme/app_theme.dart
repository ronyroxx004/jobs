import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class AppTheme {
  static final ThemeData lightTheme = _buildTheme(isDark: false);
  static final ThemeData darkTheme = _buildTheme(isDark: true);

  static ThemeData _buildTheme({required bool isDark}) {
    final background = isDark ? AppColors.bgDark : AppColors.bgLight;
    final surface = isDark ? AppColors.cardDark : AppColors.cardLight;
    final foreground =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final muted =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final brand = isDark ? AppColors.primaryLight : AppColors.primary;
    final inputFill =
        isDark ? const Color(0xFF101A2B) : const Color(0xFFFAFBFE);
    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: brand,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        tertiary: AppColors.accent,
        onTertiary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: surface,
        onSurface: foreground,
        surfaceContainerLowest: background,
        surfaceContainerLow: inputFill,
        outline: border,
        outlineVariant: border,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: background,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: foreground,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 0 : 1,
        shadowColor: const Color(0x1A202C50),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: foreground,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: foreground,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: foreground,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: muted,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: brand.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brand,
          side: BorderSide(color: brand.withValues(alpha: 0.35)),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: IconThemeData(color: muted),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppColors.primaryLight.withValues(alpha: 0.12)
            : AppColors.primary.withValues(alpha: 0.08),
        selectedColor: brand.withValues(alpha: 0.16),
        side: BorderSide(color: brand.withValues(alpha: 0.16)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: GoogleFonts.inter(
          color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: surface,
        indicatorColor: brand.withValues(alpha: isDark ? 0.22 : 0.12),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        hintStyle: GoogleFonts.inter(color: muted, fontSize: 13),
        labelStyle: GoogleFonts.inter(color: muted, fontSize: 13),
        prefixIconColor: muted,
        suffixIconColor: muted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: brand, width: 1.6),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? const Color(0xFF26344B) : const Color(0xFF172033),
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: brand,
        linearTrackColor: brand.withValues(alpha: 0.15),
      ),
    );
  }
}