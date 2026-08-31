import 'package:edu_pridge_flutter/screens/admin/nav_bar/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/services/fcm_service.dart';
import 'dart:math';

import 'forgot_password_screen.dart';

import '../teacher/teacher_home.dart';
import '../student/nav_bar/student_home_screen.dart';
import '../parents/nav_bar/parent_home.dart';
import 'create_account_screen.dart';
import '../Head of department/nav_bar/boss_home.dart';
import '../Affairs_Officer/nav_bar/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('saved_username') ?? '';
    final savedPassword = prefs.getString('saved_password') ?? '';
    
    if (savedUsername.isNotEmpty && savedPassword.isNotEmpty) {
      setState(() {
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('device_id');
    if (id == null) {
      final rand = Random.secure();
      id = List.generate(32, (_) => rand.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await prefs.setString('device_id', id);
    }
    return id;
  }

  void _showDeviceConflictDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.devices_other_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text("تنبيه الحساب مقفل", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            "هذا الحساب مسجّل على جهاز آخر.\nلا يمكنك تسجيل الدخول إلا من جهازك الأساسي، أو تقديم طلب لشؤون الطلاب لفك القفل عن جهازك القديم.",
            style: TextStyle(fontSize: 14, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCC00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _showSubmitResetRequestDialog();
              },
              child: const Text("تقديم طلب فك القفل", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubmitResetRequestDialog() {
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("طلب فك قفل الجهاز", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("يرجى كتابة سبب طلب فك قفل الجهاز (إجباري):", style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "مثلاً: تم تغيير الجهاز / فقدان الهاتف السابق...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (reasonController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("سبب الطلب مطلوب إجبارياً")),
                            );
                            return;
                          }
                          setDialogState(() => isSubmitting = true);
                          try {
                            final deviceId = await _getDeviceId();
                            final response = await Dio().post(
                              "${ApiService().baseUrl}/request-device-reset",
                              data: {
                                "username":      _usernameController.text.trim(),
                                "password":      _passwordController.text,
                                "reason":        reasonController.text.trim(),
                                "new_device_id": deviceId,
                              },
                            );
                            if (mounted) Navigator.pop(context);
                            if (response.data != null && response.data['success'] == true) {
                              _showSnackBar(response.data['message'] ?? "تم إرسال الطلب بنجاح", isError: false);
                            } else {
                              _showSnackBar(response.data['message'] ?? "حدث خطأ أثناء إرسال الطلب", isError: true);
                            }
                          } catch (e) {
                            if (mounted) Navigator.pop(context);
                            String errorMsg = "حدث خطأ أثناء تقديم الطلب";
                            if (e is DioException && e.response?.data != null && e.response?.data['message'] != null) {
                              errorMsg = e.response?.data['message'];
                            }
                            _showSnackBar(errorMsg, isError: true);
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text("إرسال الطلب", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("يرجى إدخال البيانات المطلوبة", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      Dio dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 4), receiveTimeout: const Duration(seconds: 4)));
      String url = "${ApiService().baseUrl}/login";
      final deviceId = await _getDeviceId();

      var response = await dio.post(
        url,
        data: {
          "username":     _usernameController.text.trim(),
          "password":     _passwordController.text,
          "is_student":   true,
          "device_id":    deviceId,
          "device_token": deviceId,
        },
      );

      if (response != null && response.statusCode == 200 && response.data != null) {
        final prefs = await SharedPreferences.getInstance();
        final responseData = response.data;

        debugPrint("📥 استجابة السيرفر في اللوجن: $responseData");

        String token =
            responseData['token']?.toString() ??
                responseData['access_token']?.toString() ??
                responseData['data']?['token']?.toString() ??
                "";

        var userData = responseData['user'] ?? responseData['data']?['user'];

        if (token.isEmpty) {
          throw Exception("السيرفر رد بنجاح بس ما بعت التوكن!");
        }

        if (userData == null) {
          throw Exception("بيانات المستخدم مفقودة");
        }

        String userId =
            userData['user_id']?.toString() ?? userData['id']?.toString() ?? "";
        String displayName =
            userData['full_name']?.toString() ??
                userData['name']?.toString() ??
                "مستخدم";
        String role = userData['role']?.toString() ?? "student";

        if (userData['parent_id'] != null) {
          await prefs.setString('parent_id', userData['parent_id'].toString());
          debugPrint("✅ تم حفظ معرف الأب: ${userData['parent_id']}");
        }

        await prefs.remove('selected_student_id');
        await prefs.remove('selected_student_name');

        await prefs.setString('token', token);
        await prefs.setString('user_id', userId);
        await prefs.setString('user_name', displayName);
        await prefs.setString('user_role', role);
        await prefs.setString('role', role);
        final phone = userData['phone']?.toString() ?? '';
        if (phone.isNotEmpty) await prefs.setString('user_phone', phone);

        final telegramChatId = userData['telegram_chat_id']?.toString() ?? '';
        if (telegramChatId.isNotEmpty) await prefs.setString('telegram_chat_id', telegramChatId);

        if (_rememberMe) {
          await prefs.setString('saved_username', _usernameController.text.trim());
          await prefs.setString('saved_password', _passwordController.text);
        } else {
          await prefs.remove('saved_username');
          await prefs.remove('saved_password');
        }

        debugPrint("✅ تم حفظ التوكن بنجاح: $token");

        FcmService.sendTokenAfterLogin();

        if (!mounted) return;
        _showSnackBar(
          "تم تسجيل الدخول بنجاح، أهلاً بك $displayName",
          isError: false,
        );

        _navigateToDashboard(role);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409 || (e.response?.statusCode == 403 && e.response?.data != null && e.response?.data['device_locked'] == true)) {
        if (mounted) _showDeviceConflictDialog();
      } else {
        String msg = "تأكد من اتصال السيرفر";
        if (e.response?.data != null && e.response?.data is Map) {
          msg = e.response?.data['message']?.toString() ?? msg;
        }
        _showSnackBar(msg, isError: true);
      }
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
      nextScreen = const DeptHeadHomeScreen();
    } else if (r == 'affairs' || r == 'affairs_officer') {
      nextScreen = const AffairsOfficerHomeScreen();
    } else if (r == 'admin') {
      nextScreen = const AdminHomeScreen();
    } else {
      nextScreen = const StudentHomeScreen();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
      (_) => false,
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
    const primaryYellow = Color(0xFFFFCC00);
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
                          ? primaryYellow.withValues(alpha: 0.1)
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
                    "مرحباً بك في Edu-Bridge",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Text(
                    "سجل دخولك للمتابعة",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontFamily: 'Cairo',
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 45),

                  // حقل اسم المستخدم (رقم جامعي / هاتف / بريد)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "رقم الهاتف / الإيميل / الرقم الجامعي",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor.withValues(alpha: 0.7),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    hint: "أدخل رقم الهاتف أو الإيميل أو الرقم الجامعي",
                    icon: Icons.person_outline_rounded,
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
                        color: textColor.withValues(alpha: 0.7),
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: primaryYellow,
                            checkColor: Colors.black,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                          Text(
                            "تذكرني",
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
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
                    ],
                  ),

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
                        text: "ليس لديك حساب? ",
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
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
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
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
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.2),
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
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: isDark ? const Color(0xFFFFCC00) : const Color(0xFFD4AC0D),
              size: 24,
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