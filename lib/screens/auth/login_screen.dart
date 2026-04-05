import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../teacher/teacher_home.dart';
import '../student/nav_bar/student_home_screen.dart';
import 'create_account_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  // 🌟 خيار الطالب
  bool _isStudent = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("يرجى إدخال البيانات المطلوبة");
      return;
    }

    setState(() => _isLoading = true);

    try {
      Dio dio = Dio();
      String url = "http://127.0.0.1:8000/api/login";

      var response = await dio.post(
        url,
        data: {
          "username": _usernameController.text.trim(),
          "password": _passwordController.text,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final prefs = await SharedPreferences.getInstance();
        String token = response.data['access_token']?.toString() ?? "";
        var userData = response.data['user'];
        String displayName = userData != null ? userData['name']?.toString() ?? "مستخدم" : "مستخدم";
        String role = userData != null ? userData['role']?.toString() ?? "student" : "student";

        await prefs.setString('token', token);
        await prefs.setString('user_name', displayName);
        await prefs.setString('user_role', role);

        if (!mounted) return;
        _navigateToDashboard(role);
      }
    } on DioException catch (e) {
      String msg = e.response?.data['message']?.toString() ?? "تأكد من صحة البيانات";
      _showError(msg);
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
    } else {
      nextScreen = const StudentHomeScreen();
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => nextScreen));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 50),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.amber.withOpacity(0.1) : const Color(0xFFFEF9E7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.school_outlined, size: 50, color: isDark ? primaryYellow : const Color(0xFFD4AC0D)),
                  ),
                ),
                const SizedBox(height: 20),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _isStudent ? "أهلاً عزيزي الطالب" : "مرحباً بك مجدداً",
                    key: ValueKey<bool>(_isStudent),
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Cairo'),
                  ),
                ),

                const Text("سجل دخولك للمتابعة في Edu_Pridge", style: TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
                const SizedBox(height: 40),

                // 🌟 حقل التبديل (بدون مربع خلفية)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                        padding: const EdgeInsets.only(right: 15),
                        child: Text(_isStudent ? "الرقم الجامعي" : "اسم المستخدم",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, fontFamily: 'Cairo'))
                    ),
                    // 🌟 كلمة طالب والـ Switch بدون خلفية
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("طالب", style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
                        Transform.scale(
                          scale: 0.65,
                          child: Switch(
                            value: _isStudent,
                            activeColor: primaryYellow,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: (value) {
                              setState(() {
                                _isStudent = value;
                                _usernameController.clear();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                _buildTextFieldOnly(
                  hint: _isStudent ? "أدخل رقمك الجامعي" : "الايميل أو رقم الهاتف",
                  icon: _isStudent ? Icons.badge_outlined : Icons.person_outline,
                  controller: _usernameController,
                  isDark: isDark,
                ),

                const SizedBox(height: 20),

                Padding(
                    padding: const EdgeInsets.only(right: 15, bottom: 8),
                    child: Text("كلمة المرور", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, fontFamily: 'Cairo'))
                ),
                _buildTextFieldOnly(
                  hint: "********",
                  icon: Icons.lock_outline,
                  isPassword: true,
                  controller: _passwordController,
                  isDark: isDark,
                ),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text("تسجيل الدخول", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateAccountScreen())),
                  child: Text("ليس لديك حساب؟ إنشاء حساب جديد",
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontFamily: 'Cairo')),
                ),

                const SizedBox(height: 40),
                const Divider(),
                const Text("أدوات العرض - دخول سريع", style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo')),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDevButton("معلم", Icons.person_pin, () => _navigateToDashboard('teacher')),
                    _buildDevButton("طالب", Icons.school, () => _navigateToDashboard('student')),
                    _buildDevButton("أهل", Icons.family_restroom, () => _navigateToDashboard('parent')),
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

  Widget _buildDevButton(String title, IconData icon, VoidCallback onTap) {
    return Column(
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.orangeAccent),
          style: IconButton.styleFrom(backgroundColor: Colors.orangeAccent.withOpacity(0.1), padding: const EdgeInsets.all(12)),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo')),
      ],
    );
  }

  Widget _buildTextFieldOnly({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required bool isDark,
    bool isPassword = false
  }) {
    return Container(
      decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.3))
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 22),
          suffixIcon: isPassword
              ? IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword)
          )
              : null,
        ),
      ),
    );
  }
}