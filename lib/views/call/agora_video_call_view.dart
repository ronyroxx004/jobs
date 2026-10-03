import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../controllers/agora_call_controller.dart';
import '../../models/service_model.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/agora_config.dart';

class AgoraVideoCallView extends StatelessWidget {
  final BookingModel booking;
  final bool isMentor;

  const AgoraVideoCallView({
    super.key,
    required this.booking,
    required this.isMentor,
  });

  static void startCall(BuildContext context, {required BookingModel booking, required bool isMentor}) {
    Get.to(
      () => AgoraVideoCallView(booking: booking, isMentor: isMentor),
      transition: Transition.fadeIn,
      fullscreenDialog: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      AgoraCallController(booking: booking, isMentor: isMentor),
      tag: booking.id,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _showEndCallDialog(context, controller);
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF0F172A), // Premium dark navy
          body: SafeArea(
            child: Stack(
              children: [
                // 1. Fullscreen Remote Video, Error State, or Waiting View
                Positioned.fill(
                  child: Obx(() {
                    if (controller.hasConnectionError.value) {
                      return _buildErrorState(context, controller);
                    }

                    if (!controller.isJoined.value) {
                      return _buildLoadingState(context, controller);
                    }

                    if (controller.isRemoteUserJoined.value &&
                        controller.remoteUid.value != null &&
                        controller.remoteVideoController != null) {
                      if (controller.isRemoteVideoMuted.value) {
                        return _buildRemoteVideoOff(controller);
                      }
                      return AgoraVideoView(
                        controller: controller.remoteVideoController!,
                      );
                    }

                    return _buildWaitingForParticipant(context, controller);
                  }),
                ),

                // 2. Draggable Floating Local Camera Preview (PiP)
                Positioned.fill(
                  child: Obx(() {
                    if (!controller.isJoined.value || controller.isVideoDisabled.value) {
                      return const SizedBox.shrink();
                    }

                    return Align(
                      alignment: Alignment.topLeft,
                      child: Transform.translate(
                        offset: controller.pipOffset.value,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            final size = MediaQuery.of(context).size;
                            final newX = (controller.pipOffset.value.dx + details.delta.dx)
                                .clamp(12.0, size.width - 132.0);
                            final newY = (controller.pipOffset.value.dy + details.delta.dy)
                                .clamp(80.0, size.height - 230.0);
                            controller.pipOffset.value = Offset(newX, newY);
                          },
                          child: Container(
                            width: 120,
                            height: 165,
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                if (controller.isEngineInitialized.value &&
                                    controller.localVideoController != null)
                                  AgoraVideoView(
                                    controller: controller.localVideoController!,
                                  )
                                else
                                  Container(
                                    color: const Color(0xFF1E293B),
                                    child: const Center(
                                      child: Icon(Icons.person, color: Colors.white70, size: 40),
                                    ),
                                  ),
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'You',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: InkWell(
                                    onTap: controller.switchCamera,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.flip_camera_ios_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                // 3. Top Floating Glass Header
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: _buildTopHeader(context, controller),
                ),

                // 4. Bottom Call Controls Bar
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: _buildControlBar(context, controller),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AgoraCallController controller) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 2),
              ),
              child: const Icon(
                Icons.videocam_off_rounded,
                color: Colors.redAccent,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => Text(
                controller.connectionErrorTitle.value.isNotEmpty
                    ? controller.connectionErrorTitle.value
                    : 'Agora Connection Issue',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                    () => Text(
                      controller.connectionErrorDetail.value.isNotEmpty
                          ? controller.connectionErrorDetail.value
                          : 'Failed to connect to Agora RTC channel.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[300],
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.meeting_room_outlined, size: 16, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Channel: ${controller.channelName}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: Colors.grey[300],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                        tooltip: 'Copy Channel Name',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: controller.channelName));
                          Get.snackbar(
                            'Copied',
                            'Channel name copied to clipboard',
                            duration: const Duration(seconds: 2),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.key_outlined, size: 16, color: Colors.amberAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'App ID: ${AgoraConfig.appId}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Primary: Update Credentials
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _showCredentialsDialog(context, controller),
                icon: const Icon(Icons.vpn_key_rounded, size: 18),
                label: Text(
                  'Update Token / App ID',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Secondary: Retry
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: controller.retryConnection,
                icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white70),
                label: Text(
                  'Retry Connection',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Fallback: Preview / Demo Mode
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton.icon(
                onPressed: controller.startPreviewMode,
                icon: const Icon(Icons.play_circle_outline, size: 18, color: Color(0xFF10B981)),
                label: Text(
                  'Continue in UI Preview Mode (Demo)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Exit
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'Exit Call',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCredentialsDialog(BuildContext context, AgoraCallController controller) {
    final appIdCtrl = TextEditingController(text: AgoraConfig.appId);
    final channelCtrl = TextEditingController(
      text: AgoraConfig.testingChannel.isNotEmpty ? AgoraConfig.testingChannel : controller.channelName,
    );
    final tokenCtrl = TextEditingController(text: AgoraConfig.token);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Agora RTC Configuration',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your active Agora App ID and RTC Token. Make sure the channel name matches the one used to generate the token.',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400], height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: appIdCtrl,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Agora App ID',
                  labelStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: channelCtrl,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Channel Name (e.g. job)',
                  labelStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tokenCtrl,
                maxLines: 3,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Agora RTC Token',
                  labelStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    controller.updateCredentialsAndReconnect(
                      appIdCtrl.text,
                      tokenCtrl.text,
                      newChannel: channelCtrl.text,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Save & Reconnect',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context, AgoraCallController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
            ),
            child: const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Starting 1:1 Video Session',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => Text(
                controller.statusMessage.value,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
                textAlign: TextAlign.center,
              )),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => _showCredentialsDialog(context, controller),
                icon: const Icon(Icons.vpn_key_rounded, size: 16, color: Colors.blueAccent),
                label: Text(
                  'Enter Token',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.blueAccent),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: controller.startPreviewMode,
                icon: const Icon(Icons.play_circle_outline, size: 16, color: Color(0xFF10B981)),
                label: Text(
                  'Preview Mode',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF10B981)),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingForParticipant(BuildContext context, AgoraCallController controller) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing Avatar
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 4,
                      ),
                    ),
                  ),
                  Container(
                    width: 106,
                    height: 106,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        controller.participantName.isNotEmpty
                            ? controller.participantName[0].toUpperCase()
                            : 'M',
                        style: GoogleFonts.inter(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                'Waiting for ${controller.participantName}...',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  controller.participantRole,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Session Title Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_rounded, color: AppColors.secondary, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        controller.sessionTitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Both participants will connect automatically when they open this session.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400]),
              ),
              const SizedBox(height: 14),

              // Channel Info / Copy ID
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  backgroundColor: Colors.white.withOpacity(0.06),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: controller.channelName));
                  Get.snackbar(
                    'Channel ID Copied',
                    controller.channelName,
                    backgroundColor: const Color(0xFF1E293B),
                    colorText: Colors.white,
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: Text(
                  'Room: ${controller.channelName}',
                  style: GoogleFonts.robotoMono(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemoteVideoOff(AgoraCallController controller) {
    return Container(
      color: const Color(0xFF0B1220),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 46,
              backgroundColor: const Color(0xFF1E293B),
              child: Text(
                controller.participantName.isNotEmpty
                    ? controller.participantName[0].toUpperCase()
                    : 'U',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              controller.participantName,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam_off_rounded, color: Colors.grey, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Camera is turned off',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, AgoraCallController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Live pulse dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: controller.isRemoteUserJoined.value
                  ? const Color(0xFF10B981)
                  : Colors.amber,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (controller.isRemoteUserJoined.value
                          ? const Color(0xFF10B981)
                          : Colors.amber)
                      .withOpacity(0.6),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Participant details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.participantName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  controller.sessionTitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Duration Timer Badge
          Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      controller.formattedDuration,
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(width: 6),

          // Info / Notes trigger
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _showSessionInfoSheet(context, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(BuildContext context, AgoraCallController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mic Toggle
          Obx(() {
            final isMuted = controller.isMuted.value;
            return _buildControlButton(
              icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              label: isMuted ? 'Muted' : 'Mic',
              isActive: !isMuted,
              activeColor: Colors.white.withOpacity(0.12),
              inactiveColor: Colors.redAccent.withOpacity(0.85),
              onTap: controller.toggleMuteAudio,
            );
          }),

          // Video Toggle
          Obx(() {
            final isOff = controller.isVideoDisabled.value;
            return _buildControlButton(
              icon: isOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
              label: isOff ? 'Video Off' : 'Video',
              isActive: !isOff,
              activeColor: Colors.white.withOpacity(0.12),
              inactiveColor: Colors.redAccent.withOpacity(0.85),
              onTap: controller.toggleMuteVideo,
            );
          }),

          // Switch Camera
          _buildControlButton(
            icon: Icons.flip_camera_ios_rounded,
            label: 'Flip',
            isActive: true,
            activeColor: Colors.white.withOpacity(0.12),
            inactiveColor: Colors.white.withOpacity(0.12),
            onTap: controller.switchCamera,
          ),

          // Speakerphone Toggle
          Obx(() {
            final isSpeaker = controller.isSpeakerOn.value;
            return _buildControlButton(
              icon: isSpeaker ? Icons.volume_up_rounded : Icons.phone_in_talk_rounded,
              label: isSpeaker ? 'Speaker' : 'Earpiece',
              isActive: isSpeaker,
              activeColor: AppColors.primary.withOpacity(0.4),
              inactiveColor: Colors.white.withOpacity(0.12),
              onTap: controller.toggleSpeakerphone,
            );
          }),

          // End Call Button
          _buildControlButton(
            icon: Icons.call_end_rounded,
            label: 'End',
            isActive: true,
            activeColor: const Color(0xFFEF4444),
            inactiveColor: const Color(0xFFEF4444),
            isEndCall: true,
            onTap: () => _showEndCallDialog(context, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
    bool isEndCall = false,
  }) {
    final bg = isActive ? activeColor : inactiveColor;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isEndCall ? 52 : 46,
            height: isEndCall ? 52 : 46,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              boxShadow: isEndCall
                  ? [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isEndCall ? 24 : 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isEndCall ? const Color(0xFFEF4444) : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  void _showSessionInfoSheet(BuildContext context, AgoraCallController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1:1 Session Details',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            _buildInfoRow('Service', controller.sessionTitle),
            _buildInfoRow('Mentor', booking.mentorName),
            _buildInfoRow('Candidate', booking.candidateName),
            _buildInfoRow('Channel ID', controller.channelName),
            if (booking.userQuery.isNotEmpty)
              _buildInfoRow('Candidate Query', booking.userQuery),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400], fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showEndCallDialog(BuildContext context, AgoraCallController controller) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'End Video Session?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Text(
          isMentor
              ? 'Do you want to end this 1:1 call? You can also mark the mentorship session as completed.'
              : 'Are you sure you want to leave this 1:1 video call?',
          style: GoogleFonts.inter(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Resume', style: GoogleFonts.inter(color: Colors.grey[400])),
          ),
          if (isMentor)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                controller.endCall(markAsCompleted: true);
              },
              child: const Text('End & Mark Complete'),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              controller.endCall(markAsCompleted: false);
            },
            child: const Text('Leave Call'),
          ),
        ],
      ),
    );
  }
}
