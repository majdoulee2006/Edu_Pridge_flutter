import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/services/session_guard.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// الإنذار المبكر للتعثر الأكاديمي. المسار يبدأ بـ basePath: `teacher` للمرشد أو `department-head` لرئيس القسم.
class RiskService {
  final Dio _dio = Dio()..interceptors.add(SingleSessionInterceptor());
  final String baseUrl = ApiService().baseUrl;

  Future<Options> _options() async {
    final prefs = await SharedPreferences.getInstance();
    return Options(
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer ${prefs.getString('token') ?? ''}'},
      validateStatus: (s) => s != null && s < 500,
    );
  }

  /// قائمة الطلاب. يرجع null عند الفشل، و`{'forbidden': true}` إن لم يكن المستخدم مرشدًا.
  Future<Map<String, dynamic>?> list(String basePath, {String? level, String? search, String sort = 'score', String? followUp}) async {
    try {
      final res = await _dio.get(
        '$baseUrl/$basePath/risk',
        queryParameters: {
          if (level != null && level.isNotEmpty) 'level': level,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          'sort': sort,
          if (followUp != null && followUp.isNotEmpty) 'followup': followUp,
          'per_page': 50,
        },
        options: await _options(),
      );
      if (res.statusCode == 403) return {'forbidden': true, 'message': res.data['message']};
      if (res.statusCode == 200 && res.data['success'] == true) return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('❌ Error fetching risk list: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> detail(String basePath, int studentId) async {
    try {
      final res = await _dio.get('$baseUrl/$basePath/risk/students/$studentId', options: await _options());
      if (res.statusCode == 200 && res.data['success'] == true) return Map<String, dynamic>.from(res.data['data']);
    } catch (e) {
      debugPrint('❌ Error fetching risk detail: $e');
    }
    return null;
  }

  /// يسجّل إجراء متابعة. يرجع null عند النجاح، أو رسالة الخطأ.
  Future<String?> addIntervention(String basePath, int studentId, {required String type, String? note, String? followUpOn}) async {
    try {
      final res = await _dio.post(
        '$baseUrl/$basePath/risk/students/$studentId/interventions',
        data: {
          'type': type,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          'follow_up_on': ?followUpOn,
        },
        options: await _options(),
      );
      if (res.statusCode == 201) return null;
      if (res.statusCode == 422) {
        final errors = res.data['errors'];
        if (errors is Map && errors.isNotEmpty) return (errors.values.first as List).first.toString();
      }
      return res.data is Map ? (res.data['message']?.toString() ?? 'تعذّر الحفظ') : 'تعذّر الحفظ';
    } catch (e) {
      debugPrint('❌ Error adding intervention: $e');
      return 'تعذّر الاتصال بالسيرفر';
    }
  }
}
