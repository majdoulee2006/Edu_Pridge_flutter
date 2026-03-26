import 'package:flutter/material.dart';
// ✅ تم استدعاء واجهة رمز التحقق
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // للتحكم بحقل الإدخال (يمكن أن يكون هاتف أو إيميل)
  final TextEditingController _inputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // لضمان ظهور العناصر من اليمين لليسار
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA), // خلفية فاتحة
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "نسيت كلمة السر",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          // سهم الرجوع يؤشر لليمين بشكل صحيح
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // 1. الأيقونة المضيئة
              Center(
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEFFF00).withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons
                        .lock_reset_rounded, // أيقونة مناسبة لاستعادة كلمة المرور
                    size: 45,
                    color: Color(0xFFEFFF00),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 2. النص التوضيحي
              const Text(
                "استعادة كلمة المرور",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "يرجى إدخال رقم هاتفك أو بريدك الإلكتروني المسجل لدينا لنرسل لك رمز التحقق.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
              ),

              const SizedBox(height: 45),

              // 3. حقل الإدخال (للهاتف أو البريد)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 15, bottom: 8),
                    child: Text(
                      "رقم الهاتف أو البريد الإلكتروني",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _inputController,
                      decoration: InputDecoration(
                        hintText: "أدخل بياناتك هنا...",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.person_search_outlined,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 50),

              // 4. زر المتابعة
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // ✅ الانتقال لواجهة الـ OTP للتحقق من هويته
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OTPScreen(
                          appBarTitle: "التحقق من الحساب",
                          message:
                              "تم إرسال رمز التحقق المكون من 4 أرقام لتأكيد هويتك.",
                          onConfirm: () {
                            // بعد ما يدخل الرمز صح، المفروض يروح لشاشة "إنشاء كلمة سر جديدة"
                            // مؤقتاً رح نرجعه خطوتين كإثبات نجاح العملية
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "تم التحقق بنجاح! يمكنك الآن إعادة تعيين كلمة المرور.",
                                  textAlign: TextAlign.center,
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                            int count = 0;
                            Navigator.of(context).popUntil((_) => count++ >= 2);
                          },
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFFF00),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "متابعة",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.black,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // 5. زر الإلغاء
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "إلغاء والعودة",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
