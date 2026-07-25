import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:dio/dio.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSendOtp() async {
    final email = _inputController.text.trim();
    if (email.isEmpty) {
      _showSnack('يرجى إدخال البريد الإلكتروني');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Dio().post(
        '${ApiService().baseUrl}/forgot-password',
        data: {'email': email},
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OTPScreen(
            email: email,
            appBarTitle: 'تحقق من بريدك',
            message: 'تم إرسال رمز التحقق إلى بريدك الإلكتروني',
            isPasswordReset: true,
          ),
        ),
      );
    } on DioException catch (e) {
      final msg = e.response?.data['message']?.toString() ??
          'البريد الإلكتروني غير مسجّل لدينا';
      _showSnack(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white;
    const primaryYellow = Color(0xFFFFCC00);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text('نسيت كلمة السر',
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Cairo')),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFFEF9E7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_reset_rounded,
                      size: 45,
                      color: isDark
                          ? primaryYellow
                          : const Color(0xFFD4AC0D)),
                ),
              ),
              const SizedBox(height: 30),
              Text('استعادة كلمة المرور',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'Cairo')),
              const SizedBox(height: 12),
              Text(
                'يرجى إدخال بريدك الإلكتروني المسجل لدينا لنرسل لك رمز التحقق.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: subTextColor,
                    height: 1.5,
                    fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 45),
              _buildInputField(textColor, cardColor, subTextColor),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('متابعة',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: 'Cairo')),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء والعودة',
                    style: TextStyle(
                        color: subTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
      Color textColor, Color cardColor, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 15, bottom: 8),
          child: Text('البريد الإلكتروني',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textColor,
                  fontFamily: 'Cairo')),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: textColor.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: _inputController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'example@mail.com',
              hintStyle: TextStyle(
                  color: textColor.withValues(alpha: 0.3),
                  fontSize: 13,
                  fontFamily: 'Cairo'),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.email_outlined,
                  color: subTextColor, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}
