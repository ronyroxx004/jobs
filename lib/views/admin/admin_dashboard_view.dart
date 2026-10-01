import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/job_controller.dart';
import '../../core/utils/constants.dart';
import '../../services/database_service.dart';
import 'admin_shared.dart';

class AdminDashboardView extends GetView<AdminController> {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final jobController = Get.find<JobController>();

    return RefreshIndicator(
      onRefresh: () async {
        final dbService = Get.find<DatabaseService>();
        await dbService.fetchAllData();
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
