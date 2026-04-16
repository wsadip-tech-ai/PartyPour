import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are automatically displayed by FCM on Android.
  // This handler is required but can be empty for basic notification display.
}

class PushNotificationService {
  final SupabaseClient _supabase;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  PushNotificationService(this._supabase);

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permission (Android 13+ requires runtime permission)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[PushNotification] Permission denied');
        return;
      }
      debugPrint('[PushNotification] Permission: ${settings.authorizationStatus}');

      // Initialize local notifications for foreground display
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      await _localNotifications.initialize(
        const InitializationSettings(android: androidSettings),
      );

      // Create notification channel for Android
      if (Platform.isAndroid) {
        const channel = AndroidNotificationChannel(
          'partypour_notifications',
          'PartyPour Notifications',
          description: 'Notifications from PartyPour',
          importance: Importance.high,
        );
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);

      // Register device token
      await _registerToken();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _saveToken(newToken);
      });

      _initialized = true;
      debugPrint('[PushNotification] Initialized successfully');
    } catch (e) {
      debugPrint('[PushNotification] Init error: $e');
    }
  }

  Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('[PushNotification] FCM token: ${token?.substring(0, 20)}...');
      if (token != null) {
        await _saveToken(token);
      } else {
        debugPrint('[PushNotification] FCM token is null');
      }
    } catch (e) {
      debugPrint('[PushNotification] Token registration error: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('[PushNotification] No user ID, skipping token save');
      return;
    }

    try {
      await _supabase.from('device_tokens').upsert(
        {'user_id': userId, 'token': token},
        onConflict: 'token',
      );
      debugPrint('[PushNotification] Token saved for user $userId');
    } catch (e) {
      debugPrint('[PushNotification] Token save error: $e');
    }
  }

  Future<void> removeToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;

    await _supabase.from('device_tokens').delete().eq('token', token);
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'partypour_notifications',
          'PartyPour Notifications',
          channelDescription: 'Notifications from PartyPour',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
