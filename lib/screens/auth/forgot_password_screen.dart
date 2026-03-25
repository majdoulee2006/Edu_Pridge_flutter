import 'package:flutter/material.dart';
//import '../../widgets/custom_button.dart';
import 'otp_screen.dart'; // تأكد من وجود الملف

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
   Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "استعادة كلمة المرور",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 30),
              // ✅ الأيقونة المتوهجة (نفس ديزاين الصورة اللي بعتتها)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEFFF00).withOpacity(0.4),
                        blurRadius: 50,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: const Icon(Icons.phone_android_rounded, size: 50, color: Color(0xFFF1C40F)),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "أدخل رقم هاتفك",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              const Text(
                "سنقوم بإرسال رمز تحقق (OTP) إلى رقم هاتفك المسجل لتتمكن من إعادة تعيين كلمة المرور.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 40),

              // ✅ تسمية الحقل
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "رقم الجوال",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(height: 10),

              // ✅ حقل إدخال الرقم (الديزاين الرمادي الفاتح)
              Row(
                children: [
                  // كود الدولة
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF2F3F4)),
                    ),
                    child: const Text(
                      "+966",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // حقل الرقم
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.phone,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: "50 123 4567",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF8F9F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Color(0xFFF2F3F4)),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // ✅ زر الإرسال المربوط بـ OTP
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      // الربط الفعلي مع واجهة الـ OTP
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OTPScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFFF00), // اللون الأصفر المعتمد
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "إرسال رمز التحقق",
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward, color: Colors.black, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}