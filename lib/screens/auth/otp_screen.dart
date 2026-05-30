import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

class OTPScreen extends StatefulWidget {
  final String email;
  final String appBarTitle;
  final String message;
  final bool isPasswordReset;

  const OTPScreen({
    super.key,
    required this.email,
    this.appBarTitle = "التحقق من الحساب",
    this.message = "تم إرسال رمز التحقق إلى بريدك الإلكتروني",
    this.isPasswordReset = false,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  int _counter = 59;
  Timer? _timer;
  bool _isLoading = false;
  bool _isResending = false;

  // 6 مربعات OTP
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _counter = 59);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_counter > 0) {
        if (mounted) setState(() => _counter--);
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _handleVerifyOtp() async {
    final otpCode =
        _controllers.map((c) => c.text).join().trim();

    if (otpCode.length < 6) {
      _showMessage("يرجى إدخال الرمز كاملاً (6 أرقام)", isError: true);
      return;
    }

    // وضع استعادة كلمة السر: روح مباشرة لشاشة إعادة التعيين بدون استدعاء API
    if (widget.isPasswordReset) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            email: widget.email,
            otp: otpCode,
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Dio().post(
        "${ApiService().baseUrl}/verify-otp",
        data: {"email": widget.email, "otp": otpCode},
        options: Options(headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        }),
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        _showMessage("تم التحقق بنجاح!", isError: false);
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.data['message']?.toString() ??
          "الرمز الذي أدخلته غير صحيح";
      _showMessage(msg, isError: true);
    } catch (e) {
      debugPrint("OTP verify error: $e");
      _showMessage("حدث خطأ تقني، حاول مجدداً", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResend() async {
    setState(() => _isResending = true);
    try {
      await Dio().post(
        "${ApiService().baseUrl}/resend-otp",
        data: {"email": widget.email},
        options: Options(headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        }),
      );
      _showMessage("تم إعادة إرسال الرمز إلى بريدك", isError: false);
      _startTimer();
      for (var c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    } on DioException catch (e) {
      final msg =
          e.response?.data['message']?.toString() ?? "تعذّر إعادة الإرسال";
      _showMessage(msg, isError: true);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    const primaryYellow = Color(0xFFFFCC00);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(widget.appBarTitle,
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'Cairo')),
        leading: IconButton(
            icon: Icon(Icons.arrow_forward, color: textColor),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Icon(Icons.mark_email_read_outlined,
                  size: 80,
                  color: isDark ? primaryYellow : const Color(0xFFD4AC0D)),
              const SizedBox(height: 30),
              Text("أدخل رمز التحقق",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'Cairo')),
              const SizedBox(height: 15),
              Text(
                "${widget.message}\n${widget.email}",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                    height: 1.6,
                    fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 40),

              // ── 6 مربعات OTP ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (i) => _otpBox(i, isDark)),
              ),

              const SizedBox(height: 30),
              _buildResendSection(isDark, primaryYellow, textColor),
              const SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text("تأكيد الرمز",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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

  Widget _buildResendSection(bool isDark, Color primaryYellow, Color textColor) {
    return Column(
      children: [
        Text("لم يصلك الرمز؟",
            style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 13,
                fontFamily: 'Cairo')),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isResending)
              const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFFFFCC00)))
            else
              TextButton(
                onPressed: _counter == 0 ? _handleResend : null,
                child: Text(
                  "إعادة إرسال الرمز",
                  style: TextStyle(
                      color: _counter == 0
                          ? (isDark ? primaryYellow : Colors.black)
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo'),
                ),
              ),
            const SizedBox(width: 5),
            Text(
              "00:${_counter.toString().padLeft(2, '0')}",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _otpBox(int index, bool isDark) {
    return SizedBox(
      height: 60,
      width: 48,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _controllers[index].text.isNotEmpty
                ? const Color(0xFFFFCC00)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          autofocus: index == 0,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black),
          decoration: const InputDecoration(
              counterText: "", border: InputBorder.none),
          onChanged: (value) {
            if (value.isNotEmpty && index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else if (value.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
            setState(() {});
          },
        ),
      ),
    );
  }
}
