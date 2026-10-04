import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../controllers/admin_controller.dart';
import '../../core/utils/constants.dart';
import '../../models/broadcast_notification_model.dart';
import 'admin_broadcast_dialog.dart';
import 'admin_shared.dart';

class AdminNotificationHistoryView extends StatefulWidget {
  const AdminNotificationHistoryView({super.key});

  @override
  State<AdminNotificationHistoryView> createState() =>
      _AdminNotificationHistoryViewState();
}

class _AdminNotificationHistoryViewState
    extends State<AdminNotificationHistoryView> {
  final TextEditingController _searchController = TextEditingController();
  final RxString _query = ''.obs;
  final RxString _selectedAudience = 'All'.obs;

  static const List<String> _filters = [
    'All',
    'All Users',
    'Candidates',
    'Recruiters',
    'Mentors',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(
      BuildContext context, AdminController controller, String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Notification?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to remove "$title" from notification history?',
          style: GoogleFonts.inter(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.deleteBroadcastNotification(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmQuickResend(BuildContext context, AdminController controller,
      BroadcastNotificationModel notification) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.replay_rounded,
                  color: AppColors.secondary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Resend Broadcast?',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This notification will be broadcast again to ${notification.targetAudience}.',
              style: GoogleFonts.inter(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
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
                    notification.title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              AdminBroadcastDialog.show(
                context,
                existing: notification,
                isResend: true,
              );
            },
            child: const Text('Edit & Resend'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.resendBroadcastNotification(notification);
            },
            child: const Text('Resend Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification History',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Obx(
              () => Text(
                '${controller.broadcastNotifications.length} broadcast${controller.broadcastNotifications.length == 1 ? '' : 's'} sent',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              icon: const Icon(Icons.campaign_rounded, size: 16),
              label: const Text('New Broadcast'),
              onPressed: () => AdminBroadcastDialog.show(context),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: AdminSearchField(
                controller: _searchController,
                hint: 'Search title, message or audience...',
                onChanged: (val) => _query.value = val,
                onClear: () {
                  _searchController.clear();
                  _query.value = '';
                },
              ),
            ),

            // Audience Filter Chips
            SizedBox(
              height: 38,
              child: Obx(
                () {
                  final active = _selectedAudience.value;
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final label = _filters[index];
                      final isSelected = active == label;
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (_) => _selectedAudience.value = label,
                        selectedColor: AppColors.primary,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                        backgroundColor: isDark
                            ? const Color(0xFF27273A)
                            : Colors.grey.withValues(alpha: 0.08),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.borderLight,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Notifications List
            Expanded(
              child: Obx(() {
                final query = _query.value.trim().toLowerCase();
                final filter = _selectedAudience.value;

                final list = controller.broadcastNotifications.where((n) {
                  final matchesFilter =
                      filter == 'All' || n.targetAudience == filter;
                  if (!matchesFilter) return false;

                  if (query.isEmpty) return true;
                  return n.title.toLowerCase().contains(query) ||
                      n.body.toLowerCase().contains(query) ||
                      n.targetAudience.toLowerCase().contains(query);
                }).toList();

                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_off_rounded,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            controller.broadcastNotifications.isEmpty
                                ? 'No Broadcast Notifications Yet'
                                : 'No Matching Notifications',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            controller.broadcastNotifications.isEmpty
                                ? 'Send your first broadcast announcement with push notification to all users.'
                                : 'Try searching for different keywords or change the audience filter.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (controller.broadcastNotifications.isEmpty) ...[
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.campaign_rounded, size: 18),
                              label: const Text('Send First Broadcast'),
                              onPressed: () =>
                                  AdminBroadcastDialog.show(context),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return _NotificationHistoryCard(
                      notification: item,
                      onEdit: () => AdminBroadcastDialog.show(
                        context,
                        existing: item,
                        isResend: false,
                      ),
                      onResend: () =>
                          _confirmQuickResend(context, controller, item),
                      onDelete: () => _confirmDelete(
                          context, controller, item.id, item.title),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationHistoryCard extends StatelessWidget {
  final BroadcastNotificationModel notification;
  final VoidCallback onEdit;
  final VoidCallback onResend;
  final VoidCallback onDelete;

  const _NotificationHistoryCard({
    required this.notification,
    required this.onEdit,
    required this.onResend,
    required this.onDelete,
  });

  Color _audienceColor(String aud) {
    switch (aud) {
      case 'Candidates':
        return AppColors.primary;
      case 'Recruiters':
        return AppColors.secondary;
      case 'Mentors':
        return AppColors.warning;
      default:
        return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final audColor = _audienceColor(notification.targetAudience);
    final dateStr =
        DateFormat('MMM d, yyyy • h:mm a').format(notification.createdAt);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? Colors.white12 : AppColors.borderLight,
        ),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Megaphone icon, Title, Status & Audience badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: audColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.campaign_rounded,
                      color: audColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // Audience badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: audColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              notification.targetAudience,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: audColor,
                              ),
                            ),
                          ),
                          // Push badge
                          if (notification.sendPush)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.notifications_active_rounded,
                                      size: 10, color: Color(0xFF059669)),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Push Delivered',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Resent badge
                          if (notification.resendCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Resent ${notification.resendCount}x',
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
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red, size: 20),
                  tooltip: 'Delete Notification',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Message Body Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF27273A)
                    : Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                notification.body,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? Colors.grey[200] : Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Meta Info: Timestamp & Sent by
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 13, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
                ),
                const Spacer(),
                if (notification.recipientCount > 0) ...[
                  Icon(Icons.people_alt_outlined,
                      size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${notification.recipientCount} recipients',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Actions: Edit and Resend Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onResend,
                    icon: const Icon(Icons.replay_rounded, size: 15),
                    label: const Text('Resend'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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
