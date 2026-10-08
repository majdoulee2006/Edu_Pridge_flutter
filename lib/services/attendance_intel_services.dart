import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/services/session_guard.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// تحليل الحضور: اشتباهات الغش (للمعلّم) والخريطة الحرارية والترتيب (لرئيس القسم).
class AttendanceIntelService {
  final Dio _dio = Dio()..interceptors.add(SingleSessionInterceptor());
  final String baseUrl = ApiService().baseUrl;

  Future<Options> _options() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return Options(headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
  }

  /// قائمة اشتباهات مقررات المعلّم. status: open | confirmed | dismissed | all
  Future<Map<String, dynamic>?> getFlags({String status = 'open', int page = 1}) async {
    try {
      final res = await _dio.get(
        '$baseUrl/teacher/attendance-flags',
        queryParameters: {'status': status, 'page': page},
        options: await _options(),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        return Map<String, dynamic>.from(res.data);
      }
    } catch (e) {
      debugPrint('❌ Error fetching attendance flags: $e');
    }
    return null;
  }

  /// قرار المعلّم على اشتباه. يرجع رسالة الخطأ، أو null عند النجاح.
  Future<String?> reviewFlag(int id, {required bool confirmed, String? note, bool markAbsent = false}) async {
    try {
      final res = await _dio.put(
        '$baseUrl/teacher/attendance-flags/$id',
        data: {
          'status': confirmed ? 'confirmed' : 'dismissed',
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          if (confirmed && markAbsent) 'mark_absent': true,
        },
        options: (await _options())..validateStatus = (s) => s != null && s < 500,
      );
      if (res.statusCode == 200 && res.data['success'] == true) return null;
      return res.data is Map ? (res.data['message']?.toString() ?? 'تعذّر حفظ القرار') : 'تعذّر حفظ القرار';
    } catch (e) {
      debugPrint('❌ Error reviewing flag: $e');
      return 'تعذّر الاتصال بالسيرفر';
    }
  }

  /// تحليلات الحضور لقسم رئيس القسم (خريطة حرارية، ترتيب، اتجاه، تغيّر السلوك).
  Future<Map<String, dynamic>?> getInsights({int? programId, String? from, String? to}) async {
    try {
      final res = await _dio.get(
        '$baseUrl/department-head/attendance/insights',
        queryParameters: {
          'program_id': ?programId,
          'from': ?from,
          'to': ?to,
        },
        options: await _options(),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        return Map<String, dynamic>.from(res.data);
      }
    } catch (e) {
      debugPrint('❌ Error fetching attendance insights: $e');
    }
    return null;
  }
}
