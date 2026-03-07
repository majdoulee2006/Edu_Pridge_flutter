import 'package:flutter/material.dart';
import 'screens/onboarding/onboarding_one.dart'; // استدعاء صفحة الترحيب الأولى

void main() {
  runApp(const EduBridgeApp());
}

class EduBridgeApp extends StatelessWidget {
  const EduBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // لإخفاء شريط الـ Debug المزعج
      title: 'Edu-Bridge',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Tajawal', // هاد بيفيدك لما نركب الخطوط لاحقاً
      ),
// هاد السطر هو الأهم، بيخبر التطبيق يبدأ من صفحتك
      home: const OnboardingOne(),
    );
  }
}