import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // الرابط الأساسي للـ Laravel (عدليه حسب نوع المحاكي)
  final String baseUrl = "http://10.0.2.2:8000/api";
  final Dio _dio = Dio();

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      Response response = await _dio.post(
        "$baseUrl/login",
        data: {
          "email": email,
          "password": password,
        },
      );

      if (response.statusCode == 200) {
        // حفظ التوكن في ذاكرة الموبايل
        String token = response.data['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        return response.data; // برجع البيانات كاملة (توكن، يوزر، رول)
      }
    } on DioException catch (e) {
      print("Error: ${e.response?.data['message'] ?? 'حدث خطأ ما'}");
      return null;
    }
    return null;
  }
}