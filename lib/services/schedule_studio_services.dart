import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/services/session_guard.dart';
import 'package:edu_pridge_flutter/services/study_services.dart' show StudyResult;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// استوديو الجدول لرئيس القسم: مسودة يقترحها النظام، يراجعها ويعدّلها ويعتمدها.
/// أي رفض من القواعد (تعارض معلم/شعبة/قاعة...) يرجع برسالة عربية جاهزة للعرض.
class ScheduleStudioService {
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
      final res = await _dio.request('$baseUrl/department-head/schedule-studio$path', data: body, options: (await _options()).copyWith(method: method));
      final code = res.statusCode ?? 500;
      if (code >= 200 && code < 300 && res.data is Map && res.data['success'] == true) {
        final d = res.data['data'];
        return StudyResult.ok(d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{});
      }
      if (code == 403) return const StudyResult.fail('هذه الخدمة لرؤساء الأقسام فقط');
      if (code == 404) return const StudyResult.fail('المسودة غير موجودة');
      final d = res.data;
      if (d is Map && d['errors'] is Map && (d['errors'] as Map).isNotEmpty) return StudyResult.fail((((d['errors'] as Map).values.first) as List).first.toString());
      return StudyResult.fail(d is Map ? (d['message']?.toString() ?? 'تعذّر تنفيذ الطلب') : 'تعذّر تنفيذ الطلب');
    } catch (e) {
      debugPrint('❌ Schedule studio error ($path): $e');
      return const StudyResult.fail('تعذّر الاتصال بالسيرفر');
    }
  }

  Future<StudyResult<Map<String, dynamic>>> overview({int? semesterId}) => _call('GET', semesterId == null ? '' : '?semester_id=$semesterId');
  Future<StudyResult<Map<String, dynamic>>> generate({String? name, int? periods, int? semesterId}) =>
      _call('POST', '/generate', body: {if (name != null && name.trim().isNotEmpty) 'name': name.trim(), 'periods': ?periods, 'semester_id': ?semesterId});
  Future<StudyResult<Map<String, dynamic>>> show(int id) => _call('GET', '/$id');
  Future<StudyResult<Map<String, dynamic>>> move(int id, int entryId, String day, int period) =>
      _call('POST', '/$id/move', body: {'entry_id': entryId, 'day': day, 'period': period});
  Future<StudyResult<Map<String, dynamic>>> lock(int id, int entryId, bool locked) =>
      _call('POST', '/$id/lock', body: {'entry_id': entryId, 'locked': locked});
  Future<StudyResult<Map<String, dynamic>>> regenerate(int id) => _call('POST', '/$id/regenerate');
  Future<StudyResult<Map<String, dynamic>>> approve(int id, {bool acknowledge = false}) => _call('POST', '/$id/approve', body: {'acknowledge': acknowledge});
  Future<StudyResult<Map<String, dynamic>>> discard(int id) => _call('POST', '/$id/discard');
  Future<StudyResult<Map<String, dynamic>>> revert(int id) => _call('POST', '/$id/revert');

  // ---- القاعات وتوفّر المعلمين
  Future<StudyResult<Map<String, dynamic>>> settings() => _call('GET', '/settings');
  Future<StudyResult<Map<String, dynamic>>> addRoom(String name, int capacity, {String type = 'classroom', int? programId, int? year}) =>
      _call('POST', '/rooms', body: {'name': name, 'capacity': capacity, 'type': type, 'program_id': ?programId, 'year': ?year});
  Future<StudyResult<Map<String, dynamic>>> updateRoom(int id, String name, int capacity, {String type = 'classroom', int? programId, int? year}) =>
      _call('PUT', '/rooms/$id', body: {'name': name, 'capacity': capacity, 'type': type, 'program_id': ?programId, 'year': ?year});
  /// قاعة خاصة لكل شعبة بلا قاعة (أو ربط قاعة موجودة بنفس الاسم).
  Future<StudyResult<Map<String, dynamic>>> autoRooms() => _call('POST', '/rooms/auto');
  /// استيراد قاعات من نص: سطر لكل قاعة (الاسم، السعة، النوع، الدورة، السنة).
  Future<StudyResult<Map<String, dynamic>>> importRooms(String lines) => _call('POST', '/rooms/import', body: {'lines': lines});
  Future<StudyResult<Map<String, dynamic>>> deleteRoom(int id) => _call('DELETE', '/rooms/$id');
  Future<StudyResult<Map<String, dynamic>>> addAvailability(int teacherUserId, String day, int period, String kind) =>
      _call('POST', '/availability', body: {'teacher_user_id': teacherUserId, 'day': day, 'period': period, 'kind': kind});
  Future<StudyResult<Map<String, dynamic>>> deleteAvailability(int id) => _call('DELETE', '/availability/$id');
}
