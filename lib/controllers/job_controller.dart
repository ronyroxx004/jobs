import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/job_model.dart';
import '../models/application_model.dart';
import '../models/resume_model.dart';
import '../core/utils/constants.dart';

class JobController extends GetxController {
  final DatabaseService _dbService = Get.find<DatabaseService>();
  final AuthService _authService = Get.find<AuthService>();

  final searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxString selectedTypeFilter = 'All'.obs;
  final RxString selectedExperienceFilter = 'All'.obs;

  // Post Job Controllers for Recruiters
  final postTitleController = TextEditingController();
  final postCompanyController = TextEditingController();
  final postLocationController = TextEditingController();
  final postSalaryController = TextEditingController();
  final postDescriptionController = TextEditingController();
  final postRequirementsController = TextEditingController();
  final postSkillsController = TextEditingController();
  final RxString postJobType = 'Full-time'.obs;
  final RxString postExperienceLevel = 'Mid-Level'.obs;

  // Selected Resume for Application
  final Rx<ResumeModel?> selectedResumeForApply = Rx<ResumeModel?>(null);
  final coverLetterController = TextEditingController();

  List<JobModel> get allJobs => _dbService.jobsList;
  List<ApplicationModel> get myApplications {
    final candidateId = _authService.currentUser.value?.id ?? '';
    return _dbService.applicationsList.where((a) => a.candidateId == candidateId).toList();
  }

  bool hasAppliedForJob(String jobId) {
    final candidateId = _authService.currentUser.value?.id ?? '';
    return _dbService.applicationsList.any((a) => a.candidateId == candidateId && a.jobId == jobId);
  }

  List<ApplicationModel> get recruiterApplicants {
    final recruiterId = _authService.currentUser.value?.id ?? '';
    if (recruiterId.isEmpty || _dbService.jobsList.isEmpty) {
      return _dbService.applicationsList.toList();
    }

    final myJobIds = _dbService.jobsList
        .where((j) => j.recruiterId == recruiterId || j.recruiterName.isNotEmpty)
        .map((j) => j.id)
        .toSet();

    final filtered = _dbService.applicationsList.where((a) => myJobIds.contains(a.jobId) || myJobIds.isEmpty).toList();
    return filtered.isNotEmpty ? filtered : _dbService.applicationsList.toList();
  }

  // Recruiter's posted jobs
  List<JobModel> get recruiterJobs {
    final recruiterId = _authService.currentUser.value?.id;

    if (recruiterId == null) {
      return allJobs;
    }

    final jobs = allJobs.where((job) => job.recruiterId == recruiterId).toList();
    return jobs.isNotEmpty ? jobs : allJobs;
  }

  int getApplicantCountForJob(String jobId) {
    return _dbService.applicationsList
        .where((app) => app.jobId == jobId)
        .length;
  }

  List<ApplicationModel> getApplicantsForJob(String jobId) {
    return _dbService.applicationsList
        .where((app) => app.jobId == jobId)
        .toList();
  }

  List<JobModel> get filteredJobs {
    return allJobs.where((job) {
      final matchesSearch = searchQuery.value.isEmpty ||
          job.title.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          job.companyName.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          job.skills.any((s) => s.toLowerCase().contains(searchQuery.value.toLowerCase()));

      final matchesType = selectedTypeFilter.value == 'All' ||
          job.jobType.toLowerCase().contains(selectedTypeFilter.value.toLowerCase());

      final matchesExp = selectedExperienceFilter.value == 'All' ||
          job.experienceLevel.toLowerCase().contains(selectedExperienceFilter.value.toLowerCase());

      return matchesSearch && matchesType && matchesExp;
    }).toList();
  }

  void updateSearch(String query) {
    searchQuery.value = query;
  }

  void setTypeFilter(String type) {
    selectedTypeFilter.value = type;
  }

  void setExperienceFilter(String exp) {
    selectedExperienceFilter.value = exp;
  }

  void selectResumeForApply(ResumeModel resume) {
    selectedResumeForApply.value = resume;
  }

  Future<void> submitJobApplication(JobModel job) async {
    final user = _authService.currentUser.value;
    if (user == null) {
      Get.snackbar('Error', 'Please login to apply for jobs');
      return;
    }

    final selectedResume = selectedResumeForApply.value ??
        (_dbService.resumeList.isNotEmpty ? _dbService.resumeList.first : null);

    if (selectedResume == null) {
      Get.snackbar(
        'Resume Required',
        'Please upload or select a resume before applying',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.amber,
      );
      return;
    }

    final application = ApplicationModel(
      id: 'app_${DateTime.now().millisecondsSinceEpoch}',
      jobId: job.id,
      jobTitle: job.title,
      companyName: job.companyName,
      candidateId: user.id,
      candidateName: user.name,
      candidateEmail: user.email,
      candidatePhone: user.phone,
      candidateHeadline: user.headline,
      candidateBio: user.bio,
      candidateLocation: user.location,
      candidateExperienceYears: user.experienceYears,
      candidateSkills: user.skills,
      candidateAvatar: user.avatarUrl,
      resumeUrl: selectedResume.fileUrl,
      resumeName: selectedResume.fileName,
      coverLetter: coverLetterController.text.trim(),
    );

    await _dbService.submitApplication(application);
    coverLetterController.clear();
    Get.back(); // close modal
    Get.snackbar(
      'Application Submitted! 🎉',
      'Your resume was submitted to ${job.companyName}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.secondary,
      colorText: Colors.white,
    );
  }

  Future<void> createAndPublishJob() async {
    final title = postTitleController.text.trim();
    final company = postCompanyController.text.trim();
    final location = postLocationController.text.trim();
    final salary = postSalaryController.text.trim();
    final description = postDescriptionController.text.trim();

    if (title.isEmpty || company.isEmpty || location.isEmpty || description.isEmpty) {
      Get.snackbar(
        'Incomplete Fields',
        'Please fill in all required job posting details',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    final recruiter = _authService.currentUser.value;
    final newJob = JobModel(
      id: 'job_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      companyName: company,
      companyLogo: 'https://picsum.photos/seed/$company/200/200',
      location: location,
      jobType: postJobType.value,
      experienceLevel: postExperienceLevel.value,
      salaryRange: salary.isNotEmpty ? salary : '\$90k - \$120k',
      description: description,
      requirements: postRequirementsController.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
      skills: postSkillsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      recruiterId: recruiter?.id ?? 'rec_1',
      recruiterName: recruiter?.name ?? 'Recruiter',
    );

    await _dbService.createJob(newJob);

    // Clear fields
    postTitleController.clear();
    postCompanyController.clear();
    postLocationController.clear();
    postSalaryController.clear();
    postDescriptionController.clear();
    postRequirementsController.clear();
    postSkillsController.clear();

    Get.back();
    Get.snackbar(
      'Job Posted! 🚀',
      'Your job listing is now live for candidates',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );
  }

  Future<void> updateApplicantStage(String appId, ApplicationStatus status) async {
    await _dbService.updateApplicationStatus(appId, status);
    Get.snackbar(
      'Status Updated',
      'Candidate application moved to ${status.label}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: status.color,
      colorText: Colors.white,
    );
  }

  @override
  void onClose() {
    searchController.dispose();
    postTitleController.dispose();
    postCompanyController.dispose();
    postLocationController.dispose();
    postSalaryController.dispose();
    postDescriptionController.dispose();
    postRequirementsController.dispose();
    postSkillsController.dispose();
    coverLetterController.dispose();
    super.onClose();
  }
}
