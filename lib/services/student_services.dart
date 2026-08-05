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
  // X. جلب المواد الدراسية الخاصة بالطالب
  // ==========================================
  Future<List<dynamic>?> getCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      Response response = await _dio.get(
        "${ApiService().baseUrl}/student/courses",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        var data = response.data['data'];
        if (data != null && data is List && data.isEmpty) {
          return [
            {'title': 'مبادئ البرمجة (مادة وهمية)'},
            {'title': 'هياكل البيانات (مادة وهمية)'},
            {'title': 'الرياضيات المتقدمة (مادة وهمية)'},
          ];
        }
        return data;
      }
    } catch (e) {
      debugPrint("❌ Courses Fetch Error: $e");
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

  Future<bool> markAllNotificationsAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      Response response = await _dio.put(
        "${ApiService().baseUrl}/student/notifications/read-all",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) return true;
    } catch (e) {
      debugPrint("❌ Mark All Notifications Read Error: $e");
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
    if (type != 'pdf') {
      debugPrint("❌ Export type $type is decommissioned.");
      return null;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      Response response = await _dio.get(
        "${ApiService().baseUrl}/student/my-exams/pdf",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        if (response.data != null) {
          if (response.data['pdf_url'] != null) {
            return response.data['pdf_url'];
          }
          var data = response.data['data'];
          if (data is Map) {
            return data['pdf_url'];
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Export PDF Error: $e");
    }
    return null;
  }

  Future<String?> getScheduleExportUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      Response response = await _dio.get(
        "${ApiService().baseUrl}/student/my-schedule/pdf",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        if (response.data != null) {
          if (response.data['pdf_url'] != null) {
            return response.data['pdf_url'];
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Export Schedule PDF Error: $e");
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
    String? filePath,
    String? fileName,
    String notes,
    String solutionText,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final Map<String, dynamic> dataMap = {};
      if (filePath != null && fileName != null && filePath.isNotEmpty) {
        dataMap['file'] = await MultipartFile.fromFile(filePath, filename: fileName);
      }
      if (notes.isNotEmpty) {
        dataMap['student_notes'] = notes;
      }
      if (solutionText.isNotEmpty) {
        dataMap['solution_text'] = solutionText;
      }

      final formData = FormData.fromMap(dataMap);

      Response response = await _dio.post(
        "${ApiService().baseUrl}/student/assignments/$assignmentId/submit",
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return true;
      }
    } catch (e) {
      debugPrint("❌ Submit Assignment Error TYPE: ${e.runtimeType}");
      debugPrint("❌ Submit Assignment Error: $e");
      if (e is DioException) {
        debugPrint("❌ DioException status: ${e.response?.statusCode}");
        debugPrint("❌ DioException data: ${e.response?.data}");
        debugPrint("❌ DioException message: ${e.message}");
      }
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
        data: {'excuse_text': reason},
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
  Future<bool> submitLeaveRequest(String type, String date, String reason, {String? filePath, String? fileName}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      dynamic postData;
      if (filePath != null && filePath.isNotEmpty) {
        postData = FormData.fromMap({
          'type': type,
          'date': date,
          'reason': reason,
          'document': await MultipartFile.fromFile(filePath, filename: fileName ?? 'leave_doc.pdf'),
        });
      } else {
        postData = {'type': type, 'date': date, 'reason': reason};
      }

      Response response = await _dio.post(
        "${ApiService().baseUrl}/student/leave-requests",
        data: postData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return true;
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("❌ Leave Request Error ${e.response?.statusCode}: ${e.response?.data}");
      } else {
        debugPrint("❌ Leave Request Error: $e");
      }
      rethrow;
    }
    return false;
  }

  Future<List<dynamic>> getMyLeaveRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await _dio.get(
        "${ApiService().baseUrl}/student/leave-requests",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] ?? [];
      }
    } catch (e) {
      debugPrint("❌ Get Leave Requests Error: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>?> getLeaveDetails(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await _dio.get(
        "${ApiService().baseUrl}/student/leave-requests/$id",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ Get Leave Details Error: $e");
    }
    return null;
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

  // ==========================================
  // 16. جلب بطاقة الطالب الكشف الأكاديمي الشامل
  // ==========================================
  Future<Map<String, dynamic>?> getAcademicCard(String? universityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      Response response = await _dio.get(
        "${ApiService().baseUrl}/student/academic-card",
        queryParameters: universityId != null && universityId.trim().isNotEmpty ? {'university_id': universityId.trim()} : null,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint("❌ Academic Card Fetch Error: $e");
    }
    return null;
  }
}


