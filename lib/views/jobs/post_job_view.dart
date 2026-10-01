import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/job_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/constants.dart';

import '../../services/auth_service.dart';

class PostJobView extends GetView<JobController> {
  const PostJobView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final mutedColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.editingJob.value == null
                ? 'Post a New Job'
                : 'Edit Job Post',
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF172554), Color(0xFF1E293B)]
                        : const [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : const Color(0xFFDBEAFE),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.post_add_rounded,
                        color: AppColors.primary,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.editingJob.value == null
                                ? 'Create a job listing'
                                : 'Update your job listing',
                            style: GoogleFonts.inter(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Add clear details to help the right candidates find your role.',
                            style: GoogleFonts.inter(
                              color: mutedColor,
                              fontSize: 11,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _FormSection(
                number: '01',
                icon: Icons.work_outline_rounded,
                title: 'Job overview',
                subtitle: 'The role and the company candidates will see.',
                children: [
                  _FieldLabel(text: 'Job title', required: true),
                  const SizedBox(height: 7),
                  TextField(
                    controller: controller.postTitleController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Senior Flutter Developer',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel(text: 'Company name', required: true),
                  const SizedBox(height: 7),
                  Obx(() {
                    final companies = controller.postCompanyOptions;
                    final isAdmin = Get.find<AuthService>().currentUser.value?.role == UserRole.admin;
                    if (companies.isEmpty || isAdmin) {
                      return TextField(
                        controller: controller.postCompanyController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Acme Corporation',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                      );
                    }
                    final selected = companies
                            .contains(controller.postCompanyController.text)
                        ? controller.postCompanyController.text
                        : null;
                    return DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selected,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      hint: const Text('Select your company'),
                      items: companies
                          .map(
                            (name) => DropdownMenuItem(
                              value: name,
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => value == null
                          ? null
                          : controller.selectPostCompany(value),
                    );
                  }),
                  Obx(() {
                    final isAdmin = Get.find<AuthService>().currentUser.value?.role == UserRole.admin;
                    if (!isAdmin && controller.postCompanyOptions.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: TextButton.icon(
                          onPressed: () => Get.toNamed(AppRoutes.editProfile),
                          icon: const Icon(Icons.add_business_outlined, size: 18),
                          label: const Text('Add company details in your profile'),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  const SizedBox(height: 16),
                  _FieldLabel(text: 'Work location', required: true),
                  const SizedBox(height: 7),
                  TextField(
                    controller: controller.postLocationController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Bengaluru, Karnataka (Hybrid)',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _FormSection(
                number: '02',
                icon: Icons.tune_rounded,
                title: 'Employment details',
                subtitle: 'Set expectations for the position.',
                children: [
                  _FieldLabel(text: 'Job type'),
                  const SizedBox(height: 7),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: controller.postJobType.value,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.schedule_rounded),
                      ),
                      items: const [
                        'Full-time',
                        'Part-time',
                        'Contract',
                        'Remote',
                        'Internship',
                      ]
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child:
                                  Text(type, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) controller.postJobType.value = value;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel(text: 'Experience required'),
                  const SizedBox(height: 7),
                  TextField(
                    controller: controller.postExperienceController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 2–5 years',
                      prefixIcon: Icon(Icons.trending_up_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel(text: 'Salary range'),
                  const SizedBox(height: 7),
                  TextField(
                    controller: controller.postSalaryController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      hintText: 'e.g. ₹8,00,000–₹12,00,000 per annum',
                      prefixIcon: Icon(Icons.currency_rupee_rounded),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Leave blank if compensation is as per company standards.',
                    style: GoogleFonts.inter(fontSize: 10, color: mutedColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _FormSection(
                number: '03',
                icon: Icons.description_outlined,
                title: 'Role description',
                subtitle: 'Explain what the successful candidate will do.',
                children: [
                  _FieldLabel(text: 'Job description', required: true),
                  const SizedBox(height: 7),
                  TextField(
                    controller: controller.postDescriptionController,
                    minLines: 5,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      hintText:
                          'Describe the role, team, responsibilities and what success looks like...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel(text: 'Key requirements'),
                  const SizedBox(height: 4),
                  Text(
                    'Add one requirement per line.',
                    style: GoogleFonts.inter(fontSize: 10, color: mutedColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  TextField(
                    controller: controller.postRequirementsController,
                    minLines: 4,
                    maxLines: 7,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      hintText:
                          'Relevant degree or equivalent experience\nStrong communication skills\nExperience with required technologies',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _FormSection(
                number: '04',
                icon: Icons.auto_awesome_outlined,
                title: 'Required skills',
                subtitle: 'Add skills candidates should have for this role.',
                children: [
                  _FieldLabel(text: 'Skills'),
                  const SizedBox(height: 7),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.postSkillInputController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => controller.addPostSkill(),
                          decoration: const InputDecoration(
                            hintText: 'e.g. Flutter',
                            prefixIcon: Icon(Icons.sell_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: controller.addPostSkill,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(54, 54),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(Icons.add_rounded),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => controller.postSkills.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDark ? AppColors.bgDark : AppColors.bgLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                              ),
                            ),
                            child: Text(
                              'No skills added yet. Add a skill above.',
                              style: GoogleFonts.inter(
                                color: mutedColor,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: controller.postSkills
                                .map(
                                  (skill) => InputChip(
                                    label: Text(
                                      skill,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onDeleted: () =>
                                        controller.removePostSkill(skill),
                                    deleteIcon: const Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                    ),
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.08),
                                    side: BorderSide(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.18),
                                    ),
                                    labelStyle: GoogleFonts.inter(
                                      color: isDark
                                          ? AppColors.primaryLight
                                          : AppColors.primaryDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ElevatedButton.icon(
                    onPressed: controller.createAndPublishJob,
                    icon: Icon(controller.editingJob.value == null
                        ? Icons.publish_rounded
                        : Icons.save_outlined),
                    label: Text(controller.editingJob.value == null
                        ? 'Publish job listing'
                        : 'Save changes'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Fields marked with * are required',
                  style: GoogleFonts.inter(fontSize: 10, color: mutedColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String number;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 21),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          height: 1.2,
                          color: mutedColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  number,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final labelColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          color: labelColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(text: text),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.error),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
