import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/mentorship_controller.dart';
import '../../models/service_model.dart';
import '../../core/utils/constants.dart';

class MentorBookingDialog {
  static void show(BuildContext context, MentorshipServiceModel service) {
    final controller = Get.find<MentorshipController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Reset checkout fields
    controller.appliedDiscount.value = 0.0;
    controller.appliedPromoCode.value = '';
    controller.promoCodeController.clear();
    controller.menteeNotesController.clear();

    Get.bottomSheet(
      SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
            // Drag Handle
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _iconForType(service.serviceType),
                      color: AppColors.primary,
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                service.serviceType,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              service.price > 0
                                  ? '₹${service.price.toStringAsFixed(service.price % 1 == 0 ? 0 : 2)}'
                                  : 'FREE',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service.title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'With ${service.mentorName}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Details Pill
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              service.deliverable.isNotEmpty
                                  ? service.deliverable
                                  : (service.durationMinutes > 0
                                      ? '${service.durationMinutes} Mins Session'
                                      : 'Instant Delivery'),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 1:1 Call or Webinar: Date & Time Slot Picker
                    if (service.serviceType == '1:1 Call' || service.serviceType == 'Package') ...[
                      Text(
                        'Select Date',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 14,
                          itemBuilder: (context, index) {
                            final date = DateTime.now().add(Duration(days: index + 1));
                            final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
                            final dayNum = date.day.toString();
                            final monthName = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1];

                            return Obx(() {
                              final isSelected = controller.selectedDate.value.day == date.day &&
                                  controller.selectedDate.value.month == date.month;

                              return GestureDetector(
                                onTap: () => controller.selectedDate.value = date,
                                child: Container(
                                  width: 60,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        dayName,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? Colors.white70 : Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        dayNum,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                      Text(
                                        monthName,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: isSelected ? Colors.white70 : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 18),

                      Text(
                        'Select Available Time Slot',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          '09:30 AM EST',
                          '11:00 AM EST',
                          '02:00 PM EST',
                          '04:30 PM EST',
                          '06:00 PM EST',
                          '08:00 PM EST'
                        ].map((slot) {
                          return Obx(() {
                            final isSelected = controller.selectedTimeSlot.value == slot;
                            return ChoiceChip(
                              label: Text(slot),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              labelStyle: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              ),
                              onSelected: (_) => controller.selectSlot(slot),
                            );
                          });
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                    ] else if (service.serviceType == 'Webinar') ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.event, color: AppColors.secondary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Webinar Schedule',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              service.eventDate ?? 'Upcoming Saturday • 07:00 PM EST',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Seats: ${service.bookedSeats} / ${service.maxSeats ?? 50} booked',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ] else if (service.serviceType == 'Digital Product') ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.file_download_outlined, color: AppColors.primary, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Instant Digital Delivery',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    'Download link and updates will be sent to your email immediately upon booking.',
                                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ] else if (service.serviceType == 'Priority DM') ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.flash_on, color: AppColors.secondary, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '24-Hour Guaranteed Turnaround',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    'Write your question below. The mentor will review and reply with a detailed voice/text response.',
                                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Mentee Questions / Goals Input
                    Text(
                      service.serviceType == 'Priority DM'
                          ? 'Your Question for the Mentor'
                          : 'What would you like to achieve in this session?',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.menteeNotesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: service.serviceType == 'Priority DM'
                            ? 'Explain your question or paste offer details...'
                            : 'e.g. Preparing for Senior SDE onsite at Meta, need resume and behavioral tips...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mentee Email
                    Text(
                      'Your Email Address for Confirmation',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.menteeEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'e.g. alex@example.com',
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Promo Code Input
                    Text(
                      'Have a Promo Code?',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller.promoCodeController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'Try TOPMATE10 or WELCOME20',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: Size.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
                          onPressed: () => controller.applyPromoCode(controller.promoCodeController.text),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Price Breakdown
                    Obx(() {
                      final discountRatio = controller.appliedDiscount.value;
                      final basePrice = service.price;
                      final discountAmount = basePrice * discountRatio;
                      final finalPrice = (basePrice - discountAmount).clamp(0.0, double.infinity);

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Service Price', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
                                Text('₹${basePrice.toStringAsFixed(basePrice % 1 == 0 ? 0 : 2)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            if (discountRatio > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Discount (${controller.appliedPromoCode.value})',
                                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.secondary),
                                  ),
                                  Text(
                                    '-₹${discountAmount.toStringAsFixed(discountAmount % 1 == 0 ? 0 : 2)}',
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text('Platform Convenience Fee',
                                      style: GoogleFonts.inter(
                                          fontSize: 13, color: Colors.grey)),
                                ),
                                const SizedBox(width: 8),
                                Text('FREE (₹0)',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const Divider(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total to Pay', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                                Text(
                                  '₹${finalPrice.toStringAsFixed(finalPrice % 1 == 0 ? 0 : 2)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Confirm Button with SafeArea
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Obx(() {
                    final discountRatio = controller.appliedDiscount.value;
                    final finalPrice = (service.price * (1.0 - discountRatio)).clamp(0.0, double.infinity);

                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => controller.bookMentorshipSession(service),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Confirm & Book (₹${finalPrice.toStringAsFixed(finalPrice % 1 == 0 ? 0 : 2)})',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
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

  static IconData _iconForType(String type) {
    switch (type) {
      case 'Digital Product':
        return Icons.file_download_outlined;
      case 'Priority DM':
        return Icons.bolt;
      case 'Webinar':
        return Icons.live_tv_rounded;
      case 'Package':
        return Icons.auto_awesome;
      case '1:1 Call':
      default:
        return Icons.video_call_rounded;
    }
  }
}
