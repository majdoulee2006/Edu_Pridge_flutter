import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentService {
  final Dio _dio = Dio();

  // الرابط اللي اتفقنا عليه للـ Web/Edge
  final String baseUrl = ApiService().baseUrl;

  // 1️⃣ دالة جلب الأبناء (لعرضهم في الصفحة الرئيسية)
  Future<List<dynamic>> getChildren() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String token = prefs.getString('token') ?? '';
      final String parentId = prefs.getString('parent_id') ?? '';

      if (token.isEmpty || parentId.isEmpty) return [];

      final response = await _dio.get(
        "$baseUrl/parent/children/$parentId",
        options: Options(headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );

      if (response.statusCode == 200) {
        // Laravel returns ['success' => true, 'data' => [...]]
        if (response.data is Map && response.data['data'] != null) {
          return response.data['data'] as List<dynamic>? ?? [];
        }
        return response.data as List<dynamic>? ?? [];
      }
    } catch (e) {
      debugPrint("خطأ في جلب الأبناء: $e");
    }
    return [];
  }

  // 2️⃣ دالة ربط ابن جديد (عن طريق الكود)
  Future<bool> addChildByCode(String studentCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String token = prefs.getString('token') ?? '';
      final String userId = prefs.getString('user_id') ?? '';

      if (token.isEmpty || userId.isEmpty) return false;

      final response = await _dio.post(
        "$baseUrl/parent/link-student",
        data: {
          "student_code": studentCode,
          "user_id": userId,
        },
        options: Options(headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );

      if (response.statusCode == 200) {
        return true; // تم الربط بنجاح
      }
    } catch (e) {
      debugPrint("خطأ في ربط الابن: $e");
    }
    return false;
  }
}