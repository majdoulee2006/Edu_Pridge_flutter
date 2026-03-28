//import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
//import 'package:edu_pridge_flutter/screens/student/nav_bar/student_home_screen.dart';
//import 'package:edu_pridge_flutter/screens/teacher/teacher_home.dart';
import 'package:flutter/material.dart';
import 'screens/onboarding/onboarding_one.dart'; // استدعاء صفحة الترحيب الأولى
// 🌟 استدعاء ملف الإعدادات للوصول لكلاس AppSettings 🌟
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart'; // تأكدي إنو المسار صحيح عندك

void main() {
  runApp(const EduBridgeApp());
}

class EduBridgeApp extends StatelessWidget {
  const EduBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🌟 1. الاستماع لتغيير الوضع الداكن من شاشة الإعدادات 🌟
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.isDarkMode,
      builder: (context, isDark, child) {
        // 🌟 2. الاستماع لتغيير حجم الخط من شاشة الإعدادات 🌟
        return ValueListenableBuilder<double>(
          valueListenable: AppSettings.fontSize,
          builder: (context, fontScale, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false, // لإخفاء شريط الـ Debug المزعج
              title: 'Edu-Bridge',

              // 🌟 التعديل السحري: إذا المستخدم ما غير الإعدادات يدوياً من التطبيق،
              // رح ياخد التطبيق ثيم الموبايل تلقائياً (ThemeMode.system) 🌟
              // ملاحظة: لو كنتِ حاطة كود مسبق للإعدادات، استبدليه بهذا ليدعم النظام كافتراضي
              themeMode: isDark ? ThemeMode.dark : ThemeMode.system,

              // 🎨 تصميم الوضع الفاتح (Light Theme)
              theme: ThemeData(
                primarySwatch: Colors.green,
                fontFamily: 'Tajawal', // خط التطبيق
                scaffoldBackgroundColor: const Color(0xFFF9F9F9),
                cardColor: Colors.white,
                brightness: Brightness.light,
              ),

              // 🌙 تصميم الوضع الداكن (Dark Theme)
              darkTheme: ThemeData(
                primarySwatch: Colors.green,
                fontFamily: 'Tajawal', // الحفاظ على نفس الخط بالوضع الداكن
                scaffoldBackgroundColor: const Color(
                  0xFF121212,
                ), // أسود مريح للعين
                cardColor: const Color(0xFF1E1E1E), // لون الكروت بالداكن
                brightness: Brightness.dark,
              ),

              // 🌟 تطبيق حجم الخط المختار على كل النصوص في التطبيق تلقائياً 🌟
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(
                      fontScale,
                    ), // التكبير والتصغير
                  ),
                  child: child!,
                );
              },

              // هاد السطر هو الأهم، بيخبر التطبيق يبدأ من صفحتك
              home: OnboardingOne(),
            );
          },
        );
      },
    );
  }
}
