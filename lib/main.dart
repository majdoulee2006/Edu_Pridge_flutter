import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:edu_pridge_flutter/screens/student/nav_bar/student_home_screen.dart';
import 'package:edu_pridge_flutter/screens/teacher/teacher_home.dart';
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
      home:  TeacherHomeScreen(),
    );
  }
}