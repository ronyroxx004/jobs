import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/profile_controller.dart';
import '../../core/utils/constants.dart';

class EditProfileView extends GetView<ProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Full Name', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: controller.nameController,
                decoration: const InputDecoration(hintText: 'e.g. Alex Rivera'),
              ),
              const SizedBox(height: 16),

              Text('Professional Headline', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: controller.headlineController,
                decoration: const InputDecoration(hintText: 'e.g. Senior Flutter Developer'),
              ),
              const SizedBox(height: 16),

              Text('Location', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: controller.locationController,
                decoration: const InputDecoration(hintText: 'e.g. San Francisco, CA'),
              ),
              const SizedBox(height: 16),

              Text('Bio / Overview', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: controller.bioController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Describe your background, achievements, and career goals...'),
              ),
              const SizedBox(height: 20),

              // Add Skills Section
              Text('Manage Technical Skills', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.skillInputController,
                      decoration: const InputDecoration(hintText: 'e.g. Flutter, Dart, Firebase'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: controller.addSkill,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(60, 50),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Obx(() => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: controller.currentSkills.map((skill) {
                      return Chip(
                        label: Text(skill),
                        onDeleted: () => controller.removeSkill(skill),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  )),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: controller.saveProfile,
                child: const Text('Save Profile Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
