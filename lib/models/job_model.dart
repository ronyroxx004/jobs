class JobModel {
  final String id;
  final String title;
  final String companyName;
  final String companyLogo;
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
  final DateTime postedAt;

  JobModel({
    required this.id,
    required this.title,
    required this.companyName,
    this.companyLogo = '',
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
    DateTime? postedAt,
  }) : postedAt = postedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'companyName': companyName,
      'companyLogo': companyLogo,
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
      'postedAt': postedAt.toIso8601String(),
    };
  }

  factory JobModel.fromMap(Map<String, dynamic> map, String docId) {
    return JobModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      title: map['title'] ?? '',
      companyName: map['companyName'] ?? '',
      companyLogo: map['companyLogo'] ?? '',
      location: map['location'] ?? '',
      jobType: map['jobType'] ?? 'Full-time',
      experienceLevel: map['experienceLevel'] ?? 'Mid',
      salaryRange: map['salaryRange'] ?? '\$80k - \$110k',
      description: map['description'] ?? '',
      requirements: List<String>.from(map['requirements'] ?? []),
      skills: List<String>.from(map['skills'] ?? []),
      recruiterId: map['recruiterId'] ?? '',
      recruiterName: map['recruiterName'] ?? 'Recruiter',
      applicantCount: map['applicantCount'] ?? 0,
      isFeatured: map['isFeatured'] ?? false,
      isActive: map['isActive'] ?? true,
      postedAt: map['postedAt'] != null
          ? DateTime.tryParse(map['postedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
