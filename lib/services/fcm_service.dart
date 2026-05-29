import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

// Handler لإشعارات الخلفية (يجب أن يكون top-level function)
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background FCM: ${message.notification?.title}');
}

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

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

    // إشعار وقت التطبيق مفتوح (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 Foreground FCM: ${message.notification?.title}');
    });
  }

  static Future<void> _refreshAndSendToken() async {
    try {
      final token = await _messaging.getToken();
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

  static Future<void> deleteToken() async {
    await _messaging.deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_token_sent');
  }
}
