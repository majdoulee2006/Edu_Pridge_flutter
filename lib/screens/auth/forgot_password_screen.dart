import 'package:flutter/material.dart';
// ✅ تأكدي أن ملف otp_screen يدعم الثيم الداكن أيضاً
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
    // 🎨 استخراج ألوان الثيم الحالي
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = theme.cardColor;
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

              // 1. الأيقونة المضيئة (Neon Style في الداكن)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: cardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryYellow.withValues(alpha: isDark ? 0.15 : 0.3),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.lock_reset_rounded,
                    size: 45,
                    color: primaryYellow,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 2. النصوص
              Text(
                "استعادة كلمة المرور",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "يرجى إدخال رقم هاتفك أو بريدك الإلكتروني المسجل لدينا لنرسل لك رمز التحقق.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: subTextColor, height: 1.5),
              ),

              const SizedBox(height: 45),

              // 3. حقل الإدخال
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 15, bottom: 8),
                    child: Text(
                      "رقم الهاتف أو البريد الإلكتروني",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: textColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: TextField(
                      controller: _inputController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: "أدخل بياناتك هنا...",
                        hintStyle: TextStyle(
                          color: textColor.withValues(alpha: 0.3),
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.person_search_outlined,
                          color: subTextColor,
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OTPScreen(
                          appBarTitle: "التحقق من الحساب",
                          message: "تم إرسال رمز التحقق المكون من 4 أرقام لتأكيد هويتك.",
                          onConfirm: () {
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
                    backgroundColor: primaryYellow,
                    foregroundColor: Colors.black, // النص يبقى أسود للوضوح
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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.arrow_forward_rounded,
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
                child: Text(
                  "إلغاء والعودة",
                  style: TextStyle(
                    color: subTextColor,
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