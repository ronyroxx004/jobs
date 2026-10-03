import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/mentorship_controller.dart';
import '../../services/database_service.dart';
import '../../models/service_model.dart';
import '../../core/utils/constants.dart';
import 'mentor_booking_dialog.dart';

class MentorStorefrontView extends GetView<MentorshipController> {
  const MentorStorefrontView({super.key});

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
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shareable Storefront Link Bar
              _buildStorefrontShareBar(context, isDark),
              const SizedBox(height: 16),

              // Metrics & Social Proof Highlights
              _buildMetricsRow(context, isDark),
              const SizedBox(height: 20),

              // Section Header: Offerings & Storefront
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Storefront Offerings',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '1:1 Sessions, digital assets, webinars & queries',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Category Filter Tabs (All, 1:1 Call, Digital Product, Priority DM, Webinar, Package)
              _buildCategoryTabs(isDark),
              const SizedBox(height: 16),

              // Services / Offerings Grid
              _buildOfferingsList(context, isDark),
              const SizedBox(height: 28),

              // Mentee Testimonials & Social Proof
              _buildTestimonialsSection(context, isDark),
              const SizedBox(height: 36),
            ],
          ),
        ),
      );
  }


  // --- SHAREABLE STOREFRONT BAR ---
  Widget _buildStorefrontShareBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.alternate_email, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Topmate Storefront Link',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                Text(
                  controller.storefrontUrl,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
            tooltip: 'Copy Link',
            onPressed: controller.copyStorefrontLink,
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: controller.copyStorefrontLink,
            icon: const Icon(Icons.share, size: 14, color: Colors.white),
            label: Text(
              'Share',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- METRICS ROW ---
  Widget _buildMetricsRow(BuildContext context, bool isDark) {
    return Obx(() {
      final sessions = controller.totalCompletedSessionsCount;
      final offerings = controller.myServices.where((s) => s.isActive).length;
      final reviews = controller.totalReviewsCount;

      return Row(
        children: [
          _buildMetricCard(
            'Total Sessions',
            '$sessions',
            Icons.calendar_today_rounded,
            const Color(0xFF6366F1),
            isDark,
          ),
          const SizedBox(width: 10),
          _buildMetricCard(
            'Active Offerings',
            '$offerings',
            Icons.category_rounded,
            const Color(0xFF10B981),
            isDark,
          ),
          const SizedBox(width: 10),
          _buildMetricCard(
            'Rating',
            reviews > 0 ? '${controller.mentorRating} ★' : 'New',
            Icons.star_rounded,
            const Color(0xFFF59E0B),
            isDark,
          ),
        ],
      );
    });
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- CATEGORY TABS ---
  Widget _buildCategoryTabs(bool isDark) {
    final categories = [
      'All',
      '1:1 Call',
      'Digital Product',
      'Priority DM',
      'Webinar',
      'Package',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          return Obx(() {
            final isSelected = controller.activeStorefrontTab.value == cat;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _iconForCategory(cat),
                      size: 14,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    ),
                    const SizedBox(width: 6),
                    Text(cat),
                  ],
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                onSelected: (_) => controller.activeStorefrontTab.value = cat,
              ),
            );
          });
        }).toList(),
      ),
    );
  }

  // --- OFFERINGS LIST ---
  Widget _buildOfferingsList(BuildContext context, bool isDark) {
    return Obx(() {
      final services = controller.filteredStorefrontServices;
      final isPreview = controller.isLivePreviewMode.value;

      if (services.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.storefront_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'No offerings under this category yet',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add 1:1 sessions, digital guides, webinars or packages to monetize your knowledge.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => showAddOfferingSelector(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add First Post'),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: [
          for (int i = 0; i < services.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildOfferingCard(context, services[i], isDark, isPreview),
          ],
        ],
      );
    });
  }

  // --- INDIVIDUAL TOPMATE OFFERING CARD ---
  Widget _buildOfferingCard(BuildContext context, MentorshipServiceModel service, bool isDark, bool isPreview) {
    final typeColor = _colorForType(service.serviceType);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: service.isActive
              ? Colors.grey.withOpacity(0.18)
              : Colors.red.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Type Badge + Price Pill
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_iconForCategory(service.serviceType), size: 13, color: typeColor),
                      const SizedBox(width: 4),
                      Text(
                        service.serviceType,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!service.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'PAUSED',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ),
                const Spacer(),
                Text(
                  service.price > 0 ? '₹${service.price.toStringAsFixed(service.price % 1 == 0 ? 0 : 2)}' : 'FREE',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              service.title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            // Description
            Text(
              service.description,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Topics / Deliverable Chips
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  service.deliverable.isNotEmpty
                      ? service.deliverable
                      : (service.durationMinutes > 0
                          ? '${service.durationMinutes} mins'
                          : 'Instant Delivery'),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.grey[700],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 2),
                    Text(
                      '${service.rating} (${service.reviewCount})',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),

            // Actions Row
            Row(
              children: [
                if (!isPreview) ...[
                  // Creator Mode: Quick Edit & Toggle
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => controller.toggleServiceActive(service),
                    icon: Icon(
                      service.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      size: 16,
                      color: service.isActive ? Colors.orange : Colors.green,
                    ),
                    label: Text(
                      service.isActive ? 'Pause' : 'Activate',
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    tooltip: 'Delete Offering',
                    onPressed: () => _confirmDeleteService(context, service),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => MentorBookingDialog.show(context, service),
                    child: Text(
                      'Test Booking',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ] else ...[
                  // Client Storefront View: Direct Topmate Booking action
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => MentorBookingDialog.show(context, service),
                    icon: Icon(_actionIconForType(service.serviceType), size: 16, color: Colors.white),
                    label: Text(
                      _actionLabelForType(service.serviceType),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- TESTIMONIALS SECTION ---
  Widget _buildTestimonialsSection(BuildContext context, bool isDark) {
    return Obx(() {
      final list = controller.testimonials.where((t) => t.isFeatured).toList();
      if (list.isEmpty) return const SizedBox.shrink();

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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.star_rounded, size: 20, color: Color(0xFFD97706)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What Mentees Say',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Verified testimonials & session outcomes',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: list.map((t) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary.withOpacity(0.15),
                            child: Text(
                              t.candidateName[0],
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      t.candidateName,
                                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified, size: 14, color: AppColors.secondary),
                                  ],
                                ),
                                Text(
                                  t.candidateRole,
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (i) => const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"${t.content}"',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }

  // --- ALL-IN-ONE PROFESSIONAL OFFERING CREATION SHEET ---
  static void showAddOfferingSelector(BuildContext context, [String defaultType = '1:1 Call']) {
    final controller = Get.find<MentorshipController>();
    controller.prepareNewServiceForm(defaultType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final types = [
          {'type': '1:1 Call', 'icon': Icons.video_camera_front_rounded, 'color': const Color(0xFF6366F1)},
          {'type': 'Digital Product', 'icon': Icons.file_download_outlined, 'color': const Color(0xFF10B981)},
          {'type': 'Priority DM', 'icon': Icons.bolt_rounded, 'color': const Color(0xFFF59E0B)},
          {'type': 'Webinar', 'icon': Icons.live_tv_rounded, 'color': const Color(0xFFEC4899)},
          {'type': 'Package', 'icon': Icons.auto_awesome_rounded, 'color': const Color(0xFF8B5CF6)},
        ];

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.90,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
            ],
          ),
          child: SafeArea(
            top: false,
            bottom: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Top Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Topmate Offering',
                            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Publish a session, product, or webinar to your storefront',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Sheet Form Body
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 14,
                    bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Offering Type Selector Pills
                      Text(
                        'Offering Format',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Obx(() {
                        final currentType = controller.serviceType.value;
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: types.map((item) {
                              final typeName = item['type'] as String;
                              final typeColor = item['color'] as Color;
                              final isSelected = currentType == typeName;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () => controller.prepareNewServiceForm(typeName),
                                  borderRadius: BorderRadius.circular(14),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? typeColor.withValues(alpha: 0.15)
                                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected ? typeColor : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          item['icon'] as IconData,
                                          size: 16,
                                          color: isSelected ? typeColor : Colors.grey,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          typeName,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: isSelected ? typeColor : (isDark ? Colors.white70 : Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }),
                      const SizedBox(height: 18),

                      // 2. Title Field
                      Text(
                        'Offering Title',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controller.serviceTitleController,
                        decoration: InputDecoration(
                          hintText: 'e.g. 1:1 Senior Engineering & System Design Mentorship',
                          prefixIcon: const Icon(Icons.title_rounded, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Description Field
                      Text(
                        'Description & Outcomes',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controller.serviceDescController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'What topics are covered, what will the mentee receive, and key outcomes...',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 40),
                            child: Icon(Icons.notes_rounded, size: 20),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 4. Price Field with Quick Preset Chips
                      Text(
                        'Price (USD)',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller.servicePriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                prefixText: '₹ ',
                                hintText: '499',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ...['199', '499', '999', '0'].map((preset) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: ActionChip(
                                label: Text(preset == '0' ? 'Free' : '₹$preset'),
                                labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                                onPressed: () {
                                  controller.servicePriceController.text = preset;
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 5. Duration (for Call / Webinar)
                      Obx(() {
                        final type = controller.serviceType.value;
                        if (type != '1:1 Call' && type != 'Webinar') {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Duration',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: [15, 30, 45, 60, 90].map((mins) {
                                final isSelected = controller.serviceDuration.value == mins;
                                return ChoiceChip(
                                  label: Text('$mins mins'),
                                  selected: isSelected,
                                  selectedColor: AppColors.primary,
                                  labelStyle: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                  onSelected: (val) {
                                    if (val) controller.serviceDuration.value = mins;
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                          ],
                        );
                      }),

                      // 6. Deliverable Badge Text
                      Text(
                        'Deliverable Badge',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controller.serviceDeliverableController,
                        decoration: InputDecoration(
                          hintText: 'e.g. 30 Mins 1:1 Video Call, Instant PDF Download',
                          prefixIcon: const Icon(Icons.verified_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 7. Topics / Tags
                      Text(
                        'Topics / Tags (comma separated)',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controller.serviceTopicsController,
                        decoration: InputDecoration(
                          hintText: 'e.g. System Design, Career Advice, Mock Interview',
                          prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 8. Publish Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 3,
                          ),
                          onPressed: () {
                            if (controller.validateNewServiceForm()) {
                              if (Navigator.of(sheetContext).canPop()) {
                                Navigator.of(sheetContext).pop();
                              }
                              // 2. Publish offering and refresh storefront live
                              controller.createService();
                            }
                          },
                          child: Text(
                            'Publish Offering to Storefront 🚀',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  void _confirmDeleteService(BuildContext context, MentorshipServiceModel service) {
    Get.defaultDialog(
      title: 'Delete Offering?',
      middleText: 'Are you sure you want to remove "${service.title}" from your storefront?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        controller.deleteService(service.id);
        Get.back();
      },
    );
  }



  static IconData _iconForCategory(String category) {
    switch (category) {
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

  static Color _colorForType(String type) {
    switch (type) {
      case 'Digital Product':
        return const Color(0xFF10B981);
      case 'Priority DM':
        return const Color(0xFFF59E0B);
      case 'Webinar':
        return const Color(0xFFEC4899);
      case 'Package':
        return const Color(0xFF8B5CF6);
      case '1:1 Call':
      default:
        return const Color(0xFF6366F1);
    }
  }

  static String _actionLabelForType(String type) {
    switch (type) {
      case 'Digital Product':
        return 'Get Product';
      case 'Priority DM':
        return 'Ask Query';
      case 'Webinar':
        return 'Register';
      case 'Package':
        return 'Get Package';
      case '1:1 Call':
      default:
        return 'Book Slot';
    }
  }

  static IconData _actionIconForType(String type) {
    switch (type) {
      case 'Digital Product':
        return Icons.download_rounded;
      case 'Priority DM':
        return Icons.send_rounded;
      case 'Webinar':
        return Icons.how_to_reg_rounded;
      case 'Package':
        return Icons.stars_rounded;
      case '1:1 Call':
      default:
        return Icons.calendar_today_rounded;
    }
  }
}
