import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/admin_controller.dart';
import '../../core/utils/constants.dart';
import '../../models/user_model.dart';

class AdminRoleUsersView extends StatefulWidget {
  final UserRole role;
  const AdminRoleUsersView({super.key, required this.role});

  @override
  State<AdminRoleUsersView> createState() => _AdminRoleUsersViewState();
}

class _AdminRoleUsersViewState extends State<AdminRoleUsersView> {
  AdminController get controller => Get.find<AdminController>();
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Input
            TextField(
              controller: _searchController,
              onChanged: (val) => _searchQuery.value = val,
              decoration: InputDecoration(
                hintText: 'Search by name, email or phone...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: Obx(() => _searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery.value = '';
                        },
                      )
                    : const SizedBox.shrink()),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                final query = _searchQuery.value.toLowerCase();
                final users = controller.allUsers
                    .where((u) => u.role == widget.role)
                    .where((u) =>
                        u.name.toLowerCase().contains(query) ||
                        u.email.toLowerCase().contains(query) ||
                        u.phone.toLowerCase().contains(query))
                    .toList();

                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      'No ${widget.role.name}s found',
                      style: GoogleFonts.inter(color: Colors.grey, fontSize: 15),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onLongPress: () =>
                            _showUserProfileBottomSheet(context, user),
                        onTap: () =>
                            _showUserProfileBottomSheet(context, user),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              _buildUserAvatar(user, size: 48),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.email_outlined,
                                            size: 13, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            user.email.isNotEmpty
                                                ? user.email
                                                : 'No email provided',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: Colors.grey[600]),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_outlined,
                                            size: 13, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          user.phone.isNotEmpty
                                              ? user.phone
                                              : 'No phone provided',
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.more_vert_rounded,
                                    color: Colors.grey),
                                tooltip: 'Options',
                                onPressed: () =>
                                    _showUserProfileBottomSheet(context, user),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserProfileBottomSheet(BuildContext context, UserModel user) {
    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildUserAvatar(user, size: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.inter(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user.role.displayName,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const Divider(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                        Icons.email_outlined,
                        user.email.isNotEmpty
                            ? user.email
                            : 'No email provided'),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                        Icons.phone_outlined,
                        user.phone.isNotEmpty
                            ? user.phone
                            : 'No phone provided'),
                    if (user.location.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.location_on_outlined, user.location),
                    ],
                    if (user.headline.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Professional Headline',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primary)),
                      const SizedBox(height: 4),
                      Text(user.headline,
                          style: GoogleFonts.inter(fontSize: 14)),
                    ],
                    if (user.bio.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Biography',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primary)),
                      const SizedBox(height: 4),
                      Text(user.bio,
                          style: GoogleFonts.inter(fontSize: 14, height: 1.4)),
                    ],
                    const SizedBox(height: 20),
                    Text('Experience',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text('${user.experienceYears} years of experience',
                        style: GoogleFonts.inter(fontSize: 14)),
                    if (user.skills.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Skills & Expertise',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: user.skills
                            .map((skill) => Chip(
                                  label: Text(skill,
                                      style: const TextStyle(fontSize: 11)),
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.1),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit Profile'),
                    onPressed: () {
                      Get.back();
                      _showEditUserDialog(context, user);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete Profile'),
                    onPressed: () {
                      Get.back();
                      _showDeleteConfirmation(context, user);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, UserModel user) {
    Get.dialog(
      AlertDialog(
        title: Text('Delete Profile',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to delete ${user.name}? This action cannot be undone.',
            style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Get.back();
              controller.deleteUser(user.id, user.name);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(UserModel user, {double size = 48}) {
    if (user.avatarUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(12),
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

  Widget _avatarFallback(UserModel user, {double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
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
