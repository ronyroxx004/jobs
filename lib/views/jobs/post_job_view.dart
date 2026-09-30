import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/job_controller.dart';

class PostJobView extends GetView<JobController> {
  const PostJobView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a New Job')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Job Listing',
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Fill in the job specifications to reach qualified candidates',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Title
              Text('Job Title *', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: controller.postTitleController,
                decoration: const InputDecoration(hintText: 'e.g. Senior Flutter Developer'),
              ),
              const SizedBox(height: 16),

              // Company
              Text('Company Name *', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: controller.postCompanyController,
                decoration: const InputDecoration(hintText: 'e.g. TechCorp Solutions'),
              ),
              const SizedBox(height: 16),

              // Location
              Text('Location / Remote *', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: controller.postLocationController,
                decoration: const InputDecoration(hintText: 'e.g. San Francisco, CA (Remote)'),
              ),
              const SizedBox(height: 16),

              // Salary Range
              Text('Salary Range', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: controller.postSalaryController,
                decoration: const InputDecoration(hintText: 'e.g. \$120,000 - \$150,000 / yr'),
              ),
              const SizedBox(height: 16),

              // Job Type & Experience Level
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Job Type', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Obx(() => DropdownButtonFormField<String>(
                              initialValue: controller.postJobType.value,
                              items: ['Full-time', 'Part-time', 'Contract', 'Remote', 'Internship']
                                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) controller.postJobType.value = val;
                              },
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Experience', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Obx(() => DropdownButtonFormField<String>(
                              initialValue: controller.postExperienceLevel.value,
                              items: ['Entry-Level', 'Mid-Level', 'Senior', 'Lead']
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) controller.postExperienceLevel.value = val;
                              },
                            )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Required Skills
              Text('Required Skills (comma separated)', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: controller.postSkillsController,
                decoration: const InputDecoration(hintText: 'Flutter, Dart, GetX, Firebase'),
              ),
              const SizedBox(height: 16),

              // Description
              Text('Job Description *', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: controller.postDescriptionController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Detailed description of the role, team, and expectations...'),
              ),
              const SizedBox(height: 16),

              // Requirements
              Text('Key Requirements (one per line)', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: controller.postRequirementsController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: '4+ years Flutter experience\nStrong state management skills\nFirebase integration'),
              ),
              const SizedBox(height: 28),

              // Submit
              ElevatedButton(
                onPressed: controller.createAndPublishJob,
                child: const Text('Publish Job Listing 🚀'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
