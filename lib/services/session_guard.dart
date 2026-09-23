import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/main.dart' show appNavigatorKey;
import 'package:edu_pridge_flutter/screens/auth/login_screen.dart';

/// يعالج حالة "تسجيل الدخول من جهاز آخر": الباك إند بيرجع 401 مع
/// error_code = LOGGED_IN_ELSEWHERE لأي طلب مصادق عليه بتوكن صار
/// غير صالح لأنه صار تسجيل دخول جديد لنفس الحساب من مكان تاني.
/// هون بنمسح الجلسة المحلية ونرجّع المستخدم لشاشة الدخول مع رسالة واضحة.
class SingleSessionInterceptor extends Interceptor {
  static bool _isHandling = false;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final data = err.response?.data;
    final loggedInElsewhere = err.response?.statusCode == 401 &&
        data is Map &&
        data['error_code'] == 'LOGGED_IN_ELSEWHERE';

    if (loggedInElsewhere && !_isHandling) {
      _isHandling = true;
      final message = (data['message'] as String?) ??
          'تم تسجيل الدخول لحسابك من جهاز آخر، الرجاء تسجيل الدخول مجدداً.';
      _forceLogout(message);
    }

    handler.next(err);
  }

  static Future<void> _forceLogout(String message) async {
    final prefs = await SharedPreferences.getInstance();
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
