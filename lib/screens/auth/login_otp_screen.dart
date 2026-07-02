import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../student/nav_bar/student_home_screen.dart';
import '../teacher/teacher_home.dart';
import '../parents/nav_bar/parent_home.dart';
import '../Head of department/nav_bar/boss_home.dart';
import '../admin/nav_bar/home_screen.dart';

class LoginOtpScreen extends StatefulWidget {
  const LoginOtpScreen({super.key});

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen> {
  final _phoneController = TextEditingController();
  String _selectedCode = '+963';
  bool _isLoading = false;

  static String get _base => ApiService().baseUrl;

  final List<Map<String, String>> _countries = [
    {'code': '+963', 'flag': '🇸🇾', 'name': 'سوريا'},
    {'code': '+966', 'flag': '🇸🇦', 'name': 'السعودية'},
    {'code': '+971', 'flag': '🇦🇪', 'name': 'الإمارات'},
    {'code': '+962', 'flag': '🇯🇴', 'name': 'الأردن'},
    {'code': '+961', 'flag': '🇱🇧', 'name': 'لبنان'},
    {'code': '+20',  'flag': '🇪🇬', 'name': 'مصر'},
    {'code': '+965', 'flag': '🇰🇼', 'name': 'الكويت'},
    {'code': '+974', 'flag': '🇶🇦', 'name': 'قطر'},
    {'code': '+968', 'flag': '🇴🇲', 'name': 'عُمان'},
    {'code': '+973', 'flag': '🇧🇭', 'name': 'البحرين'},
  ];

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 7) {
      _showSnack("يرجى إدخال رقم هاتف صحيح", isError: true);
      return;
    }

    final fullPhone = '$_selectedCode$phone';
    setState(() => _isLoading = true);

    try {
      final response = await Dio().post(
        '$_base/login-otp/send',
        data: {'phone': fullPhone},
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      final email = response.data['email']?.toString() ?? '';
      if (!mounted) return;

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => _OtpVerifyScreen(
            email: email,
            phone: fullPhone,
            selectedCode: _selectedCode,
          ),
        ),
      );

      if (result == true && mounted) Navigator.pop(context);
    } on DioException catch (e) {
      final msg = e.response?.data['message']?.toString() ??
          'حدث خطأ، تأكد من رقم الهاتف';
      _showSnack(msg, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14)),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  void _showCountryPicker(BuildContext ctx, Color textColor, bool isDark) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text("اختر كود الدولة",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                    fontFamily: 'Cairo')),
            const SizedBox(height: 8),
            const Divider(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: _countries.map((c) {
                  final selected = c['code'] == _selectedCode;
                  return ListTile(
                    leading: Text(c['flag']!,
                        style: const TextStyle(fontSize: 24)),
                    title: Text("${c['name']} (${c['code']})",
                        style: TextStyle(
                            color: textColor,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontFamily: 'Cairo')),
                    trailing: selected
                        ? const Icon(Icons.check_circle_rounded,
                            color: Color(0xFFFFCC00))
                        : null,
                    onTap: () {
                      setState(() => _selectedCode = c['code']!);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.shade100;
    const yellow = Color(0xFFFFCC00);

    final selectedCountry =
        _countries.firstWhere((c) => c['code'] == _selectedCode);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text("الدخول برمز التحقق",
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Cairo')),
          leading: IconButton(
            icon: Icon(Icons.arrow_forward, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 36),

              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? yellow.withValues(alpha: 0.12)
                      : const Color(0xFFFEF9E7),
                  boxShadow: [
                    BoxShadow(
                      color: yellow.withValues(alpha: isDark ? 0.2 : 0.35),
                      blurRadius: 35, spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(Icons.telegram_rounded,
                    size: 52,
                    color: isDark ? yellow : const Color(0xFFD4AC0D)),
              ),

              const SizedBox(height: 28),

              Text("الدخول برمز تيليغرام",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'Cairo')),
              const SizedBox(height: 10),
              Text(
                "أدخل رقم هاتفك المسجّل\nسيصلك رمز التحقق عبر @edubridge_otp_bot",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: subColor,
                    height: 1.6,
                    fontFamily: 'Cairo'),
              ),

              const SizedBox(height: 44),

              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4, bottom: 8),
                  child: Text("رقم الجوال",
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textColor,
                          fontFamily: 'Cairo')),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          _showCountryPicker(context, textColor, isDark),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(selectedCountry['flag']!,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 6),
                            Text(_selectedCode,
                                style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded,
                                color: subColor, size: 18),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: textColor, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: "912 345 678",
                            hintStyle: TextStyle(
                                color: textColor.withValues(alpha: 0.35),
                                fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Colors.blue.shade400, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "يجب أن يكون رقمك مسجّلاً في حسابك ومربوطاً بـ Chat ID تيليغرام",
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade400,
                            fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    disabledBackgroundColor: yellow.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2.5))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded,
                                color: Colors.black, size: 20),
                            SizedBox(width: 10),
                            Text("إرسال رمز التحقق",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    fontFamily: 'Cairo')),
                          ],
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

