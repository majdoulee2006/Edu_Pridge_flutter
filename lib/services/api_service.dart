import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // 👈 1. ضفنا هالمكتبة المهمة جداً

class ApiService {

  // ==========================================
  // 🌟 تعديل الرابط ليكون ديناميكي وذكي
  // ==========================================
  static const String _serverIp = '10.205.200.209';

  String get baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:8000/api";
    } else {
      return "http://$_serverIp:8000/api";
    }
  }

  // تصليح روابط الميديا الراجعة من السيرفرياحبيبي
  static String? fixMediaUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (!kIsWeb) {
      return url
          .replaceFirst('http://127.0.0.1:', 'http://$_serverIp:')
          .replaceFirst('http://localhost:', 'http://$_serverIp:');
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
          await prefs.setInt('user_id', response.data['user']['user_id']);
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
