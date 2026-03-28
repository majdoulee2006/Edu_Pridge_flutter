import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../../widgets/custom_button.dart';

class OnboardingThree extends StatelessWidget {
  const OnboardingThree({super.key});

  @override
  Widget build(BuildContext context) {
    // 🎨 استخراج ألوان الثيم الحالي
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final primaryYellow = const Color(0xFFEFFF00);
    final inactiveDot = isDark ? Colors.white24 : const Color(0xFFE0E0E0);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
            child: Column(
              children: [
                // 1. الشريط العلوي (النقطة الثالثة هي النشطة)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // مؤشر الصفحات (النقاط)
                      Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: inactiveDot, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: inactiveDot, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            width: 25, height: 8,
                            decoration: BoxDecoration(
                              color: primaryYellow, // النقطة الثالثة نشطة
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                      // زر الرجوع للخلف (يتكيف لونه مع الثيم)
                      IconButton(
                        icon: Icon(Icons.arrow_forward_ios, color: textColor, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 2. الصورة العلوية
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isDark ? [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5)
                        )
                      ] : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/onboarding3.png',
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 3. العنوان الرئيسي (يتكيف مع الثيم)
                Text(
                  "إدارة ذكية و",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  color: primaryYellow,
                  child: const Text(
                    "تقارير دقيقة",
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black // يبقى أسود للتباين على الأصفر
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 4. النص الوصفي
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "حلول متطورة لمتابعة الأداء الأكاديمي وضمان سير العملية التعليمية بأفضل صورة ممكنة.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: subTextColor,
                        fontSize: 16,
                        height: 1.5
                    ),
                  ),
                ),

                const Spacer(),

                // 5. زر ابدأ الآن
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: CustomButton(
                    text: "ابدأ الآن",
                    color: primaryYellow,
                    textColor: Colors.black,
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}