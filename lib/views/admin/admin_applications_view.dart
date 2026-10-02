import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/admin_controller.dart';
import '../../core/utils/constants.dart';
import '../../models/application_model.dart';
import '../../services/database_service.dart';
import 'admin_shared.dart';

/// Admin view displaying all candidate job applications with search, status filtering,
/// stage updating, details modal, editing, and deletion capabilities.
class AdminApplicationsView extends StatefulWidget {
  const AdminApplicationsView({super.key});

  @override
  State<AdminApplicationsView> createState() => _AdminApplicationsViewState();
}

class _AdminApplicationsViewState extends State<AdminApplicationsView> {
  final TextEditingController _searchController = TextEditingController();
  final RxString _query = ''.obs;
  final Rx<ApplicationStatus?> _selectedStatus = Rx<ApplicationStatus?>(null);

  late final ScrollController _scrollController;

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
    final dbService = Get.find<DatabaseService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Candidate Applications',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh applications',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => dbService.fetchAllData(),
          ),
        ],
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
              _buildApplicationsList(adminController, dbService),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(DatabaseService dbService) {
    return Obx(() {
      final allApps = dbService.applicationsList;
      final totalApps = allApps.length;
      final shortlistedOrInterview = allApps.where((a) =>
          a.status == ApplicationStatus.shortlisted ||
          a.status == ApplicationStatus.interviewing).length;
      final offeredCount = allApps
          .where((a) => a.status == ApplicationStatus.offered)
          .length;

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
                      colors: [AppColors.accent, Color(0xFFEA580C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in_rounded,
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
                        'Platform Applications',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Monitor, update stage, edit details, or remove submissions',
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
                    title: 'Total Applications',
                    value: '$totalApps',
                    accent: AppColors.accent,
                    icon: Icons.description_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatMiniCard(
                    title: 'In Pipeline',
                    value: '$shortlistedOrInterview',
                    accent: AppColors.primary,
                    icon: Icons.next_plan_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatMiniCard(
                    title: 'Offers Made',
                    value: '$offeredCount',
                    accent: AppColors.secondary,
                    icon: Icons.check_circle_outline_rounded,
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
                hintText: 'Search by candidate, role, company, skills...',
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
                    color: AppColors.accent,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Horizontal Status Filter Chips
          SizedBox(
            height: 38,
            child: Obx(() {
              final selected = _selectedStatus.value;
              return ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(
                        'All Status',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: selected == null
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected == null ? Colors.white : null,
                        ),
                      ),
                      selected: selected == null,
                      selectedColor: AppColors.accent,
                      checkmarkColor: Colors.white,
                      onSelected: (_) => _selectedStatus.value = null,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  ...ApplicationStatus.values.map((status) {
                    final isSelected = selected == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(
                          status.label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? Colors.white : status.color,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: status.color,
                        checkmarkColor: Colors.white,
                        onSelected: (_) => _selectedStatus.value = status,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsList(
    AdminController adminController,
    DatabaseService dbService,
  ) {
    return Obx(() {
      final query = _query.value.trim().toLowerCase();
      final statusFilter = _selectedStatus.value;

      final filtered = dbService.applicationsList.where((app) {
        final matchesQuery = query.isEmpty ||
            app.candidateName.toLowerCase().contains(query) ||
            app.candidateEmail.toLowerCase().contains(query) ||
            app.candidatePhone.toLowerCase().contains(query) ||
            app.jobTitle.toLowerCase().contains(query) ||
            app.companyName.toLowerCase().contains(query) ||
            app.candidateLocation.toLowerCase().contains(query) ||
            app.candidateSkills.any((s) => s.toLowerCase().contains(query));

        final matchesStatus =
            statusFilter == null || app.status == statusFilter;

        return matchesQuery && matchesStatus;
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
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_late_outlined,
                      size: 40,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No applications found',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    query.isNotEmpty || statusFilter != null
                        ? 'Try adjusting your search terms or filters.'
                        : 'No candidate applications have been submitted yet.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (query.isNotEmpty || statusFilter != null) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        _query.value = '';
                        _selectedStatus.value = null;
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
            final app = filtered[index];
            return _AdminApplicantCard(
              application: app,
              adminController: adminController,
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

class _AdminApplicantCard extends StatelessWidget {
  final ApplicationModel application;
  final AdminController adminController;

  const _AdminApplicantCard({
    required this.application,
    required this.adminController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final app = application;
    final candidateName = app.candidateName.trim().isEmpty
        ? 'Candidate'
        : app.candidateName.trim();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
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
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showApplicantDetails(context, app),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Avatar, Name, Job Title & Company
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      backgroundImage: app.candidateAvatar.isNotEmpty
                          ? NetworkImage(app.candidateAvatar)
                          : null,
                      child: app.candidateAvatar.isEmpty
                          ? Text(
                              candidateName.substring(0, 1).toUpperCase(),
                              style: GoogleFonts.inter(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            candidateName,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            app.jobTitle.isNotEmpty
                                ? app.jobTitle
                                : (app.candidateHeadline.isNotEmpty
                                    ? app.candidateHeadline
                                    : 'Applicant'),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.business_rounded,
                                  size: 13, color: Colors.grey),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  app.companyName.isNotEmpty
                                      ? app.companyName
                                      : 'Platform Role',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status picker button
                    _StatusPicker(
                      status: app.status,
                      onChanged: (newStatus) =>
                          adminController.updateApplicationStage(app.id, newStatus),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Info Pills (Experience & Location)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.bgDark : AppColors.bgLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.work_outline_rounded,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Exp: ',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              '${app.candidateExperienceYears} yrs',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: AppColors.secondary),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                app.candidateLocation.isNotEmpty
                                    ? app.candidateLocation
                                    : 'Remote',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Skills tags preview
                if (app.candidateSkills.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      ...app.candidateSkills.take(3).map((skill) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
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
                      if (app.candidateSkills.length > 3)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${app.candidateSkills.length - 3}',
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

                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 6),

                // Actions Row: View Details, Edit Application, Delete
                Row(
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: Text(
                        'View Details',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => _showApplicantDetails(context, app),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(
                        'Edit',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => _showEditDialog(context, app),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Delete application',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      onPressed: () => _confirmDeleteApplication(context, app),
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

  void _showApplicantDetails(BuildContext context, ApplicationModel app) {
    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        backgroundImage: app.candidateAvatar.isNotEmpty
                            ? NetworkImage(app.candidateAvatar)
                            : null,
                        child: app.candidateAvatar.isEmpty
                            ? Text(
                                app.candidateName.trim().isEmpty
                                    ? 'C'
                                    : app.candidateName.trim()[0].toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.candidateName.isEmpty
                                  ? 'Candidate'
                                  : app.candidateName,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              app.jobTitle.isNotEmpty
                                  ? app.jobTitle
                                  : 'Candidate',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              app.companyName,
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
                  const SizedBox(height: 16),
                  _DetailRow(icon: Icons.email_outlined, label: 'Email', value: app.candidateEmail),
                  if (app.candidatePhone.isNotEmpty)
                    _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: app.candidatePhone),
                  _DetailRow(icon: Icons.location_on_outlined, label: 'Location', value: app.candidateLocation.isNotEmpty ? app.candidateLocation : 'Remote'),
                  _DetailRow(icon: Icons.work_outline, label: 'Experience', value: '${app.candidateExperienceYears} years'),
                  _DetailRow(icon: Icons.flag_outlined, label: 'Status', value: app.status.label),

                  if (app.candidateHeadline.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Headline', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(app.candidateHeadline, style: GoogleFonts.inter(fontSize: 13)),
                  ],

                  if (app.candidateBio.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Bio', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(app.candidateBio, style: GoogleFonts.inter(fontSize: 13)),
                  ],

                  if (app.candidateSkills.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Key Skills', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: app.candidateSkills
                          .map((skill) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  skill,
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                                ),
                              ))
                          .toList(),
                    ),
                  ],

                  if (app.coverLetter.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text('Cover Letter / Notes', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(app.coverLetter, style: GoogleFonts.inter(fontSize: 12, height: 1.4)),
                    ),
                  ],

                  // Resume Section
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Submitted Resume', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                        const SizedBox(height: 4),
                        Text(app.resumeName.isNotEmpty ? app.resumeName : 'Resume.pdf', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                        if (app.resumeUrl.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: app.resumeUrl));
                              Get.snackbar('Resume link copied', 'The resume URL has been copied to your clipboard.', snackPosition: SnackPosition.BOTTOM);
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Copy resume link'),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, ApplicationModel app) {
    final statusVal = app.status.obs;
    final headlineController = TextEditingController(text: app.candidateHeadline);
    final expController = TextEditingController(text: '${app.candidateExperienceYears}');
    final locationController = TextEditingController(text: app.candidateLocation);
    final phoneController = TextEditingController(text: app.candidatePhone);
    final coverLetterController = TextEditingController(text: app.coverLetter);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Edit Application',
                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Candidate: ${app.candidateName}',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Job: ${app.jobTitle} • ${app.companyName}',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),

                // Application Status selector
                Text('Application Status / Stage', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Obx(() => DropdownButtonFormField<ApplicationStatus>(
                      initialValue: statusVal.value,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: ApplicationStatus.values
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) statusVal.value = val;
                      },
                    )),

                const SizedBox(height: 12),
                Text('Headline / Title', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: headlineController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Exp (Years)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: expController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Location', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: locationController,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Text('Phone Number', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),

                const SizedBox(height: 12),
                Text('Cover Letter / Notes', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: coverLetterController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final expYears = int.tryParse(expController.text.trim()) ?? app.candidateExperienceYears;
              final updatedApp = app.copyWith(
                status: statusVal.value,
                candidateHeadline: headlineController.text.trim(),
                candidateExperienceYears: expYears,
                candidateLocation: locationController.text.trim(),
                candidatePhone: phoneController.text.trim(),
                coverLetter: coverLetterController.text.trim(),
              );
              Navigator.of(ctx).pop();
              await adminController.updateApplication(updatedApp);
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteApplication(BuildContext context, ApplicationModel app) {
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
                'Delete Application?',
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
              'Are you sure you want to permanently delete this application submission?',
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
                    app.candidateName,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${app.jobTitle} • ${app.companyName}',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This record will be removed from Realtime Database and the job applicant count will be updated.',
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
              await adminController.deleteApplication(app.id);
            },
            child: Text(
              'Delete Application',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPicker extends StatelessWidget {
  final ApplicationStatus status;
  final ValueChanged<ApplicationStatus> onChanged;

  const _StatusPicker({
    required this.status,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ApplicationStatus>(
      initialValue: status,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => ApplicationStatus.values
          .map(
            (value) => PopupMenuItem(
              value: value,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: value.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    value.label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: status.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: status.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              status.label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: status.color,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.expand_more, size: 14, color: status.color),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }
}
