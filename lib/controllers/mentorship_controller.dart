import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/service_model.dart';
import '../core/utils/constants.dart';

class MentorshipController extends GetxController {
  final DatabaseService _dbService = Get.find<DatabaseService>();
  final AuthService _authService = Get.find<AuthService>();

  final RxString selectedCategory = 'All'.obs;
  final Rx<DateTime> selectedDate = DateTime.now().add(const Duration(days: 1)).obs;
  final RxString selectedTimeSlot = '03:00 PM EST'.obs;

  // New Service Creation Controllers for Mentors
  final serviceTitleController = TextEditingController();
  final serviceDescController = TextEditingController();
  final servicePriceController = TextEditingController();
  final RxString serviceCategory = 'Resume Review'.obs;
  final RxInt serviceDuration = 30.obs;

  List<MentorshipServiceModel> get services => _dbService.servicesList;
  List<BookingModel> get myBookings => _dbService.bookingsList;

  List<MentorshipServiceModel> get filteredServices {
    if (selectedCategory.value == 'All') return services;
    return services.where((s) => s.category == selectedCategory.value).toList();
  }

  void selectCategory(String cat) {
    selectedCategory.value = cat;
  }

  void selectSlot(String timeStr) {
    selectedTimeSlot.value = timeStr;
  }

  Future<void> bookMentorshipSession(MentorshipServiceModel service) async {
    final candidate = _authService.currentUser.value;
    if (candidate == null) {
      Get.snackbar('Login Required', 'Please login to book a mentorship session');
      return;
    }

    final booking = BookingModel(
      id: 'book_${DateTime.now().millisecondsSinceEpoch}',
      serviceId: service.id,
      serviceTitle: service.title,
      mentorId: service.mentorId,
      mentorName: service.mentorName,
      candidateId: candidate.id,
      candidateName: candidate.name,
      amount: service.price,
      scheduledAt: selectedDate.value,
      meetingUrl: 'https://meet.google.com/jobs-${DateTime.now().millisecondsSinceEpoch}',
    );

    await _dbService.createBooking(booking);

    Get.back(); // close booking dialog
    Get.snackbar(
      'Session Booked! 📅',
      'Confirmed with ${service.mentorName} for \$${service.price.toStringAsFixed(2)}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.secondary,
      colorText: Colors.white,
    );
  }

  Future<void> createService() async {
    final title = serviceTitleController.text.trim();
    final desc = serviceDescController.text.trim();
    final priceStr = servicePriceController.text.trim();

    if (title.isEmpty || desc.isEmpty || priceStr.isEmpty) {
      Get.snackbar('Incomplete', 'Please fill in service details');
      return;
    }

    final mentor = _authService.currentUser.value;
    final newService = MentorshipServiceModel(
      id: 'serv_${DateTime.now().millisecondsSinceEpoch}',
      mentorId: mentor?.id ?? 'm_1',
      mentorName: mentor?.name ?? 'Mentor',
      mentorHeadline: mentor?.headline ?? 'Senior Specialist',
      title: title,
      description: desc,
      price: double.tryParse(priceStr) ?? 29.99,
      durationMinutes: serviceDuration.value,
      category: serviceCategory.value,
    );

    await _dbService.createMentorshipService(newService);

    serviceTitleController.clear();
    serviceDescController.clear();
    servicePriceController.clear();

    Get.back();
    Get.snackbar(
      'Service Published! 🌟',
      'Your service is now available for candidates to book',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );
  }

  @override
  void onClose() {
    serviceTitleController.dispose();
    serviceDescController.dispose();
    servicePriceController.dispose();
    super.onClose();
  }
}
