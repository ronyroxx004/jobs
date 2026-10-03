import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/mentorship_controller.dart';
import '../../services/database_service.dart';
import '../../models/service_model.dart';
import '../../core/utils/constants.dart';

class MentorEarningsView extends GetView<MentorshipController> {
  const MentorEarningsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          controller.fetchServices().timeout(DatabaseService.readTimeout, onTimeout: () => controller.allServices),
          controller.fetchBookings().timeout(DatabaseService.readTimeout, onTimeout: () => controller.allBookings),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Earnings & Growth',
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Monetization, analytics & payout history',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showPayoutRequestModal(context),
                  icon: const Icon(Icons.account_balance_wallet, size: 16),
                  label: Text(
                    'Withdraw',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Top Financial Cards
            _buildBalanceHero(context, isDark),
            const SizedBox(height: 16),

            // Secondary Metrics
            _buildSecondaryMetrics(isDark),
            const SizedBox(height: 20),

            // Revenue Breakdown by Offering Format
            Text(
              'Revenue by Offering Format',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildRevenueBreakdown(isDark),
            const SizedBox(height: 24),

            // Payout History Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payout History',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => _showPayoutRequestModal(context),
                  child: const Text('Request Payout'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildPayoutHistoryList(isDark),
            const SizedBox(height: 24),

            // Testimonials & Social Proof Management
            _buildTestimonialsManager(context, isDark),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceHero(BuildContext context, bool isDark) {
    return Obx(() {
      final available = controller.availableBalance;
      final lifetime = controller.totalLifetimeEarnings;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4338CA).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.payments_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Available for Payout',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF34D399).withOpacity(0.4)),
                  ),
                  child: Text(
                    'Instant Payout Enabled',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6EE7B7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '\$${available.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Lifetime Earnings', style: GoogleFonts.inter(fontSize: 11, color: Colors.white60)),
                    Text('\$${lifetime.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                ElevatedButton(
style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF312E81),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
                  onPressed: () => _showPayoutRequestModal(context),
                  child: Text('Withdraw Funds', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSecondaryMetrics(bool isDark) {
    return Obx(() {
      final completed = controller.totalCompletedSessionsCount;
      final totalBookings = controller.totalBookingsCount;
      final rate = totalBookings > 0
          ? '${((completed / totalBookings) * 100).toStringAsFixed(0)}%'
          : '0%';

      return Row(
        children: [
          _buildMetricBox('Completed Sessions', '$completed', Icons.check_circle_outline, Colors.blue, isDark),
          const SizedBox(width: 10),
          _buildMetricBox('Total Bookings', '$totalBookings', Icons.calendar_month_outlined, Colors.purple, isDark),
          const SizedBox(width: 10),
          _buildMetricBox('Completion Rate', rate, Icons.trending_up, Colors.orange, isDark),
        ],
      );
    });
  }

  Widget _buildMetricBox(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueBreakdown(bool isDark) {
    return Obx(() {
      final bookings = controller.completedBookings;
      final services = controller.allServices;

      double callRevenue = 0.0;
      double productRevenue = 0.0;
      double webinarRevenue = 0.0;
      double dmRevenue = 0.0;

      for (final b in bookings) {
        final service = services.firstWhereOrNull((s) => s.id == b.serviceId);
        final type = service?.serviceType ?? '1:1 Call';
        if (type == '1:1 Call') {
          callRevenue += b.amount;
        } else if (type == 'Digital Product') {
          productRevenue += b.amount;
        } else if (type == 'Webinar') {
          webinarRevenue += b.amount;
        } else {
          dmRevenue += b.amount;
        }
      }

      final total = callRevenue + productRevenue + webinarRevenue + dmRevenue;

      if (total == 0) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.withOpacity(0.18)),
          ),
          child: Center(
            child: Text(
              'No revenue recorded yet. When clients complete bookings, breakdown by offering format will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
          ),
        );
      }

      String pct(double amt) => total > 0 ? '${((amt / total) * 100).toStringAsFixed(0)}%' : '0%';

      final breakdown = [
        {'format': '1:1 Video Calls', 'amount': '\$${callRevenue.toStringAsFixed(2)}', 'percent': pct(callRevenue), 'color': const Color(0xFF6366F1)},
        {'format': 'Digital Guides & Playbooks', 'amount': '\$${productRevenue.toStringAsFixed(2)}', 'percent': pct(productRevenue), 'color': const Color(0xFF10B981)},
        {'format': 'Live Webinars & Cohorts', 'amount': '\$${webinarRevenue.toStringAsFixed(2)}', 'percent': pct(webinarRevenue), 'color': const Color(0xFFEC4899)},
        {'format': 'Priority DMs', 'amount': '\$${dmRevenue.toStringAsFixed(2)}', 'percent': pct(dmRevenue), 'color': const Color(0xFFF59E0B)},
      ];

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withOpacity(0.18)),
        ),
        child: Column(
          children: breakdown.map((item) {
            final color = item['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['format'] as String,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    item['percent'] as String,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item['amount'] as String,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildPayoutHistoryList(bool isDark) {
    return Obx(() {
      final list = controller.payoutHistory;

      if (list.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: Text('No payouts requested yet')),
        );
      }

      return Column(
        children: [
          for (int i = 0; i < list.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Builder(builder: (context) {
              final payout = list[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.18)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFF059669), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(payout.payoutMethod, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('${payout.requestedAt.day}/${payout.requestedAt.month}/${payout.requestedAt.year}',
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('\$${payout.amount.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Completed', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF065F46))),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      );
    });
  }

  Widget _buildTestimonialsManager(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Testimonial Management', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Control social proof displayed on your storefront', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_comment_outlined, color: AppColors.primary),
                tooltip: 'Add Client Review',
                onPressed: () => _showAddReviewModal(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Obx(() {
            if (controller.testimonials.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No reviews yet. Mentee reviews from completed bookings will show here.',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return Column(
              children: controller.testimonials.map((t) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${t.candidateName} • ${t.candidateRole}',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('"${t.content}"',
                                style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic), maxLines: 2),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          t.isFeatured ? Icons.star_rounded : Icons.star_border_rounded,
                          color: t.isFeatured ? const Color(0xFFF59E0B) : Colors.grey,
                        ),
                        tooltip: t.isFeatured ? 'Featured on Storefront' : 'Click to feature',
                        onPressed: () => controller.toggleFeatureTestimonial(t.id),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  void _showPayoutRequestModal(BuildContext context) {
    final amountCtrl = TextEditingController(text: controller.availableBalance > 0 ? controller.availableBalance.toStringAsFixed(2) : '');
    final accountCtrl = TextEditingController();
    final method = 'Bank Transfer'.obs;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance, color: AppColors.primary),
                const SizedBox(width: 10),
                Text('Withdraw Funds', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 20),
            Text('Withdrawal Amount', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '\$ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            Text('Payout Method', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Obx(() {
              return Wrap(
                spacing: 8,
                children: ['Bank Transfer', 'UPI', 'Stripe', 'PayPal'].map((m) {
                  final isSelected = method.value == m;
                  return ChoiceChip(
                    label: Text(m),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: GoogleFonts.inter(color: isSelected ? Colors.white : null),
                    onSelected: (_) => method.value = m,
                  );
                }).toList(),
              );
            }),
            const SizedBox(height: 14),
            Text('Account / Destination Details', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: accountCtrl,
              decoration: InputDecoration(
                hintText: 'Account number, routing, or UPI ID',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final val = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                  controller.requestPayout(
                    amount: val,
                    method: method.value,
                    accountDetails: accountCtrl.text.trim(),
                  );
                },
                child: Text('Process Instant Payout', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showAddReviewModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Client Testimonial', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                hintText: 'Mentee Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: roleCtrl,
              decoration: InputDecoration(
                hintText: 'Role / Target Company (e.g. SDE @ Meta)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Mentee feedback quote...',
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
                  if (nameCtrl.text.isNotEmpty && contentCtrl.text.isNotEmpty) {
                    controller.addTestimonial(TestimonialModel(
                      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
                      mentorId: controller.currentMentorId,
                      candidateName: nameCtrl.text.trim(),
                      candidateRole: roleCtrl.text.trim().isNotEmpty ? roleCtrl.text.trim() : 'Software Engineer',
                      content: contentCtrl.text.trim(),
                      date: 'Just now',
                    ));
                    Get.back();
                  }
                },
                child: const Text('Add to Storefront', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