// ── شاشة إدخال الـ OTP بعد إرساله ──
class _OtpVerifyScreen extends StatefulWidget {
  final String email;
  final String phone;
  final String selectedCode;

  const _OtpVerifyScreen({
    required this.email,
    required this.phone,
    required this.selectedCode,
  });

  @override
  State<_OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<_OtpVerifyScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  int _secondsLeft = 300; // 5 دقائق
  bool _canResend = false;

  static String get _base => ApiService().baseUrl;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsLeft = 300;
      _canResend = false;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _canResend = true;
        }
      });
      return _secondsLeft > 0;
    });
  }

  String get _timerText {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _otp =>
      _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length < 6) {
      _showSnack("يرجى إدخال الرمز كاملاً", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await Dio().post(
        '$_base/login-otp/verify',
        data: {'email': widget.email, 'otp': _otp},
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      final token    = response.data['token']?.toString() ?? '';
      final userData = response.data['user'];

      if (token.isEmpty || userData == null) {
        _showSnack("حدث خطأ في الاستجابة", isError: true);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token',     token);
      await prefs.setString('user_id',   userData['id']?.toString() ?? '');
      await prefs.setString('user_name', userData['name']?.toString() ?? '');
      await prefs.setString('user_role', userData['role']?.toString() ?? '');
      await prefs.setString('role',      userData['role']?.toString() ?? '');
      if (userData['parent_id'] != null) {
        await prefs.setString('parent_id', userData['parent_id'].toString());
      }

      if (!mounted) return;
      _navigateToDashboard(userData['role']?.toString() ?? '');
    } on DioException catch (e) {
      final msg = e.response?.data['message']?.toString() ??
          'الرمز غير صحيح أو منتهي الصلاحية';
      _showSnack(msg, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await Dio().post(
        '$_base/login-otp/send',
        data: {'phone': widget.phone},
        options: Options(headers: {'Accept': 'application/json'}),
      );
      _startTimer();
      _showSnack("تم إعادة إرسال الرمز", isError: false);
      for (final c in _controllers) { c.clear(); }
      _focusNodes[0].requestFocus();
    } on DioException catch (e) {
      _showSnack(
          e.response?.data['message']?.toString() ?? 'حدث خطأ',
          isError: true);
    }
  }

  void _navigateToDashboard(String role) {
    final r = role.toLowerCase();
    Widget next;
    if (r == 'parent') {
      next = const ParentsHomeScreen();
    } else if (r == 'teacher') {
      next = const TeacherHomeScreen();
    } else if (r == 'boss' || r == 'head' || r == 'department_head') {
      next = const DeptHeadHomeScreen();
    } else if (r == 'admin') {
      next = const AdminHomeScreen();
    } else {
      next = const StudentHomeScreen();
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => next),
      (_) => false,
    );
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14)),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    const yellow = Color(0xFFFFCC00);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text("أدخل رمز التحقق",
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Cairo')),
          leading: IconButton(
            icon: Icon(Icons.arrow_forward, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            children: [
              const SizedBox(height: 36),

              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? yellow.withValues(alpha: 0.12)
                      : const Color(0xFFFEF9E7),
                  boxShadow: [
                    BoxShadow(
                      color: yellow.withValues(alpha: isDark ? 0.2 : 0.35),
                      blurRadius: 35, spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(Icons.verified_user_rounded,
                    size: 48,
                    color: isDark ? yellow : const Color(0xFFD4AC0D)),
              ),

              const SizedBox(height: 24),

              Text("تحقق من هويتك",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'Cairo')),
              const SizedBox(height: 10),
              Text(
                "تم إرسال رمز مكون من 6 أرقام\nعبر تيليغرام (@edubridge_otp_bot)",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: subColor,
                    height: 1.6,
                    fontFamily: 'Cairo'),
              ),

              const SizedBox(height: 40),

              // ── حقول الـ OTP ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: 46,
                    height: 56,
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: yellow, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && i < 5) {
                          _focusNodes[i + 1].requestFocus();
                        } else if (val.isEmpty && i > 0) {
                          _focusNodes[i - 1].requestFocus();
                        }
                        if (i == 5 && val.isNotEmpty) _verify();
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 30),

              // ── العداد ──
              Text(
                _canResend ? "انتهت صلاحية الرمز" : "الرمز صالح لـ $_timerText",
                style: TextStyle(
                    fontSize: 13,
                    color: _canResend ? Colors.redAccent : subColor,
                    fontFamily: 'Cairo'),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: _canResend ? _resend : null,
                child: Text(
                  "إعادة إرسال الرمز",
                  style: TextStyle(
                      color: _canResend ? yellow : subColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo'),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    disabledBackgroundColor: yellow.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2.5))
                      : const Text("تأكيد الدخول",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              fontFamily: 'Cairo')),
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
