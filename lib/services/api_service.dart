import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // 👈 1. ضفنا هالمكتبة المهمة جداً

class ApiService {

  // ==========================================
  // 🌟 تعديل الرابط ليكون ديناميكي وذكي
  // ==========================================
  String get baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:8000/api";
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return "http://localhost:8000/api";
    } else {
      return "http://127.0.0.1:8000/api";
    }
  }

  // تصليح روابط الميديا الراجعة من السيرفر (127.0.0.1 → localhost على الأندرويد)
  static String? fixMediaUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return url.replaceFirst('http://127.0.0.1:', 'http://localhost:');
    }
    return url;
  }

  final Dio _dio = Dio();

  // ==========================================
  // 1. دالة تسجيل الدخول
  // ==========================================
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      _dio.options.headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      Response response = await _dio.post(
        "$baseUrl/login",
        data: {
          "username": username,
          "password": password,
        },
      );

      if (response.statusCode == 200) {
        String token = response.data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        if (response.data['user'] != null) {
          await prefs.setString('role', response.data['user']['role']);
        }
        return response.data;
      }
    } on DioException catch (e) {
      debugPrint("Login Error: ${e.response?.data['message'] ?? 'فشل الاتصال'}");
      return null;
    }
    return null;
  }

  // ==========================================
  // 2. دالة جلب بيانات الطالب للداشبورد
  // ==========================================
  Future<Map<String, dynamic>?> getStudentDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      Response response = await _dio.get(
        "$baseUrl/student/dashboard",
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint("Dashboard Error: $e");
    }
    return null;
  }
}
