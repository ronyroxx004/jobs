import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/admin_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/constants.dart';
import '../../models/user_model.dart';
import '../profile/candidate_profile_view.dart';
import '../profile/edit_profile_view.dart';
import 'admin_user_profile_view.dart';

/// Resolves the Material icon stored against a user's `avatarIconKey`.
IconData adminIconForAvatarKey(String key) {
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

/// Renders a user avatar from a network image, a stored icon key, or initials.
class AdminUserAvatar extends StatelessWidget {
  final UserModel user;
  final double size;
  final Color accent;
  final double radius;

  const AdminUserAvatar({
    super.key,
    required this.user,
    this.size = 48,
    this.accent = AppColors.secondary,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    final isCircle = radius >= size / 2;

    if (user.avatarUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: shape,
        child: Image.network(
          user.avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(shape, isCircle),
        ),
      );
    }

    if (user.avatarIconKey.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.15),
          borderRadius: shape,
        ),
        child: Center(
          child: Icon(
            adminIconForAvatarKey(user.avatarIconKey),
            size: size * 0.52,
            color: accent,
          ),
        ),
      );
    }

    return _fallback(shape, isCircle);
  }

  Widget _fallback(BorderRadius shape, bool isCircle) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: shape,
      ),
      child: Center(
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
          style: GoogleFonts.inter(
            color: accent,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.38,
          ),
        ),
      ),
    );
  }
}

/// Compact statistic card used in the metric strips of each role screen.
class AdminStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const AdminStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded search input shared by every role screen.
class AdminSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const AdminSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onClear,
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

/// Placeholder shown when a role has no matching records.
class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Watches a [ScrollController] and reports whether the top header should be
/// shown.
///
/// Hides while scrolling down, reveals again when scrolling up, and always
/// reveals at the very top of the list.
class HeaderCollapseNotifier {
  HeaderCollapseNotifier(this.controller);

  final ScrollController controller;
  final RxBool visible = true.obs;

  double _lastOffset = 0;

  void onScroll() {
    if (!controller.hasClients) return;
    final offset = controller.position.pixels;
    if (offset == _lastOffset) return;

    final delta = offset - _lastOffset;
    _lastOffset = offset;

    if (offset <= 12) {
      // Always visible at the top of the list.
      if (!visible.value) visible.value = true;
      return;
    }
    if (delta > 6 && visible.value) {
      visible.value = false;
    } else if (delta < -6 && !visible.value) {
      visible.value = true;
    }
  }
}

/// Animates its [child] away when [visible] is false, reclaiming the space.
class CollapsibleHeader extends StatelessWidget {
  final bool visible;
  final Widget child;

  const CollapsibleHeader({
    super.key,
    required this.visible,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: visible
          ? child
          : const SizedBox(width: double.infinity, height: 0),
    );
  }
}

/// Pinned sliver header delegate used to pin search bars and filters
/// while hero and stat headers scroll upward naturally.
class AdminPinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final Color? backgroundColor;

  AdminPinnedHeaderDelegate({
    required this.child,
    required this.height,
    this.backgroundColor,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: height,
      color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant AdminPinnedHeaderDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.child != child ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

/// Opens the profile/edit screen for a user from any admin role screen.
void adminEditUser(UserModel user) {
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

/// Bottom sheet with the per-user moderation actions (view / edit / delete).
void adminShowUserActions(
  BuildContext context,
  UserModel user, {
  Color accent = AppColors.secondary,
  List<Widget> extraActions = const [],
}) {
  Get.bottomSheet(
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                AdminUserAvatar(user: user, size: 56, accent: accent),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.headline.isNotEmpty ? user.headline : user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      _RoleBadge(role: user.role, accent: accent),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...extraActions,
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.35),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('View Profile'),
                    onPressed: () {
                      Get.back();
                      if (user.role == UserRole.candidate ||
                          user.role == UserRole.recruiter ||
                          user.role == UserRole.mentor) {
                        Get.to(
                          () => CandidateProfileView(
                            candidateUser: user,
                            isAdminView: true,
                          ),
                          transition: Transition.rightToLeft,
                        );
                      } else {
                        Get.to(
                          () => AdminUserProfileView(
                            user: user,
                            role: user.role,
                          ),
                          transition: Transition.rightToLeft,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
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
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit Profile'),
                    onPressed: () {
                      Get.back();
                      if (user.role == UserRole.candidate ||
                          user.role == UserRole.recruiter ||
                          user.role == UserRole.mentor) {
                        Get.to(
                          () => EditProfileView(targetUser: user),
                          transition: Transition.rightToLeft,
                        );
                      } else {
                        adminEditUser(user);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Delete Permanently'),
                onPressed: () {
                  Get.back();
                  adminConfirmDeleteUser(user);
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Two-step delete confirmation, matching the existing admin panel flow.
void adminConfirmDeleteUser(UserModel user) {
  Get.dialog(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        'Delete ${user.name}?',
        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
      ),
      content: Text(
        'This user and all their associated data will be permanently deleted. '
        'This action cannot be undone.',
        style: GoogleFonts.inter(fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: Get.back,
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
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            Get.back();
            _adminFinalDeleteDialog(user);
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

void _adminFinalDeleteDialog(UserModel user) {
  Get.dialog(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        'Are you absolutely sure?',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: Colors.red.shade600,
        ),
      ),
      content: Text(
        'This is the final confirmation. Once deleted, all data for '
        '${user.name} will be removed from the database.',
        style: GoogleFonts.inter(fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: Get.back,
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
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () async {
            Get.back();
            final deleted =
                await Get.find<AdminController>().deleteUser(user.id, user.name);
            if (deleted && Get.currentRoute != AppRoutes.home) {
              Get.back();
            }
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

/// Case-insensitive "does this record match the search box" check.
bool adminMatchesQuery(String query, Iterable<String> fields) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return fields.any((field) => field.toLowerCase().contains(q));
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;
  final Color accent;

  const _RoleBadge({required this.role, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role.displayName,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }
}



