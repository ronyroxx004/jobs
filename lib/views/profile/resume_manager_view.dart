import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/profile_controller.dart';
import '../../core/utils/constants.dart';

class ResumeManagerView extends GetView<ProfileController> {
  const ResumeManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Resume Manager')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manage Resumes',
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Upload PDF/DOC resumes to apply for jobs and share with recruiters',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Upload Button
              Obx(() => ElevatedButton.icon(
                    onPressed: controller.isUploading.value ? null : controller.pickAndUploadResume,
                    icon: controller.isUploading.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_rounded),
                    label: Text(controller.isUploading.value ? 'Uploading...' : 'Upload New Resume (PDF / DOC)'),
                  )),
              const SizedBox(height: 24),

              Text(
                'Saved Resumes',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: Obx(() {
                  final resumes = controller.userResumes;
                  if (resumes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.picture_as_pdf_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            'No resumes uploaded yet',
                            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: resumes.length,
                    itemBuilder: (context, index) {
                      final resume = resumes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 36),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          resume.fileName,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          '${resume.fileSize} • Uploaded ${resume.uploadedAt.day}/${resume.uploadedAt.month}/${resume.uploadedAt.year}',
                                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (resume.isPrimary)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Primary',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => controller.deleteResume(resume.id),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Parsed Skills Preview
                              Text(
                                'Parsed Resume Skills:',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: resume.extractedSkills.map((skill) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.bgDark : AppColors.bgLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      skill,
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
