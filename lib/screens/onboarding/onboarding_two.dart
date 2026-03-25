import 'package:flutter/material.dart';

import 'onboarding_three.dart';
import '../auth/login_screen.dart';
import '../../widgets/custom_button.dart';
class OnboardingTwo extends StatelessWidget {
  const OnboardingTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            child: Column(
              children: [
                // الشريط العلوي (النقطة الثانية نشطة + تخطي للـ Login)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFE0E0E0), shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Container(
                            width: 25, height: 8,
                            decoration: BoxDecoration(color: const Color(0xFFEFFF00), borderRadius: BorderRadius.circular(10)),
                          ),
                          const SizedBox(width: 5),
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFE0E0E0), shape: BoxShape.circle)),
                        ],
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                        child: const Text("تخطي", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset('assets/images/onboarding2.png', height: 200, width: double.infinity, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("كل ما تحتاجه", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  color: const Color(0xFFEFFF00),
                  child: const Text("في مكان واحد", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: const [
                      FeatureItem(title: "إدارة الحسابات", subtitle: "تحكم كامل في ملفات الموظفين والطلاب.", icon: Icons.person_search),
                      FeatureItem(title: "الجداول والمواعيد", subtitle: "تنظيم الجداول ومتابعة الحضور والغياب.", icon: Icons.calendar_month),
                      FeatureItem(title: "التقارير", subtitle: "لوحة تحكم ذكية تعرض تحليلات الأداء.", icon: Icons.bar_chart),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                   child: CustomButton(
                    text: "التالي  ←",
                    color: const Color(0xFFEFFF00),
                    textColor: Colors.black,
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OnboardingThree())),
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
  const FeatureItem({super.key, required this.title, required this.subtitle, required this.icon});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle, textAlign: TextAlign.right, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      trailing: Icon(icon, color: Colors.black, size: 28),
    );
  }
}