import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/job_controller.dart';
import '../../core/utils/constants.dart';
import '../../core/routes/app_routes.dart';
import '../../services/database_service.dart';

class CandidateProfileView extends GetView<ProfileController> {
  const CandidateProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final jobController = Get.find<JobController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        final dbService = Get.find<DatabaseService>();
        await dbService.fetchAllData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Card
            Obx(() {
              final user = controller.user;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.1),
                                backgroundImage:
                                    user?.avatarUrl.isNotEmpty == true
                                        ? NetworkImage(user!.avatarUrl)
                                        : null,
                                child: user?.avatarUrl.isEmpty == true
                                    ? Text(
                                        user?.name.isNotEmpty == true
                                            ? user!.name[0]
                                            : 'U',
                                        style: GoogleFonts.inter(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: controller.pickProfilePicture,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt,
                                        color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'User',
                                  style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.headline.isNotEmpty == true
                                      ? user!.headline
                                      : 'Add a headline to describe your professional role',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      user?.location.isNotEmpty == true
                                          ? user!.location
                                          : 'Set location',
                                      style: GoogleFonts.inter(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                if ((user?.experienceYears ?? 0) > 0) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.work_outline,
                                          size: 14, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${user!.experienceYears} years experience',
                                        style: GoogleFonts.inter(
                                            fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit profile and manage resumes',
                            onPressed: () => Get.toNamed(AppRoutes.editProfile),
                            icon: const Icon(Icons.edit_outlined,
                                color: AppColors.primary),
                          ),
                        ],
                      ),
                      if (user?.email.isNotEmpty == true ||
                          user?.phone.isNotEmpty == true) ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 18,
                          runSpacing: 10,
                          children: [
                            if (user?.email.isNotEmpty == true)
                              _ProfileContact(
                                icon: Icons.email_outlined,
                                text: user!.email,
                              ),
                            if (user?.phone.isNotEmpty == true)
                              _ProfileContact(
                                icon: Icons.phone_outlined,
                                text: user!.phone,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            Obx(() {
              final bio = controller.user?.bio ?? '';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bio.isNotEmpty
                            ? bio
                            : 'Add a short professional summary to introduce your background and goals.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.5,
                          color: bio.isEmpty ? Colors.grey : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Skills Card
            Obx(() {
              final skills = controller.user?.skills ?? [];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Technical Skills',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      if (skills.isEmpty)
                        Text(
                          'No skills added yet. Tap Edit Profile to add skills.',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: skills.map((s) {
                            return Chip(
                              label: Text(s),
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.12),
                              side: BorderSide.none,
                              labelStyle: GoogleFonts.inter(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              );
            }),

            if (controller.user?.role == UserRole.candidate) ...[
              const SizedBox(height: 16),

              // My Applications Pipeline
              Text(
                'My Job Applications',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Obx(() {
                final apps = jobController.myApplications;
                if (apps.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.assignment_outlined,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              'You have not applied for any jobs yet',
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: app.status.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:
                              Icon(Icons.work_history, color: app.status.color),
                        ),
                        title: Text(app.jobTitle,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text(
                            '${app.companyName} • Applied ${app.appliedAt.day}/${app.appliedAt.month}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: app.status.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            app.status.label,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: app.status.color,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ],

            const SizedBox(height: 24),
            // End of page refresh section
            Center(
              child: Column(
                children: [
                  Text(
                    "You've reached the bottom of profile page",
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileContact extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ProfileContact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.inter(fontSize: 12)),
      ],
    );
  }
}
