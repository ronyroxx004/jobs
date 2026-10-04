import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/admin_controller.dart';
import '../../core/utils/constants.dart';
import '../../core/routes/app_routes.dart';
import '../../services/database_service.dart';
import 'admin_broadcast_dialog.dart';

class AdminDashboardView extends GetView<AdminController> {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final dbService = Get.find<DatabaseService>();
        await Future.wait([
          dbService.fetchAllData(),
          controller.refreshDeletedUsers(silent: true),
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
                  'System analytics & platform health',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // Revenue & Metrics Overview
                Obx(() => Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Platform Revenue',
                        '₹${controller.totalMentorshipRevenue.toStringAsFixed(0)}',
                        Icons.account_balance_wallet_rounded,
                        AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Active Jobs',
                        '${controller.activeJobs}',
                        Icons.work_rounded,
                        AppColors.primary,
                        onTap: () => Get.toNamed(
                          AppRoutes.adminJobs,
                          arguments: {'status': 'Live'},
                        ),
                        subtitle: '${controller.totalJobs} total • View all →',
                      ),
                    ),
                  ],
                )),
                const SizedBox(height: 12),
                Obx(() => Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Applications',
                        '${controller.totalApplications}',
                        Icons.assignment_turned_in_rounded,
                        AppColors.accent,
                        onTap: () => Get.toNamed(AppRoutes.adminApplications),
                        subtitle: 'Tap to view all →',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Mentors',
                        '${controller.mentors.length}',
                        Icons.psychology_rounded,
                        AppColors.warning,
                        onTap: () => Get.toNamed(
                          AppRoutes.adminMentors,
                          arguments: {'tab': 'All Posts'},
                        ),
                        subtitle:
                            '${Get.find<DatabaseService>().servicesList.length} services • View all →',
                      ),
                    ),
                  ],
                )),
                const SizedBox(height: 20),

                // Broadcast Message to All Button
                _buildBroadcastMessageEntry(context, controller),
                const SizedBox(height: 12),

                // Notification History Button (Edit & Resend)
                _buildNotificationHistoryEntry(context, controller),
                const SizedBox(height: 12),

                // Deleted Users Entry
                _buildDeletedUsersEntry(context, controller),
                const SizedBox(height: 16),
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
    return Obx(
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
    );
  }

  /// Entry point to compose and send broadcast push notifications to all users.
  Widget _buildBroadcastMessageEntry(
      BuildContext context, AdminController controller) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => AdminBroadcastDialog.show(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.campaign_rounded,
                color: Colors.white,
                size: 24,
              ),
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
                          'Broadcast Message to All',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PUSH',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Compose push notification & announcement for all users',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Entry point to view, edit, and resend broadcast notifications.
  Widget _buildNotificationHistoryEntry(
      BuildContext context, AdminController controller) {
    return Obx(
      () {
        final count = controller.broadcastNotifications.length;
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.toNamed(AppRoutes.adminNotificationHistory),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history_toggle_off_rounded,
                      color: AppColors.secondary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notification History',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        count == 0
                            ? 'No broadcast history yet • Tap to view'
                            : '$count broadcast${count == 1 ? '' : 's'} recorded • Edit & Resend',
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
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
    String? subtitle,
  }) {
    final isClickable = onTap != null;
    return Card(
      elevation: isClickable ? 2 : 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isClickable
            ? BorderSide(color: color.withValues(alpha: 0.35), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (isClickable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_forward_rounded,
                              size: 12, color: color),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isClickable ? FontWeight.w700 : FontWeight.w500,
                  color: isClickable ? color : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
