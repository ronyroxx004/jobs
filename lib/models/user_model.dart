import '../core/utils/constants.dart';
import 'company_profile.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
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
  }) : createdAt = createdAt ?? DateTime.now();

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
    return UserModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.candidate,
      ),
      headline: map['headline'] ?? '',
      bio: map['bio'] ?? '',
      location: map['location'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      avatarIconKey: map['avatarIconKey'] ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      companyName: map['companyName'] ?? '',
      companyLocation: map['companyLocation'] ?? '',
      companyIconKey: map['companyIconKey'] ?? '',
      companies: _parseCompanies(map['companies']),
      favoriteCompanies: _parseCompanies(map['favoriteCompanies']),
      designation: map['designation'] ?? '',
      experienceYears: map['experienceYears'] ?? 0,
      rating: (map['rating'] ?? 5.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
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
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
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
