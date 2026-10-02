import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/admin_controller.dart';
import '../../controllers/job_controller.dart';
import '../../core/utils/constants.dart';
import '../../models/user_model.dart';
import '../../models/job_model.dart';
import '../../models/deleted_user_model.dart';
import '../../services/database_service.dart';
import '../profile/candidate_profile_view.dart';
import 'admin_shared.dart';

/// Admin screen for recruiters, rendered as a performance table where every row
/// expands into the job postings that recruiter owns.
class AdminRecruitersView extends StatefulWidget {
  const AdminRecruitersView({super.key});

  @override
  State<AdminRecruitersView> createState() => _AdminRecruitersViewState();
}

class _AdminRecruitersViewState extends State<AdminRecruitersView> {
  final TextEditingController _searchController = TextEditingController();
  final RxString _query = ''.obs;
  final RxString _expandedId = ''.obs;
  final RxString _filter = 'All'.obs;

  late final ScrollController _scrollController;

  static const List<String> _filters = [
    'All',
    'Deleted Recruiters',
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
            // Hiring Partners header + 3 buttons scroll upward when scrolling on recruiter cards
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
            _buildRecruiterList(controller),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
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
                      'Hiring Partners',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Monitor recruiter accounts and their job postings',
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
                    label: 'Recruiters',
                    value: '${controller.recruiters.length}',
                    icon: Icons.badge_rounded,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AdminStatTile(
                    label: 'Live jobs',
                    value: '${controller.totalJobsByRecruiters}',
                    icon: Icons.work_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AdminStatTile(
                    label: 'Applicants',
                    value: '${controller.totalApplications}',
                    icon: Icons.how_to_reg_rounded,
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

Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: AdminSearchField(
        controller: _searchController,
        hint: 'Search recruiter, company or title...',
        onChanged: (value) => _query.value = value,
        onClear: () {
          _searchController.clear();
          _query.value = '';
        },
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
                    selectedColor: AppColors.secondary,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.secondary
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

  Widget _buildRecruiterList(AdminController controller) {
    return Obx(() {
      final query = _query.value.trim().toLowerCase();
      final expandedId = _expandedId.value;
      final filter = _filter.value;

      if (filter == 'Deleted Recruiters') {
        final deleted = controller.deletedUsers.where((u) {
          if (u.role.toLowerCase() != 'recruiter') return false;
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
              title: 'No deleted recruiters',
              subtitle:
                  'Recruiters removed by admin will appear here so you can restore them with their job posts.',
              color: AppColors.secondary,
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
                final record = deleted[itemIndex];
                return _DeletedRecruiterRow(
                  record: record,
                  controller: controller,
                );
              },
              childCount: deleted.isEmpty ? 0 : deleted.length * 2 - 1,
            ),
          ),
        );
      }

      final recruiters = controller.recruiters.where((user) {
        final jobs = controller.jobsByRecruiter(user.id);
        final matchesQuery = adminMatchesQuery(query, [
          user.name,
          user.email,
          user.phone,
          user.companyName,
          ...jobs.map((j) => j.title),
        ]);
        if (!matchesQuery) return false;

        switch (filter) {
          case 'Verified':
            return user.isVerified;
          case 'Active Jobs':
            return jobs.any((j) => j.isActive);
          default:
            return true;
        }
      }).toList();

      if (recruiters.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: AdminEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No recruiters found',
            subtitle: 'Try a different search term to find a hiring partner.',
            color: AppColors.secondary,
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
              final user = recruiters[itemIndex];
              return _RecruiterRow(
                user: user,
                controller: controller,
                isExpanded: expandedId == user.id,
                onToggle: () {
                  _expandedId.value = expandedId == user.id ? '' : user.id;
                },
              );
            },
            childCount: recruiters.isEmpty ? 0 : recruiters.length * 2 - 1,
          ),
        ),
      );
    });
  }
}

