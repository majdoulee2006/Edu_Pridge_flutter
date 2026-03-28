import 'package:flutter/material.dart';
import '../teacher/teacher_home.dart';
import '../student/nav_bar/student_home_screen.dart';
import '../parents/nav_bar/parent_home.dart';
import 'forgot_password_screen.dart';
import 'create_account_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    // 🎨 استخراج ألوان الثيم
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey;
    final primaryYellow = const Color(0xFFEFFF00);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 50),

                // 1. الشعار (الأيقونة العلوية)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.amber.withValues(alpha: 0.1)
                          : const Color(0xFFFEF9E7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.school_outlined,
                      size: 50,
                      color: isDark ? primaryYellow : const Color(0xFFD4AC0D),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 2. نصوص الترحيب
                Text(
                  "مرحباً بك مجدداً",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "بوابة المعهد الجامعي للطلاب والمعلمين",
                  style: TextStyle(fontSize: 14, color: subTextColor),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // 3. حقول الإدخال
                _buildTextField(
                  context,
                  label: "اسم المستخدم",
                  hint: "أدخل اسم المستخدم",
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  context,
                  label: "رقم الهاتف",
                  hint: "05x xxx xxxx",
                  icon: Icons.phone_iphone_outlined,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  context,
                  label: "كلمة المرور",
                  hint: "........",
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),

                const SizedBox(height: 10),

                // 4. زر هل نسيت كلمة المرور
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                      );
                    },
                    child: Text(
                      "هل نسيت كلمة المرور؟",
                      style: TextStyle(
                        color: isDark ? primaryYellow : const Color(0xFFA4A000),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 5. زر تسجيل الدخول الأساسي
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const TeacherHomeScreen()),
                          (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 55),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login_rounded, size: 22),
                      SizedBox(width: 10),
                      Text("تسجيل الدخول", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 6. الفاصل (أو / OR)
                Row(
                  children: [
                    Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.grey.shade300, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Text("أو", style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.grey.shade300, thickness: 1)),
                  ],
                ),

                const SizedBox(height: 30),

                // 7. زر إنشاء حساب جديد
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateAccountScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    "إنشاء حساب جديد",
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),

                const SizedBox(height: 40),
                Divider(color: isDark ? Colors.white10 : Colors.grey.shade200),
                Text("اختصارات للمطورين (للتجربة فقط):", style: TextStyle(color: subTextColor, fontSize: 12)),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _devButton("دخول كطالب", Colors.green, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentHomeScreen()))),
                    _devButton("دخول كمدرب", Colors.blue, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherHomeScreen()))),
                    _devButton("دخول كولي أمر", Colors.orange, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsHomeScreen()))),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _devButton(String title, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      onPressed: onPressed,
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }

  Widget _buildTextField(
      BuildContext context, {
        required String label,
        required String hint,
        required IconData icon,
        bool isPassword = false,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 15, bottom: 8),
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.3)),
          ),
          child: TextField(
            obscureText: isPassword ? _obscurePassword : false,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: InputBorder.none,
              suffixIcon: Icon(icon, color: Colors.grey.shade500, size: 22),
              prefixIcon: isPassword
                  ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}