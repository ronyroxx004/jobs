class BroadcastNotificationModel {
  final String id;
  final String title;
  final String body;
  final String targetAudience;
  final bool sendPush;
  final DateTime createdAt;
  final String sentBy;
  final int recipientCount;
  final String status;
  final DateTime? lastResentAt;
  final int resendCount;

  const BroadcastNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.targetAudience = 'All Users',
    this.sendPush = true,
    required this.createdAt,
    this.sentBy = 'Admin',
    this.recipientCount = 0,
    this.status = 'Sent',
    this.lastResentAt,
    this.resendCount = 0,
  });

  BroadcastNotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? targetAudience,
    bool? sendPush,
    DateTime? createdAt,
    String? sentBy,
    int? recipientCount,
    String? status,
    DateTime? lastResentAt,
    int? resendCount,
  }) {
    return BroadcastNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      targetAudience: targetAudience ?? this.targetAudience,
      sendPush: sendPush ?? this.sendPush,
      createdAt: createdAt ?? this.createdAt,
      sentBy: sentBy ?? this.sentBy,
      recipientCount: recipientCount ?? this.recipientCount,
      status: status ?? this.status,
      lastResentAt: lastResentAt ?? this.lastResentAt,
      resendCount: resendCount ?? this.resendCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'targetAudience': targetAudience,
      'sendPush': sendPush,
      'createdAt': createdAt.toIso8601String(),
      'sentBy': sentBy,
      'recipientCount': recipientCount,
      'status': status,
      if (lastResentAt != null) 'lastResentAt': lastResentAt!.toIso8601String(),
      'resendCount': resendCount,
    };
  }

  factory BroadcastNotificationModel.fromMap(
      Map<String, dynamic> map, String id) {
    return BroadcastNotificationModel(
      id: id.isNotEmpty ? id : (map['id']?.toString() ?? ''),
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      targetAudience: map['targetAudience']?.toString() ?? 'All Users',
      sendPush: map['sendPush'] is bool ? map['sendPush'] as bool : true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      sentBy: map['sentBy']?.toString() ?? 'Admin',
      recipientCount:
          int.tryParse(map['recipientCount']?.toString() ?? '') ?? 0,
      status: map['status']?.toString() ?? 'Sent',
      lastResentAt: map['lastResentAt'] != null
          ? DateTime.tryParse(map['lastResentAt'].toString())
          : null,
      resendCount: int.tryParse(map['resendCount']?.toString() ?? '') ?? 0,
    );
  }
}
