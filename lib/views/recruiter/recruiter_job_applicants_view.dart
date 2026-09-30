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
      appBar: AppBar(title: const Text('Job Applicants')),
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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
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
    final initials = app.candidateName.trim().isEmpty
        ? 'C'
        : app.candidateName.trim().substring(0, 1).toUpperCase();

    return Card(
      elevation: 1,
      color: isDark ? AppColors.cardDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  backgroundImage: app.candidateAvatar.isNotEmpty
                      ? NetworkImage(app.candidateAvatar)
                      : null,
                  child: app.candidateAvatar.isEmpty
                      ? Text(initials,
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.candidateName.isEmpty
                            ? 'Candidate'
                            : app.candidateName,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (app.candidateHeadline.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          app.candidateHeadline,
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 5),
                      Text(
                        'Applied ${_formatDate(app.appliedAt)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey,
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
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                if (app.candidateEmail.isNotEmpty)
                  _DetailLine(
                    icon: Icons.email_outlined,
                    text: app.candidateEmail,
                  ),
                if (app.candidatePhone.isNotEmpty)
                  _DetailLine(
                    icon: Icons.phone_outlined,
                    text: app.candidatePhone,
                  ),
                if (app.candidateLocation.isNotEmpty)
                  _DetailLine(
                    icon: Icons.location_on_outlined,
                    text: app.candidateLocation,
                  ),
                _DetailLine(
                  icon: Icons.work_outline,
                  text: '${app.candidateExperienceYears} years experience',
                ),
              ],
            ),
            if (app.candidateBio.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionLabel(title: 'PROFILE'),
              const SizedBox(height: 5),
              Text(
                app.candidateBio,
                style: GoogleFonts.inter(fontSize: 13, height: 1.45),
              ),
            ],
            if (app.candidateSkills.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionLabel(title: 'SKILLS'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: app.candidateSkills
                    .map(
                      (skill) => Chip(
                        label: Text(skill),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.primary.withOpacity(0.08),
                        side: BorderSide.none,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (app.coverLetter.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionLabel(title: 'COVER LETTER'),
              const SizedBox(height: 5),
              Text(
                app.coverLetter,
                style: GoogleFonts.inter(fontSize: 13, height: 1.45),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgDark : AppColors.bgLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Submitted resume',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: Colors.grey)),
                        Text(
                          app.resumeName,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (app.resumeUrl.isNotEmpty)
                    IconButton(
                      tooltip: 'Copy resume link',
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: app.resumeUrl),
                        );
                        Get.snackbar(
                          'Resume link copied',
                          'Paste the link to open the submitted resume.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 5),
        Text(text, style: GoogleFonts.inter(fontSize: 12)),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          letterSpacing: 0.8,
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      );
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
          color: status.color.withOpacity(0.12),
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
