import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:flutter/material.dart';
//import '../../widgets/student_speed_dial.dart';
//import '../../widgets/teacher_speed_dial.dart';
import '../teacher/teacher_home.dart';
import '../student/nav_bar/student_home_screen.dart';
import 'forgot_password_screen.dart';
// ✅ استيراد صفحة إنشاء الحساب الجديدة
import 'create_account_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 50),
              // الشعار
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFFF00).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school,
                    size: 60,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 30),
              const Text(
                "مرحباً بك مجدداً",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "بوابتكم الذكية للتواصل والنجاح",
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // حقول الإدخال
              _buildTextField(
                label: "اسم المستخدم",
                hint: "أدخل اسم المستخدم",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: "رقم الهاتف",
                hint: "05x xxx xxxx",
                icon: Icons.phone_android,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: "كلمة المرور",
                hint: "********",
                icon: Icons.lock_outline,
                isPassword: true,
              ),

              // زر هل نسيت كلمة المرور
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // ✅ الربط بصفحة استعادة كلمة المرور
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "هل نسيت كلمة المرور؟",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // زر تسجيل الدخول الأساسي (مربوط حالياً بالمدرب)
              ElevatedButton(
                onPressed: () {
                  // الانتقال لواجهة المعلم ومنع الرجوع للخلف
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TeacherHomeScreen(),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFFF00), // لون الزر الأصفر
                  foregroundColor: Colors.black, // لون النص
                  minimumSize: const Size(
                    double.infinity,
                    50,
                  ), // عرض الزر وارتفاعه
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // تدوير الحواف
                  ),
                ),
                child: const Text(
                  "تسجيل الدخول",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),

              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // ✅ تم ربط صفحة إنشاء حساب جديد هنا
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateAccountScreen(),
                    ),
                  );
                },
                child: const Text(
                  "إنشاء حساب جديد",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // ==========================================
              // أزرار مؤقتة للمطورين (تُحذف قبل تسليم المشروع)
              // ==========================================
              const SizedBox(height: 20),
              const Divider(),
              const Text(
                "اختصارات للمطورين (للتجربة فقط):",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10, // المسافة الأفقية بين الأزرار
                runSpacing: 10, // المسافة العمودية بين الأزرار
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StudentHomeScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'دخول كطالب',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TeacherHomeScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'دخول كمدرب',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange, // لون مميز لولي الأمر
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          // ✅ استدعاء واجهة الأهل
                          builder: (context) => const ParentsHomeScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'دخول كولي أمر',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: isPassword,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
          ),
        ),
      ],
    );
  }
}
