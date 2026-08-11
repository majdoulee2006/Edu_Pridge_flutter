import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'package:edu_pridge_flutter/widgets/in_app_notification_banner.dart';
import 'package:edu_pridge_flutter/main.dart' show appNavigatorKey;
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/lectures/lectures_screen.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/assignments/assignments_screen.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/attendance/attendance_screen.dart';

import 'package:edu_pridge_flutter/screens/Head%20of%20department/center_icons/appointments/hod_appointments_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/center_icons/appointments/affairs_appointments_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/center_icons/appointments_screen/appointments_screen.dart';

// Handler لإشعارات الخلفية (يجب أن يكون top-level function)
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background FCM: ${message.notification?.title}');
}

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // VAPID key من Firebase Console → Project Settings → Cloud Messaging → Web Push certificates
  static const String _vapidKey = "BPYnQg1rycEHNqFlogeie2VW-AfHoxmUkriiP649VN9aTE4l2rb1dmgbcYuXAXtkYZwwZOYch7YsusLihZfjIQg";

  static Future<void> handleNotificationData(Map<String, dynamic> data) async {
    final type = data['type']?.toString();
    final relatedIdStr = data['related_id']?.toString() ??
        data['lecture_id']?.toString() ??
        data['event_id']?.toString();
    final intId = int.tryParse(relatedIdStr ?? '');

    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;

    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('user_role') ?? '';
    final token = prefs.getString('token') ?? '';

    // إرسال طلب للباك إند لتمييز الإشعار كمقروء عند فتحه من الخارج
    if (token.isNotEmpty && type != null) {
      try {
        await Dio().put(
          '${ApiService().baseUrl}/notifications/read-by-type',
          data: {
            'type': type,
            if (intId != null) 'related_id': intId,
          },
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } catch (e) {
        debugPrint('⛔ markByTypeAndRelatedId error: $e');
      }
    }

    switch (type) {
      case 'meeting_request':
      case 'summon':
        if (userRole == 'head' || userRole == 'department_head') {
          Navigator.push(ctx, MaterialPageRoute(builder: (_) => const HodAppointmentsScreen()));
        } else if (userRole == 'affairs') {
          Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AffairsAppointmentsScreen()));
        } else if (userRole == 'parent') {
          Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AppointmentsScreen()));
        }
        break;
      case 'lecture':
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => LecturesScreen(highlightLessonId: intId),
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

      final userId = prefs.getString('user_id') ?? prefs.getInt('user_id')?.toString() ?? 'guest';
      final key = 'fcm_token_sent_$userId';
      final lastSent = prefs.getString(key) ?? '';
      if (lastSent == token) return;

      await Dio().post(
        '${ApiService().baseUrl}/user/fcm-token',
        data: {'fcm_token': token},
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );
      await prefs.setString(key, token);
      debugPrint('✅ FCM token sent to server for user $userId');
    } catch (e) {
      debugPrint('⛔ FCM token send error: $e');
    }
  }

  // يُستدعى بعد تسجيل الدخول مباشرة لضمان وصول الـ token للسيرفر
  static Future<void> sendTokenAfterLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? prefs.getInt('user_id')?.toString() ?? 'guest';
      await prefs.remove('fcm_token_sent_$userId');
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
