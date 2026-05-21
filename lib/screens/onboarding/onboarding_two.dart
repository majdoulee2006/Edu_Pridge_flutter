import 'package:flutter/material.dart';
import 'onboarding_three.dart';
import '../auth/login_screen.dart';
import '../../widgets/custom_button.dart';

class OnboardingTwo extends StatelessWidget {
  const OnboardingTwo({super.key});

  @override
  Widget build(BuildContext context) {
    // 🎨 تعريف ألوان الثيم
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final primaryYellow = const Color(0xFFFFCC00);
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
                // الشريط العلوي
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: inactiveDot, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Container(
                            width: 25, height: 8,
                            decoration: BoxDecoration(color: primaryYellow, borderRadius: BorderRadius.circular(10)),
                          ),
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
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold
                            )
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1B5E20), const Color(0xFF121212)]
                            : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dashboard_rounded, size: 80, color: primaryYellow),
                        const SizedBox(height: 12),
                        Text("لوحة تحكم شاملة", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.green.shade800)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                    "كل ما تحتاجه",
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textColor
                    )
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  color: primaryYellow,
                  child: const Text(
                      "في مكان واحد",
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black // يبقى أسود للتباين مع الأصفر
                      )
                  ),
                ),

                const SizedBox(height: 10),

                // قائمة المميزات (تعديل الألوان هنا تلقائي)
                Expanded(
                  child: ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      FeatureItem(
                        title: "إدارة الحسابات",
                        subtitle: "تحكم كامل في ملفات الموظفين والطلاب.",
                        icon: Icons.person_search,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      FeatureItem(
                        title: "الجداول والمواعيد",
                        subtitle: "تنظيم الجداول ومتابعة الحضور والغياب.",
                        icon: Icons.calendar_month,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      FeatureItem(
                        title: "التقارير",
                        subtitle: "لوحة تحكم ذكية تعرض تحليلات الأداء.",
                        icon: Icons.bar_chart,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: CustomButton(
                    text: "التالي  ←",
                    color: primaryYellow,
                    textColor: Colors.black,
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OnboardingThree())
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

class FeatureItem extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color textColor;
  final Color subTextColor;

  const FeatureItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
          title,
          textAlign: TextAlign.right,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: textColor
          )
      ),
      subtitle: Text(
          subtitle,
          textAlign: TextAlign.right,
          style: TextStyle(
              color: subTextColor,
              fontSize: 13
          )
      ),
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: textColor.withValues(alpha: 0.1), // خلفية خفيفة للأيقونة
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: textColor, size: 24),
      ),
    );
  }
}