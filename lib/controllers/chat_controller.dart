import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/chat_model.dart';

class ChatController extends GetxController {
  final DatabaseService _dbService = Get.find<DatabaseService>();
  final AuthService _authService = Get.find<AuthService>();

  final messageInputController = TextEditingController();
  final RxList<ChatMessageModel> activeRoomMessages = <ChatMessageModel>[].obs;

  List<ChatRoomModel> get rooms => _dbService.chatRoomsList;

  void loadRoomMessages(String roomId) {
    // Populate sample messages for active chat room
    activeRoomMessages.assignAll([
      ChatMessageModel(
        id: 'msg_1',
        senderId: 'other_user',
        senderName: 'Sarah Jenkins',
        text: 'Hello Alex! We were really impressed with your Flutter background.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      ChatMessageModel(
        id: 'msg_2',
        senderId: _authService.currentUser.value?.id ?? 'user_cand_1',
        senderName: _authService.currentUser.value?.name ?? 'Alex Rivera',
        text: 'Thank you Sarah! I am very excited about the Senior Flutter Developer opportunity.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      ChatMessageModel(
        id: 'msg_3',
        senderId: 'other_user',
        senderName: 'Sarah Jenkins',
        text: 'Would you be available for a technical discussion this Thursday at 2 PM?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ]);
  }

  Future<void> sendMessage(String roomId) async {
    final text = messageInputController.text.trim();
    if (text.isEmpty) return;

    final currentUser = _authService.currentUser.value;
    final message = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: currentUser?.id ?? 'user_1',
      senderName: currentUser?.name ?? 'Me',
      text: text,
      timestamp: DateTime.now(),
    );

    activeRoomMessages.add(message);
    messageInputController.clear();

    await _dbService.sendMessage(roomId, message);
  }

  @override
  void onClose() {
    messageInputController.dispose();
    super.onClose();
  }
}
