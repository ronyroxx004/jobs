class MentorshipServiceModel {
  final String id;
  final String mentorId;
  final String mentorName;
  final String mentorHeadline;
  final String title;
  final String description;
  final double price;
  final int durationMinutes; // e.g. 30, 45, 60
  final String category; // Resume Review, Mock Interview, 1:1 Call, Career Guidance
  final bool isActive;

  MentorshipServiceModel({
    required this.id,
    required this.mentorId,
    required this.mentorName,
    this.mentorHeadline = '',
    required this.title,
    required this.description,
    required this.price,
    this.durationMinutes = 30,
    required this.category,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mentorId': mentorId,
      'mentorName': mentorName,
      'mentorHeadline': mentorHeadline,
      'title': title,
      'description': description,
      'price': price,
      'durationMinutes': durationMinutes,
      'category': category,
      'isActive': isActive,
    };
  }

  factory MentorshipServiceModel.fromMap(Map<String, dynamic> map, String docId) {
    return MentorshipServiceModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      mentorId: map['mentorId'] ?? '',
      mentorName: map['mentorName'] ?? '',
      mentorHeadline: map['mentorHeadline'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      durationMinutes: map['durationMinutes'] ?? 30,
      category: map['category'] ?? '1:1 Session',
      isActive: map['isActive'] ?? true,
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
  final double amount;
  final DateTime scheduledAt;
  final String meetingUrl;
  final String status; // Pending, Confirmed, Completed, Cancelled
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.serviceId,
    required this.serviceTitle,
    required this.mentorId,
    required this.mentorName,
    required this.candidateId,
    required this.candidateName,
    required this.amount,
    required this.scheduledAt,
    this.meetingUrl = 'https://meet.google.com/xyz-jobs-platform',
    this.status = 'Confirmed',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceId': serviceId,
      'serviceTitle': serviceTitle,
      'mentorId': mentorId,
      'mentorName': mentorName,
      'candidateId': candidateId,
      'candidateName': candidateName,
      'amount': amount,
      'scheduledAt': scheduledAt.toIso8601String(),
      'meetingUrl': meetingUrl,
      'status': status,
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
      amount: (map['amount'] ?? 0.0).toDouble(),
      scheduledAt: map['scheduledAt'] != null
          ? DateTime.tryParse(map['scheduledAt']) ?? DateTime.now()
          : DateTime.now(),
      meetingUrl: map['meetingUrl'] ?? '',
      status: map['status'] ?? 'Confirmed',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
