import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // 👈 1. ضفنا هالمكتبة المهمة جداً

class ApiService {

  // ==========================================
  // 🌟 تعديل الرابط ليكون ديناميكي وذكي
  // ==========================================
  String get baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:8000/api"; // إذا فتحتيه على متصفح (كروم أو إيدج)
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:8000/api"; // إذا فتحتيه على محاكي أندرويد
    } else {
      return "http://127.0.0.1:8000/api"; // للآيفون أو أنظمة تانية
    }
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
        String token = response.data['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        if (response.data['user'] != null) {
          await prefs.setString('role', response.data['user']['role']);
        }
        return response.data;
      }
    } on DioException catch (e) {
      print("Login Error: ${e.response?.data['message'] ?? 'فشل الاتصال'}");
      return null;
    }
    return null;
  }

  // ==========================================
  // 2. دالة جلب بيانات الطالب للداشبورد 🌟
  // ==========================================
  Future<Map<String, dynamic>?> getStudentDashboard() async {

    // 🔑 توكن إسراء (للتجربة المباشرة للواجهات)
    String token = "1|Pap3d36328M9Hr4HaGflWD1VioZn1fF90no68oAf97ec3d30";

    try {
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
      print("Dashboard Error: $e");
    }
    return null;
  }
}