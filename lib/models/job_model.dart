class JobModel {
  final String id;
  final String title;
  final String companyName;
  final String companyLogo;
  final String companyIconKey;
  final String location;
  final String jobType; // Full-time, Part-time, Contract, Remote, Internship
  final String experienceLevel; // Entry, Mid, Senior, Executive
  final String salaryRange;
  final String description;
  final List<String> requirements;
  final List<String> skills;
  final String recruiterId;
  final String recruiterName;
  final int applicantCount;
  final bool isFeatured;
  final bool isActive;
  final bool isDeleted;
  final DateTime postedAt;

  JobModel({
    required this.id,
    required this.title,
    required this.companyName,
    this.companyLogo = '',
    this.companyIconKey = '',
    required this.location,
    required this.jobType,
    required this.experienceLevel,
    required this.salaryRange,
    required this.description,
    required this.requirements,
    required this.skills,
    required this.recruiterId,
    required this.recruiterName,
    this.applicantCount = 0,
    this.isFeatured = false,
    this.isActive = true,
    this.isDeleted = false,
    DateTime? postedAt,
  }) : postedAt = postedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'companyName': companyName,
      'companyLogo': companyLogo,
      'companyIconKey': companyIconKey,
      'location': location,
      'jobType': jobType,
      'experienceLevel': experienceLevel,
      'salaryRange': salaryRange,
      'description': description,
      'requirements': requirements,
      'skills': skills,
      'recruiterId': recruiterId,
      'recruiterName': recruiterName,
      'applicantCount': applicantCount,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'postedAt': postedAt.toIso8601String(),
    };
  }

  static bool _parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final s = value.trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    return defaultValue;
  }

  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (value is Map) {
      return value.values
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return [];
  }

  factory JobModel.fromMap(Map<String, dynamic> map, String docId) {
    return JobModel(
      id: docId.isNotEmpty ? docId : (map['id']?.toString() ?? ''),
      title: map['title']?.toString() ?? '',
      companyName: map['companyName']?.toString() ?? '',
      companyLogo: map['companyLogo']?.toString() ?? '',
      companyIconKey: map['companyIconKey']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      jobType: map['jobType']?.toString() ?? 'Full-time',
      experienceLevel: map['experienceLevel']?.toString() ?? 'Mid',
      salaryRange: map['salaryRange']?.toString() ?? '\$80k - \$110k',
      description: map['description']?.toString() ?? '',
      requirements: _parseStringList(map['requirements']),
      skills: _parseStringList(map['skills']),
      recruiterId: map['recruiterId']?.toString() ?? '',
      recruiterName: map['recruiterName']?.toString() ?? 'Recruiter',
      applicantCount: _parseInt(map['applicantCount'], defaultValue: 0),
      isFeatured: _parseBool(map['isFeatured'], defaultValue: false),
      isActive: _parseBool(map['isActive'], defaultValue: true),
      isDeleted: _parseBool(map['isDeleted'], defaultValue: false),
      postedAt: map['postedAt'] != null
          ? DateTime.tryParse(map['postedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  JobModel copyWith({
    String? id,
    String? title,
    String? companyName,
    String? companyLogo,
    String? companyIconKey,
    String? location,
    String? jobType,
    String? experienceLevel,
    String? salaryRange,
    String? description,
    List<String>? requirements,
    List<String>? skills,
    String? recruiterId,
    String? recruiterName,
    int? applicantCount,
    bool? isFeatured,
    bool? isActive,
    bool? isDeleted,
    DateTime? postedAt,
  }) {
    return JobModel(
      id: id ?? this.id,
      title: title ?? this.title,
      companyName: companyName ?? this.companyName,
      companyLogo: companyLogo ?? this.companyLogo,
      companyIconKey: companyIconKey ?? this.companyIconKey,
      location: location ?? this.location,
      jobType: jobType ?? this.jobType,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      salaryRange: salaryRange ?? this.salaryRange,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      skills: skills ?? this.skills,
      recruiterId: recruiterId ?? this.recruiterId,
      recruiterName: recruiterName ?? this.recruiterName,
      applicantCount: applicantCount ?? this.applicantCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      postedAt: postedAt ?? this.postedAt,
    );
  }
}
