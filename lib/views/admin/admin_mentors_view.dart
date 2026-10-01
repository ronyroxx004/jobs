import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/admin_controller.dart';
import '../../core/utils/constants.dart';
import '../../models/user_model.dart';
import '../../models/service_model.dart';
import '../../services/database_service.dart';
import 'admin_shared.dart';

/// Admin screen for mentors. Mentors are presented as wide service cards that
/// surface their published sessions, booking volume and earnings.
class AdminMentorsView extends StatefulWidget {
  const AdminMentorsView({super.key});

  @override
  State<AdminMentorsView> createState() => _AdminMentorsViewState();
}

class _AdminMentorsViewState extends State<AdminMentorsView> {
  final TextEditingController _searchController = TextEditingController();
  final RxString _query = ''.obs;
  final RxString _sort = 'Earnings'.obs;

  static const List<String> _sorts = ['Earnings', 'Bookings', 'Services', 'Name'];

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    return RefreshIndicator(
      onRefresh: () => Get.find<DatabaseService>().fetchAllData(),
      child: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Mentorship Program hero + 3 stat buttons scroll upward when scrolling on mentor cards
            SliverToBoxAdapter(
              child: _buildCollapsibleHeader(controller),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: AdminPinnedHeaderDelegate(
                height: 104,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: _buildControls(),
                ),
              ),
            ),
            _buildMentorList(controller),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleHeader(AdminController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary,
                  AppColors.secondary.withValues(alpha: 0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.psychology_alt_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mentorship Program',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${controller.mentors.length} mentors • '
                        '${controller.activeServices} active services',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: AdminStatTile(
                    label: 'Services',
                    value: '${controller.totalMentors}',
                    icon: Icons.design_services_rounded,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AdminStatTile(
                    label: 'Bookings',
                    value: '${controller.totalBookings}',
                    icon: Icons.event_available_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AdminStatTile(
                    label: 'Session revenue',
                    value:
                        '\$${controller.totalMentorshipRevenue.toStringAsFixed(0)}',
                    icon: Icons.payments_rounded,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        children: [
          AdminSearchField(
            controller: _searchController,
            hint: 'Search mentor, headline or session title...',
            onChanged: (value) => _query.value = value,
            onClear: () {
              _searchController.clear();
              _query.value = '';
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Sort by',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: Obx(
                    () {
                      // Read the observable here (not inside the lazy
                      // itemBuilder) so Obx can subscribe to it.
                      final current = _sort.value;
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _sorts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final label = _sorts[index];
                          final selected = current == label;
                          return ChoiceChip(
                            label: Text(label),
                            selected: selected,
                            onSelected: (_) => _sort.value = label,
                            showCheckmark: false,
                            selectedColor: AppColors.secondary,
                            backgroundColor: Colors.white,
                            labelStyle: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : Colors.grey[700],
                            ),
                            side: BorderSide(
                              color: selected
                                  ? AppColors.secondary
                                  : AppColors.borderLight,
                            ),
                            visualDensity: VisualDensity.compact,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMentorList(AdminController controller) {
    return Obx(() {
      final mentors = _sortedMentors(controller);

      if (mentors.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: AdminEmptyState(
            icon: Icons.groups_outlined,
            title: 'No mentors found',
            subtitle:
                'Mentors who register will appear here with their sessions.',
            color: AppColors.secondary,
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index.isOdd) return const SizedBox(height: 12);
              final itemIndex = index ~/ 2;
              return _MentorCard(
                mentor: mentors[itemIndex],
                controller: controller,
              );
            },
            childCount: mentors.isEmpty ? 0 : mentors.length * 2 - 1,
          ),
        ),
      );
    });
  }

  List<UserModel> _sortedMentors(AdminController controller) {
    final mentors = controller.mentors.where((user) {
      final services = controller.servicesByMentor(user.id);
      return adminMatchesQuery(_query.value, [
        user.name,
        user.email,
        user.headline,
        ...user.skills,
        ...services.map((s) => s.title),
      ]);
    }).toList();

    switch (_sort.value) {
      case 'Name':
        mentors.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case 'Services':
        mentors.sort((a, b) => controller
            .servicesByMentor(b.id)
            .length
            .compareTo(controller.servicesByMentor(a.id).length));
      case 'Bookings':
        mentors.sort((a, b) => controller
            .bookingsByMentor(b.id)
            .length
            .compareTo(controller.bookingsByMentor(a.id).length));
      default:
        mentors.sort((a, b) => controller
            .mentorEarnings(b.id)
            .compareTo(controller.mentorEarnings(a.id)));
    }
    return mentors;
  }
}

class _MentorCard extends StatelessWidget {
  final UserModel mentor;
  final AdminController controller;

  const _MentorCard({required this.mentor, required this.controller});

  @override
  Widget build(BuildContext context) {
    final services = controller.servicesByMentor(mentor.id);
    final bookings = controller.bookingsByMentor(mentor.id).length;
    final earnings = controller.mentorEarnings(mentor.id);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => adminShowUserActions(
          context,
          mentor,
          accent: AppColors.secondary,
          extraActions: [
            _MentorStats(services: services.length, bookings: bookings),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AdminUserAvatar(
                    user: mentor,
                    size: 52,
                    accent: AppColors.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mentor.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mentor.headline.isNotEmpty
                              ? mentor.headline
                              : 'Mentorship Expert',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              mentor.rating.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              ' (${mentor.totalReviews})',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${earnings.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary,
                        ),
                      ),
                      Text(
                        '$bookings booking${bookings == 1 ? '' : 's'}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (services.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No mentorship sessions published yet.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              else
                for (final service in services)
                  _ServiceRow(service: service, controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final MentorshipServiceModel service;
  final AdminController controller;

  const _ServiceRow({required this.service, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.video_call_rounded,
              size: 17,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${service.category} • ${service.durationMinutes} min',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${service.price.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.secondary,
            ),
          ),
          IconButton(
            tooltip: 'Remove session',
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 19,
              color: Colors.redAccent,
            ),
            onPressed: () =>
                controller.removeMentorshipService(service.id, service.title),
          ),
        ],
      ),
    );
  }
}

class _MentorStats extends StatelessWidget {
  final int services;
  final int bookings;

  const _MentorStats({required this.services, required this.bookings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$services',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  'Published sessions',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$bookings',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Total bookings',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}