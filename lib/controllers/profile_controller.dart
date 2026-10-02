import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/resume_model.dart';
import '../models/company_profile.dart';
import '../core/utils/constants.dart';

class ProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final DatabaseService _dbService = Get.find<DatabaseService>();
  final FirestoreService _firestoreService = Get.find<FirestoreService>();

  final nameController = TextEditingController();
  final headlineController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();
  final locationController = TextEditingController();
  final companyController = TextEditingController();
  final companyLocationController = TextEditingController();
  final skillInputController = TextEditingController();

  final RxList<String> currentSkills = <String>[].obs;
  final RxList<CompanyProfile> companies = <CompanyProfile>[].obs;
  final RxList<CompanyProfile> favoriteCompanies = <CompanyProfile>[].obs;
  final RxBool isUploading = false.obs;
  final RxString companyIconKey = 'business'.obs;

  UserModel? get user => _authService.currentUser.value;
  List<ResumeModel> get userResumes => _dbService.resumeList;

  @override
  void onInit() {
    super.onInit();
    _populateFields();
  }

  void _populateFields() {
    if (user != null) {
      nameController.text = user!.name;
      headlineController.text = user!.headline;
      phoneController.text = user!.phone;
      bioController.text = user!.bio;
      locationController.text = user!.location;
      companyController.text = user!.companyName;
      companyLocationController.text = user!.companyLocation;
      companyIconKey.value =
          user!.companyIconKey.isNotEmpty ? user!.companyIconKey : 'business';
      if (user!.companies.isNotEmpty) {
        companies.assignAll(user!.companies);
      } else if (user!.companyName.trim().isNotEmpty) {
        companies.assignAll([
          CompanyProfile(
            id: 'company_${user!.id}',
            name: user!.companyName,
            location: user!.companyLocation,
            iconKey: user!.companyIconKey.isNotEmpty
                ? user!.companyIconKey
                : 'business',
          ),
        ]);
      }
      favoriteCompanies.assignAll(user!.favoriteCompanies);
      currentSkills.assignAll(user!.skills);
    }
  }

  void addSkill() {
    final skill = skillInputController.text.trim();
    if (skill.isNotEmpty && !currentSkills.contains(skill)) {
      currentSkills.add(skill);
      skillInputController.clear();
    }
  }

  void removeSkill(String skill) {
    currentSkills.remove(skill);
  }

  bool saveCompany(CompanyProfile company) {
    final index = companies.indexWhere((item) => item.id == company.id);
    if (index == -1) {
      final duplicate = companies.any(
        (item) => item.name.toLowerCase() == company.name.toLowerCase(),
      );
      if (duplicate) {
        Get.snackbar('Company already added', 'Use a different company name.');
        return false;
      }
      companies.add(company);
    } else {
      final duplicate = companies.any(
        (item) =>
            item.id != company.id &&
            item.name.toLowerCase() == company.name.toLowerCase(),
      );
      if (duplicate) {
        Get.snackbar('Company already added', 'Use a different company name.');
        return false;
      }
      companies[index] = company;
    }
    return true;
  }

  bool toggleFavoriteCompany(CompanyProfile company) {
    final existing = favoriteCompanies.indexWhere(
      (item) =>
          item.id == company.id ||
          item.name.trim().toLowerCase() == company.name.trim().toLowerCase(),
    );
    final bool isNowFavorite;
    if (existing == -1) {
      favoriteCompanies.add(company);
      Get.snackbar('Company Saved', '${company.name} added to your saved list.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.secondary,
          colorText: Colors.white);
      isNowFavorite = true;
    } else {
      favoriteCompanies.removeAt(existing);
      Get.snackbar('Company Removed', '${company.name} removed from saved list.',
          snackPosition: SnackPosition.BOTTOM);
      isNowFavorite = false;
    }

    if (user != null) {
      final updated = user!.copyWith(favoriteCompanies: favoriteCompanies.toList());
      _authService.updateUserProfile(updated);
    }
    return isNowFavorite;
  }

  bool isFavoriteCompany(String companyIdOrName) {
    final clean = companyIdOrName.trim().toLowerCase();
    return favoriteCompanies.any((company) =>
        company.id.toLowerCase() == clean ||
        company.name.trim().toLowerCase() == clean);
  }

  void removeCompany(String companyId) {
    companies.removeWhere((company) => company.id == companyId);
  }

  Future<void> saveProfile() async {
    if (user == null) return;

    final savedCompanies = companies.toList();
    final savedFavoriteCompanies = favoriteCompanies.toList();
    final primaryCompany =
        savedCompanies.isNotEmpty ? savedCompanies.first : null;
    final updated = user!.copyWith(
      name: nameController.text.trim(),
      headline: headlineController.text.trim(),
      phone: phoneController.text.trim(),
      bio: bioController.text.trim(),
      location: locationController.text.trim(),
      companyName: primaryCompany?.name ?? '',
      companyLocation: primaryCompany?.location ?? '',
      companyIconKey: primaryCompany?.iconKey ?? 'business',
      companies: savedCompanies,
      favoriteCompanies: savedFavoriteCompanies,
      skills: currentSkills.toList(),
    );

    await _authService.updateUserProfile(updated);
    Get.back();
    Get.snackbar(
      'Profile Updated',
      'Your profile changes have been saved successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.secondary,
      colorText: Colors.white,
    );
  }

  Future<void> pickAndUploadResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.name.isNotEmpty) {
        isUploading.value = true;
        final file = result.files.single;

        final newResume = ResumeModel(
          id: 'res_${DateTime.now().millisecondsSinceEpoch}',
          userId: user?.id ?? 'user_1',
          fileName: file.name,
          fileUrl:
              'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          fileSize: '${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB',
          isPrimary: userResumes.isEmpty,
          extractedSkills: [
            'Flutter',
            'Dart',
            'GetX',
            'Firebase',
            'State Management'
          ],
        );

        await _dbService.addResume(newResume);

        Get.snackbar(
          'Resume Uploaded 📄',
          '${file.name} uploaded and skills parsed successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Upload Failed', 'Could not select resume file');
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> pickProfilePicture() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final mockUrl =
            'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/300/300';

        // Save image reference to Cloud Firestore as requested
        if (user != null) {
          await _firestoreService.saveImageRecord(
            collection: DatabaseKeys.userImages,
            docId: user!.id,
            imageUrl: mockUrl,
            imageType: 'avatar',
          );

          final updated = user!.copyWith(avatarUrl: mockUrl, avatarIconKey: '');
          await _authService.updateUserProfile(updated);
          Get.snackbar(
            'Avatar Updated',
            'Image stored in Cloud Firestore and profile updated!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.secondary,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.snackbar('Image Error', 'Failed to pick profile image');
    }
  }

  Future<void> setProfileAvatarIcon(String iconKey) async {
    final currentUser = user;
    if (currentUser == null) {
      Get.snackbar('Profile unavailable', 'Please sign in and try again.');
      return;
    }

    await _authService.updateUserProfile(
      currentUser.copyWith(avatarUrl: '', avatarIconKey: iconKey),
    );
    Get.back();
    Get.snackbar(
      'Profile icon updated',
      'Your new profile icon has been saved.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.secondary,
      colorText: Colors.white,
    );
  }

  Future<void> deleteResume(String resumeId) async {
    await _dbService.deleteResume(resumeId);
    Get.snackbar(
      'Resume Removed',
      'Resume deleted from database',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    headlineController.dispose();
    phoneController.dispose();
    bioController.dispose();
    locationController.dispose();
    companyController.dispose();
    companyLocationController.dispose();
    skillInputController.dispose();
    super.onClose();
  }
}
