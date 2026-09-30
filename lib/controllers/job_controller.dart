import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/job_model.dart';
import '../models/application_model.dart';
import '../models/resume_model.dart';
import '../models/company_profile.dart';
import '../core/utils/constants.dart';
import '../core/routes/app_routes.dart';

class JobController extends GetxController {
  final DatabaseService _dbService = Get.find<DatabaseService>();
  final AuthService _authService = Get.find<AuthService>();

  final searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxString selectedTypeFilter = 'All'.obs;
  final RxString selectedExperienceFilter = 'All'.obs;
  final RxString selectedApplicationFilter = 'All'.obs;

  // Post Job Controllers for Recruiters
  final postTitleController = TextEditingController();
  final postCompanyController = TextEditingController();
  final postLocationController = TextEditingController();
  final postSalaryController = TextEditingController();
  final postExperienceController = TextEditingController();
  final postDescriptionController = TextEditingController();
  final postRequirementsController = TextEditingController();
  final postSkillInputController = TextEditingController();
  final RxList<String> postSkills = <String>[].obs;
  final RxString postJobType = 'Full-time'.obs;
  final Rx<JobModel?> editingJob = Rx<JobModel?>(null);
  final RxList<String> postCompanyOptions = <String>[].obs;

  // Selected Resume for Application
  final Rx<ResumeModel?> selectedResumeForApply = Rx<ResumeModel?>(null);
  final coverLetterController = TextEditingController();

  List<JobModel> get allJobs => _dbService.jobsList;
  List<ApplicationModel> get myApplications {
    final candidateId = _authService.currentUser.value?.id ?? '';
    return _dbService.applicationsList
        .where((a) => a.candidateId == candidateId)
        .toList();
  }

  bool hasAppliedForJob(String jobId) {
    final candidateId = _authService.currentUser.value?.id ?? '';
    return _dbService.applicationsList
        .any((a) => a.candidateId == candidateId && a.jobId == jobId);
  }

  ApplicationModel? getApplicationForJob(String jobId) {
    final candidateId = _authService.currentUser.value?.id ?? '';
    return _dbService.applicationsList.firstWhereOrNull(
      (application) =>
          application.candidateId == candidateId && application.jobId == jobId,
    );
  }

  List<ApplicationModel> get recruiterApplicants {
    final recruiterId = _authService.currentUser.value?.id ?? '';
    if (recruiterId.isEmpty || _dbService.jobsList.isEmpty) {
      return [];
    }

    final myJobIds = _dbService.jobsList
        .where((j) => j.recruiterId == recruiterId)
        .map((j) => j.id)
        .toSet();

    return _dbService.applicationsList
        .where((a) => myJobIds.contains(a.jobId))
        .toList();
  }

  // Recruiter's posted jobs
  List<JobModel> get recruiterJobs {
    final recruiterId = _authService.currentUser.value?.id;

    if (recruiterId == null) {
      return [];
    }

    return allJobs.where((job) => job.recruiterId == recruiterId).toList();
  }

  int getApplicantCountForJob(String jobId) {
    final countFromApps =
        _dbService.applicationsList.where((app) => app.jobId == jobId).length;
    final job = _dbService.jobsList.firstWhereOrNull((j) => j.id == jobId);
    if (job != null && job.applicantCount > countFromApps) {
      return job.applicantCount;
    }
    return countFromApps > 0 ? countFromApps : (job?.applicantCount ?? 0);
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
          job.companyName
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()) ||
          job.skills.any(
              (s) => s.toLowerCase().contains(searchQuery.value.toLowerCase()));

      final matchesType = selectedTypeFilter.value == 'All' ||
          job.jobType
              .toLowerCase()
              .contains(selectedTypeFilter.value.toLowerCase());

      final matchesExp = selectedExperienceFilter.value == 'All' ||
          job.experienceLevel
              .toLowerCase()
              .contains(selectedExperienceFilter.value.toLowerCase());

      final isCandidate = _authService.isLoggedIn &&
          _authService.currentRole == UserRole.candidate;
      final matchesApplication = !isCandidate ||
          switch (selectedApplicationFilter.value) {
            'Applied' => hasAppliedForJob(job.id),
            'Not applied' => !hasAppliedForJob(job.id),
            _ => true,
          };

      return matchesSearch && matchesType && matchesExp && matchesApplication;
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

  void setApplicationFilter(String filter) {
    selectedApplicationFilter.value = filter;
  }

  void selectResumeForApply(ResumeModel resume) {
    selectedResumeForApply.value = resume;
  }

  void addPostSkill() {
    final skill = postSkillInputController.text.trim();
    if (skill.isNotEmpty &&
        !postSkills
            .any((existing) => existing.toLowerCase() == skill.toLowerCase())) {
      postSkills.add(skill);
      postSkillInputController.clear();
    }
  }

  void removePostSkill(String skill) {
    postSkills.remove(skill);
  }

  void selectPostCompany(String companyName) {
    postCompanyController.text = companyName;
    final profileCompany = _authService.currentUser.value?.companies
        .firstWhereOrNull((company) => company.name == companyName);
    if (profileCompany != null) {
      postLocationController.text = profileCompany.location;
    }
  }

