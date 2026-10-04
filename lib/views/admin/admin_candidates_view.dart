import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/admin_controller.dart';
import '../../core/utils/constants.dart';
import '../../models/user_model.dart';
import '../../models/deleted_user_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../profile/candidate_profile_view.dart';
import 'admin_shared.dart';

/// Admin screen for candidates, laid out as a hiring pipeline board with a
/// stat strip, segmented status filter and card grid.
class AdminCandidatesView extends StatefulWidget {
  const AdminCandidatesView({super.key});

  @override
  State<AdminCandidatesView> createState() => _AdminCandidatesViewState();
}

class _AdminCandidatesViewState extends State<AdminCandidatesView> {
  final TextEditingController _searchController = TextEditingController();
  final RxString _query = ''.obs;
  final RxString _filter = 'All'.obs;

  late final ScrollController _scrollController;

  static const List<String> _filters = [
    'All',
    'Deleted Candidates',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    if (Get.isRegistered<DatabaseService>()) {
      final db = Get.find<DatabaseService>();
      if (db.usersList.isEmpty) {
        db.fetchUsers();
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
            // Talent Pipeline header + 3 buttons scroll upward when scrolling on candidate cards
            SliverToBoxAdapter(
              child: _buildCollapsibleHeader(controller),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: AdminPinnedHeaderDelegate(
                height: 104,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSearch(),
                      _buildFilterBar(),
                    ],
                  ),
                ),
              ),
            ),
            _buildCandidateGrid(controller),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: AdminSearchField(
        controller: _searchController,
        hint: 'Search name, email, skill or location...',
        onChanged: (value) => _query.value = value,
        onClear: () {
          _searchController.clear();
          _query.value = '';
        },
      ),
    );
  }

  Widget _buildCollapsibleHeader(AdminController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.groups_2_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Talent Pipeline',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Review and manage every candidate account',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: AdminStatTile(
                    label: 'Candidates',
                    value: '${controller.candidates.length}',
                    icon: Icons.person_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AdminStatTile(
                    label: 'Verified',
                    value: '${controller.verifiedCandidates}',
                    icon: Icons.verified_rounded,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AdminStatTile(
                    label: 'Job Offers',
                    value: '${controller.totalJobOffers}',
                    icon: Icons.card_giftcard_rounded,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

Widget _buildFilterBar() {
    return Column(
      children: [
        SizedBox(
          height: 38,
          child: Obx(
            () {
              // Read the observable here (not inside the lazy itemBuilder),
              // otherwise Obx has no reactive dependency to subscribe to.
              final selected = _filter.value;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final label = _filters[index];
                  final isSelected = selected == label;
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => _filter.value = label,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.borderLight,
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCandidateGrid(AdminController controller) {
    return Obx(() {
      if (_filter.value == 'Deleted Candidates' ||
          _filter.value == 'Deleted Contacts') {
        final query = _query.value.toLowerCase().trim();
        final deleted = controller.deletedUsers.where((u) {
          if (u.role.toLowerCase() != 'candidate') return false;
          return query.isEmpty ||
              u.name.toLowerCase().contains(query) ||
              u.email.toLowerCase().contains(query) ||
              u.id.toLowerCase().contains(query);
        }).toList();

        if (deleted.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: AdminEmptyState(
              icon: Icons.restore_rounded,
              title: 'No deleted candidates',
              subtitle:
                  'Candidates removed by admin will appear here so you can restore them.',
              color: AppColors.primary,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index.isOdd) return const SizedBox(height: 10);
                final itemIndex = index ~/ 2;
                return _DeletedCandidateCard(
                  record: deleted[itemIndex],
                  controller: controller,
                );
              },
              childCount: deleted.isEmpty ? 0 : deleted.length * 2 - 1,
            ),
          ),
        );
      }

      final users = _filteredCandidates(controller);
      if (users.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: AdminEmptyState(
            icon: Icons.person_search_rounded,
            title: 'No candidates found',
            subtitle: 'Try a different search term or clear the active filter.',
            color: AppColors.primary,
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index.isOdd) return const SizedBox(height: 10);
              final itemIndex = index ~/ 2;
              return _CandidateCard(
                user: users[itemIndex],
                controller: controller,
              );
            },
            childCount: users.isEmpty ? 0 : users.length * 2 - 1,
          ),
        ),
      );
    });
  }

  List<UserModel> _filteredCandidates(AdminController controller) {
    final filter = _filter.value;
    final authService =
        Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
    final currentAdminId = authService?.currentUser.value?.id;
    final currentAdminEmail =
        authService?.currentUser.value?.email.trim().toLowerCase();

    return controller.candidates.where((user) {
      if (currentAdminId != null &&
          currentAdminId.isNotEmpty &&
          user.id == currentAdminId) {
        return false;
      }
      if (currentAdminEmail != null &&
          currentAdminEmail.isNotEmpty &&
          user.email.trim().toLowerCase() == currentAdminEmail) {
        return false;
      }
      if (user.role != UserRole.candidate && !user.isCandidateInDatabase) {
        return false;
      }

      final matchesSearch = adminMatchesQuery(_query.value, [
        user.name,
        user.email,
        user.phone,
        user.headline,
        user.location,
        ...user.skills,
      ]);
      if (!matchesSearch) return false;

      switch (filter) {
        case 'Verified':
          return user.isVerified;
        case 'Experienced':
          return user.experienceYears > 0;
        case 'Active Applications':
          return controller
              .applicationsByCandidate(user.id, email: user.email)
              .isNotEmpty;
        case 'Job Offers':
          return controller.offersForCandidate(user.id, email: user.email) > 0;
        default:
          return true;
      }
    }).toList();
  }
}

class _CandidateCard extends StatelessWidget {
  final UserModel user;
  final AdminController controller;

  const _CandidateCard({required this.user, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final applications =
          controller.applicationsByCandidate(user.id, email: user.email);
      final offers = controller.offersForCandidate(user.id, email: user.email);

      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Get.to(
            () => CandidateProfileView(candidateUser: user, isAdminView: true),
            transition: Transition.rightToLeft,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AdminUserAvatar(
                    user: user,
                    size: 46,
                    accent: AppColors.primary,
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
                                user.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (user.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                size: 15,
                                color: AppColors.secondary,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.headline.isNotEmpty
                              ? user.headline
                              : 'Candidate',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded, size: 18),
                    color: Colors.grey,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => adminShowUserActions(
                      context,
                      user,
                      accent: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _MetaRow(
                icon: Icons.mail_outline_rounded,
                value: user.email.isEmpty ? 'No email' : user.email,
              ),
              const SizedBox(height: 4),
              _MetaRow(
                icon: Icons.work_history_rounded,
                value: user.experienceYears > 0
                    ? '${user.experienceYears} yr experience'
                    : 'Fresher',
              ),
              const SizedBox(height: 10),
              if (user.skills.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: user.skills
                      .take(3)
                      .map(
                        (skill) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            skill,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  _CountBadge(
                    icon: Icons.send_rounded,
                    label: '${applications.length} applied',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  if (offers > 0)
                    _CountBadge(
                      icon: Icons.card_giftcard_rounded,
                      label: '$offers offer${offers == 1 ? '' : 's'}',
                      color: AppColors.secondary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    });
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _MetaRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CountBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


class _DeletedCandidateCard extends StatelessWidget {
  final DeletedUserModel record;
  final AdminController controller;

  const _DeletedCandidateCard({
    required this.record,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final appsCount = record.applicationsCount;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    record.name.isNotEmpty ? record.name[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.name.isNotEmpty ? record.name : 'Candidate',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        record.email.isNotEmpty ? record.email : 'No email',
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Deleted',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.send_rounded,
                      size: 13, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      appsCount > 0
                          ? '$appsCount application${appsCount == 1 ? '' : 's'} (restores active jobs)'
                          : 'No applications saved',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.restore_rounded, size: 16),
                label: Text(
                  'Restore Candidate',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () => controller.restoreUser(record),
              ),
            ),
          ],
        ),
      ),
    );
  }
}