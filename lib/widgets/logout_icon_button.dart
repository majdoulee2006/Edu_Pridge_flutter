import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/screens/auth/login_screen.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/services/chat_service.dart';
import 'package:edu_pridge_flutter/services/notification_polling.dart';

/// 🔓 نافذة تأكيد تسجيل الخروج + منطق الخروج الفعلي (تصفير الشات، حذف
/// بيانات الجلسة، إبلاغ السيرفر). مستخدمة كآخر عنصر بقائمة الخدمات
/// (بعد "سياسة الاستخدام والخصوصية") لكل الأدوار، وكمان بشاشة الإعدادات
/// للمعلّم تحديداً (ما عندو قائمة خدمات مشابهة).
Future<void> showLogoutConfirmation(BuildContext context, bool isAr) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.logout, color: Colors.red),
          const SizedBox(width: 10),
          Text(isAr ? "تسجيل الخروج" : "Logout",
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        content: Text(isAr
            ? "هل أنت متأكد أنك تريد تسجيل الخروج من الحساب؟"
            : "Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isAr ? "لا، تراجع" : "Cancel",
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);

              NotificationPolling.stop();
              await NotificationPolling.clearLastShownId();

              if (context.mounted) {
                await context.read<ChatService>().resetForLogout();
              }

              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('token') ?? '';
              if (token.isNotEmpty) {
                try {
                  await Dio().post(
                    "${ApiService().baseUrl}/logout",
                    options: Options(headers: {
                      "Accept": "application/json",
                      "Authorization": "Bearer $token",
                    }),
                  );
                } catch (e) {
                  debugPrint("خطأ أثناء تسجيل الخروج من السيرفر: $e");
                }
              }

              await prefs.remove('token');
              await prefs.remove('role');
              await prefs.remove('user_role');
              await prefs.remove('user_id');
              await prefs.remove('user_name');
              await prefs.remove('parent_id');
              await prefs.remove('selected_student_id');
              await prefs.remove('selected_student_name');

              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: Text(isAr ? "نعم، خروج" : "Yes, Logout",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );
}
