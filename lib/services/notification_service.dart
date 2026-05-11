import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Top-level handler for background messages (required by FCM)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by this point on isolate
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static String? pendingReportId;
  static String? pendingNavigation;
  // Add this public method inside NotificationService class
  Future<void> saveToken() async {
    await _saveTokenToSupabase();
  }
  // ── Initialize everything ─────────────────────────────────────────────────
  Future<void> initialize() async {
    // Register background handler FIRST
    debugPrint('🔔 NotificationService.initialize() called');
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (iOS shows dialog; Android 13+ also needs this)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return; // User declined — respect that
    }

    // Set up local notifications (needed to show heads-up on Android
    // when the app is in the foreground)
    await _setupLocalNotifications();

    // Get token and save to Supabase
    await _saveTokenToSupabase();

    await _messaging.subscribeToTopic('resq_news');
    debugPrint('✅ Subscribed to resq_news topic');

    // Optional: subscribe to emergency alerts specifically
    await _messaging.subscribeToTopic('resq_emergency');
    debugPrint('✅ Subscribed to resq_emergency topic');

    // Listen for token refreshes (tokens can rotate)
    _messaging.onTokenRefresh.listen(_updateTokenInSupabase);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Tap handler when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was launched from a notification (terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
    debugPrint('🔔 NotificationService.initialize() completed');
  }

  // ── Local notifications setup ─────────────────────────────────────────────
  Future<void> _setupLocalNotifications() async {
  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  await _localNotifications.initialize(
    const InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    ),
    onDidReceiveNotificationResponse: (details) {
      debugPrint('Local notification tapped: ${details.payload}');
      if (details.payload != null) {
        NotificationService.pendingReportId = details.payload;
      }
    },
  );

  // iOS only — show notification even when app is foregrounded
  await _messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}

  // ── Token management ──────────────────────────────────────────────────────
  Future<void> _saveTokenToSupabase() async {
    try {
      final token = await _messaging.getToken();

      debugPrint('================================================');
      debugPrint('FCM TOKEN: $token');
      debugPrint('================================================');
    
      if (token == null) {
        debugPrint('Token is null - device may not support FCM');
        return;
      }

      debugPrint('FCM token: $token');

      final userId =
          Supabase.instance.client.auth.currentSession?.user.id;
      if (userId == null) return; // Guest or not logged in

      await Supabase.instance.client.from('users').update({
        'fcm_token': token,
        'fcm_updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      debugPrint('Token saved to Supabase successfully');
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  Future<void> _updateTokenInSupabase(String token) async {
    try {
      final userId =
          Supabase.instance.client.auth.currentSession?.user.id;
      if (userId == null) return;

      await Supabase.instance.client.from('users').update({
        'fcm_token': token,
        'fcm_updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Failed to update FCM token: $e');
    }
  }

  // Call this on logout to avoid sending notifications to signed-out devices
  Future<void> clearTokenOnLogout() async {
    try {
      final userId =
          Supabase.instance.client.auth.currentSession?.user.id;
      if (userId == null) return;

      await Supabase.instance.client.from('users').update({
        'fcm_token': null,
        'fcm_updated_at': null,
      }).eq('id', userId);

      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('Failed to clear FCM token: $e');
    }
  }

  // ── Message handlers ──────────────────────────────────────────────────────
  void _handleForegroundMessage(RemoteMessage message) {
  debugPrint('Foreground message: ${message.notification?.title}');

  final notification = message.notification;
  if (notification == null) return;

  _localNotifications.show(
    notification.hashCode,
    notification.title,
    notification.body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'resq_alerts',              // channel id string directly
        'ResQ Emergency Alerts',    // channel name string directly
        channelDescription: 'Critical emergency notifications from ResQ',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: message.data['report_id'],
  );
}

  void _handleNotificationTap(RemoteMessage message) {
  debugPrint('Notification tapped: ${message.data}');

  final type = message.data['type'];

  if (type == 'news') {
    // Navigate to news tab
    NotificationService.pendingNavigation = 'news';
  } else {
    // Navigate to map/report
    final reportId = message.data['report_id'];
    if (reportId != null) {
      NotificationService.pendingReportId = reportId;
      NotificationService.pendingNavigation = 'report';
    }
  }
}

  // Simple pending navigation state (navigator key approach is cleaner
  // for large apps, but this works fine for your current structure)
}