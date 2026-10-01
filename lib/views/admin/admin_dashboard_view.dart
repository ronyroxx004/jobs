import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/job_controller.dart';
import '../../core/utils/constants.dart';
import '../../core/routes/app_routes.dart';
import '../../services/database_service.dart';
import 'admin_shared.dart';

class AdminDashboardView extends GetView<AdminController> {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final jobController = Get.find<JobController>();

    // Refresh status and deleted accounts list
    controller.refreshAccountDeletionAvailability();
    controller.refreshDeletedUsers();

    return RefreshIndicator(
      onRefresh: () async {
        final dbService = Get.find<DatabaseService>();
        await Future.wait([
          dbService.fetchAllData(),
          controller.refreshDeletedUsers(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Platform Administration',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'System analytics, job moderation & platform health',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                _buildDeletedUsersEntry(context, controller),
                _buildAuthDeletionBanner(context, controller),

                // Revenue & Metrics Overview
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Platform Revenue',
                        '\$12,450.00',
                        Icons.account_balance_wallet_rounded,
                        AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Active Jobs',
                        '${controller.totalJobs}',
                        Icons.work_rounded,
                        AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Applications',
                        '${controller.totalApplications}',
                        Icons.assignment_turned_in_rounded,
                        AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Mentors & Instructors',
                        '${controller.totalMentors + controller.totalCourses}',
                        Icons.groups_rounded,
                        AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Job Moderation List
                Text(
                  'Job Postings Moderation',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                Obx(() {
                  final jobs = jobController.allJobs;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.business, color: Colors.white, size: 20),
                          ),
                          title: Text(job.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('${job.companyName} • ${job.location}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline, color: AppColors.secondary),
                                tooltip: 'Approve',
                                onPressed: () => controller.toggleJobStatus(job.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Remove',
                                onPressed: () => controller.removeJob(job.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),

                const SizedBox(height: 24),

                // User Management List (All Users, Recruiters, Mentors, Instructors)
                Text(
                  'Platform Users Management',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage all users, recruiters, mentors, and instructors',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 10),

                Obx(() {
                  final users = controller.allUsers;
                  if (users.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text('No users found', style: GoogleFonts.inter(color: Colors.grey)),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                              style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(user.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('${user.email}\nRole: ${user.role.displayName}'),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Delete User',
                            onPressed: () => adminConfirmDeleteUser(user),
                          ),
                        ),
                      );
                    },
                  );
                }),

                const SizedBox(height: 24),
                // End of page refresh section
                Center(
                  child: Column(
                    children: [
                      Text(
                        "You've reached the end of administration panel",
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Entry point to the restore list for accounts an admin has removed.
  Widget _buildDeletedUsersEntry(
      BuildContext context, AdminController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Obx(
        () => InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.toNamed(AppRoutes.adminDeletedUsers),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.restore_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deleted Users',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${controller.deletedUsers.length} account'
                        '${controller.deletedUsers.length == 1 ? '' : 's'} '
                        'can be restored',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Warns when Firebase Auth accounts cannot be deleted yet, because the
  /// deleteUserAccount Cloud Function is not deployed.
  Widget _buildAuthDeletionBanner(
      BuildContext context, AdminController controller) {
    return Obx(() {
      if (controller.canDeleteAuthAccounts.value) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auth deletion unavailable',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Deleting a user clears Realtime Database now, but their '
                      'Firebase login stays until the deleteUserAccount '
                      'function is deployed (needs the Blaze plan):\n'
                      'firebase deploy --only functions',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        height: 1.5,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Check again',
                icon: const Icon(Icons.refresh_rounded,
                    size: 18, color: AppColors.warning),
                onPressed: controller.refreshAccountDeletionAvailability,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
