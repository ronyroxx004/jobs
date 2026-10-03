import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/constants.dart';
import '../../models/chat_model.dart';
import '../../models/service_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class PriorityDmController extends GetxController {
  final BookingModel initialBooking;
  final bool isMentor;

  PriorityDmController({
    required this.initialBooking,
    required this.isMentor,
  });

  late final Rx<BookingModel> bookingRx;
  final RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final RxBool isSending = false.obs;

  StreamSubscription? _messagesSubscription;
  Worker? _bookingSubscription;
  DatabaseService get _dbService => Get.find<DatabaseService>();
  AuthService? get _authService =>
      Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;

  String get currentUserId {
    final uid = _authService?.currentUser.value?.id;
    if (uid != null && uid.trim().isNotEmpty) return uid.trim();
    final fbUid = _authService?.firebaseUser.value?.uid;
    if (fbUid != null && fbUid.trim().isNotEmpty) return fbUid.trim();
    return isMentor ? initialBooking.mentorId : initialBooking.candidateId;
  }

  String get currentUserName {
    final name = _authService?.currentUser.value?.name;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    return isMentor
        ? (initialBooking.mentorName.isNotEmpty ? initialBooking.mentorName : 'Mentor')
        : (initialBooking.candidateName.isNotEmpty ? initialBooking.candidateName : 'Candidate');
  }

  @override
  void onInit() {
    super.onInit();
    bookingRx = Rx<BookingModel>(initialBooking);

    // Sync with database service booking list in realtime
    final match = _dbService.bookingsList
        .firstWhereOrNull((b) => b.id == initialBooking.id);
    if (match != null) {
      bookingRx.value = match;
    }

    _bookingSubscription =
        ever(_dbService.bookingsList, (List<BookingModel> list) {
      final updated = list.firstWhereOrNull((b) => b.id == initialBooking.id);
      if (updated != null) {
        bookingRx.value = updated;
      }
    });

    // Populate initial cached messages
    final cached = _dbService.priorityDmMessages[initialBooking.id];
    if (cached != null && cached.isNotEmpty) {
      messages.assignAll(cached);
    }

    // Stream realtime messages
    _messagesSubscription =
        _dbService.streamMessages(initialBooking.id).listen((incoming) {
      messages.assignAll(incoming);
      _scrollToBottom();
    });

    // Also trigger fetch in case socket event is pending
    _dbService.fetchMessages(initialBooking.id).then((fetched) {
      if (fetched.isNotEmpty && messages.isEmpty) {
        messages.assignAll(fetched);
        _scrollToBottom();
      }
    });
  }

  @override
  void onClose() {
    _messagesSubscription?.cancel();
    _bookingSubscription?.dispose();
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty || isSending.value) return;

    isSending.value = true;
    textController.clear();

    final newMsg = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: currentUserId,
      senderName: currentUserName,
      text: text,
      timestamp: DateTime.now(),
    );

    try {
      await _dbService.sendMessage(bookingRx.value.id, newMsg);
      _scrollToBottom();
    } finally {
      isSending.value = false;
    }
  }

  Future<void> startChat() async {
    await _dbService.updateBookingStatus(
      bookingRx.value.id,
      'Started',
      rescheduledAt: DateTime.now(),
    );
    Get.snackbar(
      'Priority DM Started 💬',
      'Chat is now live. Candidate has been notified with the top live banner.',
      backgroundColor: const Color(0xFF059669),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  Future<void> endChat() async {
    await _dbService.updateBookingStatus(
      bookingRx.value.id,
      'Completed',
    );
    Get.snackbar(
      'Priority DM Ended ✅',
      'Chat ended. Chat history is preserved for both mentor and candidate.',
      backgroundColor: const Color(0xFF2563EB),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  Future<void> cancelChat() async {
    await _dbService.updateBookingStatus(
      bookingRx.value.id,
      'Cancelled',
    );
    Get.snackbar(
      'Priority DM Cancelled ❌',
      'Chat cancelled. Chat history is preserved.',
      backgroundColor: const Color(0xFFDC2626),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  Future<void> restartChat() async {
    await _dbService.updateBookingStatus(
      bookingRx.value.id,
      'Started',
      rescheduledAt: DateTime.now(),
    );
    Get.snackbar(
      'Priority DM Re-Opened 💬',
      'Chat is live again. Candidate can now resume messaging.',
      backgroundColor: const Color(0xFF059669),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }
}

class PriorityDmChatView extends StatelessWidget {
  final BookingModel booking;
  final bool isMentor;

  const PriorityDmChatView({
    super.key,
    required this.booking,
    required this.isMentor,
  });

  static void openChat(
    BuildContext context, {
    required BookingModel booking,
    required bool isMentor,
  }) {
    Get.to(
      () => PriorityDmChatView(booking: booking, isMentor: isMentor),
      transition: Transition.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      PriorityDmController(initialBooking: booking, isMentor: isMentor),
      tag: booking.id,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final currentBooking = controller.bookingRx.value;
      final status = currentBooking.status.trim();
      final isLive = status == 'Started' || status == 'In Progress';
      final isCompleted = status == 'Completed' || status == 'Complete';
      final isCancelled = status == 'Cancelled';

      final otherName = isMentor
          ? (currentBooking.candidateName.isNotEmpty
              ? currentBooking.candidateName
              : 'Candidate')
          : (currentBooking.mentorName.isNotEmpty
              ? currentBooking.mentorName
              : 'Mentor');

      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 1,
          backgroundColor: isDark ? const Color(0xFF1C2541) : Colors.white,
          foregroundColor: isDark ? Colors.white : AppColors.textPrimaryLight,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Get.back(),
          ),
          title: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.18),
                    child: Text(
                      otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (isLive)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF1C2541) : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            otherName,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildStatusPill(status),
                      ],
                    ),
                    Text(
                      'Priority DM • ${currentBooking.serviceTitle}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (isMentor)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (val) {
                  if (val == 'start') {
                    controller.startChat();
                  } else if (val == 'end') {
                    _confirmEndChat(context, controller);
                  } else if (val == 'cancel') {
                    _confirmCancelChat(context, controller);
                  } else if (val == 'restart') {
                    controller.restartChat();
                  }
                },
                itemBuilder: (ctx) => [
                  if (!isLive && !isCompleted && !isCancelled)
                    const PopupMenuItem(
                      value: 'start',
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow_rounded, color: Color(0xFF059669)),
                          SizedBox(width: 8),
                          Text('Start Chat Now'),
                        ],
                      ),
                    ),
                  if (isLive)
                    const PopupMenuItem(
                      value: 'end',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Color(0xFF2563EB)),
                          SizedBox(width: 8),
                          Text('End Chat (Preserve History)'),
                        ],
                      ),
                    ),
                  if (isLive || (!isCompleted && !isCancelled))
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel_outlined, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text('Cancel Chat (Preserve History)'),
                        ],
                      ),
                    ),
                  if (isCompleted || isCancelled)
                    const PopupMenuItem(
                      value: 'restart',
                      child: Row(
                        children: [
                          Icon(Icons.replay_rounded, color: Color(0xFF059669)),
                          SizedBox(width: 8),
                          Text('Start Chat Again'),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
        body: Column(
          children: [
            // Top Status & Information Banners
            if (isCompleted)
              _buildStateBanner(
                context,
                title: 'Priority DM Completed',
                subtitle: 'Mentor has concluded this session. Chat history is permanently preserved.',
                icon: Icons.check_circle_rounded,
                bgColor: const Color(0xFFEFF6FF),
                borderColor: const Color(0xFFBFDBFE),
                iconColor: const Color(0xFF2563EB),
                textColor: const Color(0xFF1E40AF),
                actionLabel: isMentor ? 'Start Chat Again' : null,
                onAction: isMentor ? controller.restartChat : null,
              )
            else if (isCancelled)
              _buildStateBanner(
                context,
                title: 'Priority DM Cancelled',
                subtitle: 'This session was cancelled. Chat history remains available to view.',
                icon: Icons.info_outline_rounded,
                bgColor: const Color(0xFFFEF2F2),
                borderColor: const Color(0xFFFECACA),
                iconColor: const Color(0xFFDC2626),
                textColor: const Color(0xFF991B1B),
                actionLabel: isMentor ? 'Re-open Chat' : null,
                onAction: isMentor ? controller.restartChat : null,
              )
            else if (!isLive && isMentor)
              _buildStateBanner(
                context,
                title: 'Ready to start Priority DM?',
                subtitle: 'Start the chat to send a live notification banner to the candidate.',
                icon: Icons.bolt_rounded,
                bgColor: const Color(0xFFECFDF5),
                borderColor: const Color(0xFFA7F3D0),
                iconColor: const Color(0xFF059669),
                textColor: const Color(0xFF065F46),
                actionLabel: 'Start Chat',
                onAction: controller.startChat,
              )
            else if (!isLive && !isMentor)
              _buildStateBanner(
                context,
                title: 'Priority DM Scheduled',
                subtitle: 'Waiting for mentor to start the live chat session.',
                icon: Icons.access_time_rounded,
                bgColor: const Color(0xFFFFFBEB),
                borderColor: const Color(0xFFFDE68A),
                iconColor: const Color(0xFFD97706),
                textColor: const Color(0xFF92400E),
              ),

            // Message Area
            Expanded(
              child: controller.messages.isEmpty
                  ? _buildEmptyState(context, isDark, otherName)
                  : ListView.builder(
                      controller: controller.scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      itemCount: controller.messages.length,
                      itemBuilder: (context, index) {
                        final msg = controller.messages[index];
                        final isMe = msg.senderId == controller.currentUserId ||
                            (isMentor && msg.senderId == currentBooking.mentorId) ||
                            (!isMentor && msg.senderId == currentBooking.candidateId);
                        final showDateHeader = index == 0 ||
                            !_isSameDay(
                              msg.timestamp,
                              controller.messages[index - 1].timestamp,
                            );

                        return Column(
                          children: [
                            if (showDateHeader)
                              _buildDateSeparator(msg.timestamp, isDark),
                            _buildMessageBubble(
                              context: context,
                              message: msg,
                              isMe: isMe,
                              isDark: isDark,
                            ),
                          ],
                        );
                      },
                    ),
            ),

            // Chat Input Bar
            _buildInputBar(context, controller, isDark),
          ],
        ),
      );
    });
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;
    String label = status;

    if (status == 'Started' || status == 'In Progress') {
      bg = const Color(0xFFD1FAE5);
      fg = const Color(0xFF065F46);
      label = 'Live';
    } else if (status == 'Completed' || status == 'Complete') {
      bg = const Color(0xFFDBEAFE);
      fg = const Color(0xFF1E40AF);
      label = 'Ended';
    } else if (status == 'Cancelled') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF991B1B);
      label = 'Cancelled';
    } else {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
      label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildStateBanner(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
    required Color textColor,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: textColor.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, String otherName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to Priority DM',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Direct, priority channel between mentor and candidate. All messages and answers sent here are saved permanently.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Chat history is never deleted',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date, bool isDark) {
    final now = DateTime.now();
    String formatted;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      formatted = 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      formatted = 'Yesterday';
    } else {
      formatted = '${date.day}/${date.month}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        formatted,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required BuildContext context,
    required ChatMessageModel message,
    required bool isMe,
    required bool isDark,
  }) {
    final timeStr =
        '${message.timestamp.hour > 12 ? message.timestamp.hour - 12 : (message.timestamp.hour == 0 ? 12 : message.timestamp.hour)}:${message.timestamp.minute.toString().padLeft(2, '0')} ${message.timestamp.hour >= 12 ? 'PM' : 'AM'}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primary
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe
              ? null
              : Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe && message.senderName.isNotEmpty) ...[
              Text(
                message.senderName,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 3),
            ],
            Text(
              message.text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isMe
                    ? Colors.white
                    : (isDark ? Colors.white : AppColors.textPrimaryLight),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white70
                        : (isDark ? Colors.white54 : AppColors.textSecondaryLight),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_all_rounded,
                    size: 13,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(
    BuildContext context,
    PriorityDmController controller,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: 10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2541) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF29364B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: controller.textController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
                decoration: InputDecoration(
                  hintText: 'Type your priority message...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => controller.sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            final isSending = controller.isSending.value;
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                onPressed: isSending ? null : controller.sendMessage,
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _confirmEndChat(BuildContext context, PriorityDmController controller) {
    Get.defaultDialog(
      title: 'End Priority DM Session?',
      titleStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
      middleText:
          'This will mark the session as complete. Chat history will be preserved and will NOT be deleted.',
      middleTextStyle: GoogleFonts.inter(fontSize: 13),
      textConfirm: 'End Session',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFF2563EB),
      textCancel: 'Keep Open',
      onConfirm: () {
        Get.back();
        controller.endChat();
      },
    );
  }

  void _confirmCancelChat(BuildContext context, PriorityDmController controller) {
    Get.defaultDialog(
      title: 'Cancel Priority DM Session?',
      titleStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
      middleText:
          'This will mark the session as cancelled. Chat history will be preserved and will NOT be deleted.',
      middleTextStyle: GoogleFonts.inter(fontSize: 13),
      textConfirm: 'Cancel Session',
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      textCancel: 'Dismiss',
      onConfirm: () {
        Get.back();
        controller.cancelChat();
      },
    );
  }
}
