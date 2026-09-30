import 'package:flutter/material.dart';

class CompanyIconOption {
  const CompanyIconOption(this.key, this.label, this.icon, this.color);

  final String key;
  final String label;
  final IconData icon;
  final Color color;
}

const companyIconOptions = <CompanyIconOption>[
  CompanyIconOption(
    'business',
    'Corporate',
    Icons.business_rounded,
    Color(0xFF4F46E5),
  ),
  CompanyIconOption(
    'startup',
    'Startup',
    Icons.rocket_launch_rounded,
    Color(0xFF7C3AED),
  ),
  CompanyIconOption(
    'technology',
    'Technology',
    Icons.memory_rounded,
    Color(0xFF2563EB),
  ),
  CompanyIconOption(
    'creative',
    'Creative',
    Icons.palette_rounded,
    Color(0xFFDB2777),
  ),
  CompanyIconOption(
    'education',
    'Education',
    Icons.school_rounded,
    Color(0xFF0891B2),
  ),
  CompanyIconOption(
    'healthcare',
    'Healthcare',
    Icons.health_and_safety_rounded,
    Color(0xFF0F9F8F),
  ),
  CompanyIconOption(
    'finance',
    'Finance',
    Icons.account_balance_rounded,
    Color(0xFFCA8A04),
  ),
  CompanyIconOption(
    'retail',
    'Retail',
    Icons.storefront_rounded,
    Color(0xFFEA580C),
  ),
  CompanyIconOption(
    'people',
    'People',
    Icons.groups_rounded,
    Color(0xFF0F766E),
  ),
  CompanyIconOption(
    'science',
    'Science',
    Icons.science_rounded,
    Color(0xFF4F46E5),
  ),
  CompanyIconOption(
    'travel',
    'Travel',
    Icons.flight_takeoff_rounded,
    Color(0xFF0284C7),
  ),
  CompanyIconOption(
    'design',
    'Design',
    Icons.design_services_rounded,
    Color(0xFFEC4899),
  ),
];

CompanyIconOption companyIconForKey(String key) =>
    companyIconOptions.firstWhere(
      (option) => option.key == key,
      orElse: () => companyIconOptions.first,
    );
