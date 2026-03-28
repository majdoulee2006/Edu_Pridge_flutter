import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; // ✅ للربط مع الباكيند
import 'package:shared_preferences/shared_preferences.dart'; // ✅ لحفظ البيانات
import '../teacher/teacher_home.dart';
import '../student/nav_bar/student_home_screen.dart';
import 'forgot_password_screen.dart';
import 'create_account_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false; // ✅ حالة التحميل

  // ✅ تعريف المتحكمات (Controllers) لسحب النصوص من الحقول
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ✅ دالة تسجيل الدخول والربط مع API
  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("يرجى إدخال البريد وكلمة المرور");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // نستخدم 127.0.0.1 لأنكِ تعملين على الويب
      var response = await Dio().post(
        "http://127.0.0.1:8000/api/login",
        data: {
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        // حفظ التوكن والاسم
        await prefs.setString('token', response.data['access_token']);
        await prefs.setString('user_name', response.data['user']['full_name']);

        String role = response.data['user']['role'];

        if (!mounted) return;

        // التوجيه التلقائي حسب الرول القادم من قاعدة البيانات
        if (role == 'parent') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsHomeScreen()));
        } else if (role == 'teacher') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherHomeScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentHomeScreen()));
        }
      }
    } on DioException catch (e) {
      String msg = e.response?.data['message'] ?? "فشل الاتصال بالسيرفر";
      _showError(msg);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, textAlign: TextAlign.center)));
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 دعم الـ Dark Mode بجلب ألوان الثيم
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryYellow = const Color(0xFFEFFF00);
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scaffoldBg, // ✅ يتغير حسب المود
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 50),

                // 1. الشعار
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.amber.withOpacity(0.1) : const Color(0xFFFEF9E7),
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
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 8),
                const Text(
                  "بوابة المعهد الجامعي للطلاب والمعلمين",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // 3. حقول الإدخال (تم ربط الـ Controllers)
                _buildTextField(
                  label: "البريد الإلكتروني", // الباكيند يعتمد الإيميل
                  hint: "example@test.com",
                  icon: Icons.email_outlined,
                  controller: _emailController,
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: "كلمة المرور",
                  hint: "........",
                  icon: Icons.lock_outline,
                  isPassword: true,
                  controller: _passwordController,
                  isDark: isDark,
                ),

                const SizedBox(height: 10),

                // 4. زر هل نسيت كلمة المرور
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
                    child: Text(
                      "هل نسيت كلمة المرور؟",
                      style: TextStyle(color: isDark ? primaryYellow : const Color(0xFFA4A000), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 5. زر تسجيل الدخول الأساسي (تم ربط الدالة البرمجية)
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 55),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login, size: 22, color: Colors.black),
                      SizedBox(width: 10),
                      Text("تسجيل الدخول", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 6. الفاصل
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.withOpacity(0.3), thickness: 1)),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Text("أو", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                    Expanded(child: Divider(color: Colors.grey.withOpacity(0.3), thickness: 1)),
                  ],
                ),

                const SizedBox(height: 30),

                // 7. زر إنشاء حساب جديد
                OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateAccountScreen())),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    "إنشاء حساب جديد",
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ تعديل الويجت ليدعم الـ Dark Mode والـ Controller
  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required bool isDark,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 15, bottom: 8),
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.3)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword ? _obscurePassword : false,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: InputBorder.none,
              suffixIcon: Icon(icon, color: Colors.grey.shade600, size: 22),
              prefixIcon: isPassword
                  ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey.shade400,
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