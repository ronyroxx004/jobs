import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/admin_controller.dart';
import '../../core/utils/constants.dart';
import '../../models/user_model.dart';
import '../profile/candidate_profile_view.dart';
import './admin_user_profile_view.dart';

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
      body: SafeArea(
        child: Padding(
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
      ),
    );
  }

  void _showUserProfileBottomSheet(BuildContext context, UserModel user) {
    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // User info header
            Row(
              children: [
                _buildUserAvatar(user, size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    label: const Text(
                      'Edit',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      Get.back();
                      _handleEditUser(user);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    label: const Text(
                      'Delete',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      Get.back();
                      _showFirstDeleteConfirmation(context, user);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _handleEditUser(UserModel user) {
    if (user.role == UserRole.candidate ||
        user.role == UserRole.recruiter ||
        user.role == UserRole.mentor) {
      Get.to(
        () => CandidateProfileView(candidateUser: user, isAdminView: true),
        transition: Transition.rightToLeft,
      );
    } else {
      Get.to(
        () => AdminUserProfileView(user: user, role: user.role),
        transition: Transition.rightToLeft,
      );
    }
  }

  void _showFirstDeleteConfirmation(BuildContext context, UserModel user) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete ${user.name}?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'This user and all their associated data will be permanently deleted. This action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Get.back();
              _showSecondDeleteConfirmation(context, user);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showSecondDeleteConfirmation(BuildContext context, UserModel user) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Are you absolutely sure?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.red.shade600,
          ),
        ),
        content: Text(
          'This is the final confirmation. Once deleted, all data for ${user.name} will be removed from Firebase and the database.',
          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Get.back();
              await controller.deleteUser(user.id, user.name);
            },
            child: Text(
              'Delete Permanently',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
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
}
