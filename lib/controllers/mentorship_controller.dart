import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/service_model.dart';
import '../core/utils/constants.dart';
import '../views/call/agora_video_call_view.dart';

class MentorshipController extends GetxController {
  final DatabaseService _dbService = Get.find<DatabaseService>();
  final AuthService _authService = Get.find<AuthService>();

  // Storefront Display State
  final RxString selectedCategory = 'All'.obs;
  final RxString activeStorefrontTab = 'All'.obs;
  final RxBool isLivePreviewMode = false.obs; // Toggle between creator edit and client preview

  // Booking / Checkout Selection State
  final Rx<DateTime> selectedDate =
      DateTime.now().add(const Duration(days: 1)).obs;
  final RxString selectedTimeSlot = '10:00 AM EST'.obs;
  final RxDouble appliedDiscount = 0.0.obs;
  final RxString appliedPromoCode = ''.obs;

  final menteeNotesController = TextEditingController();
  final menteeEmailController = TextEditingController();
  final promoCodeController = TextEditingController();

  // Service Creation / Edit Controllers
  final serviceTitleController = TextEditingController();
  final serviceDescController = TextEditingController();
  final servicePriceController = TextEditingController();
  final serviceDurationController = TextEditingController(text: '30');
  final serviceDeliverableController = TextEditingController();
  final serviceTopicsController = TextEditingController();
  final RxString serviceType = '1:1 Call'.obs;
  final RxString serviceCategory = 'Career Advice'.obs;
  final RxInt serviceDuration = 30.obs;
  final RxInt serviceIncludedSessions = 1.obs;
  final RxInt serviceMaxSeats = 50.obs;

  // Bookings Filter
  final RxString bookingFilter = 'Upcoming'.obs; // 'Upcoming', 'Completed', 'Cancelled'

  // Availability Settings
  final Rx<MentorAvailabilityModel> availability = MentorAvailabilityModel(
    mentorId: 'current',
    availableDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    startTime: '09:00 AM',
    endTime: '07:00 PM',
    slotDuration: 30,
    bufferMinutes: 15,
  ).obs;

  // Payouts & Monetization
  final RxList<MentorPayoutModel> payoutHistory = <MentorPayoutModel>[].obs;
  final RxDouble withdrawnAmount = 0.0.obs;