class _RecruiterRow extends StatelessWidget {
  final UserModel user;
  final AdminController controller;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _RecruiterRow({
    required this.user,
    required this.controller,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final jobs = controller.jobsByRecruiter(user.id);
    final applicants = controller.applicationsForRecruiter(user.id);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  AdminUserAvatar(
                    user: user,
                    size: 46,
                    accent: AppColors.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.business_rounded,
                              size: 13,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                user.companyName.isNotEmpty
                                    ? user.companyName
                                    : 'No company listed',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey[600],
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
                        '${jobs.length}',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'jobs • $applicants apps',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
if (isExpanded) ...[
            _buildJobs(jobs),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.person_rounded, size: 16),
                      label: const Text('View Account'),
                      onPressed: () {
                        Get.to(
                          () => CandidateProfileView(
                            candidateUser: user,
                            isAdminView: true,
                          ),
                          transition: Transition.rightToLeft,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.person_remove_rounded, size: 16),
                      label: const Text('Remove'),
                      onPressed: () => adminConfirmDeleteUser(user),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJobs(List<JobModel> jobs) {
    if (jobs.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'This recruiter has not posted any jobs yet.',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      children: [
        for (final job in jobs) _JobModerationTile(job: job, controller: controller),
      ],
    );
  }
}

class _JobModerationTile extends StatelessWidget {
  final JobModel job;
  final AdminController controller;

  const _JobModerationTile({required this.job, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isActive = job.isActive;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              size: 19,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line 1: Job Title
                Text(
                  job.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                // Line 2: Company Name
                Text(
                  job.companyName.isNotEmpty
                      ? (job.location.isNotEmpty
                          ? '${job.companyName} • ${job.location}'
                          : job.companyName)
                      : (job.location.isNotEmpty
                          ? job.location
                          : 'Company'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                // Line 3: Live, Edit, Pause, Delete
                Row(
                  children: [
                    // Status Badge (Live / Paused)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (isActive ? AppColors.secondary : AppColors.warning)
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.secondary : AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isActive ? 'Live' : 'Paused',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? AppColors.secondary
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Edit listing
                    IconButton(
                      tooltip: 'Edit listing',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 19,
                        color: AppColors.primary,
                      ),
                      onPressed: () => Get.find<JobController>().openJobEditor(job),
                    ),
                    const SizedBox(width: 4),
                    // Pause / Activate listing
                    IconButton(
                      tooltip: isActive ? 'Pause listing' : 'Activate listing',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        isActive
                            ? Icons.pause_circle_outline_rounded
                            : Icons.play_circle_outline_rounded,
                        size: 20,
                        color: isActive ? AppColors.warning : AppColors.secondary,
                      ),
                      onPressed: () => controller.toggleJobStatus(job.id),
                    ),
                    const SizedBox(width: 4),
                    // Remove listing
                    IconButton(
                      tooltip: 'Remove listing',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => _confirmDeleteJob(context, job),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteJob(BuildContext context, JobModel job) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Job Listing'),
        content: Text('Are you sure you want to remove "${job.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(dialogCtx);
              controller.removeJob(job.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _DeletedRecruiterRow extends StatelessWidget {
  final DeletedUserModel record;
  final AdminController controller;

  const _DeletedRecruiterRow({
    required this.record,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final jobsCount = record.jobsCount;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                  child: Text(
                    record.name.isNotEmpty ? record.name[0].toUpperCase() : 'R',
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.name.isNotEmpty ? record.name : 'Recruiter',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        record.email,
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Deleted',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.work_history_rounded,
                      size: 16, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      jobsCount > 0
                          ? '$jobsCount job post${jobsCount == 1 ? '' : 's'} backed up & ready to restore'
                          : 'No job posts recorded',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: Text(
                  jobsCount > 0
                      ? 'Restore Recruiter & $jobsCount Job${jobsCount == 1 ? '' : 's'}'
                      : 'Restore Recruiter Profile',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
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