import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/admin_controller.dart';
import '../../core/utils/constants.dart';
import '../../models/user_model.dart';
import '../../models/job_model.dart';
import '../../services/database_service.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    return RefreshIndicator(
      onRefresh: () => Get.find<DatabaseService>().fetchAllData(),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(controller),
            _buildSearch(),
            Expanded(child: _buildRecruiterList(controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AdminController controller) {
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

  Widget _buildRecruiterList(AdminController controller) {
    return Obx(() {
      // Read both observables up-front: ListView builds items lazily, so reads
      // inside itemBuilder are outside Obx's reactive scope and would never
      // trigger a rebuild.
      final query = _query.value;
      final expandedId = _expandedId.value;

      final recruiters = controller.recruiters.where((user) {
        final jobs = controller.jobsByRecruiter(user.id);
        return adminMatchesQuery(query, [
          user.name,
          user.email,
          user.phone,
          user.companyName,
          ...jobs.map((j) => j.title),
        ]);
      }).toList();

      if (recruiters.isEmpty) {
        return const AdminEmptyState(
          icon: Icons.search_off_rounded,
          title: 'No recruiters found',
          subtitle: 'Try a different search term to find a hiring partner.',
          color: AppColors.secondary,
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: recruiters.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final user = recruiters[index];
          return _RecruiterRow(
            user: user,
            controller: controller,
            isExpanded: expandedId == user.id,
            onToggle: () {
              _expandedId.value = expandedId == user.id ? '' : user.id;
            },
          );
        },
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
                      onPressed: () => adminShowUserActions(
                        context,
                        user,
                        accent: AppColors.secondary,
                      ),
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
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${job.location} • ${job.jobType} • ${job.applicantCount} applicants',
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
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isActive ? AppColors.secondary : Colors.grey)
                  .withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isActive ? 'Live' : 'Paused',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isActive ? AppColors.secondary : Colors.grey[700],
              ),
            ),
          ),
          IconButton(
            tooltip: isActive ? 'Pause listing' : 'Approve listing',
            icon: Icon(
              isActive ? Icons.pause_circle_outline : Icons.check_circle_outline,
              size: 20,
              color: isActive ? AppColors.warning : AppColors.secondary,
            ),
            onPressed: () => controller.toggleJobStatus(job.id),
          ),
          IconButton(
            tooltip: 'Remove listing',
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: Colors.redAccent,
            ),
            onPressed: () => controller.removeJob(job.id),
          ),
        ],
      ),
    );
  }
}