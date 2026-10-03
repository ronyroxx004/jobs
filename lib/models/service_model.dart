class MentorshipServiceModel {
  final String id;
  final String mentorId;
  final String mentorName;
  final String mentorEmail;
  final String mentorHeadline;
  final String title;
  final String description;
  final double price;
  final int durationMinutes; // e.g. 15, 30, 45, 60
  final String category; // Resume Review, Mock Interview, 1:1 Call, Career Guidance
  final bool isActive;
  final bool isDeleted;

  // Topmate Specific Fields
  final String serviceType; // '1:1 Call', 'Digital Product', 'Priority DM', 'Webinar', 'Package'
  final String deliverable; // e.g. '30 Mins Video Call', 'Instant PDF Download', 'Guaranteed 24h Response', 'Live on Zoom'
  final double rating;
  final int reviewCount;
  final String? eventDate; // for webinars e.g. 'Oct 28, 2026 • 07:00 PM EST'
  final int? maxSeats; // for webinars
  final int bookedSeats; // for webinars
  final int includedSessions; // for packages
  final List<String> topics; // tags or key takeaways
  final DateTime? createdAt;

  MentorshipServiceModel({
    required this.id,
    required this.mentorId,
    required this.mentorName,
    this.mentorEmail = '',
    this.mentorHeadline = '',
    required this.title,
    required this.description,
    required this.price,
    this.durationMinutes = 30,
    required this.category,
    this.isActive = true,
    this.isDeleted = false,
    this.serviceType = '1:1 Call',
    this.deliverable = '',
    this.rating = 5.0,
    this.reviewCount = 15,
    this.eventDate,
    this.maxSeats,
    this.bookedSeats = 0,
    this.includedSessions = 1,
    this.topics = const [],
    this.createdAt,
  });

  /// Guaranteed creation timestamp for ordering recent posts first
  DateTime get effectiveCreatedAt {
    if (createdAt != null) return createdAt!;
    final match = RegExp(r'\d{10,}').firstMatch(id);
    if (match != null) {
      final ms = int.tryParse(match.group(0)!);
      if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  MentorshipServiceModel copyWith({
    String? id,
    String? mentorId,
    String? mentorName,
    String? mentorEmail,
    String? mentorHeadline,
    String? title,
    String? description,
    double? price,
    int? durationMinutes,
    String? category,
    bool? isActive,
    bool? isDeleted,
    String? serviceType,
    String? deliverable,
    double? rating,
    int? reviewCount,
    String? eventDate,
    int? maxSeats,
    int? bookedSeats,
    int? includedSessions,
    List<String>? topics,
    DateTime? createdAt,
  }) {
    return MentorshipServiceModel(
      id: id ?? this.id,
      mentorId: mentorId ?? this.mentorId,
      mentorName: mentorName ?? this.mentorName,
      mentorEmail: mentorEmail ?? this.mentorEmail,
      mentorHeadline: mentorHeadline ?? this.mentorHeadline,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      serviceType: serviceType ?? this.serviceType,
      deliverable: deliverable ?? this.deliverable,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      eventDate: eventDate ?? this.eventDate,
      maxSeats: maxSeats ?? this.maxSeats,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      includedSessions: includedSessions ?? this.includedSessions,
      topics: topics ?? this.topics,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'mentorId': mentorId,
      'mentorName': mentorName,
      'mentorEmail': mentorEmail,
      'mentorHeadline': mentorHeadline,
      'title': title,
      'description': description,
      'price': price,
      'durationMinutes': durationMinutes,
      'category': category,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'serviceType': serviceType,
      'deliverable': deliverable,
      'rating': rating,
      'reviewCount': reviewCount,
      'bookedSeats': bookedSeats,
      'includedSessions': includedSessions,
      'topics': topics,
      'createdAt': (createdAt ?? effectiveCreatedAt).toIso8601String(),
    };
    if (eventDate != null) map['eventDate'] = eventDate;
    if (maxSeats != null) map['maxSeats'] = maxSeats;
    return map;
  }

  static double _toDouble(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    if (val is String) {
      final clean = val.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(clean) ?? fallback;
    }
    return fallback;
  }

  static int _toInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) {
      final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(clean) ?? fallback;
    }
    return fallback;
  }

  static bool _toBool(dynamic val, [bool fallback = true]) {
    if (val == null) return fallback;
    if (val is bool) return val;
    if (val is String) {
      final s = val.toLowerCase().trim();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    if (val is num) return val != 0;
    return fallback;
  }

  static List<String> _toTopics(dynamic val) {
    if (val == null) return const [];
    if (val is List) {
      return val.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    if (val is String) {
      return val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    if (val is Map) {
      return val.values.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  factory MentorshipServiceModel.fromMap(Map<String, dynamic> map, String docId) {
    final title = map['title']?.toString() ?? map['name']?.toString() ?? 'Mentorship Session';
    final desc = map['description']?.toString() ?? map['desc']?.toString() ?? '';
    final mentorName = map['mentorName']?.toString() ?? map['mentor_name']?.toString() ?? 'Topmate Mentor';
    final mentorId = map['mentorId']?.toString() ?? map['mentor_id']?.toString() ?? '';
    final mentorEmail = map['mentorEmail']?.toString() ?? map['mentor_email']?.toString() ?? '';

    DateTime? createdAt;
    final rawCreated = map['createdAt'] ?? map['created_at'];
    if (rawCreated != null) {
      if (rawCreated is int) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(rawCreated);
      } else if (rawCreated is String) {
        createdAt = DateTime.tryParse(rawCreated);
        if (createdAt == null) {
          final ms = int.tryParse(rawCreated);
          if (ms != null) createdAt = DateTime.fromMillisecondsSinceEpoch(ms);
        }
      }
    }
    if (createdAt == null) {
      final docKey = docId.isNotEmpty ? docId : (map['id']?.toString() ?? '');
      final match = RegExp(r'\d{10,}').firstMatch(docKey);
      if (match != null) {
        final ms = int.tryParse(match.group(0)!);
        if (ms != null) createdAt = DateTime.fromMillisecondsSinceEpoch(ms);
      }
    }

    return MentorshipServiceModel(
      id: docId.isNotEmpty ? docId : (map['id']?.toString() ?? 'serv_${DateTime.now().millisecondsSinceEpoch}'),
      mentorId: mentorId,
      mentorName: mentorName,
      mentorEmail: mentorEmail,
      mentorHeadline: map['mentorHeadline']?.toString() ?? map['headline']?.toString() ?? '',
      title: title,
      description: desc,
      price: _toDouble(map['price'], 0.0),
      durationMinutes: _toInt(map['durationMinutes'] ?? map['duration'], 30),
      category: map['category']?.toString() ?? '1:1 Session',
      isActive: _toBool(map['isActive'], true),
      isDeleted: _toBool(map['isDeleted'], false),
      serviceType: map['serviceType']?.toString() ?? map['type']?.toString() ?? '1:1 Call',
      deliverable: map['deliverable']?.toString() ?? '',
      rating: _toDouble(map['rating'], 5.0),
      reviewCount: _toInt(map['reviewCount'] ?? map['reviews'], 15),
      eventDate: map['eventDate']?.toString(),
      maxSeats: map['maxSeats'] != null ? _toInt(map['maxSeats']) : null,
      bookedSeats: _toInt(map['bookedSeats'], 0),
      includedSessions: _toInt(map['includedSessions'], 1),
      topics: _toTopics(map['topics'] ?? map['tags']),
      createdAt: createdAt,
    );
  }
}

class BookingModel {
  final String id;
  final String serviceId;
  final String serviceTitle;
  final String mentorId;
  final String mentorName;
  final String candidateId;
  final String candidateName;
  final String candidateEmail;
  final double amount;
  final DateTime scheduledAt;
  final String meetingUrl;
  final String status; // Pending, Confirmed, Completed, Cancelled, Rescheduled
  final String serviceType; // 1:1 Call, Digital Product, Priority DM, Webinar, Package
  final String userQuery;
  final String mentorNotes;
  final bool isPaid;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.serviceId,
    required this.serviceTitle,
    required this.mentorId,
    required this.mentorName,
    required this.candidateId,
    required this.candidateName,
    this.candidateEmail = '',
    required this.amount,
    required this.scheduledAt,
    this.meetingUrl = 'https://meet.google.com/topmate-session',
    this.status = 'Confirmed',
    this.serviceType = '1:1 Call',
    this.userQuery = '',
    this.mentorNotes = '',
    this.isPaid = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  BookingModel copyWith({
    String? id,
    String? serviceId,
    String? serviceTitle,
    String? mentorId,
    String? mentorName,
    String? candidateId,
    String? candidateName,
    String? candidateEmail,
    double? amount,
    DateTime? scheduledAt,
    String? meetingUrl,
    String? status,
    String? serviceType,
    String? userQuery,
    String? mentorNotes,
    bool? isPaid,
    DateTime? createdAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      mentorId: mentorId ?? this.mentorId,
      mentorName: mentorName ?? this.mentorName,
      candidateId: candidateId ?? this.candidateId,
      candidateName: candidateName ?? this.candidateName,
      candidateEmail: candidateEmail ?? this.candidateEmail,
      amount: amount ?? this.amount,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      meetingUrl: meetingUrl ?? this.meetingUrl,
      status: status ?? this.status,
      serviceType: serviceType ?? this.serviceType,
      userQuery: userQuery ?? this.userQuery,
      mentorNotes: mentorNotes ?? this.mentorNotes,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceId': serviceId,
      'serviceTitle': serviceTitle,
      'mentorId': mentorId,
      'mentorName': mentorName,
      'candidateId': candidateId,
      'candidateName': candidateName,
      'candidateEmail': candidateEmail,
      'amount': amount,
      'scheduledAt': scheduledAt.toIso8601String(),
      'meetingUrl': meetingUrl,
      'status': status,
      'serviceType': serviceType,
      'userQuery': userQuery,
      'mentorNotes': mentorNotes,
      'isPaid': isPaid,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String docId) {
    return BookingModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      serviceId: map['serviceId'] ?? '',
      serviceTitle: map['serviceTitle'] ?? '',
      mentorId: map['mentorId'] ?? '',
      mentorName: map['mentorName'] ?? '',
      candidateId: map['candidateId'] ?? '',
      candidateName: map['candidateName'] ?? '',
      candidateEmail: map['candidateEmail'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      scheduledAt: map['scheduledAt'] != null
          ? (map['scheduledAt'] is int
              ? DateTime.fromMillisecondsSinceEpoch(map['scheduledAt'] as int)
              : (DateTime.tryParse(map['scheduledAt'].toString()) ??
                  DateTime.now()))
          : DateTime.now(),
      meetingUrl: map['meetingUrl'] ?? 'https://meet.google.com/topmate-session',
      status: map['status'] ?? 'Confirmed',
      serviceType: map['serviceType'] ?? '1:1 Call',
      userQuery: map['userQuery'] ?? '',
      mentorNotes: map['mentorNotes'] ?? '',
      isPaid: map['isPaid'] ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is int
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
              : (DateTime.tryParse(map['createdAt'].toString()) ??
                  DateTime.now()))
          : DateTime.now(),
    );
  }
}

class TestimonialModel {
  final String id;
  final String mentorId;
  final String candidateName;
  final String candidateRole;
  final String candidateCompany;
  final double rating;
  final String content;
  final String date;
  final bool isFeatured;

  TestimonialModel({
    required this.id,
    required this.mentorId,
    required this.candidateName,
    required this.candidateRole,
    this.candidateCompany = '',
    this.rating = 5.0,
    required this.content,
    required this.date,
    this.isFeatured = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mentorId': mentorId,
      'candidateName': candidateName,
      'candidateRole': candidateRole,
      'candidateCompany': candidateCompany,
      'rating': rating,
      'content': content,
      'date': date,
      'isFeatured': isFeatured,
    };
  }

  factory TestimonialModel.fromMap(Map<String, dynamic> map, String docId) {
    return TestimonialModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      mentorId: map['mentorId'] ?? '',
      candidateName: map['candidateName'] ?? 'Mentee',
      candidateRole: map['candidateRole'] ?? 'Software Engineer',
      candidateCompany: map['candidateCompany'] ?? '',
      rating: (map['rating'] ?? 5.0).toDouble(),
      content: map['content'] ?? '',
      date: map['date'] ?? 'Recently',
      isFeatured: map['isFeatured'] ?? true,
    );
  }
}

class MentorAvailabilityModel {
  final String mentorId;
  final List<String> availableDays; // ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']
  final String startTime; // '09:00 AM'
  final String endTime; // '07:00 PM'
  final int slotDuration; // 15, 30, 45, 60
  final int bufferMinutes; // 5, 10, 15

  MentorAvailabilityModel({
    required this.mentorId,
    this.availableDays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    this.startTime = '09:00 AM',
    this.endTime = '07:00 PM',
    this.slotDuration = 30,
    this.bufferMinutes = 15,
  });

  Map<String, dynamic> toMap() {
    return {
      'mentorId': mentorId,
      'availableDays': availableDays,
      'startTime': startTime,
      'endTime': endTime,
      'slotDuration': slotDuration,
      'bufferMinutes': bufferMinutes,
    };
  }

  factory MentorAvailabilityModel.fromMap(Map<String, dynamic> map) {
    return MentorAvailabilityModel(
      mentorId: map['mentorId'] ?? '',
      availableDays: (map['availableDays'] as List?)?.map((e) => e.toString()).toList() ??
          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      startTime: map['startTime'] ?? '09:00 AM',
      endTime: map['endTime'] ?? '07:00 PM',
      slotDuration: map['slotDuration'] ?? 30,
      bufferMinutes: map['bufferMinutes'] ?? 15,
    );
  }
}

class MentorPayoutModel {
  final String id;
  final String mentorId;
  final double amount;
  final String payoutMethod; // 'Bank Transfer', 'UPI', 'Stripe', 'PayPal'
  final String status; // 'Completed', 'Processing'
  final String accountDetail;
  final DateTime requestedAt;

  MentorPayoutModel({
    required this.id,
    required this.mentorId,
    required this.amount,
    required this.payoutMethod,
    this.status = 'Completed',
    required this.accountDetail,
    DateTime? requestedAt,
  }) : requestedAt = requestedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mentorId': mentorId,
      'amount': amount,
      'payoutMethod': payoutMethod,
      'status': status,
      'accountDetail': accountDetail,
      'requestedAt': requestedAt.toIso8601String(),
    };
  }

  factory MentorPayoutModel.fromMap(Map<String, dynamic> map, String docId) {
    return MentorPayoutModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      mentorId: map['mentorId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      payoutMethod: map['payoutMethod'] ?? 'Bank Transfer',
      status: map['status'] ?? 'Completed',
      accountDetail: map['accountDetail'] ?? '',
      requestedAt: map['requestedAt'] != null
          ? DateTime.tryParse(map['requestedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
