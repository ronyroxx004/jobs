class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String mediaUrl;
  final DateTime timestamp;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.mediaUrl = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'mediaUrl': mediaUrl,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChatMessageModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      mediaUrl: map['mediaUrl'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ChatRoomModel {
  final String id;
  final List<String> participantIds;
  final String otherUserName;
  final String otherUserAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;

  ChatRoomModel({
    required this.id,
    required this.participantIds,
    required this.otherUserName,
    this.otherUserAvatar = '',
    this.lastMessage = '',
    DateTime? lastMessageTime,
  }) : lastMessageTime = lastMessageTime ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participantIds': participantIds,
      'otherUserName': otherUserName,
      'otherUserAvatar': otherUserAvatar,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
    };
  }

  factory ChatRoomModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChatRoomModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      participantIds: List<String>.from(map['participantIds'] ?? []),
      otherUserName: map['otherUserName'] ?? 'User',
      otherUserAvatar: map['otherUserAvatar'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.tryParse(map['lastMessageTime']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
