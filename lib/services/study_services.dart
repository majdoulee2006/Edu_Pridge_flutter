import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/services/session_guard.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// نتيجة استدعاء: إمّا بيانات أو رسالة خطأ عربية جاهزة للعرض.
class StudyResult<T> {
  final T? data;
  final String? error;
  const StudyResult.ok(this.data) : error = null;
  const StudyResult.fail(this.error) : data = null;
  bool get ok => error == null;
}

/// رفيق المذاكرة: المعلم (`teacher`) يولّد ويراجع ويعتمد، والطالب (`student`) يقرأ ويتدرب.
class StudyService {
  final Dio _dio = Dio()..interceptors.add(SingleSessionInterceptor());
  final String baseUrl = ApiService().baseUrl;

  Future<Options> _options() async {
    final prefs = await SharedPreferences.getInstance();
    return Options(
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer ${prefs.getString('token') ?? ''}'},
      validateStatus: (s) => s != null && s < 500,
    );
  }

  String _message(Response res, String fallback) {
    final d = res.data;
    if (d is Map) {
      final errors = d['errors'];
      if (errors is Map && errors.isNotEmpty) return (errors.values.first as List).first.toString();
      if (d['message'] != null) return d['message'].toString();
    }
    return fallback;
  }

  Future<StudyResult<dynamic>> _call(String method, String path, {Object? body, String fallback = 'تعذّر تنفيذ الطلب'}) async {
    try {
      final res = await _dio.request(
        '$baseUrl/$path',
        data: body,
        options: (await _options()).copyWith(method: method),
      );
      final code = res.statusCode ?? 500;
      if (code >= 200 && code < 300 && res.data is Map && res.data['success'] == true) {
        return StudyResult.ok(res.data['data']);
      }
      if (code == 404) return const StudyResult.fail('غير موجود أو ليس لك صلاحية عليه');
      return StudyResult.fail(_message(res, fallback));
    } catch (e) {
      debugPrint('❌ Study API error ($path): $e');
      return const StudyResult.fail('تعذّر الاتصال بالسيرفر');
    }
  }

  List<Map<String, dynamic>> asList(dynamic v) =>
      ((v as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  // ---- المعلم
  Future<StudyResult<dynamic>> teacherList() => _call('GET', 'teacher/study');
  Future<StudyResult<dynamic>> generate(int lessonId) => _call('POST', 'teacher/study/generate/$lessonId');
  Future<StudyResult<dynamic>> teacherShow(int id) => _call('GET', 'teacher/study/$id');
  Future<StudyResult<dynamic>> save(int id, Map<String, dynamic> body) => _call('PUT', 'teacher/study/$id', body: body);
  Future<StudyResult<dynamic>> approve(int id) => _call('POST', 'teacher/study/$id/approve');
  Future<StudyResult<dynamic>> unpublish(int id) => _call('POST', 'teacher/study/$id/unpublish');
  Future<StudyResult<dynamic>> exportQuiz(int id) => _call('POST', 'teacher/study/$id/export');

  // ---- الطالب
  Future<StudyResult<dynamic>> studentList() => _call('GET', 'student/study');
  Future<StudyResult<dynamic>> studentShow(int id) => _call('GET', 'student/study/$id');
  Future<StudyResult<dynamic>> attempt(int id, Map<int, int> answers) =>
      _call('POST', 'student/study/$id/attempt', body: {'answers': answers.map((k, v) => MapEntry('$k', v))});
}
