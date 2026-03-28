import 'package:flutter/material.dart';
import 'onboarding_two.dart';
import '../auth/login_screen.dart';
import '../../widgets/custom_button.dart';

class OnboardingOne extends StatelessWidget {
  const OnboardingOne({super.key});

  @override
  Widget build(BuildContext context) {
    // 🎨 استخراج الألوان من الثيم الحالي
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final primaryYellow = const Color(0xFFEFFF00);
    final inactiveDot = isDark ? Colors.white24 : const Color(0xFFE0E0E0);

    return Scaffold(
      backgroundColor: scaffoldBg, // يتغير حسب الثيم
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            // حساب الطول المتاح للشاشة بدقة
            height: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
            child: Column(
              children: [
                // الشريط العلوي
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // النقطة النشطة (دائماً صفراء)
                          Container(
                            width: 25, height: 8,
                            decoration: BoxDecoration(
                                color: primaryYellow,
                                borderRadius: BorderRadius.circular(10)
                            ),
                          ),
                          const SizedBox(width: 5),
                          // النقاط غير النشطة (تتغير حسب الثيم)
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: inactiveDot, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: inactiveDot, shape: BoxShape.circle)),
                        ],
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen())
                        ),
                        child: Text(
                            "تخطي",
                            style: TextStyle(
                                color: textColor, // أسود في الفاتح، أبيض في الداكن
                                fontSize: 18,
                                fontWeight: FontWeight.bold
                            )
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // الصورة (أضفت خلفية خفيفة في الداكن لبروز الصورة إذا كانت شفافة)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isDark ? [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5)
                        )
                      ] : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                          'assets/images/onboarding1.png',
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                    "مرحباً بك في",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor
                    )
                ),

                // كلمة Edu-Bridge بخلفية صفراء
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  color: primaryYellow,
                  child: const Text(
                      "Edu-Bridge",
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black // النص يبقى أسود دائماً على الأصفر للوضوح
                      )
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "الجسر التعليمي الذكي لإدارة مهامك الأكاديمية والإدارية بكل سهولة واحترافية.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: subTextColor,
                        fontSize: 16,
                        height: 1.5
                    ),
                  ),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: CustomButton(
                    text: "ابدأ رحلتك  ←",
                    color: primaryYellow,
                    textColor: Colors.black, // دائماً أسود على الأصفر لتباين ممتاز
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OnboardingTwo())
                    ),
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