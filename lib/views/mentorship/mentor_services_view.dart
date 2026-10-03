import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/mentorship_controller.dart';
import '../../services/database_service.dart';
import '../../models/service_model.dart';
import '../../core/utils/constants.dart';
import 'mentor_storefront_view.dart';

class MentorServicesView extends GetView<MentorshipController> {
  const MentorServicesView({super.key});

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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Offerings',
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Your services, digital products & webinars',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () => MentorStorefrontView.showAddOfferingSelector(context),
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: Text('Add Offering', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Services Stats Summary Bar
            _buildStatsBar(isDark),
            const SizedBox(height: 16),

            // Offering Type Filters
            _buildFilterChips(isDark),
            const SizedBox(height: 16),

            // Offerings List
            Obx(() {
              final services = controller.filteredStorefrontServices;

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
                        const Icon(Icons.category_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          'No offerings in this category',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap + button below to create a 1:1 call, digital guide, or webinar.',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
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
                    _buildServiceItem(context, services[i], isDark),
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

  Widget _buildStatsBar(bool isDark) {
    return Obx(() {
      final total = controller.myServices.length;
      final active = controller.myServices.where((s) => s.isActive).length;
      final calls = controller.myServices.where((s) => s.serviceType == '1:1 Call').length;
      final products = controller.myServices.where((s) => s.serviceType == 'Digital Product').length;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatCol('Total Offerings', '$total'),
            Container(height: 24, width: 1, color: Colors.grey.withOpacity(0.3)),
            _buildStatCol('Active Live', '$active', color: Colors.green),
            Container(height: 24, width: 1, color: Colors.grey.withOpacity(0.3)),
            _buildStatCol('1:1 Calls', '$calls'),
            Container(height: 24, width: 1, color: Colors.grey.withOpacity(0.3)),
            _buildStatCol('Digital Guides', '$products'),
          ],
        ),
      );
    });
  }

  Widget _buildStatCol(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final categories = [
      'All',
      '1:1 Call',
      'Priority DM',
      'Mock Interview',
      'Resume Review',
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
              child: FilterChip(
                label: Text(cat),
                selected: isSelected,
                selectedColor: AppColors.primary.withOpacity(0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black87),
                ),
                onSelected: (_) => controller.activeStorefrontTab.value = cat,
              ),
            );
          });
        }).toList(),
      ),
    );
  }

  Widget _buildServiceItem(BuildContext context, MentorshipServiceModel service, bool isDark) {
    final color = _colorForType(service.serviceType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: service.isActive ? Colors.grey.withOpacity(0.18) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_iconForCategory(service.serviceType), size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${service.serviceType} • ${service.deliverable.isNotEmpty ? service.deliverable : "${service.durationMinutes} mins"}',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                service.price > 0 ? '₹${service.price.toStringAsFixed(service.price % 1 == 0 ? 0 : 2)}' : 'FREE',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            service.description,
            style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(height: 20),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              // Active / Pause Switch
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: service.isActive,
                      activeThumbColor: Colors.green,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (_) => controller.toggleServiceActive(service),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    service.isActive ? 'Active' : 'Paused',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: service.isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
              // Action buttons (Start Call/Chat, Edit, Delete)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (service.serviceType == '1:1 Call') ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF059669),
                        side: const BorderSide(color: Color(0xFF059669)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => controller.startServiceCallFromOffering(context, service),
                      icon: const Icon(Icons.videocam_rounded, size: 14),
                      label: Text(
                        'Start Call',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  if (service.serviceType == 'Priority DM') ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF059669),
                        side: const BorderSide(color: Color(0xFF059669)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => controller.startServicePriorityDmFromOffering(context, service),
                      icon: const Icon(Icons.chat_bubble_rounded, size: 14),
                      label: Text(
                        'Start Chat',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  // Edit button - compact with tapTargetSize shrinkWrap to avoid overflow
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showEditServiceDialog(context, service),
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: Text(
                      'Edit',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Delete button
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    tooltip: 'Delete Offering',
                    onPressed: () {
                      Get.defaultDialog(
                        title: 'Delete Offering?',
                        middleText: 'Are you sure you want to remove "${service.title}"?',
                        textConfirm: 'Delete',
                        textCancel: 'Cancel',
                        confirmTextColor: Colors.white,
                        buttonColor: Colors.redAccent,
                        onConfirm: () {
                          controller.deleteService(service.id);
                          Get.back();
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditServiceDialog(BuildContext context, MentorshipServiceModel service) {
    final titleCtrl = TextEditingController(text: service.title);
    final descCtrl = TextEditingController(text: service.description);
    final priceCtrl = TextEditingController(text: service.price % 1 == 0 ? service.price.toInt().toString() : service.price.toStringAsFixed(2));
    final deliverableCtrl = TextEditingController(text: service.deliverable);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: bottomInset > 0 ? bottomInset + 16 : 20,
          ),
          child: SafeArea(
            top: false,
            bottom: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Edit Offering', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Title', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleCtrl,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text('Description', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text('Price (₹ / INR)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            prefixText: '₹ ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text('Deliverable / Format Badge', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: deliverableCtrl,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      final cleanPrice = priceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
                      final updated = service.copyWith(
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        price: double.tryParse(cleanPrice) ?? service.price,
                        deliverable: deliverableCtrl.text.trim(),
                      );
                      Navigator.of(sheetContext).pop();
                      controller.updateService(updated);
                    },
                    child: Text('Save Changes', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static IconData _iconForCategory(String category) {
    switch (category) {
      case 'All':
        return Icons.grid_view_rounded;
      case '1:1 Call':
        return Icons.video_call_rounded;
      case 'Priority DM':
        return Icons.bolt;
      case 'Mock Interview':
        return Icons.record_voice_over_rounded;
      case 'Resume Review':
        return Icons.description_outlined;
      case 'Webinar':
        return Icons.live_tv_rounded;
      case 'Package':
        return Icons.auto_awesome;
      case 'Digital Product':
        return Icons.file_download_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  static Color _colorForType(String type) {
    switch (type) {
      case '1:1 Call':
        return const Color(0xFF6366F1);
      case 'Priority DM':
        return const Color(0xFFF59E0B);
      case 'Mock Interview':
        return const Color(0xFF0EA5E9);
      case 'Resume Review':
        return const Color(0xFF14B8A6);
      case 'Webinar':
        return const Color(0xFFEC4899);
      case 'Package':
        return const Color(0xFF8B5CF6);
      case 'Digital Product':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6366F1);
    }
  }
}
