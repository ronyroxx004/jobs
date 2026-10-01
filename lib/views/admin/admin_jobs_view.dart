import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/admin_controller.dart';
import '../../controllers/job_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/constants.dart';
import '../../models/job_model.dart';
import '../../services/database_service.dart';
import 'admin_shared.dart';

/// Admin view displaying all job postings with real-time search, filtering,
/// editing, status toggling, and deletion capabilities.
class AdminJobsView extends StatefulWidget {
  const AdminJobsView({super.key});

  @override
  State<AdminJobsView> createState() => _AdminJobsViewState();
}

class _AdminJobsViewState extends State<AdminJobsView> {
  final TextEditingController _searchController = TextEditingController();
  final RxString _query = ''.obs;
  final RxString _selectedType = 'All'.obs;
  final RxString _selectedStatus = 'All'.obs;

  late final ScrollController _scrollController;

  static const List<String> _typeFilters = [
    'All',
    'Full-time',
    'Part-time',
    'Remote',
    'Contract',
    'Internship',
  ];

  static const List<String> _statusFilters = [
    'All',
    'Live',
    'Paused',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminController = Get.find<AdminController>();
    final jobController = Get.find<JobController>();
    final dbService = Get.find<DatabaseService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Job Postings',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh jobs',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => dbService.fetchAllData(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Post Job',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        onPressed: () => jobController.openJobEditor(null),
      ),
      body: RefreshIndicator(
        onRefresh: () => dbService.fetchAllData(),
        child: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(dbService),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: AdminPinnedHeaderDelegate(
                  height: 104,
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: _buildFilterBar(),
                  ),
                ),
              ),
              _buildJobsList(adminController, jobController, dbService),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(DatabaseService dbService) {
    return Obx(() {
      final allJobs = dbService.jobsList;
      final totalJobs = allJobs.length;
      final liveJobs = allJobs.where((j) => j.isActive).length;
      final totalApplicants = allJobs.fold(0, (sum, j) => sum + j.applicantCount);

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
                      colors: [AppColors.primary, Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.work_rounded,
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
                        'Platform Job Listings',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Review, edit, pause, and delete all jobs across recruiters',
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
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatMiniCard(
                    title: 'Total Jobs',
                    value: '$totalJobs',
                    accent: AppColors.primary,
                    icon: Icons.work_outline_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatMiniCard(
                    title: 'Live Jobs',
                    value: '$liveJobs',
                    accent: AppColors.secondary,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatMiniCard(
                    title: 'Applicants',
                    value: '$totalApplicants',
                    accent: AppColors.accent,
                    icon: Icons.people_outline_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Column(
        children: [
          // Search box
          SizedBox(
            height: 42,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => _query.value = val,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search by title, company, recruiter, location...',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: Obx(
                  () => _query.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _query.value = '';
                          },
                        )
                      : const SizedBox.shrink(),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.25),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.25),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Horizontal Filter Chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._statusFilters.map((status) => Obx(() {
                      final isSelected = _selectedStatus.value == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(
                            status == 'All' ? 'All Status' : status,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (status == 'Live'
                                      ? AppColors.secondary
                                      : (status == 'Paused'
                                          ? AppColors.warning
                                          : null)),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: status == 'Live'
                              ? AppColors.secondary
                              : (status == 'Paused'
                                  ? AppColors.warning
                                  : AppColors.primary),
                          checkmarkColor: Colors.white,
                          onSelected: (_) => _selectedStatus.value = status,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    })),
                const VerticalDivider(width: 12, indent: 6, endIndent: 6),
                ..._typeFilters.map((type) => Obx(() {
                      final isSelected = _selectedType.value == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(
                            type == 'All' ? 'All Types' : type,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected ? Colors.white : null,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.white,
                          onSelected: (_) => _selectedType.value = type,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    })),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList(
    AdminController adminController,
    JobController jobController,
    DatabaseService dbService,
  ) {
    return Obx(() {
      final query = _query.value.trim().toLowerCase();
      final typeFilter = _selectedType.value;
      final statusFilter = _selectedStatus.value;

      final filtered = dbService.jobsList.where((job) {
        // Query match
        final matchesQuery = query.isEmpty ||
            job.title.toLowerCase().contains(query) ||
            job.companyName.toLowerCase().contains(query) ||
            job.location.toLowerCase().contains(query) ||
            job.recruiterName.toLowerCase().contains(query) ||
            job.skills.any((s) => s.toLowerCase().contains(query));

        // Type match
        final matchesType = typeFilter == 'All' ||
            job.jobType.toLowerCase() == typeFilter.toLowerCase();

        // Status match
        final matchesStatus = statusFilter == 'All' ||
            (statusFilter == 'Live' && job.isActive) ||
            (statusFilter == 'Paused' && !job.isActive);

        return matchesQuery && matchesType && matchesStatus;
      }).toList();

      if (filtered.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.work_off_outlined,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No job postings found',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    query.isNotEmpty || typeFilter != 'All' || statusFilter != 'All'
                        ? 'Try adjusting your search terms or filters.'
                        : 'No jobs have been posted on the platform yet.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (query.isNotEmpty ||
                      typeFilter != 'All' ||
                      statusFilter != 'All') ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        _query.value = '';
                        _selectedType.value = 'All';
                        _selectedStatus.value = 'All';
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Reset filters'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final job = filtered[index];
            return _JobCard(
              job: job,
              adminController: adminController,
              jobController: jobController,
            );
          },
          childCount: filtered.length,
        ),
      );
    });
  }
}

class _StatMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;
  final IconData icon;

  const _StatMiniCard({
    required this.title,
    required this.value,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  final AdminController adminController;
  final JobController jobController;

  const _JobCard({
    required this.job,
    required this.adminController,
    required this.jobController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = job.isActive;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))
              : Colors.amber.withValues(alpha: 0.4),
          width: isActive ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.toNamed(AppRoutes.jobDetails, arguments: job),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Company Icon, Title, and Live/Paused Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.8),
                            AppColors.primary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          job.companyName.isNotEmpty
                              ? job.companyName[0].toUpperCase()
                              : 'J',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  job.companyName,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (job.location.isNotEmpty) ...[
                                Text(' • ', style: TextStyle(color: Colors.grey[500])),
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    job.location,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isActive ? AppColors.secondary : AppColors.warning)
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
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
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isActive ? AppColors.secondary : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Tags row (Job Type, Salary, Experience, Applicants)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _InfoTag(
                      icon: Icons.schedule_rounded,
                      label: job.jobType,
                      color: AppColors.primary,
                    ),
                    if (job.salaryRange.isNotEmpty)
                      _InfoTag(
                        icon: Icons.payments_outlined,
                        label: job.salaryRange,
                        color: AppColors.secondary,
                      ),
                    if (job.experienceLevel.isNotEmpty)
                      _InfoTag(
                        icon: Icons.trending_up_rounded,
                        label: job.experienceLevel,
                        color: const Color(0xFF6366F1),
                      ),
                    _InfoTag(
                      icon: Icons.people_alt_outlined,
                      label: '${job.applicantCount} applicants',
                      color: AppColors.accent,
                    ),
                  ],
                ),

                // Recruiter attribution & date
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Recruiter: ${job.recruiterName.isNotEmpty ? job.recruiterName : "Admin"}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Skills tags (up to 4)
                if (job.skills.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      ...job.skills.take(4).map((skill) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              skill,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          )),
                      if (job.skills.length > 4)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${job.skills.length - 4}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Action Buttons Bar (View, Edit, Toggle, Delete)
                Row(
                  children: [
                    // View details
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: Text(
                        'View',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => Get.toNamed(AppRoutes.jobDetails, arguments: job),
                    ),
                    const SizedBox(width: 4),

                    // Edit button
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(
                        'Edit',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => jobController.openJobEditor(job),
                    ),

                    const Spacer(),

                    // Pause / Activate toggle
                    IconButton(
                      tooltip: isActive ? 'Pause listing' : 'Activate listing',
                      icon: Icon(
                        isActive
                            ? Icons.pause_circle_outline_rounded
                            : Icons.play_circle_outline_rounded,
                        color: isActive ? AppColors.warning : AppColors.secondary,
                        size: 22,
                      ),
                      onPressed: () => adminController.toggleJobStatus(job.id),
                    ),

                    // Delete job button
                    IconButton(
                      tooltip: 'Delete job',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 22,
                      ),
                      onPressed: () => _confirmDeleteJob(context, job),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteJob(BuildContext context, JobModel job) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Delete Job Listing?',
                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete this job listing?',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[800]),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${job.companyName} • ${job.location}',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This listing will be removed from Realtime Database and candidate feeds immediately.',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.red[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await adminController.removeJob(job.id);
            },
            child: Text(
              'Delete Job',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
