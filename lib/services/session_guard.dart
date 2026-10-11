import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/main.dart' show appNavigatorKey;
import 'package:edu_pridge_flutter/screens/auth/login_screen.dart';
import 'package:edu_pridge_flutter/services/ai_service.dart';

/// يعالج حالة "تسجيل الدخول من جهاز آخر": الباك إند بيرجع 401 مع
/// error_code = LOGGED_IN_ELSEWHERE لأي طلب مصادق عليه بتوكن صار
/// غير صالح لأنه صار تسجيل دخول جديد لنفس الحساب من مكان تاني.
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

/// يعالج حالة "تسجيل الدخول من جهاز آخر" وتمرير لغة التطبيق لجميع الطلبات
class SingleSessionInterceptor extends Interceptor {
  static bool _isHandling = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = AppSettings.language.value;
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final data = err.response?.data;
    final loggedInElsewhere = err.response?.statusCode == 401 &&
        data is Map &&
        data['error_code'] == 'LOGGED_IN_ELSEWHERE';

    // توكن منتهي الصلاحية أو ملغى: 401 على طلب كان يحمل Authorization (ما عدا مسار الدخول نفسه)
    final tokenRejected = err.response?.statusCode == 401 &&
        err.requestOptions.headers['Authorization'] != null &&
        !err.requestOptions.path.contains('/login');

    if ((loggedInElsewhere || tokenRejected) && !_isHandling) {
      _isHandling = true;
      final message = (loggedInElsewhere ? data['message'] as String? : null) ??
          (loggedInElsewhere
              ? 'تم تسجيل الدخول لحسابك من جهاز آخر، الرجاء تسجيل الدخول مجدداً.'
              : 'انتهت صلاحية الجلسة، الرجاء تسجيل الدخول مجدداً.');
      _forceLogout(message);
    }

    handler.next(err);
  }

  static Future<void> _forceLogout(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await AiService.clearLocalChats();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('parent_id');
    await prefs.remove('selected_student_id');
    await prefs.remove('selected_student_name');

    final navState = appNavigatorKey.currentState;
    if (navState == null) {
      _isHandling = false;
      return;
    }

    navState.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = appNavigatorKey.currentContext;
      _isHandling = false;
      if (ctx == null) return;
      showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          title: const Text('تم إنهاء الجلسة'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    });
  }
}
