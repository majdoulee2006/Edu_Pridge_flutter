import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'otp_screen.dart';

class EditEmailScreen extends StatefulWidget {
  const EditEmailScreen({super.key});

  @override
  State<EditEmailScreen> createState() => _EditEmailScreenState();
}

class _EditEmailScreenState extends State<EditEmailScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String _telegramChatId = '';

  static String get _base => ApiService().baseUrl;

  @override
  void initState() {
    super.initState();
    _loadTelegramId();
  }

  Future<void> _loadTelegramId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _telegramChatId = prefs.getString('telegram_chat_id') ?? '');
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _handleSendOtp() async {
    final newEmail = _emailController.text.trim();

    if (newEmail.isEmpty) {
      _showSnack("يرجى إدخال البريد الإلكتروني الجديد", isError: true);
      return;
    }
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(newEmail)) {
      _showSnack("يرجى إدخال بريد إلكتروني صحيح", isError: true);
      return;
    }
    if (_telegramChatId.isEmpty) {
      _showSnack("لم يتم العثور على Chat ID — سجّل الدخول من جديد", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = await _getToken();

      await Dio().post(
        '$_base/profile/send-otp',
        data: {'telegram_chat_id': _telegramChatId},
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      if (!mounted) return;

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => OTPScreen(
            appBarTitle: "تأكيد البريد الجديد",
            message: "تم إرسال رمز التحقق عبر تيليغرام\nأدخله لتأكيد بريدك الجديد",
            icon: Icons.mark_email_read_outlined,
            onVerify: (otp) async {
              final t = await _getToken();
              try {
                // تحقق من OTP
                await Dio().post(
                  '$_base/profile/verify-otp',
                  data: {'otp': otp},
                  options: Options(headers: {
                    'Authorization': 'Bearer $t',
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                  }),
                );
                // OTP صحيح — حدّث الإيميل مباشرةً
                await Dio().post(
                  '$_base/profile/update',
                  data: {'email': newEmail},
                  options: Options(headers: {
                    'Authorization': 'Bearer $t',
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                  }),
                );
                return null;
              } on DioException catch (e) {
                return e.response?.data['message']?.toString() ??
                    'الرمز غير صحيح أو منتهي الصلاحية';
              }
            },
            onResend: () async {
              final t = await _getToken();
              await Dio().post(
                '$_base/profile/send-otp',
                data: {'telegram_chat_id': _telegramChatId},
                options: Options(headers: {
                  'Authorization': 'Bearer $t',
                  'Accept': 'application/json',
                }),
              );
            },
          ),
        ),
      );

      if (result == true && mounted) {
        _showSnack("تم تغيير البريد الإلكتروني بنجاح ✓", isError: false);
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      final msg = e.response?.data['message']?.toString() ??
          'حدث خطأ أثناء إرسال رمز التحقق';
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

  @override
  void dispose() {
    _emailController.dispose();
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text("تعديل البريد الإلكتروني",
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Cairo')),
          leading: IconButton(
            icon: Icon(Icons.arrow_forward,
                color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 36),

              // ── أيقونة مضيئة ──
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? yellow.withValues(alpha: 0.12)
                      : const Color(0xFFFEF9E7),
                  boxShadow: [
                    BoxShadow(
                      color: yellow.withValues(alpha: isDark ? 0.2 : 0.35),
                      blurRadius: 35,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(Icons.email_rounded,
                    size: 52,
                    color: isDark ? yellow : const Color(0xFFD4AC0D)),
              ),

              const SizedBox(height: 28),

              Text("تغيير البريد الإلكتروني",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'Cairo')),
              const SizedBox(height: 10),
              Text(
                "سيتم إرسال رمز تحقق مكون من 6 أرقام\nعبر تيليغرام (@edubridge_otp_bot)",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: subColor,
                    height: 1.6,
                    fontFamily: 'Cairo'),
              ),

              const SizedBox(height: 44),

              // ── حقل الإيميل ──
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4, bottom: 8),
                  child: Text("البريد الإلكتروني الجديد",
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
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontFamily: 'Cairo'),
                  decoration: InputDecoration(
                    hintText: "example@mail.com",
                    hintStyle: TextStyle(
                        color: textColor.withValues(alpha: 0.35),
                        fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.alternate_email_rounded,
                        color: isDark ? yellow : const Color(0xFFD4AC0D),
                        size: 22),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── تنبيه تيليغرام ──
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.telegram_rounded,
                        color: Colors.blue.shade400, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "سيصلك رمز التحقق عبر تيليغرام (@edubridge_otp_bot)",
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

              // ── زر إرسال OTP ──
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
                          width: 24,
                          height: 24,
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
