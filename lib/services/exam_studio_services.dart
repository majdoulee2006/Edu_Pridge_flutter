import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/services/session_guard.dart';
import 'package:edu_pridge_flutter/services/study_services.dart' show StudyResult;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مولّد الجدول الامتحاني لرئيس القسم (مذاكرات + امتحانات): توزيع الطلاب على القاعات، مراقب لكل قاعة، ثم اعتماد.
/// أي رفض من القواعد يرجع برسالة عربية جاهزة للعرض.
class ExamStudioService {
  final Dio _dio = Dio()..interceptors.add(SingleSessionInterceptor());
  final String baseUrl = ApiService().baseUrl;

  Future<Options> _options() async {
    final prefs = await SharedPreferences.getInstance();
    return Options(
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer ${prefs.getString('token') ?? ''}'},
      validateStatus: (s) => s != null && s < 500,
    );
  }

  Future<StudyResult<Map<String, dynamic>>> _call(String method, String path, {Object? body}) async {
    try {
      final res = await _dio.request('$baseUrl/department-head/exam-studio$path', data: body, options: (await _options()).copyWith(method: method));
      final code = res.statusCode ?? 500;
      if (code >= 200 && code < 300 && res.data is Map && res.data['success'] == true) {
        final d = res.data['data'];
        return StudyResult.ok(d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{});
      }
      if (code == 403) return const StudyResult.fail('هذه الخدمة لرؤساء الأقسام فقط');
      if (code == 404) return const StudyResult.fail('الجدول غير موجود');
      final d = res.data;
      if (d is Map && d['errors'] is List && (d['errors'] as List).isNotEmpty) return StudyResult.fail((d['errors'] as List).join(' — '));
      if (d is Map && d['errors'] is Map && (d['errors'] as Map).isNotEmpty) return StudyResult.fail((((d['errors'] as Map).values.first) as List).first.toString());
      return StudyResult.fail(d is Map ? (d['message']?.toString() ?? 'تعذّر تنفيذ الطلب') : 'تعذّر تنفيذ الطلب');
    } catch (e) {
      debugPrint('❌ Exam studio error ($path): $e');
      return const StudyResult.fail('تعذّر الاتصال بالسيرفر');
    }
  }

  Future<StudyResult<Map<String, dynamic>>> overview({int? semesterId}) => _call('GET', semesterId == null ? '' : '?semester_id=$semesterId');

  /// kinds: {'midterm': {from,to,duration,excluded:[...],slots:[{start,end}]}, 'final': {...}}؛ النوع غير المطلوب يُحذف من الخريطة.
  Future<StudyResult<Map<String, dynamic>>> generate(Map<String, dynamic> kinds, {int? semesterId}) =>
      _call('POST', '/generate', body: {'kinds': kinds, 'semester_id': ?semesterId});

  Future<StudyResult<Map<String, dynamic>>> show(int id) => _call('GET', '/$id');
  Future<StudyResult<Map<String, dynamic>>> move(int id, int entryId, String date, int slot) => _call('POST', '/$id/move', body: {'entry_id': entryId, 'date': date, 'slot': slot});
  Future<StudyResult<Map<String, dynamic>>> lock(int id, int entryId, bool locked) => _call('POST', '/$id/lock', body: {'entry_id': entryId, 'locked': locked});
  Future<StudyResult<Map<String, dynamic>>> moveStudent(int id, int entryId, int studentId, String room) =>
      _call('POST', '/$id/student', body: {'entry_id': entryId, 'student_id': studentId, 'room': room});
  Future<StudyResult<Map<String, dynamic>>> setProctor(int id, int entryId, String room, int? userId) =>
      _call('POST', '/$id/proctor', body: {'entry_id': entryId, 'room': room, 'user_id': userId});
  Future<StudyResult<Map<String, dynamic>>> regenerate(int id) => _call('POST', '/$id/regenerate');
  Future<StudyResult<Map<String, dynamic>>> approve(int id, {bool acknowledge = false}) => _call('POST', '/$id/approve', body: {'acknowledge': acknowledge});
  Future<StudyResult<Map<String, dynamic>>> discard(int id) => _call('POST', '/$id/discard');
  Future<StudyResult<Map<String, dynamic>>> revert(int id) => _call('POST', '/$id/revert');
}

/// ما يخص المعلم من الجدول الامتحاني المعتمد: قاعات مراقبته، وقاعات تقييمات مقرراته.
class TeacherExamService {
  final Dio _dio = Dio()..interceptors.add(SingleSessionInterceptor());
  final String baseUrl = ApiService().baseUrl;

  Future<List<Map<String, dynamic>>?> _list(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final res = await _dio.get('$baseUrl/teacher/$path',
          options: Options(headers: {'Accept': 'application/json', 'Authorization': 'Bearer ${prefs.getString('token') ?? ''}'}, validateStatus: (s) => s != null && s < 500));
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
