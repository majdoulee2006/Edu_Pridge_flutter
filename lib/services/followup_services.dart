import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/services/session_guard.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// لوحة متابعة الطلاب: للمرشد (basePath = teacher) ولرئيس القسم (basePath = department-head).
/// نفس بيانات صفحة الويب /hod|teacher/follow-up.
class FollowUpService {
  final Dio _dio = Dio()..interceptors.add(SingleSessionInterceptor());
  final String baseUrl = ApiService().baseUrl;

  /// يرجع null عند الفشل، و`{'forbidden': true}` إن لم يكن المستخدم مرشدًا أو رئيس قسم.
  Future<Map<String, dynamic>?> load(
    String basePath, {
    String? status,
    String sort = 'attention',
    String? search,
    int? programId,
    int? days,
    bool pending = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final res = await _dio.get(
        '$baseUrl/$basePath/follow-up',
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          'sort': sort,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          'program_id': ?programId,
          'days': ?days,
          if (pending) 'pending': 1,
        },
        options: Options(
          headers: {'Accept': 'application/json', 'Authorization': 'Bearer ${prefs.getString('token') ?? ''}'},
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      if (res.statusCode == 403) return {'forbidden': true, 'message': res.data['message']};
      if (res.statusCode == 200 && res.data['success'] == true) return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('❌ Error fetching follow-up dashboard: $e');
    }
    return null;
  }
}
