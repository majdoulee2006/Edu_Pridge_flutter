import 'package:flutter/material.dart';
// ✅ تم إضافة استدعاء واجهة التحقق (تأكدي من المسار الصحيح بملفاتك)
import 'otp_screen.dart';

class EditEmailScreen extends StatefulWidget {
  const EditEmailScreen({super.key});

  @override
  State<EditEmailScreen> createState() => _EditEmailScreenState();
}

class _EditEmailScreenState extends State<EditEmailScreen> {
  // معرفات للتحكم بالنصوص في الحقول
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // لضمان ظهور العناصر من اليمين لليسار
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA), // خلفية فاتحة جداً
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "تعديل البريد الإلكتروني",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          // سهم الرجوع
          leading: IconButton(
            icon: const Icon(
              Icons
                  .arrow_back, // ✅ تم تعديل السهم ليتناسب مع الواجهة العربية بشكل صحيح
              color: Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // أيقونة الظرف المركزية مع الخلفية الدائرية الفاتحة
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFEFFF00,
                    ).withOpacity(0.1), // أصفر شفاف جداً
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.email_rounded,
                      color: Color(0xFFEFFF00), // اللون الأصفر المعتمد
                      size: 80,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // النصوص التوضيحية
              const Text(
                "البريد الإلكتروني الجديد",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "يرجى إدخال عنوان البريد الإلكتروني الجديد.\nسنرسل لك رمز تحقق لتأكيد التغيير.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
              ),

              const SizedBox(height: 45),

              // حقل البريد الإلكتروني
              _buildInputLabel("البريد الإلكتروني"),
              _buildTextField(
                controller: _emailController,
                hintText: "user@example.com",
                icon: Icons.alternate_email_rounded,
                isEmail: true,
              ),

              const SizedBox(height: 25),

              // حقل كلمة المرور
              _buildInputLabel("كلمة المرور"),
              _buildTextField(
                controller: _passwordController,
                hintText: "........",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),

              const SizedBox(height: 50),

              // زر إرسال رمز التحقق
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // ✅ تم ربط الزر مع تمرير دالة الرجوع المزدوج (Double Pop) ورسالة النجاح
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OTPScreen(
                          appBarTitle: "تأكيد البريد الإلكتروني",
                          message:
                              "تم إرسال رمز التحقق المكون من 4 أرقام إلى\nبريدك الإلكتروني الجديد",
                          // 🌟 أمر الرجوع خطوتين للوراء مع إظهار رسالة النجاح 🌟
                          onConfirm: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "تم تغيير البريد الإلكتروني بنجاح! ✅",
                                  textAlign: TextAlign.center,
                                ),
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
                    backgroundColor: const Color(0xFFEFFF00),
                    foregroundColor: Colors.black,
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ويدجت لبناء عنوان الحقل (Label)
  Widget _buildInputLabel(String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(right: 15, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black,
        ),
      ),
    );
  }

  // ويدجت لبناء حقل الإدخال المخصص
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool isEmail = false,
  }) {
    return Container(
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
        controller: controller,
        obscureText: isPassword,
        textAlign: isEmail
            ? TextAlign.left
            : TextAlign.right, // الإيميل يبدأ من اليسار
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: InputBorder.none,
          // وضع الأيقونة في نهاية الحقل (جهة اليسار في RTL)
          suffixIcon: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Icon(icon, color: Colors.grey.shade600, size: 22),
          ),
        ),
      ),
    );
  }
}
