class ResumeModel {
  final String id;
  final String userId;
  final String fileName;
  final String fileUrl;
  final String fileSize;
  final bool isPrimary;
  final List<String> extractedSkills;
  final DateTime uploadedAt;

  ResumeModel({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.fileUrl,
    this.fileSize = '1.2 MB',
    this.isPrimary = false,
    this.extractedSkills = const [],
    DateTime? uploadedAt,
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'isPrimary': isPrimary,
      'extractedSkills': extractedSkills,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  factory ResumeModel.fromMap(Map<String, dynamic> map, String docId) {
    return ResumeModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      userId: map['userId'] ?? '',
      fileName: map['fileName'] ?? 'Resume.pdf',
      fileUrl: map['fileUrl'] ?? '',
      fileSize: map['fileSize'] ?? '1.2 MB',
      isPrimary: map['isPrimary'] ?? false,
      extractedSkills: List<String>.from(map['extractedSkills'] ?? []),
      uploadedAt: map['uploadedAt'] != null
          ? DateTime.tryParse(map['uploadedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
