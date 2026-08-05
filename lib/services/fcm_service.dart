import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'package:edu_pridge_flutter/widgets/in_app_notification_banner.dart';
import 'package:edu_pridge_flutter/main.dart' show appNavigatorKey;
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/schedule/schedule_screen.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/assignments/assignments_screen.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/attendance/attendance_screen.dart';

// Handler لإشعارات الخلفية (يجب أن يكون top-level function)
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background FCM: ${message.notification?.title}');
}

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // VAPID key من Firebase Console → Project Settings → Cloud Messaging → Web Push certificates
  static const String _vapidKey = "BPYnQg1rycEHNqFlogeie2VW-AfHoxmUkriiP649VN9aTE4l2rb1dmgbcYuXAXtkYZwwZOYch7YsusLihZfjIQg";

  static void handleNotificationData(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final relatedIdStr = data['related_id']?.toString() ??
        data['lecture_id']?.toString() ??
        data['event_id']?.toString();
    final intId = int.tryParse(relatedIdStr ?? '');

    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;

    switch (type) {
      case 'lecture':
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => const ScheduleScreen(),
          ),
        );
        break;
      case 'assignment':
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => AssignmentsScreen(highlightId: intId),
          ),
        );
        break;
      case 'attendance':
        Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const AttendanceScreen()),
        );
        break;
      default:
        break;
    }
  }

  static Future<void> initWeb() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('⛔ Web FCM permission denied');
        return;
      }
      await _refreshAndSendToken(vapidKey: _vapidKey);
      _messaging.onTokenRefresh.listen(_sendTokenToServer);
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (!AppSettings.isNotificationsEnabled.value) return;
        debugPrint('🔔 Web Foreground FCM: ${message.notification?.title}');
        final title = message.notification?.title ?? message.data['title'] ?? '';
        final body  = message.notification?.body  ?? message.data['body']  ?? '';
        if (title.isNotEmpty || body.isNotEmpty) {
          final ctx = appNavigatorKey.currentContext;
          if (ctx != null) {
            showInAppBanner(
              ctx,
              title,
              body,
              onTap: () => handleNotificationData(message.data),
            );
          }
        }
      });
      debugPrint('✅ Web FCM initialized');
    } catch (e) {
      debugPrint('⛔ Web FCM init error: $e');
    }
  }

  static Future<void> init() async {
    // طلب الصلاحية
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // الاستماع لإشعارات الخلفية
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // جلب الـ token وإرساله للسيرفر
    await _refreshAndSendToken();

    // إذا تجدّد الـ token
    _messaging.onTokenRefresh.listen(_sendTokenToServer);

    // عند ضغط الإشعار والتطبيق في الخلفية
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 FCM Opened App: ${message.data}');
      handleNotificationData(message.data);
    });

    // عند فتح التطبيق من الإشعار وهو مغلق تماماً
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🔔 FCM Initial Message: ${message.data}');
        handleNotificationData(message.data);
      }
    });

    // إشعار وقت التطبيق مفتوح (foreground) — عرض بانر حقيقي
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!AppSettings.isNotificationsEnabled.value) return;
      debugPrint('🔔 Foreground FCM: ${message.notification?.title}');
      final title = message.notification?.title ?? message.data['title'] ?? '';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      if (title.isNotEmpty || body.isNotEmpty) {
        final ctx = appNavigatorKey.currentContext;
        if (ctx != null) {
          showInAppBanner(
            ctx,
            title,
            body,
            onTap: () => handleNotificationData(message.data),
          );
        }
      }
    });
  }

  static Future<void> _refreshAndSendToken({String? vapidKey}) async {
    try {
      final token = await _messaging.getToken(vapidKey: vapidKey);
      if (token != null) await _sendTokenToServer(token);
    } catch (e) {
      debugPrint('⛔ FCM token error: $e');
    }
  }

  static Future<void> _sendTokenToServer(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token') ?? '';
      if (authToken.isEmpty) return;

      // تجنب إرسال نفس الـ token مرتين
      final lastSent = prefs.getString('fcm_token_sent') ?? '';
      if (lastSent == token) return;

      await Dio().post(
        '${ApiService().baseUrl}/user/fcm-token',
        data: {'fcm_token': token},
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );
      await prefs.setString('fcm_token_sent', token);
      debugPrint('✅ FCM token sent to server');
    } catch (e) {
      debugPrint('⛔ FCM token send error: $e');
    }
  }

  // يُستدعى بعد تسجيل الدخول مباشرة لضمان وصول الـ token للسيرفر
  static Future<void> sendTokenAfterLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token_sent');
      await _refreshAndSendToken(vapidKey: kIsWeb ? _vapidKey : null);
    } catch (e) {
      debugPrint('⛔ sendTokenAfterLogin error: $e');
    }
  }

  static Future<void> deleteToken() async {
    await _messaging.deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_token_sent');
  }
}
