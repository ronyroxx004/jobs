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

  @override
  void onInit() {
    super.onInit();
    refreshPostCompanyOptions();
    ever(_authService.currentUser, (_) {
      refreshPostCompanyOptions();
      resetFilters();
      _dbService.fetchJobs();
    });
    if (_dbService.jobsList.isEmpty) {
      _dbService.fetchJobs();
    }
  }

  // Selected Resume for Application
  final Rx<ResumeModel?> selectedResumeForApply = Rx<ResumeModel?>(null);
  final coverLetterController = TextEditingController();

  List<JobModel> get allJobs => _dbService.jobsList;
  List<ApplicationModel> get myApplications {
    final candidateId = _authService.currentUser.value?.id ?? '';
    final firebaseUid = _authService.firebaseUser.value?.uid ?? '';
    final userEmail = _authService.currentUser.value?.email.toLowerCase().trim() ?? '';
    return _dbService.applicationsList
        .where((a) =>
            (candidateId.isNotEmpty && a.candidateId == candidateId) ||
            (firebaseUid.isNotEmpty && a.candidateId == firebaseUid) ||
            (userEmail.isNotEmpty && a.candidateEmail.toLowerCase().trim() == userEmail))
        .toList();
  }

  bool hasAppliedForJob(String jobId) {
    final candidateId = _authService.currentUser.value?.id ?? '';
    final firebaseUid = _authService.firebaseUser.value?.uid ?? '';
    final userEmail = _authService.currentUser.value?.email.toLowerCase().trim() ?? '';
    return _dbService.applicationsList.any((a) =>
        a.jobId == jobId &&
        ((candidateId.isNotEmpty && a.candidateId == candidateId) ||
            (firebaseUid.isNotEmpty && a.candidateId == firebaseUid) ||
            (userEmail.isNotEmpty && a.candidateEmail.toLowerCase().trim() == userEmail)));
  }

  ApplicationModel? getApplicationForJob(String jobId) {
    final candidateId = _authService.currentUser.value?.id ?? '';
    final firebaseUid = _authService.firebaseUser.value?.uid ?? '';
    final userEmail = _authService.currentUser.value?.email.toLowerCase().trim() ?? '';
    return _dbService.applicationsList.firstWhereOrNull(
      (application) =>
          application.jobId == jobId &&
          ((candidateId.isNotEmpty && application.candidateId == candidateId) ||
              (firebaseUid.isNotEmpty &&
                  application.candidateId == firebaseUid) ||
              (userEmail.isNotEmpty &&
                  application.candidateEmail.toLowerCase().trim() == userEmail)),
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
    final user = _authService.currentUser.value;
    if (user == null) {
      return [];
    }

    return allJobs.where((job) {
      if (job.isDeleted) return false;
      if (job.recruiterId == user.id) return true;
      if (user.role == UserRole.recruiter) {
        if (job.recruiterId.isEmpty || job.recruiterId.startsWith('rec_')) {
          if (job.recruiterName.isNotEmpty &&
              user.name.trim().toLowerCase() ==
                  job.recruiterName.trim().toLowerCase()) {
            return true;
          }
          if (user.companies.any((c) =>
              c.name.trim().toLowerCase() ==
              job.companyName.trim().toLowerCase())) {
            return true;
          }
          if (user.companyName.isNotEmpty &&
              user.companyName.trim().toLowerCase() ==
                  job.companyName.trim().toLowerCase()) {
            return true;
          }
        }
      }
      return false;
    }).toList();
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
      if (job.isDeleted) return false;
      if (!job.isActive) return false;

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

  void resetFilters() {
    searchQuery.value = '';
    searchController.clear();
    selectedTypeFilter.value = 'All';
    selectedExperienceFilter.value = 'All';
    selectedApplicationFilter.value = 'All';
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
    if (profileCompany != null && profileCompany.location.isNotEmpty) {
      postLocationController.text = profileCompany.location;
    }
  }

  void refreshPostCompanyOptions() {
    final user = _authService.currentUser.value;
    final profileCompanies = user?.companies ?? [];
    final companyNames = profileCompanies.isNotEmpty
        ? profileCompanies.map((company) => company.name.trim()).toList()
        : [if (user?.companyName.trim().isNotEmpty == true) user!.companyName.trim()];

    final previousJobCompanies = recruiterJobs
        .map((j) => j.companyName.trim())
        .where((name) => name.isNotEmpty);

    final allOptions = <String>{
      ...companyNames.where((name) => name.isNotEmpty),
      ...previousJobCompanies,
      if (editingJob.value?.companyName.isNotEmpty == true)
        editingJob.value!.companyName.trim(),
    };

    postCompanyOptions.assignAll(allOptions);
  }

  void addCompanyAndSelect(CompanyProfile company) {
    if (!postCompanyOptions.contains(company.name)) {
      postCompanyOptions.add(company.name);
    }
    postCompanyController.text = company.name;
    if (company.location.isNotEmpty) {
      postLocationController.text = company.location;
    }

    final user = _authService.currentUser.value;
    if (user != null) {
      final existingCompanies = user.companies.toList();
      final idx = existingCompanies.indexWhere(
        (c) =>
            c.id == company.id ||
            c.name.toLowerCase() == company.name.toLowerCase(),
      );
      if (idx == -1) {
        existingCompanies.add(company);
      } else {
        existingCompanies[idx] = company;
      }
      final updated = user.copyWith(
        companies: existingCompanies,
        companyName: user.companyName.isEmpty ? company.name : user.companyName,
        companyLocation:
            user.companyLocation.isEmpty ? company.location : user.companyLocation,
        companyIconKey:
            user.companyIconKey.isEmpty ? company.iconKey : user.companyIconKey,
      );
      _authService.updateUserProfile(updated);
    }
  }

  void openJobEditor([JobModel? job]) {
    editingJob.value = job;
    refreshPostCompanyOptions();
    postTitleController.text = job?.title ?? '';
    postCompanyController.text = job?.companyName ??
        (postCompanyOptions.isNotEmpty ? postCompanyOptions.first : '');
    postLocationController.text = job?.location ?? '';
    if (job == null &&
        postLocationController.text.isEmpty &&
        postCompanyController.text.isNotEmpty) {
      final user = _authService.currentUser.value;
      final selectedCompany = user?.companies.firstWhereOrNull(
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
    final user = _authService.currentUser.value;
    final isAdmin = user?.role == UserRole.admin;
    final isRecruiter = user?.role == UserRole.recruiter;

    final isOwner = user != null &&
        (user.id == job.recruiterId ||
            job.recruiterId.isEmpty ||
            job.recruiterId.startsWith('rec_') ||
            (job.recruiterName.isNotEmpty &&
                user.name.trim().toLowerCase() ==
                    job.recruiterName.trim().toLowerCase()) ||
            (user.companies.any((c) =>
                c.name.trim().toLowerCase() ==
                job.companyName.trim().toLowerCase())) ||
            (user.companyName.isNotEmpty &&
                user.companyName.trim().toLowerCase() ==
                    job.companyName.trim().toLowerCase()));

    if (user == null || (!isAdmin && !isRecruiter && !isOwner)) {
      throw StateError('You can only delete your own job posts');
    }

    await _dbService.softDeleteJob(job);
  }

  Future<void> restoreJob(JobModel job) async {
    await _dbService.restoreJob(job.id);
  }

  Future<void> submitJobApplication(JobModel job, {bool isUpdating = false}) async {
    final user = _authService.currentUser.value;
    if (user == null) {
      Get.snackbar('Error', 'Please login to apply for jobs');
      return;
    }

    final hasApplied = hasAppliedForJob(job.id);
    if (hasApplied && !isUpdating) {
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

    final currentUid = _authService.firebaseUser.value?.uid;
    final candidateId = (currentUid != null && currentUid.isNotEmpty)
        ? currentUid
        : user.id;

    final existingApp = getApplicationForJob(job.id);
    final sanitizedJobId = job.id.replaceAll(RegExp(r'[.#$\[\]/]'), '_');
    final sanitizedCandidateId = candidateId.replaceAll(RegExp(r'[.#$\[\]/]'), '_');
    final appId = existingApp?.id ??
        'app_${base64Url.encode(utf8.encode('$sanitizedJobId:$sanitizedCandidateId')).replaceAll('=', '')}';

    final application = ApplicationModel(
      id: appId,
      jobId: job.id,
      jobTitle: job.title,
      companyName: job.companyName,
      candidateId: candidateId,
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
      coverLetter: coverLetterController.text.trim().isNotEmpty
          ? coverLetterController.text.trim()
          : (existingApp?.coverLetter ?? ''),
      status: existingApp?.status ?? ApplicationStatus.applied,
      appliedAt: existingApp?.appliedAt ?? DateTime.now(),
    );

    try {
      await _dbService.submitApplication(application);
    } catch (e) {
      debugPrint('Failed to save job application: $e');
      final msg = e.toString().toLowerCase();
      if (!isUpdating && (msg.contains('already applied') || msg.contains('already exists'))) {
        Get.snackbar(
          'Already Applied',
          'You have already applied for this job.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
        );
        return;
      }
      Get.snackbar(
        'Application Not Saved',
        'Your application could not be saved ($e). Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    coverLetterController.clear();
    Get.back(); // close modal
    Get.snackbar(
      isUpdating ? 'Resume Updated! 🎉' : 'Application Submitted! 🎉',
      isUpdating
          ? 'Your resume for ${job.companyName} was updated successfully.'
          : 'Your resume was submitted to ${job.companyName}',
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
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    final recruiter = _authService.currentUser.value;
    final isAdmin = recruiter?.role == UserRole.admin;
    final existingJob = editingJob.value;
    if (existingJob != null && !isAdmin && existingJob.recruiterId != recruiter?.id) {
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
                id: 'legacy_${recruiter?.id ?? ''}',
                name: recruiter?.companyName ?? '',
                location: recruiter?.companyLocation ?? '',
                iconKey: recruiter?.companyIconKey ?? 'business',
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
