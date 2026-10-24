import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/services/session_guard.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ما يخص المعلم من الجدول الامتحاني المعتمد: قاعات مراقبته، وقاعات تقييمات مقرراته.
class TeacherExamService {
  final Dio _dio = Dio()..interceptors.add(SingleSessionInterceptor());
  final String baseUrl = ApiService().baseUrl;

  Future<List<Map<String, dynamic>>?> _list(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final res = await _dio.get(
        '$baseUrl/teacher/$path',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${prefs.getString('token') ?? ''}',
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      if (res.statusCode == 200 && res.data is Map && res.data['success'] == true) {
        return ((res.data['data'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint('❌ Teacher exams error ($path): $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> invigilations() => _list('invigilations');
  Future<List<Map<String, dynamic>>?> courseExamRooms() => _list('exam-rooms');
}
