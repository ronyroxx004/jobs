import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/admin_controller.dart';
import '../../core/utils/constants.dart';
import '../../models/user_model.dart';
import '../../models/service_model.dart';
import '../../services/database_service.dart';
import 'admin_shared.dart';

/// Admin screen for mentors.
/// Supports viewing all mentor details ("View All Things of Mentor"),
/// browsing all published mentorship posts/offerings, and soft delete/restore.
class AdminMentorsView extends StatefulWidget {
  const AdminMentorsView({super.key});

  @override
  State<AdminMentorsView> createState() => _AdminMentorsViewState();
}

class _AdminMentorsViewState extends State<AdminMentorsView> {
  final TextEditingController _searchController = TextEditingController();
  final RxString _query = ''.obs;
  final RxString _sort = 'Earnings'.obs;
  final RxString _activeTab = 'Mentors'.obs; // 'Mentors' or 'All Posts'
  final RxString _statusFilter = 'All'.obs; // 'All', 'Live', 'Soft Deleted'

  static const List<String> _sorts = ['Earnings', 'Bookings', 'Services', 'Name'];
  static const List<String> _statuses = ['All', 'Live', 'Soft Deleted'];

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    if (Get.isRegistered<DatabaseService>()) {
      final db = Get.find<DatabaseService>();
      if (db.usersList.isEmpty) {
        db.fetchUsers();
      }
      if (db.servicesList.isEmpty) {
        db.fetchServices();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    return RefreshIndicator(
      onRefresh: () => Get.find<DatabaseService>().fetchAllData(),
      child: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Mentorship Program hero + 3 stat tiles
            SliverToBoxAdapter(
              child: _buildCollapsibleHeader(controller),
            ),
            // Pinned controls: Tab switcher, search, sort/filter
            SliverPersistentHeader(
              pinned: true,
              delegate: AdminPinnedHeaderDelegate(
                height: 154,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: _buildControls(controller),
                ),
              ),
            ),
            // Dynamic content: Mentors list or All Posts list
            Obx(() {
              if (_activeTab.value == 'Mentors') {
                return _buildMentorList(controller);
              } else {
                return _buildAllPostsList(controller);
              }
            }),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleHeader(AdminController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary,
                  AppColors.secondary.withValues(alpha: 0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.psychology_alt_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mentorship Management',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Obx(() => Text(
                            '${controller.mentors.length} mentors • '
                            '${controller.activeServices} active posts',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: AdminStatTile(
                    label: 'Total Posts',
                    value: '${Get.find<DatabaseService>().servicesList.length}',
                    icon: Icons.design_services_rounded,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AdminStatTile(
                    label: 'Bookings',
                    value: '${controller.totalBookings}',
                    icon: Icons.event_available_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AdminStatTile(
                    label: 'Revenue',
                    value:
                        '₹${controller.totalMentorshipRevenue.toStringAsFixed(0)}',
                    icon: Icons.payments_rounded,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildControls(AdminController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          // Section Tabs: Mentors vs All Posts
          Obx(() {
            final activeTab = _activeTab.value;
            final db = Get.find<DatabaseService>();
            final mentorCount = controller.mentors.length;
            final postsCount = db.servicesList.length;

            return Container(
              height: 40,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _activeTab.value = 'Mentors',
                      child: Container(
                        decoration: BoxDecoration(
                          color: activeTab == 'Mentors'
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: activeTab == 'Mentors'
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Mentors ($mentorCount)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: activeTab == 'Mentors'
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: activeTab == 'Mentors'
                                ? AppColors.secondary
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _activeTab.value = 'All Posts',
                      child: Container(
                        decoration: BoxDecoration(
                          color: activeTab == 'All Posts'
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: activeTab == 'All Posts'
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'All Posts / Offerings ($postsCount)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: activeTab == 'All Posts'
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: activeTab == 'All Posts'
                                ? AppColors.secondary
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),

          // Search Field
          AdminSearchField(
            controller: _searchController,
            hint: 'Search mentor, headline, post title or deliverable...',
            onChanged: (value) => _query.value = value,
            onClear: () {
              _searchController.clear();
              _query.value = '';
            },
          ),
          const SizedBox(height: 8),

          // Filter / Sort Row
          Obx(() {
            final isMentorsTab = _activeTab.value == 'Mentors';
            if (isMentorsTab) {
              return Row(
                children: [
                  Text(
                    'Sort by',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _sorts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final label = _sorts[index];
                          final selected = _sort.value == label;
                          return ChoiceChip(
                            label: Text(label),
                            selected: selected,
                            onSelected: (_) => _sort.value = label,
                            showCheckmark: false,
                            selectedColor: AppColors.secondary,
                            backgroundColor: Colors.white,
                            labelStyle: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : Colors.grey[700],
                            ),
                            side: BorderSide(
                              color: selected
                                  ? AppColors.secondary
                                  : AppColors.borderLight,
                            ),
                            visualDensity: VisualDensity.compact,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return Row(
                children: [
                  Text(
                    'Status',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _statuses.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final label = _statuses[index];
                          final selected = _statusFilter.value == label;
                          final isSoft = label == 'Soft Deleted';
                          final activeColor =
                              isSoft ? Colors.orange[800]! : AppColors.secondary;
                          return ChoiceChip(
                            label: Text(label),
                            selected: selected,
                            onSelected: (_) => _statusFilter.value = label,
                            showCheckmark: false,
                            selectedColor: activeColor,
                            backgroundColor: Colors.white,
                            labelStyle: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : Colors.grey[700],
                            ),
                            side: BorderSide(
                              color: selected ? activeColor : AppColors.borderLight,
                            ),
                            visualDensity: VisualDensity.compact,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            }
          }),
        ],
      ),
    );
  }

  // --- MENTORS LIST BUILDER ---
  Widget _buildMentorList(AdminController controller) {
    return Obx(() {
      final mentors = _sortedMentors(controller);

      if (mentors.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: AdminEmptyState(
            icon: Icons.groups_outlined,
            title: 'No mentors found',
            subtitle:
                'Mentors who register or publish offerings will appear here.',
            color: AppColors.secondary,
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index.isOdd) return const SizedBox(height: 12);
              final itemIndex = index ~/ 2;
              return _MentorCard(
                mentor: mentors[itemIndex],
                controller: controller,
                onViewAllThings: () => _showAllThingsOfMentorModal(
                  context,
                  mentors[itemIndex],
                  controller,
                ),
              );
            },
            childCount: mentors.isEmpty ? 0 : mentors.length * 2 - 1,
          ),
        ),
      );
    });
  }

  // --- ALL POSTS / OFFERINGS BUILDER ---
  Widget _buildAllPostsList(AdminController controller) {
    return Obx(() {
      final db = Get.find<DatabaseService>();
      final allServices = db.servicesList;

      final filtered = allServices.where((s) {
        final matchesQuery = adminMatchesQuery(_query.value, [
          s.title,
          s.description,
          s.category,
          s.serviceType,
          s.mentorName,
          s.mentorHeadline,
          s.deliverable,
          ...s.topics,
        ]);
        if (!matchesQuery) return false;

        switch (_statusFilter.value) {
          case 'Live':
            return s.isActive && !s.isDeleted;
          case 'Soft Deleted':
            return s.isDeleted;
          default:
            return true;
        }
      }).toList();

      if (filtered.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: AdminEmptyState(
            icon: Icons.design_services_outlined,
            title: 'No mentor posts match filter',
            subtitle: 'Try changing the search query or status filter.',
            color: AppColors.secondary,
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index.isOdd) return const SizedBox(height: 10);
              final itemIndex = index ~/ 2;
              final service = filtered[itemIndex];
              return _AdminPostCard(
                service: service,
                controller: controller,
                onViewMentorDetails: () {
                  final mentor = controller.mentors.firstWhereOrNull(
                    (m) => m.id == service.mentorId,
                  );
                  if (mentor != null) {
                    _showAllThingsOfMentorModal(context, mentor, controller);
                  } else {
                    final synthetic = UserModel(
                      id: service.mentorId,
                      name: service.mentorName,
                      email: '',
                      role: UserRole.mentor,
                      headline: service.mentorHeadline,
                      rating: service.rating,
                      totalReviews: service.reviewCount,
                    );
                    _showAllThingsOfMentorModal(context, synthetic, controller);
                  }
                },
              );
            },
            childCount: filtered.isEmpty ? 0 : filtered.length * 2 - 1,
          ),
        ),
      );
    });
  }

  List<UserModel> _sortedMentors(AdminController controller) {
    final mentors = controller.mentors.where((user) {
      final services = controller.servicesByMentor(user.id);
      return adminMatchesQuery(_query.value, [
        user.name,
        user.email,
        user.headline,
        ...user.skills,
        ...services.map((s) => s.title),
      ]);
    }).toList();

    switch (_sort.value) {
      case 'Name':
        mentors.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case 'Services':
        mentors.sort((a, b) => controller
            .servicesByMentor(b.id)
            .length
            .compareTo(controller.servicesByMentor(a.id).length));
      case 'Bookings':
        mentors.sort((a, b) => controller
            .bookingsByMentor(b.id)
            .length
            .compareTo(controller.bookingsByMentor(a.id).length));
      default:
        mentors.sort((a, b) => controller
            .mentorEarnings(b.id)
            .compareTo(controller.mentorEarnings(a.id)));
    }
    return mentors;
  }
}

// ============================================================================
// MENTOR CARD IN ADMIN LIST
// ============================================================================
class _MentorCard extends StatelessWidget {
  final UserModel mentor;
  final AdminController controller;
  final VoidCallback onViewAllThings;

  const _MentorCard({
    required this.mentor,
    required this.controller,
    required this.onViewAllThings,
  });

  @override
  Widget build(BuildContext context) {
    final services = controller.servicesByMentor(mentor.id);
    final bookings = controller.bookingsByMentor(mentor.id).length;
    final earnings = controller.mentorEarnings(mentor.id);
    final softDeletedCount = services.where((s) => s.isDeleted).length;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Avatar, Info, Revenue
            Row(
              children: [
                AdminUserAvatar(
                  user: mentor,
                  size: 52,
                  accent: AppColors.secondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              mentor.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (mentor.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: AppColors.secondary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mentor.headline.isNotEmpty
                            ? mentor.headline
                            : 'Mentorship Expert',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            mentor.rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            ' (${mentor.totalReviews})',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (softDeletedCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$softDeletedCount soft deleted',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${earnings.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                    Text(
                      '$bookings booking${bookings == 1 ? '' : 's'}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Services preview rows
            if (services.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No mentorship sessions published yet.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              )
            else
              for (final service in services.take(3))
                _ServiceRow(service: service, controller: controller),

            if (services.length > 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: Text(
                    '+ ${services.length - 3} more offerings',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Action Buttons: "View All Things of Mentor" & Quick User Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onViewAllThings,
                    icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
                    label: Text(
                      'View All Things of Mentor',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => adminShowUserActions(
                    context,
                    mentor,
                    accent: AppColors.secondary,
                    extraActions: [
                      _MentorStats(services: services.length, bookings: bookings),
                    ],
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                  child: const Icon(
                    Icons.more_horiz_rounded,
                    size: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SERVICE ROW INSIDE MENTOR CARD
// ============================================================================
class _ServiceRow extends StatelessWidget {
  final MentorshipServiceModel service;
  final AdminController controller;

  const _ServiceRow({required this.service, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isSoftDeleted = service.isDeleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isSoftDeleted
            ? Colors.orange.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.06),
        border: isSoftDeleted
            ? Border.all(color: Colors.orange.withValues(alpha: 0.3))
            : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSoftDeleted
                  ? Colors.orange.withValues(alpha: 0.15)
                  : AppColors.secondary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isSoftDeleted
                  ? Icons.archive_outlined
                  : Icons.video_call_rounded,
              size: 16,
              color: isSoftDeleted ? Colors.orange[800] : AppColors.secondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        service.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          decoration: isSoftDeleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSoftDeleted
                            ? Colors.orange.withValues(alpha: 0.2)
                            : const Color(0xFF059669).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isSoftDeleted ? 'Soft Deleted' : 'Live',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isSoftDeleted
                              ? Colors.orange[800]
                              : const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${service.category} • ${service.durationMinutes} min • ₹${service.price.toStringAsFixed(0)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // EDIT BUTTON
          IconButton(
            tooltip: 'Edit post',
            icon: const Icon(
              Icons.edit_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            onPressed: () => _showEditServiceDialog(context, service, controller),
          ),

          // SOFT DELETE OR RESTORE BUTTON
          if (!isSoftDeleted)
            IconButton(
              tooltip: 'Soft delete (hide from candidates)',
              icon: Icon(
                Icons.archive_outlined,
                size: 18,
                color: Colors.orange[800],
              ),
              onPressed: () => _confirmSoftDelete(context, service, controller),
            )
          else
            IconButton(
              tooltip: 'Restore post (make live)',
              icon: const Icon(
                Icons.unarchive_outlined,
                size: 18,
                color: Color(0xFF059669),
              ),
              onPressed: () => _confirmRestore(context, service, controller),
            ),

          // HARD REMOVE BUTTON
          IconButton(
            tooltip: 'Permanently remove',
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: Colors.redAccent,
            ),
            onPressed: () => _confirmPermanentDelete(context, service, controller),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ADMIN POST CARD (IN ALL POSTS VIEW)
// ============================================================================
class _AdminPostCard extends StatelessWidget {
  final MentorshipServiceModel service;
  final AdminController controller;
  final VoidCallback onViewMentorDetails;

  const _AdminPostCard({
    required this.service,
    required this.controller,
    required this.onViewMentorDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isSoftDeleted = service.isDeleted;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSoftDeleted
              ? Colors.orange.withValues(alpha: 0.3)
              : AppColors.borderLight,
        ),
      ),
      color: isSoftDeleted ? Colors.orange.withValues(alpha: 0.03) : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Type chip, Status chip, Price
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    service.serviceType,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSoftDeleted
                        ? Colors.orange.withValues(alpha: 0.15)
                        : const Color(0xFF059669).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSoftDeleted ? 'Soft Deleted' : 'Live',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSoftDeleted
                          ? Colors.orange[800]
                          : const Color(0xFF059669),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  service.price == 0 ? 'FREE' : '₹${service.price.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              service.title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                decoration: isSoftDeleted ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 4),

            // Description / Deliverable
            if (service.description.isNotEmpty)
              Text(
                service.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[700],
                  height: 1.3,
                ),
              ),
            const SizedBox(height: 8),

            // Mentor Tag & Duration
            Row(
              children: [
                const Icon(Icons.person_pin_circle_rounded,
                    size: 15, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Mentor: ${service.mentorName.isNotEmpty ? service.mentorName : "Anonymous"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Text(
                  '${service.durationMinutes} min',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Bottom Actions Row: View Mentor Details + Soft Delete / Restore + Delete
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onViewMentorDetails,
                  icon: const Icon(Icons.visibility_rounded, size: 14),
                  label: Text(
                    'View Mentor',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Spacer(),

                // Soft Delete or Restore Button
                if (!isSoftDeleted)
                  ElevatedButton.icon(
                    onPressed: () =>
                        _confirmSoftDelete(context, service, controller),
                    icon: const Icon(Icons.archive_outlined, size: 14),
                    label: Text(
                      'Soft Delete',
                      style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800] ?? Colors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () =>
                        _confirmRestore(context, service, controller),
                    icon: const Icon(Icons.unarchive_outlined, size: 14),
                    label: Text(
                      'Restore',
                      style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Edit post',
                  icon: const Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  onPressed: () =>
                      _showEditServiceDialog(context, service, controller),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Delete permanently',
                  icon: const Icon(
                    Icons.delete_forever_rounded,
                    size: 20,
                    color: Colors.redAccent,
                  ),
                  onPressed: () =>
                      _confirmPermanentDelete(context, service, controller),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ALL THINGS OF MENTOR BOTTOM SHEET MODAL
// ============================================================================
void _showAllThingsOfMentorModal(
  BuildContext context,
  UserModel mentor,
  AdminController controller,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AllThingsOfMentorSheet(
      mentor: mentor,
      controller: controller,
    ),
  );
}

class _AllThingsOfMentorSheet extends StatelessWidget {
  final UserModel mentor;
  final AdminController controller;

  const _AllThingsOfMentorSheet({
    required this.mentor,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final services = controller.servicesByMentor(mentor.id);
    final bookings = controller.bookingsByMentor(mentor.id);
    final earnings = controller.mentorEarnings(mentor.id);
    final activePosts = services.where((s) => s.isActive && !s.isDeleted).length;
    final softDeletedPosts = services.where((s) => s.isDeleted).length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Things of Mentor',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Complete 360° overview and admin controls',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PROFILE HERO CARD ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdminUserAvatar(
                          user: mentor,
                          size: 64,
                          accent: AppColors.secondary,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      mentor.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  if (mentor.isVerified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified_rounded,
                                        size: 18, color: AppColors.secondary),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mentor.headline.isNotEmpty
                                    ? mentor.headline
                                    : 'Career Coach & Mentor',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.star_rounded,
                                      size: 16, color: AppColors.warning),
                                  const SizedBox(width: 3),
                                  Text(
                                    mentor.rating.toStringAsFixed(1),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    ' (${mentor.totalReviews} reviews)',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- METRICS ROW ---
                  Row(
                    children: [
                      Expanded(
                        child: _MetricBox(
                          label: 'Active Posts',
                          value: '$activePosts',
                          color: const Color(0xFF059669),
                          icon: Icons.check_circle_outline_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricBox(
                          label: 'Soft Deleted',
                          value: '$softDeletedPosts',
                          color: Colors.orange[800]!,
                          icon: Icons.archive_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricBox(
                          label: 'Bookings',
                          value: '${bookings.length}',
                          color: AppColors.primary,
                          icon: Icons.calendar_today_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricBox(
                          label: 'Earnings',
                          value: '₹${earnings.toStringAsFixed(0)}',
                          color: AppColors.secondary,
                          icon: Icons.payments_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- CONTACT & BIO DETAILS ---
                  Text(
                    'Profile & Bio',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (mentor.email.isNotEmpty)
                          _InfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: mentor.email,
                            onCopy: () {
                              Clipboard.setData(
                                  ClipboardData(text: mentor.email));
                              Get.snackbar(
                                'Copied',
                                'Email copied to clipboard',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            },
                          ),
                        if (mentor.phone.isNotEmpty)
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: mentor.phone,
                          ),
                        if (mentor.location.isNotEmpty)
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Location',
                            value: mentor.location,
                          ),
                        _InfoRow(
                          icon: Icons.badge_outlined,
                          label: 'Mentor ID',
                          value: mentor.id,
                          onCopy: () {
                            Clipboard.setData(ClipboardData(text: mentor.id));
                            Get.snackbar(
                              'Copied',
                              'Mentor ID copied to clipboard',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                        ),
                        if (mentor.bio.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'About:',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mentor.bio,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.4,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                        if (mentor.skills.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: mentor.skills.map((s) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  s,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- ALL PUBLISHED POSTS & OFFERINGS ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Published Posts (${services.length})',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$activePosts Live • $softDeletedPosts Soft Deleted',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (services.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No mentorship posts created yet by this mentor.',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.grey[600]),
                      ),
                    )
                  else
                    for (final s in services)
                      _ServiceDetailCard(
                        service: s,
                        controller: controller,
                      ),
                  const SizedBox(height: 24),

                  // --- BOOKINGS LIST ---
                  Text(
                    'Bookings Received (${bookings.length})',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (bookings.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No bookings received yet.',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.grey[600]),
                      ),
                    )
                  else
                    for (final b in bookings)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b.serviceTitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Candidate: ${b.candidateName.isNotEmpty ? b.candidateName : b.candidateEmail} • ${b.scheduledAt.day}/${b.scheduledAt.month}/${b.scheduledAt.year}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '₹${b.amount.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SERVICE DETAIL CARD WITH INLINE SOFT-DELETE & RESTORE CONTROLS
// ============================================================================
class _ServiceDetailCard extends StatelessWidget {
  final MentorshipServiceModel service;
  final AdminController controller;

  const _ServiceDetailCard({
    required this.service,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isSoftDeleted = service.isDeleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSoftDeleted
            ? Colors.orange.withValues(alpha: 0.07)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSoftDeleted
              ? Colors.orange.withValues(alpha: 0.4)
              : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category, Status, Price
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  service.serviceType,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isSoftDeleted
                      ? Colors.orange.withValues(alpha: 0.18)
                      : const Color(0xFF059669).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isSoftDeleted ? 'Soft Deleted' : 'Live',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSoftDeleted
                        ? Colors.orange[800]
                        : const Color(0xFF059669),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                service.price == 0 ? 'FREE' : '₹${service.price.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title & Description
          Text(
            service.title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              decoration: isSoftDeleted ? TextDecoration.lineThrough : null,
            ),
          ),
          if (service.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              service.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
          const SizedBox(height: 8),

          // Specs: Duration, Deliverable
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${service.durationMinutes} min',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
              ),
              if (service.deliverable.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(Icons.send_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    service.deliverable,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.grey[600]),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Inline Actions: Soft Delete, Restore, Remove
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isSoftDeleted)
                ElevatedButton.icon(
                  onPressed: () =>
                      _confirmSoftDelete(context, service, controller),
                  icon: const Icon(Icons.archive_outlined, size: 13),
                  label: Text(
                    'Soft Delete',
                    style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800] ?? Colors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () =>
                      _confirmRestore(context, service, controller),
                  icon: const Icon(Icons.unarchive_outlined, size: 13),
                  label: Text(
                    'Restore Post',
                    style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    _confirmPermanentDelete(context, service, controller),
                icon: const Icon(Icons.delete_forever_rounded,
                    size: 13, color: Colors.redAccent),
                label: Text(
                  'Permanent Delete',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HELPER COMPONENTS & CONFIRMATION DIALOGS
// ============================================================================
class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700]),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          if (onCopy != null)
            InkWell(
              onTap: onCopy,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.copy_rounded, size: 13, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}

/// Admin edit sheet for a mentor offering. Ownership is preserved, so the post
/// always stays with its original mentor.
void _showEditServiceDialog(
  BuildContext context,
  MentorshipServiceModel service,
  AdminController controller,
) {
  final titleCtrl = TextEditingController(text: service.title);
  final descriptionCtrl = TextEditingController(text: service.description);
  final priceCtrl = TextEditingController(
      text: service.price % 1 == 0 ? service.price.toStringAsFixed(0) : service.price.toString());
  final durationCtrl = TextEditingController(text: '${service.durationMinutes}');
  final deliverableCtrl = TextEditingController(text: service.deliverable);
  var category = service.category.isEmpty ? 'Career Advice' : service.category;
  var serviceType =
      service.serviceType.isEmpty ? '1:1 Call' : service.serviceType;

  const categories = [
    'Career Advice',
    'Resume Review',
    'Mock Interview',
    '1:1 Call',
    'Portfolio Review',
    'LinkedIn Optimization',
    'Live Webinar',
    'Digital Product',
    'Mentorship Program',
  ];
  const serviceTypes = [
    '1:1 Call',
    'Digital Product',
    'Priority DM',
    'Webinar',
    'Package',
  ];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.edit_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Edit Post',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: serviceTypes.contains(serviceType) ? serviceType : null,
                decoration: const InputDecoration(
                  labelText: 'Offering type',
                  border: OutlineInputBorder(),
                ),
                items: serviceTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => serviceType = v ?? serviceType),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: categories.contains(category) ? category : null,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => category = v ?? category),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: deliverableCtrl,
                decoration: const InputDecoration(
                  labelText: 'Deliverable',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: Size.zero,
            ),
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              final price = double.tryParse(priceCtrl.text.trim());
              final minutes = int.tryParse(durationCtrl.text.trim());
              Navigator.pop(ctx);
              controller.editMentorshipService(service.copyWith(
                title: title,
                description: descriptionCtrl.text.trim(),
                price: price ?? service.price,
                durationMinutes: minutes ?? service.durationMinutes,
                category: category,
                serviceType: serviceType,
                deliverable: deliverableCtrl.text.trim(),
              ));
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    ),
  ).then((_) {
    titleCtrl.dispose();
    descriptionCtrl.dispose();
    priceCtrl.dispose();
    durationCtrl.dispose();
    deliverableCtrl.dispose();
  });
}

void _confirmSoftDelete(
  BuildContext context,
  MentorshipServiceModel service,
  AdminController controller,
) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.archive_outlined, color: Colors.orange, size: 24),
          const SizedBox(width: 8),
          const Text('Soft Delete Post'),
        ],
      ),
      content: Text(
        'Are you sure you want to soft delete "${service.title}"?\n\n'
        'This post will be immediately hidden from candidates and public search. '
        'You can restore it at any time from this screen.',
        style: GoogleFonts.inter(fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[800] ?? Colors.orange,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(ctx);
            controller.softDeleteMentorshipService(service.id, service.title);
          },
          child: const Text('Soft Delete'),
        ),
      ],
    ),
  );
}

void _confirmRestore(
  BuildContext context,
  MentorshipServiceModel service,
  AdminController controller,
) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.unarchive_outlined,
              color: Color(0xFF059669), size: 24),
          const SizedBox(width: 8),
          const Text('Restore Post'),
        ],
      ),
      content: Text(
        'Restore "${service.title}"?\n\n'
        'This post will immediately become live again and visible to all candidates.',
        style: GoogleFonts.inter(fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(ctx);
            controller.restoreMentorshipService(service.id, service.title);
          },
          child: const Text('Restore Post'),
        ),
      ],
    ),
  );
}

void _confirmPermanentDelete(
  BuildContext context,
  MentorshipServiceModel service,
  AdminController controller,
) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 24),
          SizedBox(width: 8),
          Text('Permanently Delete'),
        ],
      ),
      content: Text(
        'Permanently delete "${service.title}"?\n\n'
        'This cannot be undone and will permanently remove this offering from the database.',
        style: GoogleFonts.inter(fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(ctx);
            controller.removeMentorshipService(service.id, service.title);
          },
          child: const Text('Delete Permanently'),
        ),
      ],
    ),
  );
}

class _MentorStats extends StatelessWidget {
  final int services;
  final int bookings;

  const _MentorStats({required this.services, required this.bookings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$services',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  'Published sessions',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$bookings',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Total bookings',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}