import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/utils/agora_config.dart';
import '../models/service_model.dart';
import '../services/database_service.dart';

class AgoraCallController extends GetxController {
  final BookingModel booking;
  final bool isMentor;

  AgoraCallController({
    required this.booking,
    required this.isMentor,
  });

  late RtcEngine _engine;
  RtcEngine get engine => _engine;

  // Reactive Call States
  final RxBool isEngineInitialized = false.obs;
  final RxBool isJoined = false.obs;
  final RxnInt localUid = RxnInt();
  final RxnInt remoteUid = RxnInt();
  final RxBool isRemoteUserJoined = false.obs;
  final RxBool isRemoteVideoMuted = false.obs;
  final RxBool isRemoteAudioMuted = false.obs;

  // Local Controls
  final RxBool isMuted = false.obs;
  final RxBool isVideoDisabled = false.obs;
  final RxBool isFrontCamera = true.obs;
  final RxBool isSpeakerOn = true.obs;
  final RxBool isPiPMinimized = false.obs;

  // Call Status & Duration
  final RxInt callSeconds = 0.obs;
  Timer? _callTimer;
  Worker? _bookingWatcher;
  final RxBool _isEnding = false.obs;
  final RxString statusMessage = 'Initializing video call...'.obs;

  // Draggable PiP position
  final Rx<Offset> pipOffset = const Offset(20, 80).obs;

  String get channelName => AgoraConfig.getChannelName(booking.id);

  String get participantName =>
      isMentor ? booking.candidateName : booking.mentorName;

  String get participantRole => isMentor ? 'Candidate / Mentee' : 'Expert Mentor';

  String get sessionTitle => booking.serviceTitle;

  String get formattedDuration {
    final minutes = (callSeconds.value ~/ 60).toString().padLeft(2, '0');
    final seconds = (callSeconds.value % 60).toString().padLeft(2, '0');
    final hours = (callSeconds.value ~/ 3600);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void onInit() {
    super.onInit();
    _listenToBookingStatus();
    initAgora();
  }

  void _listenToBookingStatus() {
    if (Get.isRegistered<DatabaseService>()) {
      final db = Get.find<DatabaseService>();
      _bookingWatcher = ever(db.bookingsList, (List<BookingModel> list) {
        final current = list.firstWhereOrNull((b) => b.id == booking.id);
        if (current != null) {
          if (current.status == 'Completed' || current.status == 'Cancelled') {
            _handleCallTerminatedByStatus(current.status);
          }
        }
      });
    }
  }

  Future<void> _handleCallTerminatedByStatus(String status) async {
    if (_isEnding.value) return;
    _isEnding.value = true;
    await _cleanupEngine();

    if (Get.isDialogOpen == true) Get.back();
    if (Get.isBottomSheetOpen == true) Get.back();
    Get.back();

    if (status == 'Completed') {
      Get.snackbar(
        '1:1 Session Completed! 🎉',
        isMentor
            ? 'You have completed this session.'
            : 'The mentor has marked this 1:1 session as completed.',
        backgroundColor: const Color(0xFF059669),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 5),
      );
    } else {
      Get.snackbar(
        'Session Cancelled',
        'This 1:1 call session has been cancelled.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
      );
    }
  }

  @override
  void onClose() {
    _bookingWatcher?.dispose();
    _cleanupEngine();
    super.onClose();
  }

