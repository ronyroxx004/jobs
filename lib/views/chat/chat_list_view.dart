import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/chat_controller.dart';
import '../../services/database_service.dart';
import '../../core/utils/constants.dart';
import 'chat_detail_view.dart';

class ChatListView extends GetView<ChatController> {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Recruiter & Mentor Messages',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            'Realtime candidate communication and interview discussions',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final dbService = Get.find<DatabaseService>();
                await dbService.fetchAllData();
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: controller.rooms.length + 1,
                itemBuilder: (context, index) {
                  if (index == controller.rooms.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              "You've reached the end of messages",
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final room = controller.rooms[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        backgroundImage: room.otherUserAvatar.isNotEmpty ? NetworkImage(room.otherUserAvatar) : null,
                        child: room.otherUserAvatar.isEmpty ? Text(room.otherUserName[0]) : null,
                      ),
                      title: Text(
                        room.otherUserName,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        room.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      trailing: Text(
                        '${room.lastMessageTime.hour}:${room.lastMessageTime.minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                      ),
                      onTap: () {
                        controller.loadRoomMessages(room.id);
                        Get.to(() => ChatDetailView(room: room));
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
