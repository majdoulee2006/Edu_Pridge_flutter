import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.isDarkMode,
      builder: (context, isDark, _) => ValueListenableBuilder<String>(
        valueListenable: AppSettings.language,
        builder: (context, lang, _) {
          final isAr = lang == 'ar';
          final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
          final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
          final textColor = isDark ? Colors.white : Colors.black;
          final subColor = isDark ? Colors.grey.shade400 : Colors.grey;

          return Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              backgroundColor: bgColor,
              appBar: AppBar(
                backgroundColor: cardColor,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  isAr ? "حول التطبيق" : "About App",
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                ),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCC00),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(Icons.school_rounded, size: 60, color: Colors.black),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Edu-Bridge",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "إصدار v1.0.2",
                        style: TextStyle(color: Color(0xFFFFCC00), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      isAr
                          ? "منصة Edu-Bridge هي نظام متكامل لإدارة الشؤون الأكاديمية والطلابية والمعاهد، تهدف لتسهيل التواجد، الخدمات الإلكترونية، ومتابعة المحاضرات والنتائج بكل يسر وأمان."
                          : "Edu-Bridge is a comprehensive platform for managing academic and student affairs, providing seamless e-services, attendance tracking, and grades management.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: subColor, fontSize: 14, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
