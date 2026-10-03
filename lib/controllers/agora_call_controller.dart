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

  VideoViewController? localVideoController;
  VideoViewController? remoteVideoController;

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

  // Connection Error handling & diagnostics
  final RxBool hasConnectionError = false.obs;
  final RxString connectionErrorTitle = ''.obs;
  final RxString connectionErrorDetail = ''.obs;
  final RxString connectionErrorCode = ''.obs;
  Timer? _connectionTimeoutTimer;

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
          // If status is completed or cancelled by remote mentor, candidate ends call
          if (!isMentor && (current.status == 'Completed' || current.status == 'Cancelled')) {
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
    String currentStep = 'Requesting permissions';
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
      currentStep = 'Creating RTC Engine';

      // 1. Create engine
      _engine = createAgoraRtcEngine();
      currentStep = 'Initializing RTC Engine (App ID: ${AgoraConfig.appId})';
      await _engine.initialize(RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      // 2. Register event handlers
      currentStep = 'Registering Event Handlers';
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('[Agora] Local user ${connection.localUid} joined channel: ${connection.channelId}');
            _connectionTimeoutTimer?.cancel();
            isJoined.value = true;
            hasConnectionError.value = false;
            localUid.value = connection.localUid;
            statusMessage.value = 'Joined channel. Waiting for $participantName...';
            _startTimer();
          },
          onUserJoined: (RtcConnection connection, int uid, int elapsed) {
            debugPrint('[Agora] Remote user $uid joined channel');
            remoteUid.value = uid;
            remoteVideoController = VideoViewController.remote(
              rtcEngine: _engine,
              canvas: VideoCanvas(uid: uid),
              connection: RtcConnection(channelId: channelName),
            );
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
              remoteVideoController?.dispose();
              remoteVideoController = null;
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
            debugPrint('[Agora] Event onError $err: $msg');
            _handleAsyncAgoraError(err, msg);
          },
          onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
            debugPrint('[Agora] Connection state changed: $state, reason: $reason');
            if (state == ConnectionStateType.connectionStateFailed) {
              _connectionTimeoutTimer?.cancel();
              _handleConnectionFailureReason(reason);
            }
          },
        ),
      );

      // 3. Enable Video and start local camera preview
      currentStep = 'Enabling Video Module';
      await _engine.enableVideo();

      currentStep = 'Starting Camera Preview';
      await _engine.startPreview();

      localVideoController = VideoViewController(
        rtcEngine: _engine,
        canvas: const VideoCanvas(uid: 0),
      );

      // 4. Join channel (client role broadcaster is handled directly by ChannelMediaOptions)
      currentStep = 'Joining Channel ($channelName)';
      await _engine.joinChannel(
        token: AgoraConfig.token,
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );

      // Start 6-second timeout: if token is required by Agora certificate, notify gracefully
      _connectionTimeoutTimer?.cancel();
      _connectionTimeoutTimer = Timer(const Duration(seconds: 6), () {
        if (!isJoined.value && !hasConnectionError.value) {
          hasConnectionError.value = true;
          if (AgoraConfig.token.isEmpty) {
            connectionErrorTitle.value = 'Agora RTC Token Required';
            connectionErrorDetail.value =
                'Connection to Agora server timed out.\n\n'
                'Your Agora Console project has "App Certificate" enabled, which requires an active RTC Token.\n\n'
                'Channel Name: $channelName\n\n'
                'How to fix:\n'
                '1. Go to console.agora.io > Project Management.\n'
                '2. Generate a temporary RTC Token for channel "$channelName".\n'
                '3. Tap "Update Token / App ID" below and paste the token, or test in Preview Mode.';
          } else {
            connectionErrorTitle.value = 'Connection Timed Out';
            connectionErrorDetail.value =
                'Unable to reach Agora servers for channel "$channelName". Please verify your internet connection or check your Agora App ID / Token.';
          }
          statusMessage.value = connectionErrorTitle.value;
        }
      });

      // Safe speakerphone enable after joining
      try {
        await _engine.setEnableSpeakerphone(true);
        isSpeakerOn.value = true;
      } catch (e) {
        debugPrint('[Agora] setEnableSpeakerphone notice: $e');
      }

      isEngineInitialized.value = true;
    } on AgoraRtcException catch (e) {
      debugPrint('[Agora] AgoraRtcException: code ${e.code}, message: ${e.message}');
      hasConnectionError.value = true;
      connectionErrorCode.value = e.code.toString();

      final codeStr = e.code.toString();
      final msgStr = (e.message ?? '').toLowerCase();
      String title = 'Agora Connection Error (${e.code})';
      String detail = '';

      if (codeStr.contains('110') ||
          codeStr.contains('109') ||
          codeStr.contains('Token') ||
          msgStr.contains('token')) {
        title = 'Agora RTC Token Required';
        detail =
            'Failed at: $currentStep\n\n'
            'Your Agora project has "App Certificate" enabled, requiring an active RTC Token.\n\n'
            'Channel Name: $channelName\n\n'
            'How to fix:\n'
            '1. In console.agora.io > Project Management, generate a temporary RTC Token for channel "$channelName".\n'
            '2. Tap "Update Token / App ID" below and paste the token.';
      } else if (codeStr.contains('101') ||
          codeStr.contains('InvalidAppId') ||
          msgStr.contains('app id')) {
        title = 'Invalid Agora App ID';
        detail =
            'Failed at: $currentStep\n\n'
            'The App ID "${AgoraConfig.appId}" was not found or is inactive in Agora Console.\n\n'
            'Fix: Copy your real App ID from console.agora.io and paste it using "Update Token / App ID" below.';
      } else if (codeStr.contains('-2') ||
          codeStr.contains('InvalidArgument') ||
          msgStr.contains('argument')) {
        title = 'Agora Parameter Rejected (-2)';
        detail =
            'Failed at: $currentStep\n\n'
            'Agora rejected parameters passed to the engine.\n'
            'Message: ${e.message ?? "Invalid argument"}\n'
            'Channel: $channelName\n'
            'App ID: ${AgoraConfig.appId}';
      } else if (codeStr.contains('-3') ||
          codeStr.contains('NotReady') ||
          msgStr.contains('ready')) {
        title = 'Agora Engine Not Ready (-3)';
        detail =
            'Failed at: $currentStep\n\n'
            'The Agora RTC engine was not ready for this command.\n\n'
            'Please tap "Retry Connection" to reconnect.';
      } else if (codeStr.contains('17') || codeStr.contains('Rejected')) {
        title = 'Join Channel Rejected (-17)';
        detail =
            'Failed at: $currentStep\n\n'
            'The Agora server rejected joining channel "$channelName" (Code: ${e.code}). Message: ${e.message ?? "Rejected"}';
      } else {
        title = 'Agora Error (${e.code})';
        detail =
            'Failed at: $currentStep\n\n'
            'Code: ${e.code}\n'
            'Message: ${e.message ?? "Unknown Agora RTC issue"}\n\n'
            'You can tap "Continue in UI Preview Mode" to test the video call interface without Agora servers.';
      }

      connectionErrorTitle.value = title;
      connectionErrorDetail.value = detail;
      statusMessage.value = title;

      Get.snackbar(
        title,
        detail,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 8),
      );
    } on MissingPluginException catch (e) {
      debugPrint('[Agora] MissingPluginException: $e');
      hasConnectionError.value = true;
      connectionErrorTitle.value = 'Native App Rebuild Required';
      connectionErrorDetail.value =
          'New native Agora plugins were added. Please stop the app and run "flutter run" to compile native libraries.';
      statusMessage.value = 'Rebuild required to load native Agora RTC';
      Get.snackbar(
        'App Rebuild Required ⚙️',
        'Please stop the app and run "flutter run" again to compile native Agora libraries.',
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 6),
      );
    } catch (e) {
      debugPrint('[Agora] Initialization error: $e');
      final errStr = e.toString();
      hasConnectionError.value = true;

      if (errStr.contains('AgoraRtcException') || errStr.contains('-110') || errStr.contains('-109')) {
        connectionErrorTitle.value = 'Agora Token Required';
        connectionErrorDetail.value =
            'Your Agora project requires an RTC Token (Certificate enabled).\nChannel: $channelName';
      } else if (errStr.contains('MissingPluginException') || errStr.contains('plugin')) {
        connectionErrorTitle.value = 'Native App Rebuild Required';
        connectionErrorDetail.value =
            'Please stop the running app and execute "flutter run" again.';
      } else {
        connectionErrorTitle.value = 'Connection Error';
        connectionErrorDetail.value = '$e';
      }

      statusMessage.value = 'Connection notice: $e';
      Get.snackbar(
        connectionErrorTitle.value,
        connectionErrorDetail.value,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 7),
      );
    }
  }

  void _handleConnectionFailureReason(ConnectionChangedReasonType reason) {
    hasConnectionError.value = true;
    final reasonStr = reason.toString();

    if (reasonStr.contains('Token') || reasonStr.contains('token')) {
      connectionErrorTitle.value = 'Agora RTC Token Required';
      connectionErrorDetail.value =
          'Agora rejected the connection because your project has "App Certificate" enabled, which requires an active RTC Token.\n\n'
          'Channel Name: $channelName\n\n'
          'How to fix:\n'
          '1. Go to console.agora.io > Project Management.\n'
          '2. Generate a temporary RTC Token for channel "$channelName".\n'
          '3. Tap "Update Token / App ID" below and paste the token.';
    } else if (reasonStr.contains('InvalidAppId') || reasonStr.contains('appId')) {
      connectionErrorTitle.value = 'Invalid Agora App ID';
      connectionErrorDetail.value =
          'The App ID "${AgoraConfig.appId}" is invalid or inactive in Agora Console.\n\n'
          'Please update AgoraConfig.appId with your active App ID from console.agora.io.';
    } else if (reasonStr.contains('Rejected') || reasonStr.contains('rejected')) {
      connectionErrorTitle.value = 'Connection Rejected by Server';
      connectionErrorDetail.value =
          'Agora server rejected connection for channel "$channelName" ($reason).';
    } else {
      connectionErrorTitle.value = 'Agora Connection Failed';
      connectionErrorDetail.value =
          'Failed to connect to Agora channel "$channelName". Reason: $reason';
    }

    statusMessage.value = connectionErrorTitle.value;
  }

  void _handleAsyncAgoraError(ErrorCodeType err, String msg) {
    final errStr = err.toString();
    if (errStr.contains('errTokenExpired') || errStr.contains('errInvalidToken') || msg.toLowerCase().contains('token')) {
      hasConnectionError.value = true;
      connectionErrorTitle.value = 'Agora RTC Token Required';
      connectionErrorDetail.value =
          'Agora requires an active RTC Token to join channel "$channelName".\n\n'
          'Please tap "Update Token / App ID" to enter your RTC Token.';
      statusMessage.value = connectionErrorTitle.value;
    }
  }

  Future<void> retryConnection() async {
    hasConnectionError.value = false;
    statusMessage.value = 'Reconnecting to Agora...';
    await _cleanupEngine();
    await initAgora();
  }

  Future<void> updateCredentialsAndReconnect(String newAppId, String newToken, {String? newChannel}) async {
    if (newAppId.trim().isNotEmpty) {
      AgoraConfig.appId = newAppId.trim();
    }
    AgoraConfig.token = newToken.trim();
    if (newChannel != null && newChannel.trim().isNotEmpty) {
      AgoraConfig.testingChannel = newChannel.trim();
    }
    await retryConnection();
  }

  void startPreviewMode() {
    hasConnectionError.value = false;
    isJoined.value = true;
    _startTimer();
    statusMessage.value = 'Preview Mode Active';
    Get.snackbar(
      'Demo Preview Mode 🎬',
      'You are previewing the call interface. Real-time video streaming requires valid Agora Console credentials.',
      backgroundColor: const Color(0xFF1E293B),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  void _startTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      callSeconds.value++;
    });
  }

  Future<void> toggleMuteAudio() async {
    final nextState = !isMuted.value;
    if (isEngineInitialized.value) {
      await _engine.muteLocalAudioStream(nextState);
    }
    isMuted.value = nextState;
  }

  Future<void> toggleMuteVideo() async {
    final nextState = !isVideoDisabled.value;
    if (isEngineInitialized.value) {
      await _engine.muteLocalVideoStream(nextState);
    }
    isVideoDisabled.value = nextState;
  }

  Future<void> switchCamera() async {
    if (isEngineInitialized.value) {
      await _engine.switchCamera();
    }
    isFrontCamera.value = !isFrontCamera.value;
  }

  Future<void> toggleSpeakerphone() async {
    final nextState = !isSpeakerOn.value;
    if (isEngineInitialized.value) {
      await _engine.setEnableSpeakerphone(nextState);
    }
    isSpeakerOn.value = nextState;
  }

  Future<void> endCall({bool markAsCompleted = false}) async {
    await _cleanupEngine();

    if (markAsCompleted && isMentor) {
      try {
        if (Get.isRegistered<DatabaseService>()) {
          final db = Get.find<DatabaseService>();
          await db.updateBookingStatus(booking.id, 'Completed');
        }
      } catch (e) {
        debugPrint('Could not update booking status: $e');
      }
    }

    if (Get.isDialogOpen == true) Get.back();
    Get.back();

    Get.snackbar(
      markAsCompleted ? 'Session Completed & Call Ended' : 'Call Ended',
      markAsCompleted
          ? 'Mentorship session marked completed. Top live call banner removed.'
          : 'Session duration: $formattedDuration',
      backgroundColor: markAsCompleted ? const Color(0xFF059669) : const Color(0xFF1E293B),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _cleanupEngine() async {
    _callTimer?.cancel();
    localVideoController?.dispose();
    localVideoController = null;
    remoteVideoController?.dispose();
    remoteVideoController = null;
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
