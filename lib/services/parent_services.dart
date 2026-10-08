import 'dart:io';

import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/services/session_guard.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentService {
  final Dio _dio = Dio()..interceptors.add(SingleSessionInterceptor());

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

  // 2️⃣.5️⃣ دالة إزالة/فك ربط ابن
  Future<bool> unlinkChild(int studentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String token = prefs.getString('token') ?? '';

      if (token.isEmpty) return false;

      final response = await _dio.post(
        "$baseUrl/parent/children/$studentId/unlink",
        options: Options(headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );

      if (response.statusCode == 200) {
        return response.data['success'] == true;
      }
    } catch (e) {
      debugPrint("خطأ في فك ربط الابن: $e");
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

  // 🔟 الملخص الأسبوعي: قائمة الملخصات (مع عدد غير المقروء)
  Future<Map<String, dynamic>?> getDigests({int? studentId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String token = prefs.getString('token') ?? '';
      if (token.isEmpty) return null;

      final response = await _dio.get(
        "$baseUrl/parent/digests",
        queryParameters: {'student_id': ?studentId},
        options: Options(headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (e) {
      debugPrint("❌ Error fetching digests: $e");
    }
    return null;
  }

  // تعليم ملخص كمقروء
  Future<bool> markDigestRead(int digestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String token = prefs.getString('token') ?? '';
      if (token.isEmpty) return false;

      final response = await _dio.put(
        "$baseUrl/parent/digests/$digestId/read",
        options: Options(headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ Error marking digest read: $e");
    }
    return false;
  }

  // هل الملخص الأسبوعي مفعّل لهذا الحساب؟ (null عند الفشل)
  Future<bool?> getDigestEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String token = prefs.getString('token') ?? '';
      if (token.isEmpty) return null;

      final response = await _dio.get(
        "$baseUrl/parent/digest-settings",
        options: Options(headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['digest_enabled'] == true;
      }
    } catch (e) {
      debugPrint("❌ Error fetching digest settings: $e");
    }
    return null;
  }

  // تفعيل/إيقاف الملخص الأسبوعي
  Future<bool> setDigestEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String token = prefs.getString('token') ?? '';
      if (token.isEmpty) return false;

      final response = await _dio.put(
        "$baseUrl/parent/digest-settings",
        data: {'digest_enabled': enabled},
        options: Options(headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ Error updating digest settings: $e");
    }
    return false;
  }

  // تنزيل الملخص الأسبوعي كملف PDF وحفظه على الجهاز (يرجع مسار الملف أو null عند الفشل)
  Future<String?> downloadDigestPdf(int digestId, {String? fileName}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String token = prefs.getString('token') ?? '';
      if (token.isEmpty) return null;

      final response = await _dio.get<List<int>>(
        "$baseUrl/parent/digests/$digestId/pdf",
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            "Accept": "application/pdf",
            "Authorization": "Bearer $token",
          },
          receiveTimeout: const Duration(seconds: 40),
        ),
      );

      final bytes = response.data;
      if (response.statusCode != 200 || bytes == null || bytes.isEmpty) return null;

      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/${fileName ?? 'weekly_digest_$digestId.pdf'}';
      await File(path).writeAsBytes(bytes, flush: true);
      return path;
    } catch (e) {
      debugPrint("❌ Error downloading digest PDF: $e");
    }
    return null;
  }
}
