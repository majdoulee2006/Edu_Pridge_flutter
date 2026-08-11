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

  // 3️⃣ طلب موعد جديد من الإدارة أو رئيس القسم
  Future<bool> requestMeeting({
    required String subject,
    required String reason,
    int? studentId,
    String? preferredDate,
    String targetPerson = 'hod', // 'hod' = رئيس القسم, 'admin' = الإدارة
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String token = prefs.getString('token') ?? '';
      if (token.isEmpty) return false;

      final response = await _dio.post(
        "$baseUrl/parent/request-meeting",
        data: {
          "subject": subject,
          "reason": reason,
          "student_id": studentId,
          "preferred_date": preferredDate,
          "target_person": targetPerson,
        },
        options: Options(headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['success'] == true;
      }
    } catch (e) {
      debugPrint("❌ Error requesting meeting: $e");
    }
    return false;
  }

  // 4️⃣ جلب المواعيد المطلوبة من الأهل
  Future<List<dynamic>> getMyMeetingRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String token = prefs.getString('token') ?? '';
      if (token.isEmpty) return [];

      final response = await _dio.get(
        "$baseUrl/parent/meeting-requests",
        options: Options(headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as List<dynamic>? ?? [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching meeting requests: $e");
    }
    return [];
  }

  // 5️⃣ جلب الاستدعاءات الصادرة للأهالي من الإدارة
  Future<List<dynamic>> getMySummons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String token = prefs.getString('token') ?? '';
      if (token.isEmpty) return [];

      final response = await _dio.get(
        "$baseUrl/parent/summons",
        options: Options(headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as List<dynamic>? ?? [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching summons: $e");
    }
    return [];
  }

  // 6️⃣ الرد على استدعاء الإدارة
  Future<bool> respondToSummon(int summonId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String token = prefs.getString('token') ?? '';
      if (token.isEmpty) return false;

      final response = await _dio.post(
        "$baseUrl/parent/summons/$summonId/respond",
        data: {
          "status": status,
        },
        options: Options(headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );

      if (response.statusCode == 200) {
        return response.data['success'] == true;
      }
    } catch (e) {
      debugPrint("❌ Error responding to summon: $e");
    }
    return false;
  }

  // 7️⃣ كشف علامات الطفل الأكاديمي
  Future<Map<String, dynamic>?> getChildAcademicCard(int childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String token = prefs.getString('token') ?? '';
      if (token.isEmpty) return null;

      final response = await _dio.get(
        "$baseUrl/parent/children/$childId/academic-card",
        options: Options(headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint("❌ Error fetching child academic card: $e");
    }
    return null;
  }

  // 8️⃣ تصدير كشف علامات الطفل PDF
  Future<Map<String, dynamic>?> exportChildAcademicCardPdf(int childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String token = prefs.getString('token') ?? '';
      if (token.isEmpty) return null;

      final response = await _dio.get(
        "$baseUrl/parent/children/$childId/academic-card/export-pdf",
        options: Options(headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint("❌ Error exporting child academic card PDF: $e");
    }
    return null;
  }

  // 9️⃣ تصدير كشف علامات الطفل Excel
  Future<Map<String, dynamic>?> exportChildAcademicCardExcel(int childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String token = prefs.getString('token') ?? '';
      if (token.isEmpty) return null;

      final response = await _dio.get(
        "$baseUrl/parent/children/$childId/academic-card/export-excel",
        options: Options(headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint("❌ Error exporting child academic card Excel: $e");
    }
    return null;
  }
}