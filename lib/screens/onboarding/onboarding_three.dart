import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../auth/login_screen.dart'; // تأكدي من صحة المسار لملف تسجيل الدخول

class OnboardingThree extends StatelessWidget {
  const OnboardingThree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            // ضبط الارتفاع ليتناسب مع حجم الشاشة ومنع Overflow
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
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE0E0E0),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE0E0E0),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            width: 25,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFFF00), // النقطة الثالثة صفراء وطويلة
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                      // زر الرجوع للخلف
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 2. الصورة العلوية
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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

                const SizedBox(height: 30),

                // 3. العنوان الرئيسي
                const Text(
                  "إدارة ذكية و",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  color: const Color(0xFFEFFF00),
                  child: const Text(
                    "تقارير دقيقة",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 20),

                // 4. النص الوصفي الشامل
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "حلول متطورة لمتابعة الأداء الأكاديمي وضمان سير العملية التعليمية بأفضل صورة ممكنة.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),

                const Spacer(),

                // 5. زر ابدأ الآن (ينقلك لصفحة تسجيل الدخول)
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: CustomButton(
                    text: "ابدأ الآن",
                    color: const Color(0xFFEFFF00),
                    textColor: Colors.black,
                    onPressed: () {
                      // استخدام pushReplacement لمنع الرجوع لصفحات الترحيب
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