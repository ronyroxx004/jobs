import '../core/utils/constants.dart';
import 'company_profile.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String rawRole;
  final String headline;
  final String bio;
  final String location;
  final String avatarUrl;
  final String avatarIconKey;
  final List<String> skills;
  final String companyName;
  final String companyLocation;
  final String companyIconKey;
  final List<CompanyProfile> companies;
  final List<CompanyProfile> favoriteCompanies;
  final String designation;
  final int experienceYears;
  final double rating;
  final int totalReviews;
  final bool isVerified;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    required this.role,
    String? rawRole,
    this.headline = '',
    this.bio = '',
    this.location = '',
    this.avatarUrl = '',
    this.avatarIconKey = '',
    this.skills = const [],
    this.companyName = '',
    this.companyLocation = '',
    this.companyIconKey = '',
    this.companies = const [],
    this.favoriteCompanies = const [],
    this.designation = '',
    this.experienceYears = 0,
    this.rating = 5.0,
    this.totalReviews = 0,
    this.isVerified = false,
    DateTime? createdAt,
  })  : rawRole = (rawRole != null && rawRole.trim().isNotEmpty)
            ? rawRole.trim()
            : role.name,
        createdAt = createdAt ?? DateTime.now();

  /// True if this user's role in the Realtime Database is explicitly 'candidate'.
  bool get isCandidateInDatabase => rawRole.trim().toLowerCase() == 'candidate';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'headline': headline,
      'bio': bio,
      'location': location,
      'avatarUrl': avatarUrl,
      'avatarIconKey': avatarIconKey,
      'skills': skills,
      'companyName': companyName,
      'companyLocation': companyLocation,
      'companyIconKey': companyIconKey,
      'companies': companies.map((company) => company.toMap()).toList(),
      'favoriteCompanies': favoriteCompanies.map((company) => company.toMap()).toList(),
      'designation': designation,
      'experienceYears': experienceYears,
      'rating': rating,
      'totalReviews': totalReviews,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    final rawRole = map['role']?.toString().trim() ?? '';
    final normalized = rawRole.toLowerCase();

    UserRole parsedRole;
    if (normalized == 'candidate') {
      parsedRole = UserRole.candidate;
    } else if (normalized == 'recruiter' || normalized == 'hr') {
      parsedRole = UserRole.recruiter;
    } else if (normalized == 'instructor' || normalized == 'course') {
      parsedRole = UserRole.instructor;
    } else if (normalized == 'mentor') {
      parsedRole = UserRole.mentor;
    } else if (normalized == 'admin') {
      parsedRole = UserRole.admin;
    } else {
      UserRole? match;
      for (final r in UserRole.values) {
        if (r.name.toLowerCase() == normalized) {
          match = r;
          break;
        }
      }
      if (match != null) {
        parsedRole = match;
      } else {
        final email = map['email']?.toString().trim().toLowerCase() ?? '';
        if (email == 'admin@gmail.com' || email.contains('admin')) {
          parsedRole = UserRole.admin;
        } else if (email.contains('recruiter') || email.contains('hr')) {
          parsedRole = UserRole.recruiter;
        } else if (email.contains('instructor') || email.contains('course')) {
          parsedRole = UserRole.instructor;
        } else if (email.contains('mentor')) {
          parsedRole = UserRole.mentor;
        } else {
          parsedRole = UserRole.candidate;
        }
      }
    }

    return UserModel(
      id: docId.isNotEmpty ? docId : (map['id']?.toString() ?? ''),
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      role: parsedRole,
      rawRole: rawRole,
      headline: map['headline']?.toString() ?? '',
      bio: map['bio']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      avatarUrl: map['avatarUrl']?.toString() ?? '',
      avatarIconKey: map['avatarIconKey']?.toString() ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      companyName: map['companyName']?.toString() ?? '',
      companyLocation: map['companyLocation']?.toString() ?? '',
      companyIconKey: map['companyIconKey']?.toString() ?? '',
      companies: _parseCompanies(map['companies']),
      favoriteCompanies: _parseCompanies(map['favoriteCompanies']),
      designation: map['designation']?.toString() ?? '',
      experienceYears: (map['experienceYears'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      totalReviews: (map['totalReviews'] as num?)?.toInt() ?? 0,
      isVerified: map['isVerified'] == true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static List<CompanyProfile> _parseCompanies(dynamic rawCompanies) {
    final entries = switch (rawCompanies) {
      List<dynamic> values => values,
      Map<dynamic, dynamic> values => values.values.toList(),
      _ => const <dynamic>[],
    };
    return entries.whereType<Map>().map(CompanyProfile.fromMap).toList();
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? headline,
    String? bio,
    String? location,
    String? avatarUrl,
    String? avatarIconKey,
    List<String>? skills,
    String? companyName,
    String? companyLocation,
    String? companyIconKey,
    List<CompanyProfile>? companies,
    List<CompanyProfile>? favoriteCompanies,
    String? designation,
    int? experienceYears,
    double? rating,
    int? totalReviews,
    bool? isVerified,
    String? rawRole,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      rawRole: rawRole ?? (role != null ? role.name : this.rawRole),
      headline: headline ?? this.headline,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarIconKey: avatarIconKey ?? this.avatarIconKey,
      skills: skills ?? this.skills,
      companyName: companyName ?? this.companyName,
      companyLocation: companyLocation ?? this.companyLocation,
      companyIconKey: companyIconKey ?? this.companyIconKey,
      companies: companies ?? this.companies,
      favoriteCompanies: favoriteCompanies ?? this.favoriteCompanies,
      designation: designation ?? this.designation,
      experienceYears: experienceYears ?? this.experienceYears,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
    );
  }
}
