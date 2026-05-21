import 'package:flutter/material.dart';
import 'otp_screen.dart';

class EditEmailScreen extends StatefulWidget {
  const EditEmailScreen({super.key});

  @override
  State<EditEmailScreen> createState() => _EditEmailScreenState();
}

class _EditEmailScreenState extends State<EditEmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // 🎨 استخراج الألوان من الثيم الحالي (فاتح أو داكن)
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ألوان مخصصة للوضع الداكن والفاتح
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
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
            "تعديل البريد الإلكتروني",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: textColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // أيقونة الظرف المركزية
              Center(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: primaryYellow.withValues(alpha: 0.1), // شفافية متوافقة مع التحديثات
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.email_rounded,
                      color: primaryYellow,
                      size: 70,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Text(
                "البريد الإلكتروني الجديد",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "يرجى إدخال عنوان البريد الإلكتروني الجديد.\nسنرسل لك رمز تحقق لتأكيد التغيير.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: subTextColor, height: 1.5),
              ),

              const SizedBox(height: 40),

              // حقل البريد الإلكتروني
              _buildInputLabel("البريد الإلكتروني", textColor),
              _buildTextField(
                controller: _emailController,
                hintText: "user@example.com",
                icon: Icons.alternate_email_rounded,
                isEmail: true,
                cardColor: cardColor,
                textColor: textColor,
              ),

              const SizedBox(height: 20),

              // حقل كلمة المرور
              _buildInputLabel("كلمة المرور", textColor),
              _buildTextField(
                controller: _passwordController,
                hintText: "........",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                cardColor: cardColor,
                textColor: textColor,
              ),

              const SizedBox(height: 40),

              // زر إرسال رمز التحقق
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OTPScreen(
                          appBarTitle: "تأكيد البريد الإلكتروني",
                          message: "تم إرسال رمز التحقق المكون من 4 أرقام إلى\nبريدك الإلكتروني الجديد",
                          onConfirm: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("تم تغيير البريد الإلكتروني بنجاح! ✅", textAlign: TextAlign.center),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
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
                    foregroundColor: Colors.black, // النص دائماً أسود على الأصفر لتباين أفضل
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "إرسال رمز التحقق",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(right: 15, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required Color cardColor,
    required Color textColor,
    bool isPassword = false,
    bool isEmail = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor, // يتغير حسب الثيم (أبيض في الفاتح، رمادي غامق في الداكن)
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: textColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(color: textColor),
        textAlign: isEmail ? TextAlign.left : TextAlign.right,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: InputBorder.none,
          suffixIcon: Icon(icon, color: textColor.withValues(alpha: 0.5), size: 22),
        ),
      ),
    );
  }
}