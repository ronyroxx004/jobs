import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/mentorship_controller.dart';
import '../../services/database_service.dart';
import '../../models/service_model.dart';
import '../../core/utils/constants.dart';

class MentorBookingsView extends GetView<MentorshipController> {
  const MentorBookingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        final dbService = Get.find<DatabaseService>();
        await Future.wait([
          dbService.fetchServices().timeout(DatabaseService.readTimeout, onTimeout: () => dbService.servicesList),
          dbService.fetchBookings().timeout(DatabaseService.readTimeout, onTimeout: () => dbService.bookingsList),
        ]);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header + Availability Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bookings & Calendar',
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Scheduled sessions, video meetings & clients',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    foregroundColor: isDark ? Colors.white : AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                    ),
                  ),
                  onPressed: () => _showAvailabilityModal(context),
                  icon: const Icon(Icons.schedule, size: 16, color: AppColors.primary),
                  label: Text(
                    'Availability',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Segmented Filter Tabs (Upcoming, Completed, Cancelled)
            _buildSegmentedFilter(isDark),
            const SizedBox(height: 16),

            // Bookings List
            Obx(() {
              final bookings = controller.filteredBookings;

              if (bookings.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withOpacity(0.18)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          size: 48,
                          color: Colors.grey.withOpacity(0.6),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No ${controller.bookingFilter.value.toLowerCase()} bookings found',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          controller.bookingFilter.value == 'Upcoming'
                              ? 'When clients book your 1:1 calls or webinars, they will show up here.'
                              : 'Past sessions and cancelled requests will be recorded here.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  for (int i = 0; i < bookings.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    _buildBookingCard(context, bookings[i], isDark),
                  ],
                ],
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedFilter(bool isDark) {
    final filters = ['Upcoming', 'Completed', 'Cancelled'];

    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: filters.map((f) {
            final isSelected = controller.bookingFilter.value == f;
            return Expanded(
              child: GestureDetector(
                onTap: () => controller.bookingFilter.value = f,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      f,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildBookingCard(BuildContext context, BookingModel booking, bool isDark) {
    final formattedDate =
        '${booking.scheduledAt.day} ${_monthName(booking.scheduledAt.month)} ${booking.scheduledAt.year} • ${_timeFormat(booking.scheduledAt)}';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Mentee Info + Status Pill
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(
                  booking.candidateName.isNotEmpty ? booking.candidateName[0].toUpperCase() : 'C',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.candidateName,
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      booking.candidateEmail.isNotEmpty ? booking.candidateEmail : 'Client / Mentee',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              _buildStatusPill(booking.status),
            ],
          ),
          const Divider(height: 20),

          // Service Title & Time
          Text(
            booking.serviceTitle,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                formattedDate,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
              const Spacer(),
              Text(
                '₹${booking.amount.toStringAsFixed(booking.amount % 1 == 0 ? 0 : 2)}',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.green),
              ),
            ],
          ),

          // User Goal / Inquiry if present
          if (booking.userQuery.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.help_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.userQuery,
                      style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Mentor Private Notes if present
          if (booking.mentorNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note_alt_outlined, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Notes: ${booking.mentorNotes}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Actions
          if (booking.status != 'Cancelled') ...[
            Row(
              children: [
                // Join Call Button
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onPressed: () => _openMeetingUrl(context, booking.meetingUrl),
                    icon: const Padding(
                      padding: EdgeInsets.only(left: 6, right: 2),
                      child: Icon(Icons.videocam_rounded, size: 18),
                    ),
                    label: Text(
                      'Video Call',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Session Notes
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  onPressed: () => _showNotesDialog(context, booking),
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Notes'),
                ),
                // More options Popup
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) {
                    if (val == 'complete') {
                      controller.markBookingCompleted(booking.id);
                    } else if (val == 'cancel') {
                      controller.cancelBooking(booking.id);
                    } else if (val == 'copy') {
                      Clipboard.setData(ClipboardData(text: booking.meetingUrl));
                      Get.snackbar('Link Copied', 'Meeting link copied to clipboard');
                    }
                  },
                  itemBuilder: (context) => [
                    if (booking.status != 'Completed')
                      const PopupMenuItem(
                        value: 'complete',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Text('Mark Completed'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Copy Meet Link'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Cancel Session'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'Completed':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        break;
      case 'Cancelled':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        break;
      case 'Rescheduled':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        break;
      case 'Confirmed':
      default:
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1E40AF);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(
        status,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  void _openMeetingUrl(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    Get.snackbar(
      'Launching Meeting Link 🚀',
      'Meeting link: $url (Copied to clipboard)',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF059669),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  void _showNotesDialog(BuildContext context, BookingModel booking) {
    final notesCtrl = TextEditingController(text: booking.mentorNotes);

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          top: 22,
          bottom: MediaQuery.of(context).viewInsets.bottom > 0
              ? MediaQuery.of(context).viewInsets.bottom + 16
              : 22,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          bottom: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Private Session Notes', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Only visible to you as mentor', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 14),
              TextField(
                controller: notesCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Record key takeaways, candidate feedback, weaknesses identified, follow-up links...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    controller.saveMentorNotes(booking.id, notesCtrl.text.trim());
                    Get.back();
                  },
                  child: Text('Save Notes', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
      useRootNavigator: true,
    );
  }

  void _showAvailabilityModal(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          bottom: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text('Availability & Operating Hours', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available Days of Week', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: days.map((day) {
                          return Obx(() {
                            final isAvailable = controller.availability.value.availableDays.contains(day);
                            return FilterChip(
                              label: Text(day),
                              selected: isAvailable,
                              selectedColor: AppColors.primary.withOpacity(0.18),
                              checkmarkColor: AppColors.primary,
                              onSelected: (_) => controller.toggleAvailableDay(day),
                            );
                          });
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      Text('Daily Operating Hours', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Start Time', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                  ),
                                  child: Text('09:00 AM EST', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('End Time', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                  ),
                                  child: Text('07:00 PM EST', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Text('Session Buffer Time', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('Break time added automatically between consecutive sessions',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Obx(() {
                        final currentBuffer = controller.availability.value.bufferMinutes;
                        return Row(
                          children: [5, 10, 15, 30].map((mins) {
                            final isSelected = currentBuffer == mins;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('$mins mins'),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                labelStyle: GoogleFonts.inter(
                                  color: isSelected ? Colors.white : null,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (_) => controller.updateAvailabilityTimes(buffer: mins),
                              ),
                            );
                          }).toList(),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    controller.updateAvailabilityTimes();
                    Get.back();
                  },
                  child: Text('Save Availability Settings',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
      useRootNavigator: true,
    );
  }

  static String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(month - 1).clamp(0, 11)];
  }

  static String _timeFormat(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm EST';
  }
}
