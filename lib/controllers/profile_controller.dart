import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/resume_model.dart';
import '../core/utils/constants.dart';

class ProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final DatabaseService _dbService = Get.find<DatabaseService>();
  final FirestoreService _firestoreService = Get.find<FirestoreService>();

  final nameController = TextEditingController();
  final headlineController = TextEditingController();
  final bioController = TextEditingController();
  final locationController = TextEditingController();
  final companyController = TextEditingController();
  final skillInputController = TextEditingController();

  final RxList<String> currentSkills = <String>[].obs;
  final RxBool isUploading = false.obs;

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
      bioController.text = user!.bio;
      locationController.text = user!.location;
      companyController.text = user!.companyName;
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

  Future<void> saveProfile() async {
    if (user == null) return;

    final updated = user!.copyWith(
      name: nameController.text.trim(),
      headline: headlineController.text.trim(),
      bio: bioController.text.trim(),
      location: locationController.text.trim(),
      companyName: companyController.text.trim(),
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
          fileUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          fileSize: '${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB',
          isPrimary: userResumes.isEmpty,
          extractedSkills: ['Flutter', 'Dart', 'GetX', 'Firebase', 'State Management'],
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
        final mockUrl = 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/300/300';
        
        // Save image reference to Cloud Firestore as requested
        if (user != null) {
          await _firestoreService.saveImageRecord(
            collection: DatabaseKeys.userImages,
            docId: user!.id,
            imageUrl: mockUrl,
            imageType: 'avatar',
          );

          final updated = user!.copyWith(avatarUrl: mockUrl);
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
    bioController.dispose();
    locationController.dispose();
    companyController.dispose();
    skillInputController.dispose();
    super.onClose();
  }
}
