import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // الرابط الأساسي (10.0.2.2 للمحاكي)
  final String baseUrl = "http://10.119.244.82:8000/api";
  final Dio _dio = Dio();

  // 🌟 تعديل: استقبال username بدلاً من email
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      // إعداد الهيدرز لضمان استلام استجابة JSON واضحة من Laravel
      _dio.options.headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      Response response = await _dio.post(
        "$baseUrl/login",
        data: {
          "username": username, // 👈 التعديل هنا (ارسال الرقم الجامعي أو الهاتف)
          "password": password,
        },
      );

      if (response.statusCode == 200) {
        // حفظ التوكن في ذاكرة الموبايل (مهم جداً للعمليات اللاحقة)
        String token = response.data['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        // حفظ دور المستخدم (طالب أم أب) لنعرف لأي صفحة سنوجهه
        if (response.data['user'] != null) {
          await prefs.setString('role', response.data['user']['role']);
        }

        return response.data;
      }
    } on DioException catch (e) {
      // طباعة الخطأ القادم من السيرفر (مثلاً: كلمة المرور خاطئة)
      print("Login Error: ${e.response?.data['message'] ?? 'فشل الاتصال بالسيرفر'}");
      return null;
    }
    return null;
  }
}