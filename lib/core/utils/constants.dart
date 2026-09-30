import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF60A5FA);

  // Secondary & Accents
  static const Color secondary = Color(0xFF10B981); // Emerald Green
  static const Color accent = Color(0xFF8B5CF6); // Violet / Purple
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red

  // Backgrounds
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bgDark = Color(0xFF0F172A);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Borders & Dividers
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);
}

enum UserRole {
  candidate,
  recruiter,
  mentor,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.candidate:
        return 'Candidate';
      case UserRole.recruiter:
        return 'Recruiter';
      case UserRole.mentor:
        return 'Mentor';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

enum ApplicationStatus {
  applied,
  shortlisted,
  interviewing,
  offered,
  rejected;

  String get label {
    switch (this) {
      case ApplicationStatus.applied:
        return 'Applied';
      case ApplicationStatus.shortlisted:
        return 'Shortlisted';
      case ApplicationStatus.interviewing:
        return 'Interview Scheduled';
      case ApplicationStatus.offered:
        return 'Job Offered';
      case ApplicationStatus.rejected:
        return 'Not Selected';
    }
  }

  Color get color {
    switch (this) {
      case ApplicationStatus.applied:
        return const Color(0xFF3B82F6);
      case ApplicationStatus.shortlisted:
        return const Color(0xFF8B5CF6);
      case ApplicationStatus.interviewing:
        return const Color(0xFFF59E0B);
      case ApplicationStatus.offered:
        return const Color(0xFF10B981);
      case ApplicationStatus.rejected:
        return const Color(0xFFEF4444);
    }
  }
}

class DatabaseKeys {
  static const String users = 'users';
  static const String jobs = 'jobs';
  static const String resumes = 'resumes';
  static const String applications = 'applications';
  static const String mentorshipServices = 'mentorship_services';
  static const String bookings = 'bookings';
  static const String courses = 'courses';
  static const String enrollments = 'enrollments';
  static const String chats = 'chats';
  static const String messages = 'messages';

  // Firestore collections for images and media
  static const String userImages = 'user_images';
  static const String companyLogos = 'company_logos';
  static const String courseThumbnails = 'course_thumbnails';
  static const String portfolioImages = 'portfolio_images';
}
