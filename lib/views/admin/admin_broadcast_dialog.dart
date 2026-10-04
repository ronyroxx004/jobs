import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/admin_controller.dart';
import '../../core/utils/constants.dart';
import '../../models/broadcast_notification_model.dart';

class AdminBroadcastDialog extends StatefulWidget {
  final BroadcastNotificationModel? existing;
  final bool isResend;

  const AdminBroadcastDialog({
    super.key,
    this.existing,
    this.isResend = false,
  });

  static Future<void> show(
    BuildContext context, {
    BroadcastNotificationModel? existing,
    bool isResend = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AdminBroadcastDialog(
        existing: existing,
        isResend: isResend,
      ),
    );
  }

  @override
  State<AdminBroadcastDialog> createState() => _AdminBroadcastDialogState();
}

class _AdminBroadcastDialogState extends State<AdminBroadcastDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late String _targetAudience;
  late bool _sendPush;
  bool _isSubmitting = false;

  final List<String> _audiences = const [
    'All Users',
    'Candidates',
    'Recruiters',
    'Mentors',
  ];

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existing?.title ?? '');
    _bodyController = TextEditingController(text: widget.existing?.body ?? '');
    _targetAudience = widget.existing?.targetAudience ?? 'All Users';
    _sendPush = widget.existing?.sendPush ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final controller = Get.find<AdminController>();

    bool success;
    if (widget.existing != null && !widget.isResend) {
      success = await controller.updateBroadcastNotification(
        widget.existing!,
        title: _titleController.text,
        body: _bodyController.text,
        targetAudience: _targetAudience,
        sendPush: _sendPush,
      );
    } else if (widget.isResend && widget.existing != null) {
      success = await controller.resendBroadcastNotification(
        widget.existing!,
        updatedTitle: _titleController.text,
        updatedBody: _bodyController.text,
      );
    } else {
      success = await controller.sendBroadcastNotification(
        title: _titleController.text,
        body: _bodyController.text,
        targetAudience: _targetAudience,
        sendPush: _sendPush,
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
        Get.snackbar(
          'Broadcast Sent',
          'Notification dispatched to $_targetAudience successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF065F46),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
        );
      } else {
        Get.snackbar(
          'Broadcast Failed',
          'Could not send notification. Please verify Firebase Realtime Database rules.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade800,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.existing != null && !widget.isResend;
    final isResending = widget.isResend;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isResending
                            ? [AppColors.secondary, const Color(0xFF065F46)]
                            : [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isResending
                          ? Icons.replay_rounded
                          : (isEditing
                              ? Icons.edit_note_rounded
                              : Icons.campaign_rounded),
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
                          isResending
                              ? 'Resend Broadcast'
                              : (isEditing
                                  ? 'Edit Broadcast Message'
                                  : 'Broadcast Message to All'),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          isResending
                              ? 'Review and deliver this message again'
                              : (isEditing
                                  ? 'Update the recorded notification message'
                                  : 'Deliver instant push notification to all users'),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 18),

              // Title Field
              Text(
                'Notification Title',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                maxLength: 80,
                decoration: InputDecoration(
                  hintText: 'e.g. System Update / New Mentorship Features',
                  prefixIcon: const Icon(Icons.title_rounded, size: 20),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF27273A)
                      : Colors.grey.withValues(alpha: 0.07),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a notification title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Body Field
              Text(
                'Message Body',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _bodyController,
                minLines: 3,
                maxLines: 5,
                maxLength: 400,
                decoration: InputDecoration(
                  hintText:
                      'Type the full message announcement for users here...',
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF27273A)
                      : Colors.grey.withValues(alpha: 0.07),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the message body';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Target Audience Selector
              Text(
                'Target Audience',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _audiences.map((aud) {
                  final isSelected = _targetAudience == aud;
                  return ChoiceChip(
                    label: Text(aud),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _targetAudience = aud);
                      }
                    },
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
                            : Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Push Notification Switch
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF27273A)
                      : Colors.grey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _sendPush
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Send Push Notification',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Deliver as immediate push notification to user devices',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  value: _sendPush,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _sendPush = val),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                ),
              ),
              const SizedBox(height: 22),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _handleSend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isResending
                            ? AppColors.secondary
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isResending
                                  ? Icons.replay_rounded
                                  : (isEditing
                                      ? Icons.check_rounded
                                      : Icons.send_rounded),
                              size: 18,
                            ),
                      label: Text(
                        _isSubmitting
                            ? 'Sending...'
                            : (isResending
                                ? 'Resend Broadcast'
                                : (isEditing
                                    ? 'Save Changes'
                                    : 'Send Broadcast')),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
