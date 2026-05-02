import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// استيراد الملف الجديد (تأكدي أن اسم الملف forgot_password_screen.dart صحيح في مشروعك)
import 'forgot_password_screen.dart';

import '../teacher/teacher_home.dart';
import '../student/nav_bar/student_home_screen.dart';
import '../parents/nav_bar/parent_home.dart';
import 'create_account_screen.dart';
import '../Head of department/nav_bar/boss_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isStudent = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("يرجى إدخال البيانات المطلوبة", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      Dio dio = Dio();
      String url = "http://127.0.0.1:8000/api/login";

      var response = await dio.post(
        url,
        data: {
          "login": _usernameController.text
              .trim(), // 👈 تم التعديل من username إلى login
          "password": _passwordController.text,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final prefs = await SharedPreferences.getInstance();
        final responseData = response.data;

        // 💡 تشخيص: لنشوف شو الداتا اللي رجعها السيرفر بالضبط
        debugPrint("📥 استجابة السيرفر في اللوجن: $responseData");

        // 🌟 الحل الجذري: صيد التوكن بأي اسم بيرجعه اللارافل
        String token =
            responseData['token']?.toString() ??
            responseData['access_token']?.toString() ??
            responseData['data']?['token']?.toString() ??
            "";

        // 🌟 صيد بيانات اليوزر بشكل مرن (أحياناً بتكون جوا data وأحياناً برا)
        var userData = responseData['user'] ?? responseData['data']?['user'];

        if (token.isEmpty) {
          throw Exception("السيرفر رد بنجاح بس ما بعت التوكن!");
        }

        if (userData == null) {
          throw Exception("بيانات المستخدم مفقودة");
        }

        // 💡 استخراج البيانات وتجهيزها
        String userId =
            userData['user_id']?.toString() ?? userData['id']?.toString() ?? "";
        String displayName =
            userData['full_name']?.toString() ??
            userData['name']?.toString() ??
            "مستخدم";
        String role = userData['role']?.toString() ?? "student";

        // ✨ إذا كان المستخدم ولي أمر
        if (userData['parent_id'] != null) {
          await prefs.setInt('parent_id', userData['parent_id']);
          debugPrint("✅ تم حفظ معرف الأب: ${userData['parent_id']}");
        }

        // مسح بيانات الابن المختار سابقاً
        await prefs.remove('selected_student_id');
        await prefs.remove('selected_student_name');

        // 💾 حفظ البيانات الأساسية بالذاكرة
        await prefs.setString('token', token);
        await prefs.setString('user_id', userId);
        await prefs.setString('user_name', displayName);
        await prefs.setString('user_role', role);

        debugPrint("✅ تم حفظ التوكن بنجاح: $token");

        if (!mounted) return;
        _showSnackBar(
          "تم تسجيل الدخول بنجاح، أهلاً بك $displayName",
          isError: false,
        );

        _navigateToDashboard(role);
      }
    } on DioException catch (e) {
      // إظهار رسالة الخطأ القادمة من الباك-إند (مثل: بيانات الدخول غير صحيحة)
      String msg =
          e.response?.data['message']?.toString() ?? "تأكد من اتصال السيرفر";
      _showSnackBar(msg, isError: true);
    } catch (e) {
      debugPrint("🚨 Error: $e");
      _showSnackBar("حدث خطأ تقني: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToDashboard(String role) {
    Widget nextScreen;
    String r = role.toLowerCase();

    if (r == 'parent') {
      nextScreen = const ParentsHomeScreen();
    } else if (r == 'teacher') {
      nextScreen = const TeacherHomeScreen();
    } else if (r == 'boss' || r == 'head' || r == 'department_head') {
      // 👈 أضفنا 'head' لتطابق السيدر
      nextScreen = DeptHeadHomeScreen();
    } else {
      nextScreen = const StudentHomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryYellow = Color(0xFFEFFF00);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? primaryYellow.withOpacity(0.1)
                          : const Color(0xFFFEF9E7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.school_outlined,
                      size: 60,
                      color: isDark ? primaryYellow : const Color(0xFFD4AC0D),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    _isStudent ? "أهلاً عزيزي الطالب" : "مرحباً بك مجدداً",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const Text(
                    "سجل دخولك للمتابعة في Edu_Bridge",
                    style: TextStyle(color: Colors.grey, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 45),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isStudent ? "الرقم الجامعي" : "اسم المستخدم / الإيميل",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: textColor.withOpacity(0.7),
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            "طالب",
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: textColor.withOpacity(0.5),
                            ),
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: _isStudent,
                              activeColor: primaryYellow,
                              onChanged: (value) =>
                                  setState(() => _isStudent = value),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  _buildTextField(
                    hint: _isStudent
                        ? "أدخل رقمك الجامعي"
                        : "أدخل اسم المستخدم أو الإيميل",
                    icon: _isStudent
                        ? Icons.badge_outlined
                        : Icons.alternate_email,
                    controller: _usernameController,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "كلمة المرور",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor.withOpacity(0.7),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    hint: "********",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    controller: _passwordController,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 15),

                  // ================= تم التعديل هنا =================
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        // الانتقال لصفحة استعادة كلمة السر
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "نسيت كلمة المرور؟",
                        style: TextStyle(
                          color: primaryYellow,
                          fontSize: 12,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ),

                  // =================================================
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryYellow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              "تسجيل الدخول",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontFamily: 'Cairo',
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateAccountScreen(),
                      ),
                    ),
                    child: Text.rich(
                      TextSpan(
                        text: "ليس لديك حساب؟ ",
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontFamily: 'Cairo',
                        ),
                        children: const [
                          TextSpan(
                            text: "إنشاء حساب جديد",
                            style: TextStyle(
                              color: primaryYellow,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  const Divider(),
                  const Center(
                    child: Text(
                      "أدوات المطور - دخول سريع",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDevButton(
                          "رئيس قسم",
                          Icons.admin_panel_settings,
                          () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DeptHeadHomeScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 15),
                        _buildDevButton("معلم", Icons.person_pin, () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TeacherHomeScreen(),
                            ),
                          );
                        }),
                        const SizedBox(width: 15),
                        _buildDevButton("طالب", Icons.school, () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StudentHomeScreen(),
                            ),
                          );
                        }),
                        const SizedBox(width: 15),
                        _buildDevButton("أهل", Icons.family_restroom, () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ParentsHomeScreen(),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDevButton(String title, IconData icon, VoidCallback onTap) {
    return Column(
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.orangeAccent),
          style: IconButton.styleFrom(
            backgroundColor: Colors.orangeAccent.withOpacity(0.1),
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required bool isDark,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
        ),
      ),
    );
  }
}
