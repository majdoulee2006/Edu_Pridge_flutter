import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentService {
  final Dio _dio = Dio();

  // الرابط اللي اتفقنا عليه للـ Web/Edge
  final String baseUrl = "http://127.0.0.1:8000/api";

  // 1️⃣ دالة جلب الأبناء (لعرضهم في الصفحة الرئيسية)
  Future<List<dynamic>> getChildren() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('user_id'); // بنجيب المعرف اللي حفظناه باللوج إن

      if (userId == null) return [];

      // نستخدم رابط الـ test اللي بعتيه في الـ api.php لأنه أضمن حالياً
      final response = await _dio.get("$baseUrl/test-parent-children/$userId");

      if (response.statusCode == 200) {
        return response.data; // قائمة الأبناء
      }
    } catch (e) {
      print("خطأ في جلب الأبناء: $e");
    }
    return [];
  }

  // 2️⃣ دالة ربط ابن جديد (عن طريق الكود)
  Future<bool> addChildByCode(String studentCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('user_id');

      if (userId == null) return false;

      final response = await _dio.post(
        "$baseUrl/parent/link-student",
        data: {
          "student_code": studentCode,
          "user_id": userId,
        },
      );

      if (response.statusCode == 200) {
        return true; // تم الربط بنجاح
      }
    } catch (e) {
      print("خطأ في ربط الابن: $e");
    }
    return false;
  }
}