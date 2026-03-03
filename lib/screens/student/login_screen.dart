import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // أضفنا هذا الـ Widget لجعل الصفحة قابلة للتمرير وحل مشكلة الـ Overflow
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // الأيقونة العلوية
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F8E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school,
                    size: 50,
                    color: Color(0xFFCDDC39),
                  ),
                ),
                const SizedBox(height: 30),

                // نصوص الترحيب
                const Text(
                  "مرحباً بك مجدداً",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "بوابة المعهد الجامعي للطلاب والمعلمين",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 50),

                // حقل اسم المستخدم
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text("اسم المستخدم", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                TextField(
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: "أدخل اسم المستخدم",
                    prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFCDDC39)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // حقل كلمة المرور
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text("كلمة المرور", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                TextField(
                  textAlign: TextAlign.right,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "********",
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFCDDC39)),
                    suffixIcon: const Icon(Icons.visibility_off, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // هل نسيت كلمة المرور
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      "هل نسيت كلمة المرور؟",
                      style: TextStyle(color: Color(0xFFCDDC39)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // زر تسجيل الدخول
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCDDC39),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "تسجيل الدخول ←",
                      style: TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text("أو", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),

                // زر إنشاء حساب
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCDDC39)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "إنشاء حساب جديد 👤+",
                      style: TextStyle(fontSize: 18, color: Color(0xFFCDDC39)),
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