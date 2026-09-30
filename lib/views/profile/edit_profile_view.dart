import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/profile_controller.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/company_icons.dart';
import '../../core/routes/app_routes.dart';
import '../../models/company_profile.dart';

class EditProfileView extends GetView<ProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            tooltip: 'Manage resumes',
            icon: const Icon(Icons.description_outlined),
            onPressed: () => Get.toNamed(AppRoutes.resumeManager),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Full Name',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: controller.nameController,
                decoration: const InputDecoration(hintText: 'e.g. Alex Rivera'),
              ),
              const SizedBox(height: 16),

              Text('Professional Headline',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: controller.headlineController,
                decoration: const InputDecoration(
                    hintText: 'e.g. Senior Flutter Developer'),
              ),
              const SizedBox(height: 16),

              Text('Location',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: controller.locationController,
                decoration:
                    const InputDecoration(hintText: 'e.g. San Francisco, CA'),
              ),
              const SizedBox(height: 16),

              if (controller.user?.role == UserRole.recruiter) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Company profiles',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _editCompany(context),
                      icon: const Icon(Icons.add_business_outlined, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Add the companies you recruit for. They will be available when you post a job.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => controller.companies.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No companies added yet.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: controller.companies.map((company) {
                            final icon = companyIconForKey(company.iconKey);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: icon.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Icon(icon.icon, color: icon.color),
                                ),
                                title: Text(
                                  company.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  company.location.isEmpty
                                      ? 'Company place not added'
                                      : company.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _editCompany(context, company),
                                trailing: IconButton(
                                  tooltip: 'Remove company',
                                  onPressed: () =>
                                      controller.removeCompany(company.id),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 20),
              ],

              Text('Bio / Overview',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: controller.bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText:
                        'Describe your background, achievements, and career goals...'),
              ),
              const SizedBox(height: 20),

              // Add Skills Section
              Text('Manage Technical Skills',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.skillInputController,
                      decoration: const InputDecoration(
                          hintText: 'e.g. Flutter, Dart, Firebase'),
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

Future<void> _editCompany(
  BuildContext context, [
  CompanyProfile? company,
]) async {
  final controller = Get.find<ProfileController>();
  final result = await showDialog<CompanyProfile>(
    context: context,
    builder: (_) => _CompanyEditorDialog(company: company),
  );
  if (result != null) controller.saveCompany(result);
}

class _CompanyEditorDialog extends StatefulWidget {
  const _CompanyEditorDialog({this.company});

  final CompanyProfile? company;

  @override
  State<_CompanyEditorDialog> createState() => _CompanyEditorDialogState();
}

class _CompanyEditorDialogState extends State<_CompanyEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late String _iconKey;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.company?.name ?? '');
    _locationController =
        TextEditingController(text: widget.company?.location ?? '');
    _iconKey = widget.company?.iconKey ?? 'business';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      CompanyProfile(
        id: widget.company?.id ??
            'company_${DateTime.now().microsecondsSinceEpoch}',
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        iconKey: _iconKey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.company == null ? 'Add a company' : 'Edit company'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a company name'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Company name',
                  hintText: 'e.g. Infosys Limited',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Company place',
                  hintText: 'e.g. Bengaluru, Karnataka',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Company icon',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 172,
                child: GridView.builder(
                  itemCount: companyIconOptions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisExtent: 78,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final option = companyIconOptions[index];
                    final selected = option.key == _iconKey;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _iconKey = option.key),
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: option.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: selected
                                    ? option.color
                                    : option.color.withValues(alpha: 0.25),
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Icon(option.icon, color: option.color),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 9),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(widget.company == null ? 'Add company' : 'Save'),
        ),
      ],
    );
  }
}
