import 'package:flutter/material.dart';

class StudentLoginScreen extends StatelessWidget {
  const StudentLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView( // لحل مشكلة الخطوط الصفراء عند ظهور الكيبورد
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // أيقونة قبعة التخرج (للطلاب)
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F8E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school_outlined, // أيقونة مختلفة قليلاً للتميز
                    size: 50,
                    color: Color(0xFFCDDC39),
                  ),
                ),
                const SizedBox(height: 30),

                const Text(
                  "دخول الطلاب",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "مرحباً بك في بوابة الطالب الجامعية",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 50),

                const Align(
                  alignment: Alignment.centerRight,
                  child: Text("الرقم الجامعي / الاسم", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                TextField(
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: "أدخل بياناتك",
                    prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFFCDDC39)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

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

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text("هل نسيت كلمة المرور؟", style: TextStyle(color: Color(0xFFCDDC39))),
                  ),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // هنا سنبرمج الانتقال للصفحة الرئيسية لاحقاً
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCDDC39),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text("تسجيل الدخول ←", style: TextStyle(fontSize: 18, color: Colors.black)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("أو", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCDDC39)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text("إنشاء حساب طالب جديد", style: TextStyle(fontSize: 18, color: Color(0xFFCDDC39))),
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