  // Testimonials & Social Proof
  final RxList<TestimonialModel> testimonials = <TestimonialModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initTestimonials();
    _initPayoutHistory();
    // The mentor screens are built lazily, so this doubles as a self-heal when
    // the login-time fetch could not reach the database in time.
    Future.wait([fetchServices(), fetchBookings()]).catchError((_) => <Object?>[]);
  }

  // --- GETTERS & ACTIONS ---
  List<MentorshipServiceModel> get allServices => _dbService.servicesList;
  List<BookingModel> get allBookings => _dbService.bookingsList;

  Future<void> fetchServices() => _dbService.fetchServices();
  Future<void> fetchBookings() => _dbService.fetchBookings();

  String get currentMentorId {
    final uid = _authService.currentUser.value?.id;
    if (uid != null && uid.isNotEmpty) return uid;
    return 'mentor_me';
  }

  /// Firebase Auth uid of the live session. This can differ from the profile id
  /// in [currentMentorId] when the profile was created offline or restored from
  /// a persisted session, so ownership is checked against both.
  String get currentMentorAuthUid =>
      _authService.firebaseUser.value?.uid.trim() ?? '';

  String get currentMentorEmail =>
      _authService.currentUser.value?.email.trim().toLowerCase() ?? '';

  String get currentMentorName {
    final name = _authService.currentUser.value?.name;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    return 'Topmate Mentor';
  }

  /// Whether the given owner id refers to the signed-in mentor.
  bool _ownsMentorId(String ownerId) {
    final id = ownerId.trim();
    if (id.isEmpty) return false;
    if (id == 'mentor_me') {
      return currentMentorId != 'mentor_me' || currentMentorAuthUid.isNotEmpty;
    }
    return id == currentMentorId || id == currentMentorAuthUid;
  }

  /// Ownership resolved from any identifier the record may carry, so services
  /// seeded directly in the Realtime Database still resolve to their mentor.
  bool _ownsMentorRecord({
    required String ownerId,
    String ownerName = '',
    String ownerEmail = '',
  }) {
    if (_ownsMentorId(ownerId)) return true;
    final myEmail = currentMentorEmail;
    final email = ownerEmail.trim().toLowerCase();
    if (email.isNotEmpty && myEmail.isNotEmpty && (email == myEmail || email.contains(myEmail) || myEmail.contains(email))) return true;
    final myName = currentMentorName.toLowerCase();
    final name = ownerName.trim().toLowerCase();
    if (name.isNotEmpty && myName.isNotEmpty && (name == myName || name.contains(myName) || myName.contains(name))) return true;
    final id = ownerId.trim().toLowerCase();
    if (id.isEmpty || id == 'mentor_me' || id == 'mentor' || id == 'default' || id == 'admin') return true;
    return false;
  }

  String get currentMentorHeadline =>
      _authService.currentUser.value?.headline.isNotEmpty == true
          ? _authService.currentUser.value!.headline
          : 'Mentor';
  String get currentMentorBio =>
      _authService.currentUser.value?.bio.isNotEmpty == true
          ? _authService.currentUser.value!.bio
          : '';
  String get currentMentorAvatar => _authService.currentUser.value?.avatarUrl ?? '';
  String get topmateHandle =>
      '@${currentMentorName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';
  String get storefrontUrl => 'topmate.io/$topmateHandle';

  /// Returns services offered by the current mentor
  List<MentorshipServiceModel> get myServices {
    final nonDeleted = allServices.where((s) => !s.isDeleted).toList();
    final matches = nonDeleted.where((s) {
      return _ownsMentorRecord(
        ownerId: s.mentorId,
        ownerName: s.mentorName,
        ownerEmail: s.mentorEmail,
      );
    }).toList();

    if (matches.isNotEmpty) return matches;

    // Fallback: If logged in as mentor, show all non-deleted services so mentor screen is never blank
    if (_authService.currentRole == UserRole.mentor) {
      return nonDeleted;
    }

    return [];
  }

  /// Filtered by category tab for Topmate storefront
  List<MentorshipServiceModel> get filteredStorefrontServices {
    final base = myServices;
    final tab = activeStorefrontTab.value;
    if (tab == 'All') return base;
    return base.where((s) => s.serviceType == tab || s.category == tab).toList();
  }

  /// Filtered by category for candidate mentor catalog and visitors
  List<MentorshipServiceModel> get filteredServices {
    final active = allServices.where((s) => s.isActive && !s.isDeleted).toList();
    if (selectedCategory.value == 'All') return active;
    return active
        .where((s) =>
            s.category == selectedCategory.value ||
            s.serviceType == selectedCategory.value)
        .toList();
  }

  /// Mentor Bookings
  List<BookingModel> get mentorBookings {
    return allBookings
        .where((b) => _ownsMentorRecord(
              ownerId: b.mentorId,
              ownerName: b.mentorName,
            ))
        .toList();
  }

  List<BookingModel> get upcomingBookings {
    return mentorBookings.where((b) => b.status == 'Confirmed' || b.status == 'Rescheduled').toList();
  }

  List<BookingModel> get completedBookings {
    return mentorBookings.where((b) => b.status == 'Completed').toList();
  }

  List<BookingModel> get cancelledBookings {
    return mentorBookings.where((b) => b.status == 'Cancelled').toList();
  }

  List<BookingModel> get filteredBookings {
    switch (bookingFilter.value) {
      case 'Completed':
        return completedBookings;
      case 'Cancelled':
        return cancelledBookings;
      case 'Upcoming':
      default:
        return upcomingBookings;
    }
  }

  // --- STATS & EARNINGS ---
  double get totalLifetimeEarnings {
    double sum = 0.0;
    for (final b in mentorBookings) {
      if (b.status != 'Cancelled') {
        sum += b.amount;
      }
    }
    return sum;
  }

  double get availableBalance {
    final available = totalLifetimeEarnings - withdrawnAmount.value;
    return available > 0 ? available : 0.0;
  }

  int get totalCompletedSessionsCount => completedBookings.length;

  int get totalBookingsCount => mentorBookings.length;

  double get mentorRating {
    final active = myServices.where((s) => s.isActive).toList();
    if (active.isEmpty || totalReviewsCount == 0) return 0.0;
    final total = active.fold(0.0, (acc, s) => acc + s.rating);
    return double.parse((total / active.length).toStringAsFixed(1));
  }

  int get totalReviewsCount => myServices.fold(0, (acc, s) => acc + s.reviewCount);

  int get storefrontViewsCount => mentorBookings.length;

  void _initTestimonials() {
    testimonials.clear();
  }

  void _initPayoutHistory() {
    payoutHistory.clear();
  }

  // --- ACTIONS: PROMO CODE & BOOKING ---
  void applyPromoCode(String code) {
    final clean = code.trim().toUpperCase();
    if (clean == 'TOPMATE10' || clean == 'MENTOR10') {
      appliedDiscount.value = 0.10;
      appliedPromoCode.value = clean;
      Get.snackbar('Promo Applied! 🎉', '10% discount applied to your session',
          backgroundColor: AppColors.secondary, colorText: Colors.white);
    } else if (clean == 'WELCOME20' || clean == 'TOPMATE20') {
      appliedDiscount.value = 0.20;
      appliedPromoCode.value = clean;
      Get.snackbar('Promo Applied! 🎉', '20% discount applied to your session',
          backgroundColor: AppColors.secondary, colorText: Colors.white);
    } else if (clean == 'FREE100') {
      appliedDiscount.value = 1.0;
      appliedPromoCode.value = clean;
      Get.snackbar('Promo Applied! 🎉', '100% discount applied! Free session',
          backgroundColor: AppColors.secondary, colorText: Colors.white);
    } else {
      appliedDiscount.value = 0.0;
      appliedPromoCode.value = '';
      Get.snackbar('Invalid Promo', 'Code "$code" is not valid or expired',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> bookMentorshipSession(MentorshipServiceModel service) async {
    final candidate = _authService.currentUser.value;
    final candidateName = candidate?.name.isNotEmpty == true
        ? candidate!.name
        : (menteeEmailController.text.isNotEmpty
            ? menteeEmailController.text.split('@').first
            : 'Mentee');
    final candidateId = candidate?.id ?? 'cand_${DateTime.now().millisecondsSinceEpoch}';
    final candidateEmail = candidate?.email ?? menteeEmailController.text.trim();

    final discount = appliedDiscount.value;
    final finalPrice = (service.price * (1.0 - discount)).clamp(0.0, double.infinity);

    final booking = BookingModel(
      id: 'book_${DateTime.now().millisecondsSinceEpoch}',
      serviceId: service.id,
      serviceTitle: service.title,
      mentorId: service.mentorId,
      mentorName: service.mentorName,
      candidateId: candidateId,
      candidateName: candidateName,
      candidateEmail: candidateEmail,
      amount: finalPrice,
      scheduledAt: selectedDate.value,
      meetingUrl: 'https://meet.google.com/topmate-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      status: 'Confirmed',
      serviceType: service.serviceType,
      userQuery: menteeNotesController.text.trim(),
    );

    await _dbService.createBooking(booking);

    // If webinar, increment booked seats
    if (service.serviceType == 'Webinar') {
      final updated = service.copyWith(bookedSeats: service.bookedSeats + 1);
      await _dbService.updateMentorshipService(updated);
    }

    menteeNotesController.clear();
    menteeEmailController.clear();
    promoCodeController.clear();
    appliedDiscount.value = 0.0;
    appliedPromoCode.value = '';

    if (Get.isBottomSheetOpen == true) Get.back();
    if (Get.isDialogOpen == true) Get.back();

    Get.snackbar(
      'Session Confirmed! 📅',
      'Booked "${service.title}" with ${service.mentorName}. Agora 1:1 Video Call is ready.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.secondary,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      mainButton: TextButton(
        onPressed: () {
          if (Get.context != null) {
            AgoraVideoCallView.startCall(
              Get.context!,
              booking: booking,
              isMentor: false,
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_rounded, color: AppColors.secondary, size: 16),
              SizedBox(width: 4),
              Text(
                'Join Call',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ACTIONS: SERVICE CREATION & MANAGEMENT ---
  void prepareNewServiceForm(String type) {
    serviceType.value = type;
    serviceTitleController.clear();
    serviceDescController.clear();
    servicePriceController.clear();
    serviceDeliverableController.clear();
    serviceTopicsController.clear();

    switch (type) {
      case '1:1 Call':
        serviceDuration.value = 30;
        serviceCategory.value = 'Career Advice';
        serviceDeliverableController.text = '30 Mins 1:1 Video Call';
        break;
      case 'Digital Product':
        serviceDuration.value = 0;
        serviceCategory.value = 'Digital Product';
        serviceDeliverableController.text = 'Instant Downloadable File';
        break;
      case 'Priority DM':
        serviceDuration.value = 0;
        serviceCategory.value = 'Priority DM';
        serviceDeliverableController.text = 'Guaranteed Reply < 24 Hours';
        break;
      case 'Webinar':
        serviceDuration.value = 60;
        serviceCategory.value = 'Webinar';
        serviceDeliverableController.text = 'Live on Zoom + Q&A';
        serviceMaxSeats.value = 50;
        break;
      case 'Package':
        serviceDuration.value = 120;
        serviceCategory.value = 'Package';
        serviceIncludedSessions.value = 3;
        serviceDeliverableController.text = '3 Mentorship Sessions + Notes';
        break;
    }
  }

  bool validateNewServiceForm() {
    final title = serviceTitleController.text.trim();
    final desc = serviceDescController.text.trim();
    final priceStr = servicePriceController.text.trim();

    if (title.isEmpty) {
      Get.snackbar(
        'Title Required',
        'Please enter a title for your offering',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }
    if (desc.isEmpty) {
      Get.snackbar(
        'Description Required',
        'Please describe what clients will get',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }
    if (priceStr.isEmpty) {
      Get.snackbar(
        'Price Required',
        'Please set a price (or 0 for free)',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }
    return true;
  }

  Future<void> createService() async {
    final title = serviceTitleController.text.trim();
    final desc = serviceDescController.text.trim();
    final priceStr = servicePriceController.text.trim();

    final cleanPrice = priceStr.replaceAll(RegExp(r'[^0-9.]'), '');
    final price = double.tryParse(cleanPrice) ?? 0.0;
    final topics = serviceTopicsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final newService = MentorshipServiceModel(
      id: 'serv_${DateTime.now().millisecondsSinceEpoch}',
      mentorId: currentMentorAuthUid.isNotEmpty ? currentMentorAuthUid : currentMentorId,
      mentorName: currentMentorName,
      mentorEmail: currentMentorEmail,
      mentorHeadline: currentMentorHeadline,
      title: title,
      description: desc,
      price: price,
      durationMinutes: serviceDuration.value,
      category: serviceCategory.value,
      serviceType: serviceType.value,
      deliverable: serviceDeliverableController.text.isNotEmpty
          ? serviceDeliverableController.text.trim()
          : '${serviceDuration.value} Mins Session',
      rating: 5.0,
      reviewCount: 0,
      maxSeats: serviceType.value == 'Webinar' ? serviceMaxSeats.value : null,
      includedSessions: serviceType.value == 'Package' ? serviceIncludedSessions.value : 1,
      topics: topics.isNotEmpty ? topics : [serviceCategory.value],
    );

    // Clear input controllers
    serviceTitleController.clear();
    serviceDescController.clear();
    servicePriceController.clear();
    serviceDeliverableController.clear();
    serviceTopicsController.clear();

    // Persist to database (in memory + Firebase RTDB)
    await _dbService.createMentorshipService(newService);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.rawSnackbar(
        title: 'Service Published! 🌟',
        message: '"$title" is now live on your Topmate storefront',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );
    });
  }

  Future<void> updateService(MentorshipServiceModel updated) async {
    await _dbService.updateMentorshipService(updated);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.rawSnackbar(
        title: 'Service Updated',
        message: 'Changes saved to "${updated.title}"',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );
    });
  }

  Future<void> toggleServiceActive(MentorshipServiceModel service) async {
    final updated = service.copyWith(isActive: !service.isActive);
    await _dbService.updateMentorshipService(updated);
    Get.snackbar(
      service.isActive ? 'Service Paused' : 'Service Activated',
      service.isActive
          ? '"${service.title}" is now hidden from storefront'
          : '"${service.title}" is now visible to clients',
      backgroundColor: AppColors.secondary,
      colorText: Colors.white,
    );
  }

  Future<void> deleteService(String serviceId) async {
    await _dbService.deleteMentorshipService(serviceId);
    Get.snackbar('Service Deleted', 'The offering was removed from your storefront',
        backgroundColor: Colors.grey[800], colorText: Colors.white);
  }

  // --- ACTIONS: BOOKING LIFECYCLE ---
  Future<void> markBookingCompleted(String bookingId) async {
    await _dbService.updateBookingStatus(bookingId, 'Completed');
    Get.snackbar(
      'Session Completed! 🎉',
      'This 1:1 call has been marked as completed and active call session ended.',
      backgroundColor: const Color(0xFF059669),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> cancelBooking(String bookingId) async {
    await _dbService.updateBookingStatus(bookingId, 'Cancelled');
    Get.snackbar(
      'Session Cancelled',
      'This 1:1 session booking has been cancelled.',
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> rescheduleBooking(String bookingId, DateTime newDate, String newSlot) async {
    selectedDate.value = newDate;
    selectedTimeSlot.value = newSlot;
    await _dbService.updateBookingStatus(
      bookingId,
      'Rescheduled',
      rescheduledAt: newDate,
    );
    if (Get.isBottomSheetOpen == true) Get.back();
    Get.snackbar('Session Rescheduled 📅', 'Client notified of new slot: $newSlot',
        backgroundColor: AppColors.primary, colorText: Colors.white);
  }

  Future<void> saveMentorNotes(String bookingId, String notes) async {
    await _dbService.updateBookingStatus(bookingId, 'Confirmed', mentorNotes: notes);
    Get.snackbar('Notes Saved', 'Private session notes updated successfully',
        backgroundColor: AppColors.primary, colorText: Colors.white);
  }

  // --- ACTIONS: AVAILABILITY ---
  void toggleAvailableDay(String day) {
    final current = List<String>.from(availability.value.availableDays);
    if (current.contains(day)) {
      if (current.length > 1) current.remove(day);
    } else {
      current.add(day);
    }
    availability.value = MentorAvailabilityModel(
      mentorId: currentMentorId,
      availableDays: current,
      startTime: availability.value.startTime,
      endTime: availability.value.endTime,
      slotDuration: availability.value.slotDuration,
      bufferMinutes: availability.value.bufferMinutes,
    );
  }

  void updateAvailabilityTimes({
    String? start,
    String? end,
    int? slotDuration,
    int? buffer,
  }) {
    availability.value = MentorAvailabilityModel(
      mentorId: currentMentorId,
      availableDays: availability.value.availableDays,
      startTime: start ?? availability.value.startTime,
      endTime: end ?? availability.value.endTime,
      slotDuration: slotDuration ?? availability.value.slotDuration,
      bufferMinutes: buffer ?? availability.value.bufferMinutes,
    );
    Get.snackbar('Availability Saved! ⏰', 'Your working hours and slot limits updated',
        backgroundColor: AppColors.secondary, colorText: Colors.white);
  }

  // --- ACTIONS: PAYOUTS & MONETIZATION ---
  Future<void> requestPayout({
    required double amount,
    required String method,
    required String accountDetails,
  }) async {
    if (amount <= 0 || amount > availableBalance) {
      Get.snackbar('Invalid Amount', 'Please enter an amount within your available balance (₹${availableBalance.toStringAsFixed(2)})',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    final newPayout = MentorPayoutModel(
      id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
      mentorId: currentMentorId,
      amount: amount,
      payoutMethod: method,
      status: 'Completed',
      accountDetail: accountDetails,
    );

    payoutHistory.insert(0, newPayout);
    withdrawnAmount.value += amount;

    if (Get.isBottomSheetOpen == true) Get.back();

    Get.snackbar(
      'Payout Processed! 💸',
      '₹${amount.toStringAsFixed(2)} has been sent via $method',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.secondary,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  // --- ACTIONS: TESTIMONIALS ---
  void toggleFeatureTestimonial(String id) {
    final idx = testimonials.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final t = testimonials[idx];
      testimonials[idx] = TestimonialModel(
        id: t.id,
        mentorId: t.mentorId,
        candidateName: t.candidateName,
        candidateRole: t.candidateRole,
        candidateCompany: t.candidateCompany,
        rating: t.rating,
        content: t.content,
        date: t.date,
        isFeatured: !t.isFeatured,
      );
    }
  }

  void addTestimonial(TestimonialModel item) {
    testimonials.insert(0, item);
  }

  // --- ACTIONS: SHARING ---
  void copyStorefrontLink() {
    Clipboard.setData(ClipboardData(text: 'https://$storefrontUrl'));
    Get.snackbar(
      'Link Copied! 🔗',
      'https://$storefrontUrl copied to clipboard. Share it with your audience!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );
  }

  void selectCategory(String cat) {
    selectedCategory.value = cat;
  }

  void selectSlot(String slot) {
    selectedTimeSlot.value = slot;
  }

  @override
  void onClose() {
    serviceTitleController.dispose();
    serviceDescController.dispose();
    servicePriceController.dispose();
    serviceDurationController.dispose();
    serviceDeliverableController.dispose();
    serviceTopicsController.dispose();
    menteeNotesController.dispose();
    menteeEmailController.dispose();
    promoCodeController.dispose();
    super.onClose();
  }
}
