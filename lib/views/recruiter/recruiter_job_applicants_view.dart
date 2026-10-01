import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/job_controller.dart';
import '../../core/utils/constants.dart';
import '../../models/application_model.dart';
import '../../models/job_model.dart';

class RecruiterJobApplicantsView extends GetView<JobController> {
  final JobModel job;

  const RecruiterJobApplicantsView({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applicants'),
        actions: [
          IconButton(
            tooltip: 'Edit job post',
            onPressed: () => controller.openJobEditor(job),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete job post',
            onPressed: () => _confirmDeleteJob(context),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
      body: Column(
        children: [
          Obx(
            () => _JobHeader(
              job: job,
              applicantCount: controller.getApplicantCountForJob(job.id),
            ),
          ),
          Expanded(
            child: Obx(() {
              final applicants = controller.getApplicantsForJob(job.id);
              if (applicants.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline,
                            size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No applications yet',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Candidates who apply for this position will appear here.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: applicants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) => _ApplicantCard(
                  application: applicants[index],
                  isDark: isDark,
                  onStatusChanged: (status) => controller.updateApplicantStage(
                    applicants[index].id,
                    status,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteJob(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete job post?'),
        content: Text(
          '“${job.title}” will be removed from job listings. Existing application records will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await controller.deleteJob(job);
      if (context.mounted) {
        Get.back();
        Get.snackbar(
          'Job post deleted',
          'The job post has been removed.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (error) {
      if (context.mounted) {
        Get.snackbar(
          'Could not delete job post',
          'Please try again. $error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    }
  }
}

class _JobHeader extends StatelessWidget {
  final JobModel job;
  final int applicantCount;

  const _JobHeader({required this.job, required this.applicantCount});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job.title,
            style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            '${job.companyName}  •  ${job.location}',
            style: GoogleFonts.inter(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _JobMetric(label: 'Applicants', value: '$applicantCount'),
              const SizedBox(width: 20),
              _JobMetric(label: 'Job type', value: job.jobType),
              const SizedBox(width: 20),
              Expanded(
                child:
                    _JobMetric(label: 'Experience', value: job.experienceLevel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JobMetric extends StatelessWidget {
  final String label;
  final String value;

  const _JobMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 3),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final ApplicationModel application;
  final bool isDark;
  final ValueChanged<ApplicationStatus> onStatusChanged;

  const _ApplicantCard({
    required this.application,
    required this.isDark,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final app = application;
    final firstName = app.candidateName.trim().isEmpty
        ? 'Candidate'
        : app.candidateName.trim().split(RegExp(r'\s+')).first;

    final headline = app.candidateHeadline.isNotEmpty
        ? app.candidateHeadline
        : 'Professional candidate';

    return Card(
      elevation: 1,
      color: isDark ? AppColors.cardDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showApplicantDetails(context, app),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    backgroundImage: app.candidateAvatar.isNotEmpty
                        ? NetworkImage(app.candidateAvatar)
                        : null,
                    child: app.candidateAvatar.isEmpty
                        ? Text(
                            firstName.substring(0, 1).toUpperCase(),
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          headline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusPicker(
                    status: app.status,
                    onChanged: onStatusChanged,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.bgDark : AppColors.bgLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _CompactInfoRow(
                        icon: Icons.work_outline,
                        label: 'Exp',
                        value: '${app.candidateExperienceYears} yrs',
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _CompactInfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Place',
                        value: app.candidateLocation.isNotEmpty
                            ? app.candidateLocation
                            : 'Remote',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApplicantDetails(BuildContext context, ApplicationModel app) {
    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        backgroundImage: app.candidateAvatar.isNotEmpty
                            ? NetworkImage(app.candidateAvatar)
                            : null,
                        child: app.candidateAvatar.isEmpty
                            ? Text(
                                app.candidateName.trim().isEmpty
                                    ? 'C'
                                    : app.candidateName.trim()[0].toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.candidateName.isEmpty ? 'Candidate' : app.candidateName,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (app.candidateHeadline.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                app.candidateHeadline,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (app.candidateEmail.isNotEmpty)
                    _DetailInfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: app.candidateEmail,
                    ),
                  if (app.candidatePhone.isNotEmpty)
                    _DetailInfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: app.candidatePhone,
                    ),
                  if (app.candidateLocation.isNotEmpty)
                    _DetailInfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: app.candidateLocation,
                    ),
                  _DetailInfoRow(
                    icon: Icons.work_outline,
                    label: 'Experience',
                    value: '${app.candidateExperienceYears} years',
                  ),
                  if (app.candidateBio.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Bio',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.bgDark : AppColors.bgLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        app.candidateBio,
                        style: GoogleFonts.inter(fontSize: 13, height: 1.5),
                      ),
                    ),
                  ],
                  if (app.candidateSkills.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'SKILLS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: app.candidateSkills
                          .map(
                            (skill) => Chip(
                              label: Text(skill),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                              side: BorderSide.none,
                              labelStyle: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (app.coverLetter.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'COVER LETTER',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.bgDark : AppColors.bgLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        app.coverLetter,
                        style: GoogleFonts.inter(fontSize: 13, height: 1.5),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgDark : AppColors.bgLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resume',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          app.resumeName.isNotEmpty ? app.resumeName : 'Resume.pdf',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (app.resumeUrl.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: app.resumeUrl),
                              );
                              Get.snackbar(
                                'Resume link copied',
                                'The resume URL has been copied to your clipboard.',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            },
                            icon: const Icon(Icons.copy_all_rounded, size: 18),
                            label: const Text('Copy resume link'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Close'),
                    ),
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

class _DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _StatusPicker extends StatelessWidget {
  final ApplicationStatus status;
  final ValueChanged<ApplicationStatus> onChanged;

  const _StatusPicker({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ApplicationStatus>(
      tooltip: 'Update application status',
      onSelected: onChanged,
      itemBuilder: (context) => ApplicationStatus.values
          .map(
            (value) => PopupMenuItem(
              value: value,
              child: Text(value.label),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: status.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status.label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: status.color,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.expand_more, size: 15, color: status.color),
          ],
        ),
      ),
    );
  }
}

class _CompactInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CompactInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
