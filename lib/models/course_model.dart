class LessonModel {
  final String id;
  final String title;
  final String duration;
  final String videoUrl;
  final bool isFreePreview;

  LessonModel({
    required this.id,
    required this.title,
    required this.duration,
    required this.videoUrl,
    this.isFreePreview = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'duration': duration,
      'videoUrl': videoUrl,
      'isFreePreview': isFreePreview,
    };
  }

  factory LessonModel.fromMap(Map<String, dynamic> map) {
    return LessonModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      duration: map['duration'] ?? '10m',
      videoUrl: map['videoUrl'] ?? '',
      isFreePreview: map['isFreePreview'] ?? false,
    );
  }
}

class CourseModel {
  final String id;
  final String title;
  final String instructorName;
  final String thumbnail;
  final String description;
  final double price;
  final double rating;
  final int enrolledCount;
  final String category;
  final List<LessonModel> lessons;
  final DateTime createdAt;

  CourseModel({
    required this.id,
    required this.title,
    required this.instructorName,
    required this.thumbnail,
    required this.description,
    required this.price,
    this.rating = 4.8,
    this.enrolledCount = 120,
    required this.category,
    required this.lessons,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'instructorName': instructorName,
      'thumbnail': thumbnail,
      'description': description,
      'price': price,
      'rating': rating,
      'enrolledCount': enrolledCount,
      'category': category,
      'lessons': lessons.map((l) => l.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CourseModel.fromMap(Map<String, dynamic> map, String docId) {
    return CourseModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      title: map['title'] ?? '',
      instructorName: map['instructorName'] ?? '',
      thumbnail: map['thumbnail'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      rating: (map['rating'] ?? 4.8).toDouble(),
      enrolledCount: map['enrolledCount'] ?? 0,
      category: map['category'] ?? 'General',
      lessons: (map['lessons'] as List? ?? [])
          .map((l) => LessonModel.fromMap(Map<String, dynamic>.from(l)))
          .toList(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
