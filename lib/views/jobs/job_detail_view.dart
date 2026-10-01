import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../controllers/job_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../services/auth_service.dart';
import '../../models/job_model.dart';
import '../../models/company_profile.dart';
import '../../core/utils/constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/company_icons.dart';
import 'apply_job_modal.dart';

class JobDetailView extends GetView<JobController> {
  const JobDetailView({super.key});

  static final GlobalKey _shareKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final JobModel job = Get.arguments as JobModel;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = Get.find<AuthService>();
    final profileController = Get.find<ProfileController>();
    final isFavorite = profileController.user != null &&
        profileController.user!.favoriteCompanies.any(
          (company) => company.name.toLowerCase() == job.companyName.toLowerCase(),
        );

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(job.companyName),
            actions: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isFavorite ? AppColors.primary : null,
                ),
                onPressed: () {
                  if (!authService.isLoggedIn) {
                    Get.snackbar(
                      'Sign In Required',
                      'Please sign in to save job listings',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.primary,
                      colorText: Colors.white,
                    );
                    Get.toNamed(AppRoutes.login);
                    return;
                  }

                  final company = CompanyProfile(
                    id: 'company_${job.companyName}_${job.recruiterId}',
                    name: job.companyName,
                    location: job.location,
                    iconKey: job.companyIconKey.isNotEmpty
                        ? job.companyIconKey
                        : 'business',
                  );

                  final currentIsFavorite = profileController.user != null &&
                      profileController.user!.favoriteCompanies.any(
                        (item) => item.id == company.id ||
                            item.name.toLowerCase() == company.name.toLowerCase(),
                      );

                  profileController.toggleFavoriteCompany(company);
                  final updatedUser = authService.currentUser.value?.copyWith(
                    favoriteCompanies: profileController.favoriteCompanies.toList(),
                  );
                  if (updatedUser != null) {
                    authService.updateUserProfile(updatedUser);
                  }

                  Get.snackbar(
                    currentIsFavorite ? 'Removed from favorites' : 'Job company saved',
                    currentIsFavorite
                        ? 'Removed from your saved companies list'
                        : 'Added to your saved companies list',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.primary,
                    colorText: Colors.white,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => _handleShare(context, job),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Job Header Card Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (job.companyIconKey.isNotEmpty)
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: companyIconForKey(job.companyIconKey)
                                        .color
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    companyIconForKey(job.companyIconKey).icon,
                                    color:
                                        companyIconForKey(job.companyIconKey).color,
                                    size: 28,
                                  ),
                                )
                              else if (job.companyLogo.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    job.companyLogo,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 56,
                                      height: 56,
                                      color: AppColors.primary.withValues(alpha: 0.12),
                                      child: const Icon(Icons.business_rounded,
                                          color: AppColors.primary, size: 28),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.business_rounded,
                                      color: AppColors.primary, size: 28),
                                ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      job.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      job.companyName,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Quick Specs Card Box (2 rows, 2 items per row)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : AppColors.bgLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSpecItem(
                                      Icons.location_on_outlined,
                                      'Location',
                                      job.location,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildSpecItem(
                                      Icons.work_outline_rounded,
                                      'Type',
                                      job.jobType,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSpecItem(
                                      Icons.attach_money_rounded,
                                      'Salary',
                                      job.salaryRange,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildSpecItem(
                                      Icons.people_outline_rounded,
                                      'Applicants',
                                      '${controller.getApplicantCountForJob(job.id)}',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Job Description Card Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Job Description',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                job.description,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  height: 1.6,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Key Requirements Card Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Key Requirements',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...job.requirements.map((req) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          color: AppColors.secondary, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          req,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Required Skills Card Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Required Skills',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: job.skills.map((skill) {
                                  return Chip(
                                    label: Text(skill),
                                    backgroundColor:
                                        AppColors.primary.withValues(alpha: 0.12),
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
                      ],
                    ),
                  ),
                ),

                // Bottom Apply Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      )
                    ],
                  ),
                  child: Obx(() {
                    final alreadyApplied = controller.hasAppliedForJob(job.id);
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: alreadyApplied
                            ? Colors.grey.shade400
                            : AppColors.primary,
                      ),
                      onPressed: alreadyApplied
                          ? null
                          : () {
                              if (!authService.isLoggedIn) {
                                Get.snackbar(
                                  'Sign In Required',
                                  'Please sign in or register to apply for jobs',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.primary,
                                  colorText: Colors.white,
                                );
                                Get.toNamed(AppRoutes.login);
                                return;
                              }
                              Get.bottomSheet(
                                ApplyJobModal(job: job),
                                isScrollControlled: true,
                              );
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (alreadyApplied) ...[
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                          ],
                          Text(alreadyApplied ? 'Already Applied' : 'Apply Now'),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        // Offstage RepaintBoundary for screenshot generation (cropped: without title bar, without key requirements, till job description with apply option)
        Offstage(
          offstage: true,
          child: RepaintBoundary(
            key: _shareKey,
            child: Material(
              color: isDark ? AppColors.bgDark : AppColors.bgLight,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: _buildShareableCard(job, isDark),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareableCard(JobModel job, bool isDark) {
    return Container(
      width: 420,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business_rounded,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.companyName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Quick Specs
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.bgLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShareSpecItem(Icons.location_on_outlined, 'Location', job.location),
                _buildShareSpecItem(Icons.work_outline_rounded, 'Type', job.jobType),
                _buildShareSpecItem(Icons.attach_money_rounded, 'Salary', job.salaryRange),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Job Description
          Text(
            'Job Description',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            job.description,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.5,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),

          // Apply Now banner/button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '✨ Apply Now on Jobs App',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareSpecItem(IconData icon, String title, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(height: 2),
        Text(title, style: GoogleFonts.inter(fontSize: 9, color: Colors.grey)),
        const SizedBox(height: 1),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Future<void> _handleShare(BuildContext context, JobModel job) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      await Future.delayed(const Duration(milliseconds: 50));

      RenderRepaintBoundary? boundary =
          _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        if (Get.isDialogOpen == true) Get.back();
        await Share.share(_buildShareText(job));
        return;
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        if (Get.isDialogOpen == true) Get.back();
        await Share.share(_buildShareText(job));
        return;
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();
      final outputDir = await getTemporaryDirectory();
      final file = File(
          '${outputDir.path}/job_${job.id}_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);
      final xFile = XFile(file.path);

      if (Get.isDialogOpen == true) Get.back();

      _showShareBottomSheet(context, job, xFile);
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      await Share.share(_buildShareText(job));
    }
  }

  String _buildShareText(JobModel job) {
    return '🚀 *Job Opening: ${job.title}* at *${job.companyName}*!\n\n📍 Location: ${job.location}\n💰 Salary: ${job.salaryRange}\n💼 Type: ${job.jobType}\n\n✨ *Apply Now on Jobs App!*';
  }

  void _showShareBottomSheet(BuildContext context, JobModel job, XFile xFile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shareText = _buildShareText(job);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share Job',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Share "${job.title}" at ${job.companyName} (cropped till job description with Apply Now)',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.green,
                  size: 22,
                ),
              ),
              title: Text(
                'Share to WhatsApp',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Share job card & Apply Now to WhatsApp',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
              ),
              onTap: () async {
                Get.back();
                try {
                  await Share.shareXFiles(
                    [xFile],
                    text: shareText,
                    subject: 'Job Opening: ${job.title} at ${job.companyName}',
                  );
                } catch (e) {
                  await Share.share(shareText);
                }
              },
            ),
            const Divider(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.share_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              title: Text(
                'More Share Options',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Share image & text via other apps',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
              ),
              onTap: () async {
                Get.back();
                try {
                  await Share.shareXFiles(
                    [xFile],
                    text: shareText,
                    subject: 'Job Opening: ${job.title} at ${job.companyName}',
                  );
                } catch (e) {
                  await Share.share(shareText);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildSpecItem(IconData icon, String title, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(title, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
