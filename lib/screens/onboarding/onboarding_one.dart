import 'package:flutter/material.dart';

import 'onboarding_two.dart';
import '../auth/login_screen.dart';

class OnboardingOne extends StatelessWidget {
  const OnboardingOne({super.key});

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
                // الشريط العلوي (النقطة الأولى نشطة + تخطي للـ Login)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 25, height: 8,
                            decoration: BoxDecoration(color: const Color(0xFFEFFF00), borderRadius: BorderRadius.circular(10)),
                          ),
                          const SizedBox(width: 5),
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFE0E0E0), shape: BoxShape.circle)),
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
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset('assets/images/onboarding1.png', height: 250, width: double.infinity, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 30),
                const Text("مرحباً بك في", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  color: const Color(0xFFEFFF00),
                  child: const Text("Edu-Bridge", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "الجسر التعليمي الذكي لإدارة مهامك الأكاديمية والإدارية بكل سهولة واحترافية.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: CustomButton(
                    text: "ابدأ رحلتك  ←",
                    color: const Color(0xFFEFFF00),
                    textColor: Colors.black,
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OnboardingTwo())),
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