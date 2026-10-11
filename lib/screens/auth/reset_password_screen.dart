import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:dio/dio.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool get isAr => AppSettings.language.value == 'ar';

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  Future<void> _handleReset() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.isEmpty || confirm.isEmpty) {
      _showMessage(isAr ? 'يرجى إدخال كلمة المرور' : 'Please enter password', isError: true);
      return;
    }
    if (password.length < 8) {
      _showMessage(
        isAr ? 'كلمة المرور يجب أن تكون 8 أحرف على الأقل' : 'Password must be at least 8 characters',
        isError: true,
      );
      return;
    }
    if (password != confirm) {
      _showMessage(isAr ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Dio().post(
        '${ApiService().baseUrl}/reset-password',
        data: {
          'email':    widget.email,
          'otp':      widget.otp,
          'password': password,
        },
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        _showMessage(isAr ? 'تم تغيير كلمة المرور بنجاح!' : 'Password reset successfully!', isError: false);
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.data['message']?.toString() ??
          (isAr ? 'الرمز غير صحيح أو منتهي الصلاحية' : 'Code is invalid or expired');
      _showMessage(msg, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    const primaryYellow = Color(0xFFFFCC00);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            isAr ? 'تعيين كلمة مرور جديدة' : 'Reset New Password',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Cairo',
            ),
          ),
          leading: IconButton(
            icon: Icon(isAr ? Icons.arrow_back : Icons.arrow_forward, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(Icons.lock_reset_rounded,
                  size: 80,
                  color: isDark ? primaryYellow : const Color(0xFFD4AC0D)),
              const SizedBox(height: 25),
              Text(
                isAr ? 'أدخل كلمة المرور الجديدة' : 'Enter New Password',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 40),
              _buildField(
                controller: _passwordController,
                hint: '••••••••',
                label: isAr ? 'كلمة المرور الجديدة' : 'New Password',
                obscure: _obscurePassword,
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                isDark: isDark,
                textColor: textColor,
              ),
              const SizedBox(height: 20),
              _buildField(
                controller: _confirmController,
                hint: '••••••••',
                label: isAr ? 'تأكيد كلمة المرور' : 'Confirm Password',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                isDark: isDark,
                textColor: textColor,
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          isAr ? 'تغيير كلمة المرور' : 'Change Password',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Cairo',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required bool isDark,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: textColor.withValues(alpha: 0.7),
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.grey.withValues(alpha: 0.2)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            textAlign: isAr ? TextAlign.right : TextAlign.left,
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  TextStyle(color: Colors.grey.shade500, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 18),
              border: InputBorder.none,
              prefixIcon:
                  Icon(Icons.lock_outline, color: Colors.grey.shade600, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                    size: 20),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
