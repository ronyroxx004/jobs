import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import '../core/utils/constants.dart';

const AndroidNotificationChannel _broadcastChannel = AndroidNotificationChannel(
  'broadcast_channel',
  'Broadcast Notifications',
  description: 'High-priority broadcast messages and system announcements',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Top-level background message handler invoked by Android/iOS when the app is closed.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('🔔 [FCM Closed/Background] Push received: ${message.messageId} - ${message.notification?.title}');

    // If the message has a notification payload, Android and iOS automatically
    // show it in the system notification shade via Google Play Services / APNs.
    // If it's a data-only message while closed, show it via local notifications.
    if (message.notification == null && message.data.isNotEmpty) {
      final title = message.data['title'] ?? 'New Notification';
      final body = message.data['body'] ?? '';
      await _showSystemNotification(title: title, body: body);
    }
  } catch (e) {
    debugPrint('🔔 [FCM Background] Error: $e');
  }
}

final Set<String> _recentNotificationDedupe = {};

Future<void> _showSystemNotification({required String title, required String body}) async {
  final dedupeKey = '$title|$body';
  if (_recentNotificationDedupe.contains(dedupeKey)) {
    debugPrint('🔔 [Deduplication] Suppressed duplicate notification within 4s: $dedupeKey');
    return;
  }
  _recentNotificationDedupe.add(dedupeKey);
  Timer(const Duration(seconds: 4), () {
    _recentNotificationDedupe.remove(dedupeKey);
  });

  try {
    final androidPlugin = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  } catch (_) {}

  final notifId = dedupeKey.hashCode.abs() % 100000;

  await _localNotificationsPlugin.show(
    id: notifId,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _broadcastChannel.id,
        _broadcastChannel.name,
        channelDescription: _broadcastChannel.description,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        visibility: NotificationVisibility.public,
        ticker: title,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
  );
}

class NotificationService extends GetxService {
  static NotificationService get to => Get.find<NotificationService>();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RxString fcmToken = ''.obs;

  StreamSubscription? _broadcastSubscription;
  StreamSubscription? _userNotificationsSubscription;
  DateTime _serviceStartTime = DateTime.now();
  String? _currentSubscribedRole;
  String? _currentSubscribedUserTopic;