  Future<void> initAgora() async {
    try {
      statusMessage.value = 'Requesting camera & microphone permissions...';
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      if (statuses[Permission.camera]?.isDenied == true ||
          statuses[Permission.microphone]?.isDenied == true) {
        statusMessage.value = 'Camera and microphone permissions are required for video call.';
        Get.snackbar(
          'Permission Required',
          'Please allow Camera and Microphone permissions to start video call.',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      statusMessage.value = 'Connecting to Agora network...';

      // 1. Create engine
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // 2. Register event handlers
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('[Agora] Local user ${connection.localUid} joined channel: ${connection.channelId}');
            isJoined.value = true;
            localUid.value = connection.localUid;
            statusMessage.value = 'Joined channel. Waiting for $participantName...';
            _startTimer();
          },
          onUserJoined: (RtcConnection connection, int uid, int elapsed) {
            debugPrint('[Agora] Remote user $uid joined channel');
            remoteUid.value = uid;
            isRemoteUserJoined.value = true;
            isRemoteVideoMuted.value = false;
            statusMessage.value = 'Connected with $participantName';
            Get.snackbar(
              'Call Connected 🟢',
              '$participantName joined the 1:1 session.',
              backgroundColor: const Color(0xFF059669),
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 3),
            );
          },
          onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
            debugPrint('[Agora] Remote user $uid left channel: $reason');
            if (remoteUid.value == uid) {
              remoteUid.value = null;
              isRemoteUserJoined.value = false;
              statusMessage.value = '$participantName has left the call.';
              Get.snackbar(
                'Participant Left',
                '$participantName has disconnected.',
                backgroundColor: Colors.orangeAccent,
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP,
              );
            }
          },
          onUserMuteVideo: (RtcConnection connection, int uid, bool muted) {
            if (remoteUid.value == uid) {
              isRemoteVideoMuted.value = muted;
            }
          },
          onUserMuteAudio: (RtcConnection connection, int uid, bool muted) {
            if (remoteUid.value == uid) {
              isRemoteAudioMuted.value = muted;
            }
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('[Agora] Error $err: $msg');
          },
          onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
            debugPrint('[Agora] Connection state changed: $state, reason: $reason');
          },
        ),
      );

      // 3. Enable Video and set configurations
      await _engine.enableVideo();
      await _engine.startPreview();
      await _engine.setEnableSpeakerphone(true);
      isSpeakerOn.value = true;

      // 4. Join channel
      await _engine.joinChannel(
        token: AgoraConfig.token,
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
        ),
      );

      isEngineInitialized.value = true;
    } on MissingPluginException catch (e) {
      debugPrint('[Agora] MissingPluginException: $e');
      isJoined.value = true; // allow UI preview
      _startTimer();
      statusMessage.value = 'Rebuild required to load native Agora RTC';
      Get.snackbar(
        'App Rebuild Required ⚙️',
        'New native Agora plugins were added. Please stop the running app and run "flutter run" to compile the native libraries.',
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 6),
      );
    } catch (e) {
      debugPrint('[Agora] Initialization error: $e');
      final errStr = e.toString();
      if (errStr.contains('MissingPluginException') || errStr.contains('plugin')) {
        isJoined.value = true;
        _startTimer();
        statusMessage.value = 'Full app rebuild required (stop & run flutter run)';
        Get.snackbar(
          'App Rebuild Required ⚙️',
          'Please stop the app and run "flutter run" again to compile the Agora native plugin.',
          backgroundColor: const Color(0xFF1E293B),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 6),
        );
      } else {
        statusMessage.value = 'Connection notice: $e';
        Get.snackbar(
          'Connection Info',
          '$e',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  void _startTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      callSeconds.value++;
    });
  }

  Future<void> toggleMuteAudio() async {
    final nextState = !isMuted.value;
    await _engine.muteLocalAudioStream(nextState);
    isMuted.value = nextState;
  }

  Future<void> toggleMuteVideo() async {
    final nextState = !isVideoDisabled.value;
    await _engine.muteLocalVideoStream(nextState);
    isVideoDisabled.value = nextState;
  }

  Future<void> switchCamera() async {
    await _engine.switchCamera();
    isFrontCamera.value = !isFrontCamera.value;
  }

  Future<void> toggleSpeakerphone() async {
    final nextState = !isSpeakerOn.value;
    await _engine.setEnableSpeakerphone(nextState);
    isSpeakerOn.value = nextState;
  }

  Future<void> endCall({bool markAsCompleted = false}) async {
    await _cleanupEngine();

    if (markAsCompleted && isMentor) {
      try {
        if (Get.isRegistered<DatabaseService>()) {
          final db = Get.find<DatabaseService>();
          final updated = booking.copyWith(status: 'Completed');
          await db.updateBooking(updated);
        }
      } catch (e) {
        debugPrint('Could not update booking status: $e');
      }
    }

    if (Get.isDialogOpen == true) Get.back();
    Get.back();

    Get.snackbar(
      'Call Ended',
      'Session duration: $formattedDuration',
      backgroundColor: const Color(0xFF1E293B),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _cleanupEngine() async {
    _callTimer?.cancel();
    if (isEngineInitialized.value) {
      try {
        await _engine.leaveChannel();
        await _engine.stopPreview();
        await _engine.release();
      } catch (e) {
        debugPrint('[Agora] Cleanup error: $e');
      }
      isEngineInitialized.value = false;
      isJoined.value = false;
      remoteUid.value = null;
    }
  }
}
