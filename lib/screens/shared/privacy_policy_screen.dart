import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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

          return Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              backgroundColor: bgColor,
              appBar: AppBar(
                backgroundColor: cardColor,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  isAr ? "سياسة الخصوصية والشروط" : "Privacy Policy & Terms",
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                ),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    isAr ? "سياسة الخصوصية وأمان البيانات" : "Privacy & Data Security Policy",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAr
                        ? "نحن نلتزم بحماية بياناتك الشخصية والأكاديمية. يتم استخدام البيانات المجمعة حصرياً لأغراض التحقق من الهوية والأداء الأكاديمي داخل المعهد ومتابعة الخدمات الطلابية."
                        : "We are committed to protecting your personal and academic data. Collected data is strictly used for identification, academic performance tracking, and student services within the institute.",
                    style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 14, height: 1.6),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
