import '../core/utils/constants.dart';

class ApplicationModel {
  final String id;
  final String jobId;
  final String jobTitle;
  final String companyName;
  final String candidateId;
  final String candidateName;
  final String candidateEmail;
  final String candidatePhone;
  final String candidateHeadline;
  final String candidateBio;
  final String candidateLocation;
  final int candidateExperienceYears;
  final List<String> candidateSkills;
  final String candidateAvatar;
  final String resumeUrl;
  final String resumeName;
  final String coverLetter;
  final ApplicationStatus status;
  final DateTime appliedAt;

  ApplicationModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    required this.candidateId,
    required this.candidateName,
    required this.candidateEmail,
    this.candidatePhone = '',
    this.candidateHeadline = '',
    this.candidateBio = '',
    this.candidateLocation = '',
    this.candidateExperienceYears = 0,
    this.candidateSkills = const [],
    this.candidateAvatar = '',
    required this.resumeUrl,
    this.resumeName = 'Resume.pdf',
    this.coverLetter = '',
    this.status = ApplicationStatus.applied,
    DateTime? appliedAt,
  }) : appliedAt = appliedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'companyName': companyName,
      'candidateId': candidateId,
      'candidateName': candidateName,
      'candidateEmail': candidateEmail,
      'candidatePhone': candidatePhone,
      'candidateHeadline': candidateHeadline,
      'candidateBio': candidateBio,
      'candidateLocation': candidateLocation,
      'candidateExperienceYears': candidateExperienceYears,
      'candidateSkills': candidateSkills,
      'candidateAvatar': candidateAvatar,
      'resumeUrl': resumeUrl,
      'resumeName': resumeName,
      'coverLetter': coverLetter,
      'status': status.name,
      'appliedAt': appliedAt.toIso8601String(),
    };
  }

  factory ApplicationModel.fromMap(Map<String, dynamic> map, String docId) {
    return ApplicationModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      jobId: map['jobId'] ?? '',
      jobTitle: map['jobTitle'] ?? '',
      companyName: map['companyName'] ?? '',
      candidateId: map['candidateId'] ?? '',
      candidateName: map['candidateName'] ?? '',
      candidateEmail: map['candidateEmail'] ?? '',
      candidatePhone: map['candidatePhone'] ?? '',
      candidateHeadline: map['candidateHeadline'] ?? '',
      candidateBio: map['candidateBio'] ?? '',
      candidateLocation: map['candidateLocation'] ?? '',
      candidateExperienceYears: map['candidateExperienceYears'] ?? 0,
      candidateSkills: List<String>.from(map['candidateSkills'] ?? []),
      candidateAvatar: map['candidateAvatar'] ?? '',
      resumeUrl: map['resumeUrl'] ?? '',
      resumeName: map['resumeName'] ?? 'Resume.pdf',
      coverLetter: map['coverLetter'] ?? '',
      status: ApplicationStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => ApplicationStatus.applied,
      ),
      appliedAt: map['appliedAt'] != null
          ? DateTime.tryParse(map['appliedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ApplicationModel copyWith({
    String? id,
    String? jobId,
    String? jobTitle,
    String? companyName,
    String? candidateId,
    String? candidateName,
    String? candidateEmail,
    String? candidatePhone,
    String? candidateHeadline,
    String? candidateBio,
    String? candidateLocation,
    int? candidateExperienceYears,
    List<String>? candidateSkills,
    String? candidateAvatar,
    String? resumeUrl,
    String? resumeName,
    String? coverLetter,
    ApplicationStatus? status,
    DateTime? appliedAt,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
      candidateId: candidateId ?? this.candidateId,
      candidateName: candidateName ?? this.candidateName,
      candidateEmail: candidateEmail ?? this.candidateEmail,
      candidatePhone: candidatePhone ?? this.candidatePhone,
      candidateHeadline: candidateHeadline ?? this.candidateHeadline,
      candidateBio: candidateBio ?? this.candidateBio,
      candidateLocation: candidateLocation ?? this.candidateLocation,
      candidateExperienceYears:
          candidateExperienceYears ?? this.candidateExperienceYears,
      candidateSkills: candidateSkills ?? this.candidateSkills,
      candidateAvatar: candidateAvatar ?? this.candidateAvatar,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      resumeName: resumeName ?? this.resumeName,
      coverLetter: coverLetter ?? this.coverLetter,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
    );
  }
}