  void openJobEditor([JobModel? job]) {
    editingJob.value = job;
    final user = _authService.currentUser.value;
    final profileCompanies = user?.companies ?? [];
    final companyNames = profileCompanies.isNotEmpty
        ? profileCompanies.map((company) => company.name.trim()).toList()
        : [user?.companyName.trim() ?? ''];
    postCompanyOptions.assignAll({
      ...companyNames.where((name) => name.isNotEmpty),
      if (job?.companyName.isNotEmpty == true) job!.companyName,
    });
    postTitleController.text = job?.title ?? '';
    postCompanyController.text = job?.companyName ??
        (postCompanyOptions.isNotEmpty ? postCompanyOptions.first : '');
    postLocationController.text = job?.location ?? '';
    if (job == null && postLocationController.text.isEmpty) {
      final selectedCompany = profileCompanies.firstWhereOrNull(
        (company) => company.name == postCompanyController.text,
      );
      postLocationController.text =
          selectedCompany?.location ?? user?.companyLocation ?? '';
    }
    postSalaryController.text = job?.salaryRange == 'As per company standards'
        ? ''
        : job?.salaryRange ?? '';
    postExperienceController.text = job?.experienceLevel == 'Not specified'
        ? ''
        : job?.experienceLevel ?? '';
    postDescriptionController.text = job?.description ?? '';
    postRequirementsController.text = job?.requirements.join('\n') ?? '';
    postSkillInputController.clear();
    postSkills.assignAll(job?.skills ?? []);
    const jobTypes = [
      'Full-time',
      'Part-time',
      'Contract',
      'Remote',
      'Internship',
    ];
    postJobType.value =
        jobTypes.contains(job?.jobType) ? job!.jobType : 'Full-time';
    Get.toNamed(AppRoutes.postJob);
  }

  Future<void> deleteJob(JobModel job) async {
    final recruiterId = _authService.currentUser.value?.id;
    if (recruiterId == null || recruiterId != job.recruiterId) {
      throw StateError('You can only delete your own job posts');
    }

    await _dbService.deleteJob(job.id);
  }

  Future<void> submitJobApplication(JobModel job) async {
    final user = _authService.currentUser.value;
    if (user == null) {
      Get.snackbar('Error', 'Please login to apply for jobs');
      return;
    }

    if (hasAppliedForJob(job.id)) {
      Get.snackbar('Already Applied', 'You have already applied for this job');
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
      id: 'app_${base64Url.encode(utf8.encode('${job.id}:${user.id}')).replaceAll('=', '')}',
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

    try {
      await _dbService.submitApplication(application);
    } catch (e) {
      debugPrint('Failed to save job application: $e');
      Get.snackbar(
        'Application Not Saved',
        'Your application could not be saved. Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

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

    if (title.isEmpty ||
        company.isEmpty ||
        location.isEmpty ||
        description.isEmpty) {
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
    final existingJob = editingJob.value;
    if (existingJob != null && existingJob.recruiterId != recruiter?.id) {
      Get.snackbar(
        'Unable to edit job',
        'You can only edit job posts created by your account.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }
    final selectedCompany = recruiter?.companies.firstWhereOrNull(
          (profile) => profile.name == company,
        ) ??
        (recruiter?.companyName == company
            ? CompanyProfile(
                id: 'legacy_${recruiter!.id}',
                name: recruiter.companyName,
                location: recruiter.companyLocation,
                iconKey: recruiter.companyIconKey,
              )
            : null);

    final updatedJob = JobModel(
      id: existingJob?.id ?? 'job_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      companyName: company,
      companyLogo: existingJob?.companyLogo ?? '',
      companyIconKey: selectedCompany?.iconKey ??
          existingJob?.companyIconKey ??
          recruiter?.companyIconKey ??
          '',
      location:
          location.isNotEmpty ? location : selectedCompany?.location ?? '',
      jobType: postJobType.value,
      experienceLevel: postExperienceController.text.trim().isNotEmpty
          ? postExperienceController.text.trim()
          : 'Not specified',
      salaryRange: salary.isNotEmpty ? salary : 'As per company standards',
      description: description,
      requirements: postRequirementsController.text
          .split('\n')
          .where((s) => s.trim().isNotEmpty)
          .toList(),
      skills: postSkills.toList(),
      recruiterId: existingJob?.recruiterId ?? recruiter?.id ?? 'rec_1',
      recruiterName:
          existingJob?.recruiterName ?? recruiter?.name ?? 'Recruiter',
      applicantCount: existingJob?.applicantCount ?? 0,
      isFeatured: existingJob?.isFeatured ?? false,
      isActive: existingJob?.isActive ?? true,
      postedAt: existingJob?.postedAt,
    );

    if (existingJob == null) {
      await _dbService.createJob(updatedJob);
    } else {
      await _dbService.updateJob(updatedJob);
    }

    // Clear fields
    postTitleController.clear();
    postCompanyController.clear();
    postLocationController.clear();
    postSalaryController.clear();
    postExperienceController.clear();
    postDescriptionController.clear();
    postRequirementsController.clear();
    postSkillInputController.clear();
    postSkills.clear();
    editingJob.value = null;

    Get.back();
    Get.snackbar(
      existingJob == null ? 'Job Posted!' : 'Job Updated',
      existingJob == null
          ? 'Your job listing is now live for candidates'
          : 'Your job listing changes have been saved.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );
  }

  Future<void> updateApplicantStage(
      String appId, ApplicationStatus status) async {
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
    postExperienceController.dispose();
    postDescriptionController.dispose();
    postRequirementsController.dispose();
    postSkillInputController.dispose();
    coverLetterController.dispose();
    super.onClose();
  }
}
