import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/admin_controller.dart';
import '../../core/utils/constants.dart';
import '../../models/user_model.dart';
import '../profile/edit_profile_view.dart';

class AdminUserProfileView extends GetView<AdminController> {
  final UserModel user;
  final UserRole role;

  const AdminUserProfileView(
      {super.key, required this.user, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user.name,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
            tooltip: 'Edit User',
            onPressed: () {
              if (role == UserRole.candidate) {
                Get.to(
                  () => EditProfileView(targetUser: user),
                  transition: Transition.rightToLeft,
                );
              } else {
                _showEditUserDialog(context, user);
              }
            },
          ),
          if (role == UserRole.candidate)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete Candidate',
              onPressed: () {
                controller.deleteUser(user.id, user.name);
                Get.back();
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildUserAvatar(user, size: 72),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: GoogleFonts.inter(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.email_outlined,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                user.email.isNotEmpty
                                    ? user.email
                                    : 'No email provided',
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              user.phone.isNotEmpty
                                  ? user.phone
                                  : 'No phone provided',
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              if (user.headline.isNotEmpty) ...[
                Text('Professional Headline',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary)),
                const SizedBox(height: 6),
                Text(user.headline, style: GoogleFonts.inter(fontSize: 15)),
                const SizedBox(height: 20),
              ],
              if (user.bio.isNotEmpty) ...[
                Text('Biography / About',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary)),
                const SizedBox(height: 6),
                Text(user.bio,
                    style: GoogleFonts.inter(fontSize: 15, height: 1.4)),
                const SizedBox(height: 20),
              ],
              if (user.location.isNotEmpty) ...[
                Text('Location',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary)),
                const SizedBox(height: 6),
                Text(user.location, style: GoogleFonts.inter(fontSize: 15)),
                const SizedBox(height: 20),
              ],
              Text('Experience',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary)),
              const SizedBox(height: 6),
              Text('${user.experienceYears} years of experience',
                  style: GoogleFonts.inter(fontSize: 15)),
              const SizedBox(height: 20),
              if (user.skills.isNotEmpty) ...[
                Text('Skills & Expertise',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: user.skills
                      .map((skill) => Chip(
                            label:
                                Text(skill, style: const TextStyle(fontSize: 12)),
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.1),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit Profile'),
                      onPressed: () {
                        if (role == UserRole.candidate) {
                          Get.to(
                            () => EditProfileView(targetUser: user),
                            transition: Transition.rightToLeft,
                          );
                        } else {
                          _showEditUserDialog(context, user);
                        }
                      },
                    ),
                  ),
                  if (role == UserRole.candidate) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete Candidate'),
                        onPressed: () async {
                          final deleted = await controller.deleteUser(
                            user.id,
                            user.name,
                          );
                          if (deleted && Get.isBottomSheetOpen == false) {
                            Get.back();
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(UserModel user, {double size = 72}) {
    if (user.avatarUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          user.avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _avatarFallback(user, size: size),
        ),
      );
    } else if (user.avatarIconKey.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Icon(
            _iconForAvatarKey(user.avatarIconKey),
            size: size * 0.55,
            color: AppColors.secondary,
          ),
        ),
      );
    }
    return _avatarFallback(user, size: size);
  }

  Widget _avatarFallback(UserModel user, {double size = 72}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.375,
          ),
        ),
      ),
    );
  }

  IconData _iconForAvatarKey(String key) {
    const Map<String, IconData> avatarIcons = {
      'candidate_rocket': Icons.rocket_launch_rounded,
      'candidate_code': Icons.code_rounded,
      'candidate_star': Icons.workspace_premium_rounded,
      'candidate_palette': Icons.palette_rounded,
      'candidate_explore': Icons.explore_rounded,
      'candidate_build': Icons.construction_rounded,
      'candidate_flash': Icons.bolt_rounded,
      'candidate_person': Icons.person_rounded,
      'candidate_trending': Icons.trending_up_rounded,
      'candidate_terminal': Icons.terminal_rounded,
      'candidate_trophy': Icons.emoji_events_rounded,
      'recruiter_business': Icons.business_center_rounded,
      'recruiter_groups': Icons.groups_rounded,
      'recruiter_handshake': Icons.handshake_rounded,
      'recruiter_star': Icons.stars_rounded,
      'recruiter_search': Icons.manage_search_rounded,
      'recruiter_badge': Icons.military_tech_rounded,
      'recruiter_connect': Icons.connect_without_contact_rounded,
      'recruiter_person': Icons.person_rounded,
      'recruiter_target': Icons.track_changes_rounded,
      'recruiter_verified': Icons.verified_rounded,
      'recruiter_graph': Icons.query_stats_rounded,
      'mentor_mind': Icons.psychology_rounded,
      'mentor_bulb': Icons.lightbulb_rounded,
      'mentor_school': Icons.school_rounded,
      'mentor_support': Icons.support_agent_rounded,
      'mentor_compass': Icons.explore_rounded,
      'mentor_favorite': Icons.favorite_rounded,
      'mentor_trophy': Icons.emoji_events_rounded,
      'mentor_person': Icons.person_rounded,
      'mentor_route': Icons.alt_route_rounded,
      'mentor_growth': Icons.trending_up_rounded,
      'mentor_chat': Icons.forum_rounded,
      'instructor_teach': Icons.cast_for_education_rounded,
      'instructor_book': Icons.menu_book_rounded,
      'instructor_science': Icons.science_rounded,
      'instructor_computer': Icons.computer_rounded,
      'instructor_draw': Icons.draw_rounded,
      'instructor_quiz': Icons.quiz_rounded,
      'instructor_language': Icons.translate_rounded,
      'instructor_person': Icons.person_rounded,
      'instructor_award': Icons.workspace_premium_rounded,
    };
    return avatarIcons[key] ?? Icons.person_rounded;
  }

  void _showEditUserDialog(BuildContext context, UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone);
    final headlineController = TextEditingController(text: user.headline);
    final bioController = TextEditingController(text: user.bio);
    final locationController = TextEditingController(text: user.location);
    final experienceController =
        TextEditingController(text: user.experienceYears.toString());

    Get.dialog(
      AlertDialog(
        title: Text('Edit ${user.name}',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: headlineController,
                decoration: const InputDecoration(labelText: 'Headline'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: experienceController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Experience Years'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updated = user.copyWith(
                name: nameController.text.trim(),
                email: emailController.text.trim(),
                phone: phoneController.text.trim(),
                headline: headlineController.text.trim(),
                bio: bioController.text.trim(),
                location: locationController.text.trim(),
                experienceYears:
                    int.tryParse(experienceController.text.trim()) ??
                        user.experienceYears,
              );
              controller.updateUserProfile(updated);
              Get.back();
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
