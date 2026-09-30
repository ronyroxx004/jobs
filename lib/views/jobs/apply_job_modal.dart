import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/job_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../models/job_model.dart';
import '../../core/utils/constants.dart';

class ApplyJobModal extends GetView<JobController> {
  final JobModel job;
  const ApplyJobModal({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
              'Apply for ${job.title}',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Submitting application to ${job.companyName}',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Select Resume Section
            Text('Select Resume', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),

            Obx(() {
              final resumes = profileController.userResumes;
              if (resumes.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No resumes found on your profile. Upload one now to apply.',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () => profileController.pickAndUploadResume(),
                        child: const Text('Upload PDF'),
                      ),
                    ],
                  ),
                );
              }

              final selectedResume = controller.selectedResumeForApply.value;

              return Column(
                children: resumes.map((resume) {
                  final selected = selectedResume?.id == resume.id ||
                      (selectedResume == null && resume.isPrimary);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => controller.selectResumeForApply(resume),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary.withOpacity(0.1) : (isDark ? AppColors.bgDark : AppColors.bgLight),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resume.fileName,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    '${resume.fileSize} • Skills: ${resume.extractedSkills.take(3).join(', ')}',
                                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
            const SizedBox(height: 16),

            // Cover Letter Input
            Text('Cover Letter / Message (Optional)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: controller.coverLetterController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Introduce yourself and share why you are a great fit for this position...',
              ),
            ),
            const SizedBox(height: 24),

            // Apply Button
            ElevatedButton(
              onPressed: () => controller.submitJobApplication(job),
              child: const Text('Submit Application'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