  @override
  void onInit() {
    super.onInit();
    _serviceStartTime = DateTime.now();
    _setupLocalNotificationChannels();
    initializeFcm();
    _setupRealtimeBroadcastListener();

    // If already logged in, sync personal user topic
    final uid = _auth.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      syncUserSubscription(uid);
    }
  }

  @override
  void onClose() {
    _broadcastSubscription?.cancel();
    _userNotificationsSubscription?.cancel();
    super.onClose();
  }

  /// Show a system notification directly in the phone's status bar
  Future<void> showStatusNotification({required String title, required String body}) async {
    await _showSystemNotification(title: title, body: body);
  }

  /// Create system notification channels on Android and request POST_NOTIFICATIONS permission
  Future<void> _setupLocalNotificationChannels() async {
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _localNotificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('🔔 User tapped system notification: ${details.payload}');
        },
      );

      final androidPlugin = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_broadcastChannel);
        final bool? granted = await androidPlugin.requestNotificationsPermission();
        debugPrint('🔔 Android notification permission granted: $granted');
      }
    } catch (e) {
      debugPrint('🔔 Error setting up notification channel: $e');
    }
  }

  /// Initialize FCM permissions, token registration, topic subscriptions, and listeners.
  Future<void> initializeFcm() async {
    try {
      // 1. Request notification permissions (required for iOS and Android 13+)
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('🔔 FCM Permission status: ${settings.authorizationStatus}');

      // 2. Enable foreground display options
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Automatically subscribe to the global 'all_users' broadcast topic (FREE on Spark plan)
      await _fcm.subscribeToTopic('all_users');
      debugPrint('🔔 Subscribed to FCM topic: all_users');

      // 4. Retrieve and store the device token
      try {
        final token = await _fcm.getToken();
        if (token != null) {
          fcmToken.value = token;
          debugPrint('🔔 FCM Device Token: $token');
          await _saveTokenToDatabase(token);
        }
      } catch (tokenErr) {
        debugPrint('🔔 Could not fetch FCM token directly: $tokenErr');
      }

      // Listen for token updates
      _fcm.onTokenRefresh.listen((newToken) {
        fcmToken.value = newToken;
        _saveTokenToDatabase(newToken);
      });

      // 5. Foreground message handler: display system notification in status bar
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 Foreground FCM received: ${message.notification?.title}');
        final title = message.notification?.title ?? message.data['title'] ?? 'New Notification';
        final body = message.notification?.body ?? message.data['body'] ?? '';
        _showSystemNotification(title: title, body: body);
      });

      // 6. Handle notification click when app is opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 User tapped notification: ${message.notification?.title}');
      });

      // 7. Handle notification if app was opened from terminated state
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🔔 App launched from closed state via push: ${initialMessage.notification?.title}');
      }
    } catch (e) {
      debugPrint('🔔 Error initializing FCM: $e');
    }
  }

  /// Subscribe user device to their specific role topic (e.g., candidates, recruiters, mentors)
  Future<void> updateRoleTopic(String? role) async {
    if (role == null || role.isEmpty) return;
    final normalized = role.toLowerCase().trim();

    if (_currentSubscribedRole == normalized) return;

    try {
      if (_currentSubscribedRole != null) {
        await _fcm.unsubscribeFromTopic(_currentSubscribedRole!);
      }

      String topic;
      switch (normalized) {
        case 'candidate':
          topic = 'candidates';
          break;
        case 'recruiter':
          topic = 'recruiters';
          break;
        case 'mentor':
          topic = 'mentors';
          break;
        case 'instructor':
          topic = 'instructors';
          break;
        default:
          topic = '${normalized}s';
      }

      await _fcm.subscribeToTopic(topic);
      _currentSubscribedRole = topic;
      debugPrint('🔔 Subscribed to role topic: $topic');
    } catch (e) {
      debugPrint('🔔 Failed to subscribe to role topic: $e');
    }
  }

  /// Subscribe user device to their personal UID topic (e.g. user_abc123)
  /// and start listening for real-time candidate notifications.
  Future<void> syncUserSubscription(String? uid) async {
    if (uid == null || uid.isEmpty) return;
    final cleanUid = uid.replaceAll(RegExp(r'[^a-zA-Z0-9-_]'), '_');
    final topic = 'user_$cleanUid';

    if (_currentSubscribedUserTopic != topic) {
      try {
        if (_currentSubscribedUserTopic != null) {
          await _fcm.unsubscribeFromTopic(_currentSubscribedUserTopic!);
        }
        await _fcm.subscribeToTopic(topic);
        _currentSubscribedUserTopic = topic;
        debugPrint('🔔 Subscribed to personal candidate topic: $topic');
      } catch (e) {
        debugPrint('🔔 Failed to subscribe to personal topic: $e');
      }
    }

    _listenToUserNotifications(uid);
  }

  /// Saves or updates the FCM token in Firebase Realtime Database
  Future<void> _saveTokenToDatabase(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final db = FirebaseDatabase.instance;
      await db.ref(DatabaseKeys.fcmTokens).child(uid).set({
        'token': token,
        'updatedAt': DateTime.now().toIso8601String(),
        'platform': GetPlatform.isAndroid ? 'android' : (GetPlatform.isIOS ? 'ios' : 'web'),
      });
    } catch (e) {
      debugPrint('🔔 Error saving FCM token to database: $e');
    }
  }

  /// Listen for targeted notifications sent to this specific user (e.g. mentor bookings, candidate status)
  void _listenToUserNotifications(String userId) {
    _userNotificationsSubscription?.cancel();
    try {
      final db = FirebaseDatabase.instance;
      _userNotificationsSubscription = db
          .ref(DatabaseKeys.userNotifications)
          .child(userId)
          .limitToLast(5)
          .onChildAdded
          .listen((event) {
        final data = event.snapshot.value;
        if (data is! Map) return;

        final map = Map<String, dynamic>.from(data);
        final createdAtStr = map['createdAt'] as String?;
        final title = map['title'] as String? ?? 'New Notification';
        final body = map['body'] as String? ?? '';

        if (createdAtStr != null) {
          final createdAt = DateTime.tryParse(createdAtStr);
          if (createdAt != null && createdAt.isBefore(_serviceStartTime)) {
            return;
          }
        }

        // Post directly to phone's status bar
        _showSystemNotification(title: title, body: body);
      });
    } catch (e) {
      debugPrint('🔔 Error setting up user notifications listener: $e');
    }
  }

  /// Real-time broadcast listener that ensures active users also see the system notification
  void _setupRealtimeBroadcastListener() {
    _broadcastSubscription?.cancel();
    try {
      final db = FirebaseDatabase.instance;
      _broadcastSubscription = db
          .ref(DatabaseKeys.broadcastNotifications)
          .limitToLast(5)
          .onChildAdded
          .listen((event) {
        final data = event.snapshot.value;
        if (data is! Map) return;

        final map = Map<String, dynamic>.from(data);
        final createdAtStr = map['createdAt'] as String?;
        final title = map['title'] as String? ?? 'Broadcast Message';
        final body = map['body'] as String? ?? '';

        if (createdAtStr != null) {
          final createdAt = DateTime.tryParse(createdAtStr);
          if (createdAt != null && createdAt.isBefore(_serviceStartTime)) {
            return;
          }
        }

        // Deliver system status bar notification
        _showSystemNotification(title: title, body: body);
      });
    } catch (e) {
      debugPrint('🔔 Error setting up realtime broadcast listener: $e');
    }
  }

  /// Dispatches push notification to a specific user (candidate, mentor, recruiter)
  Future<bool> sendUserPush({
    required String userId,
    required String title,
    required String body,
    String? referenceId,
    String? type,
  }) async {
    final cleanUid = userId.replaceAll(RegExp(r'[^a-zA-Z0-9-_]'), '_');
    final topic = 'user_$cleanUid';

    // 1. Record in Realtime Database under user_notifications/$userId
    try {
      final db = FirebaseDatabase.instance;
      final notifRef = db.ref(DatabaseKeys.userNotifications).child(userId).push();
      await notifRef.set({
        'id': notifRef.key,
        'title': title,
        'body': body,
        'referenceId': referenceId ?? '',
        'type': type ?? 'general',
        'createdAt': DateTime.now().toIso8601String(),
      });
      debugPrint('🔔 Recorded notification in user_notifications for $userId');
    } catch (dbErr) {
      debugPrint('🔔 Error recording user notification: $dbErr');
    }

    // 2. Fetch user's device token from fcm_tokens/$userId
    String? deviceToken;
    try {
      final tokenSnap = await FirebaseDatabase.instance
          .ref(DatabaseKeys.fcmTokens)
          .child(userId)
          .child('token')
          .get();
      if (tokenSnap.exists && tokenSnap.value != null) {
        deviceToken = tokenSnap.value.toString().trim();
      }
    } catch (_) {}

    final payloadData = {
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'type': type ?? 'general',
      'userId': userId,
      'referenceId': referenceId ?? '',
      'title': title,
      'body': body,
    };

    // 3. Dispatch to deviceToken if available, otherwise fallback to personal topic (never send to both)
    if (deviceToken != null && deviceToken.isNotEmpty) {
      return await _dispatchFcmMessage(
        token: deviceToken,
        title: title,
        body: body,
        data: payloadData,
      );
    } else {
      return await _dispatchFcmMessage(
        topic: topic,
        title: title,
        body: body,
        data: payloadData,
      );
    }
  }

  /// Dispatches push notification when recruiter updates a candidate's application status
  Future<bool> sendCandidatePush({
    required String candidateId,
    required String title,
    required String body,
    String? appId,
  }) {
    return sendUserPush(
      userId: candidateId,
      title: title,
      body: body,
      referenceId: appId,
      type: 'application_status',
    );
  }

  /// Sends a broadcast push notification to an FCM Topic without requiring the Blaze plan.
  Future<bool> sendFreeFcmPush({
    required String title,
    required String body,
    required String targetAudience,
    String? notificationId,
  }) async {
    String topic;
    switch (targetAudience.toLowerCase().trim()) {
      case 'candidates':
        topic = 'candidates';
        break;
      case 'recruiters':
        topic = 'recruiters';
        break;
      case 'mentors':
        topic = 'mentors';
        break;
      default:
        topic = 'all_users';
    }

    return await _dispatchFcmMessage(
      topic: topic,
      title: title,
      body: body,
      data: {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'id': notificationId ?? '',
        'title': title,
        'body': body,
        'audience': targetAudience,
      },
    );
  }

  /// Internal helper to send push notifications via FCM HTTP v1 or FCM Legacy
  Future<bool> _dispatchFcmMessage({
    String? topic,
    String? token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if ((topic == null || topic.isEmpty) && (token == null || token.isEmpty)) {
      return false;
    }

    try {
      final db = FirebaseDatabase.instance;

      // 1. Try FCM HTTP v1 using Service Account JSON credentials
      try {
        final serviceAccountSnap =
            await db.ref(DatabaseKeys.appConfig).child('fcm_service_account').get();

        if (serviceAccountSnap.exists && serviceAccountSnap.value != null) {
          dynamic rawData = serviceAccountSnap.value;
          Map<String, dynamic> saMap;
          if (rawData is String) {
            saMap = jsonDecode(rawData) as Map<String, dynamic>;
          } else {
            saMap = Map<String, dynamic>.from(rawData as Map);
          }

          final projectId = saMap['project_id'] ?? 'jobs-37214';
          final credentials = auth.ServiceAccountCredentials.fromJson(saMap);
          final client = await auth.clientViaServiceAccount(
            credentials,
            ['https://www.googleapis.com/auth/firebase.messaging'],
          );

          final url =
              'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

          final messagePayload = <String, dynamic>{
            'notification': {
              'title': title,
              'body': body,
            },
            'android': {
              'priority': 'HIGH',
              'notification': {
                'channel_id': 'broadcast_channel',
                'sound': 'default',
                'default_vibrate_timings': true,
                'notification_priority': 'PRIORITY_MAX',
                'visibility': 'PUBLIC',
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound': 'default',
                  'content-available': 1,
                },
              },
            },
            'data': data?.map((k, v) => MapEntry(k, v.toString())) ?? {},
          };

          if (token != null && token.isNotEmpty) {
            messagePayload['token'] = token;
          } else if (topic != null && topic.isNotEmpty) {
            messagePayload['topic'] = topic;
          }

          final response = await client.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': messagePayload}),
          );

          client.close();
          debugPrint('🔔 [FCM v1 Response]: ${response.statusCode} - ${response.body}');
          if (response.statusCode == 200) {
            return true;
          }
        }
      } catch (v1Err) {
        debugPrint('🔔 FCM v1 dispatch error: $v1Err');
      }

      // 2. Try FCM Legacy Server Key if present
      try {
        final configSnap =
            await db.ref(DatabaseKeys.appConfig).child('fcm_server_key').get();
        if (configSnap.exists && configSnap.value != null) {
          final serverKey = configSnap.value.toString().trim();
          if (serverKey.isNotEmpty) {
            final target = token != null && token.isNotEmpty ? token : '/topics/$topic';
            final response = await http.post(
              Uri.parse('https://fcm.googleapis.com/fcm/send'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'key=$serverKey',
              },
              body: jsonEncode({
                'to': target,
                'priority': 'high',
                'notification': {
                  'title': title,
                  'body': body,
                  'sound': 'default',
                  'channel_id': 'broadcast_channel',
                  'android_channel_id': 'broadcast_channel',
                },
                'data': data ?? {},
              }),
            );
            debugPrint('🔔 [FCM Legacy Response]: ${response.statusCode} - ${response.body}');
            return response.statusCode == 200;
          }
        }
      } catch (legacyErr) {
        debugPrint('🔔 FCM Legacy dispatch error: $legacyErr');
      }

      return true;
    } catch (e) {
      debugPrint('🔔 Error in _dispatchFcmMessage: $e');
      return false;
    }
  }
}
