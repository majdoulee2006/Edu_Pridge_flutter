import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

class StudentServices {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );

  // ==========================================
  // 1. جلب بيانات الرئيسية (الداشبورد) للطالب
  // ==========================================
  Future<Map<String, dynamic>?> getDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception("لا يوجد توكن، يرجى تسجيل الدخول");
      }

      Response response = await _dio.get(
        "${ApiService().baseUrl}/student/dashboard",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // 🌟 انتبهي: استخدمنا status بدال success لأن الباك إند تبعنا هيك مبرمج
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ Student Dashboard Error: $e");
      rethrow;
    }
    return null;
  }

  // ==========================================
  // 2. جلب بيانات الملف الشخصي
  // ==========================================
  Future<Map<String, dynamic>?> getProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      Response response = await _dio.get(
        "${ApiService().baseUrl}/student/profile",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ Profile Fetch Error: $e");
      rethrow;
    }
    return null;
  }

  // ==========================================
  // 3. تحديث صورة الملف الشخصي
  // ==========================================
  Future<bool> updateProfileImage(List<int> imageBytes, String fileName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // تجهيز الصورة كـ FormData لرفعها للسيرفر
      FormData formData = FormData.fromMap({
        'avatar': MultipartFile.fromBytes(imageBytes, filename: fileName),
      });

      // ملاحظة: تأكدي إنو الرابط هون بيطابق الرابط اللي بملف api.php باللارافل
      Response response = await _dio.post(
        "${ApiService().baseUrl}/student/profile/update",
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return true;
      }
    } catch (e) {
      debugPrint("❌ Profile Update Error: $e");
      rethrow;
    }
    return false;
  }

  // ==========================================
  // 4. جلب الإشعارات (أكاديمي + إداري)
  // ==========================================
  Future<Map<String, dynamic>?> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      Response response = await _dio.get(
        "${ApiService().baseUrl}/student/notifications",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ Notifications Fetch Error: $e");
      rethrow;
    }
    return null;
  }

  // ==========================================
  // 5. تحديد الإشعار كمقروء (Mark as read)
  // ==========================================
  Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      Response response = await _dio.put(
        "${ApiService().baseUrl}/student/notifications/$notificationId/read",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return true;
      }
    } catch (e) {
      debugPrint("❌ Mark Notification Read Error: $e");
    }
    return false;
  }

  // ==========================================
  // 6. جلب جدول الحصص
  // ==========================================
  Future<List<dynamic>?> getSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      Response response = await _dio.get(
        "${ApiService().baseUrl}/student/my-schedule",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ Schedules Fetch Error: $e");
    }
    return null;
  }

  // ==========================================
  // 7. جلب جدول الامتحانات
  // ==========================================
  Future<List<dynamic>?> getExams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      Response response = await _dio.get(
        "${ApiService().baseUrl}/student/my-exams",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ Exams Fetch Error: $e");
    }
    return null;
  }

  // ==========================================
  // 8. تصدير جدول الامتحانات (PDF / Excel)
  // ==========================================
  Future<String?> getExportUrl(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      Response response = await _dio.get(
        "${ApiService().baseUrl}/student/my-exams/$type",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        // فحص إذا كان الرابط بداخل مصفوفة data أو بالخارج مباشرة
        var data = response.data['data'] ?? response.data;
        return type == 'pdf' ? data['pdf_url'] : data['excel_url'];
      }
    } catch (e) {
      debugPrint("❌ Export $type Error: $e");
    }
    return null;
  }

  // ==========================================
  // 9. جلب قائمة المحاضرات والملفات
  // ==========================================
  Future<List<dynamic>?> getLectures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      Response response = await _dio.get(
        "${ApiService().baseUrl}/student/lectures",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ Lectures Fetch Error: $e");
    }
    return null;
  }

  // ==========================================
  // 10. جلب سجل الحضور والغياب
  // ==========================================
  Future<List<dynamic>?> getAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      Response response = await _dio.get(
        "${ApiService().baseUrl}/student/attendance",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ Attendance Fetch Error: $e");
    }
    return null;
  }

  // ==========================================
  // 11. جلب الواجبات والمشاريع
  // ==========================================
  Future<List<dynamic>?> getAssignments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      Response response = await _dio.get(
        "${ApiService().baseUrl}/student/assignments",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ Assignments Fetch Error: $e");
    }
    return null;
  }

  // ==========================================
  // 12. تسليم الواجب
  // ==========================================
  Future<bool> submitAssignment(
    int assignmentId,
    List<int> fileBytes,
    String fileName,
    String notes,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
        if (notes.isNotEmpty) 'notes': notes,
      });

      Response response = await _dio.post(
        "${ApiService().baseUrl}/student/assignments/$assignmentId/submit",
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return true;
      }
    } catch (e) {
      debugPrint("❌ Submit Assignment Error: $e");
      rethrow;
    }
    return false;
  }

  // ==========================================
  // 13. تقديم عذر غياب
  // ==========================================
  Future<bool> submitAttendanceExcuse(int attendanceId, String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      Response response = await _dio.post(
        "${ApiService().baseUrl}/student/attendance/$attendanceId/excuse",
        data: {'reason': reason},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return true;
      }
    } catch (e) {
      debugPrint("❌ Attendance Excuse Error: $e");
      rethrow;
    }
    return false;
  }

  // ==========================================
  // 14. طلب إجازة
  // ==========================================
  Future<bool> submitLeaveRequest(String type, String date, String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      Response response = await _dio.post(
        "${ApiService().baseUrl}/student/leave-requests",
        data: {'type': type, 'date': date, 'reason': reason},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return true;
      }
    } catch (e) {
      debugPrint("❌ Leave Request Error: $e");
      rethrow;
    }
    return false;
  }

  // ==========================================
  // 15. جلب العلامات
  // ==========================================
  Future<List<dynamic>?> getGrades() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      Response response = await _dio.get(
        "${ApiService().baseUrl}/student/grades",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ Grades Fetch Error: $e");
    }
    return null;
  }
}


