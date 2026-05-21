import 'package:flutter/material.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _inputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // 🎨 استخراج ألوان الثيم الحالي (هنا تم تعريف isDark لتعمل في الأسفل)
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final primaryYellow = const Color(0xFFEFFF00);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            "نسيت كلمة السر",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Cairo',
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFFEF9E7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_reset_rounded,
                    size: 45,
                    color: isDark ? primaryYellow : const Color(0xFFD4AC0D),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "استعادة كلمة المرور",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "يرجى إدخال بريدك الإلكتروني المسجل لدينا لنرسل لك رمز التحقق.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: subTextColor, height: 1.5, fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 45),
              _buildInputField(textColor, cardColor, subTextColor),
              const SizedBox(height: 50),

              // 🌟 تعديل زر المتابعة ليتوافق مع OTPScreen الجديدة
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    String inputEmail = _inputController.text.trim();
                    if (inputEmail.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("يرجى إدخال البريد الإلكتروني")),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OTPScreen(
                          email: inputEmail, // 👈 أضفنا الإيميل المطلوب
                          appBarTitle: "تحقق من بريدك",
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text(
                    "متابعة",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo'),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("إلغاء والعودة", style: TextStyle(color: subTextColor, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(Color textColor, Color cardColor, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 15, bottom: 8),
          child: Text(
            "البريد الإلكتروني",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor, fontFamily: 'Cairo'),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: textColor.withOpacity(0.1)),
          ),
          child: TextField(
            controller: _inputController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: "example@mail.com",
              hintStyle: TextStyle(color: textColor.withOpacity(0.3), fontSize: 13, fontFamily: 'Cairo'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.email_outlined, color: subTextColor, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}