import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/company_icons.dart';
import '../../core/routes/app_routes.dart';
import '../../models/company_profile.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';

class EditProfileView extends StatefulWidget {
  final UserModel? targetUser;

  const EditProfileView({super.key, this.targetUser});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late final TextEditingController _nameController;
  late final TextEditingController _headlineController;
  late final TextEditingController _locationController;
  late final TextEditingController _phoneController;
  late final TextEditingController _experienceController;
  late final TextEditingController _bioController;
  late final TextEditingController _skillInputController;

  final RxList<String> _currentSkills = <String>[].obs;
  final RxList<CompanyProfile> _companies = <CompanyProfile>[].obs;
  UserModel? _user;
  bool _isEditingOtherUser = false;

  @override
  void initState() {
    super.initState();
    final profileController =
        Get.isRegistered<ProfileController>() ? Get.find<ProfileController>() : null;
    
    // Check if targetUser was passed directly or via Get.arguments
    _user = widget.targetUser ??
        (Get.arguments is UserModel ? Get.arguments as UserModel : null) ??
        profileController?.user;

    final currentLoggedInId = profileController?.user?.id ?? '';
    _isEditingOtherUser = _user != null && _user!.id != currentLoggedInId;

    _nameController = TextEditingController(text: _user?.name ?? '');
    _headlineController = TextEditingController(text: _user?.headline ?? '');
    _locationController = TextEditingController(text: _user?.location ?? '');
    _phoneController = TextEditingController(text: _user?.phone ?? '');
    _experienceController =
        TextEditingController(text: (_user?.experienceYears ?? 0).toString());
    _bioController = TextEditingController(text: _user?.bio ?? '');
    _skillInputController = TextEditingController();

    if (_user != null) {
      _currentSkills.assignAll(_user!.skills);
      if (_user!.companies.isNotEmpty) {
        _companies.assignAll(_user!.companies);
      } else if (_user!.companyName.trim().isNotEmpty) {
        _companies.assignAll([
          CompanyProfile(
            id: 'company_${_user!.id}',
            name: _user!.companyName,
            location: _user!.companyLocation,
            iconKey: _user!.companyIconKey.isNotEmpty
                ? _user!.companyIconKey
                : 'business',
          ),
        ]);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headlineController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _skillInputController.dispose();
    super.dispose();
  }

  void _addSkill() {
    final skill = _skillInputController.text.trim();
    if (skill.isNotEmpty && !_currentSkills.contains(skill)) {
      _currentSkills.add(skill);
      _skillInputController.clear();
    }
  }

  void _removeSkill(String skill) {
    _currentSkills.remove(skill);
  }

  Future<void> _handleSaveProfile() async {
    if (_user == null) return;

    final primaryCompany = _companies.isNotEmpty ? _companies.first : null;
    final updated = _user!.copyWith(
      name: _nameController.text.trim(),
      headline: _headlineController.text.trim(),
      phone: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
      location: _locationController.text.trim(),
      experienceYears: int.tryParse(_experienceController.text.trim()) ??
          _user!.experienceYears,
      companyName: primaryCompany?.name ?? '',
      companyLocation: primaryCompany?.location ?? '',
      companyIconKey: primaryCompany?.iconKey ?? 'business',
      companies: _companies.toList(),
      skills: _currentSkills.toList(),
    );

    if (_isEditingOtherUser) {
      // Admin editing candidate: Save to DatabaseService and AdminController
      final dbService = Get.find<DatabaseService>();
      await dbService.saveUserProfile(updated);
      final idx = dbService.usersList.indexWhere((u) => u.id == updated.id);
      if (idx != -1) {
        dbService.usersList[idx] = updated;
      }
      if (Get.isRegistered<AdminController>()) {
        Get.find<AdminController>().updateUserProfile(updated);
      }
      Get.back();
      Get.snackbar(
        'Profile Updated',
        'Candidate profile changes have been saved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.secondary,
        colorText: Colors.white,
      );
    } else {
      // Candidate editing their own profile
      final profileController = Get.find<ProfileController>();
      profileController.nameController.text = _nameController.text.trim();
      profileController.headlineController.text =
          _headlineController.text.trim();
      profileController.phoneController.text = _phoneController.text.trim();
      profileController.bioController.text = _bioController.text.trim();
      profileController.locationController.text =
          _locationController.text.trim();
      profileController.currentSkills.assignAll(_currentSkills);
      profileController.companies.assignAll(_companies);
      await profileController.saveProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditingOtherUser
        ? 'Edit ${_user?.name ?? 'Candidate'}\'s Profile'
        : 'Edit Profile';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'e.g. Alex Rivera'),
              ),
              const SizedBox(height: 16),

              Text('Professional Headline',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _headlineController,
                decoration: const InputDecoration(
                    hintText: 'e.g. Senior Flutter Developer'),
              ),
              const SizedBox(height: 16),

              Text('Location',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _locationController,
                decoration:
                    const InputDecoration(hintText: 'e.g. San Francisco, CA'),
              ),
              const SizedBox(height: 16),

              Text('Mobile Number / Phone',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'e.g. +1 555-0199 or +91 9876543210',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              Text('Experience (Years)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _experienceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'e.g. 3',
                  prefixIcon: Icon(Icons.work_history_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              if (_user?.role == UserRole.recruiter) ...[
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
                  () => _companies.isEmpty
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
                          children: _companies.map((company) {
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
                                      _companies.removeWhere((c) => c.id == company.id),
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
                controller: _bioController,
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
                      controller: _skillInputController,
                      decoration: const InputDecoration(
                          hintText: 'e.g. Flutter, Dart, Firebase'),
                      onSubmitted: (_) => _addSkill(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _addSkill,
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
                    children: _currentSkills.map((skill) {
                      return Chip(
                        label: Text(skill),
                        onDeleted: () => _removeSkill(skill),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  )),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _handleSaveProfile,
                  child: const Text('Save Profile Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editCompany(
    BuildContext context, [
    CompanyProfile? company,
  ]) async {
    final result = await showDialog<CompanyProfile>(
      context: context,
      builder: (_) => CompanyEditorDialog(company: company),
    );
    if (result != null) {
      final index = _companies.indexWhere((item) => item.id == result.id);
      if (index == -1) {
        final duplicate = _companies.any(
          (item) => item.name.toLowerCase() == result.name.toLowerCase(),
        );
        if (duplicate) {
          Get.snackbar(
            'Company already added',
            'Use a different company name.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
          return;
        }
        _companies.add(result);
      } else {
        final duplicate = _companies.any(
          (item) =>
              item.id != result.id &&
              item.name.toLowerCase() == result.name.toLowerCase(),
        );
        if (duplicate) {
          Get.snackbar(
            'Company already added',
            'Use a different company name.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
          return;
        }
        _companies[index] = result;
      }

      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().saveCompany(result);
      }
    }
  }
}

class CompanyEditorDialog extends StatefulWidget {
  const CompanyEditorDialog({super.key, this.company});

  final CompanyProfile? company;

  @override
  State<CompanyEditorDialog> createState() => _CompanyEditorDialogState();
}

class _CompanyEditorDialogState extends State<CompanyEditorDialog> {
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
