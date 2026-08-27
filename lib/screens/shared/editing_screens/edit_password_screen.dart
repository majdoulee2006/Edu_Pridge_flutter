import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/utils/network_helper.dart';
import 'otp_screen.dart';

class EditPasswordScreen extends StatefulWidget {
  const EditPasswordScreen({super.key});

  @override
  State<EditPasswordScreen> createState() => _EditPasswordScreenState();
}

class _EditPasswordScreenState extends State<EditPasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  final _chatIdController = TextEditingController();
  bool _isLoading = false;

  static String get _base => ApiService().baseUrl;

  @override
  void initState() {
    super.initState();
    _loadTelegramId();
  }

  Future<void> _loadTelegramId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _chatIdController.text = prefs.getString('telegram_chat_id') ?? '');
  }

  // ── قوة كلمة المرور ──
  _PasswordStrength _getStrength(String p) {
    if (p.isEmpty) return _PasswordStrength.none;
    if (p.length < 6) return _PasswordStrength.weak;
    final hasUpper = p.contains(RegExp(r'[A-Z]'));
    final hasDigit = p.contains(RegExp(r'\d'));
    final hasSpecial = p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    final score = (hasUpper ? 1 : 0) + (hasDigit ? 1 : 0) + (hasSpecial ? 1 : 0);
    if (p.length >= 10 && score >= 2) return _PasswordStrength.strong;
    if (p.length >= 8 || score >= 1) return _PasswordStrength.medium;
    return _PasswordStrength.weak;
  }

  Future<void> _handleSave() async {
    final current = _currentCtrl.text;
    final newPass = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty) {
      _showSnack("يرجى إدخال كلمة المرور الحالية", isError: true);
      return;
    }
    if (newPass.isEmpty) {
      _showSnack("يرجى إدخال كلمة المرور الجديدة", isError: true);
      return;
    }
    if (newPass.length < 6) {
      _showSnack("كلمة المرور يجب أن تكون 6 أحرف على الأقل", isError: true);
      return;
    }
    if (newPass != confirm) {
      _showSnack("كلمتا المرور غير متطابقتين", isError: true);
      return;
    }
    final chatId = _chatIdController.text.trim();
    if (chatId.isEmpty) {
      _showSnack("يرجى إدخال Telegram Chat ID", isError: true);
      return;
    }

    if (!await NetworkHelper.hasInternet()) {
      _showSnack("لا يوجد اتصال بالإنترنت", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      await prefs.setString('telegram_chat_id', chatId);

      // أرسل OTP عبر تيليغرام أولاً
      await Dio().post(
        '$_base/profile/send-otp',
        data: {'telegram_chat_id': chatId},
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
            appBarTitle: "تأكيد تغيير كلمة المرور",
            message: "تم إرسال رمز التحقق عبر تيليغرام\nأدخله للمتابعة",
            icon: Icons.lock_person_rounded,
            onVerify: (otp) async {
              final t = prefs.getString('token') ?? '';
              try {
                await Dio().post(
                  '$_base/profile/verify-otp',
                  data: {'otp': otp},
                  options: Options(headers: {
                    'Authorization': 'Bearer $t',
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                  }),
                );
                await Dio().post(
                  '$_base/profile/update',
                  data: {'current_password': current, 'password': newPass},
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
              final t = prefs.getString('token') ?? '';
              await Dio().post(
                '$_base/profile/send-otp',
                data: {'telegram_chat_id': chatId},
                options: Options(headers: {
                  'Authorization': 'Bearer $t',
                  'Accept': 'application/json',
                }),
              );
            },
          ),
        ),
      );

      if (result == true && mounted) _showSuccessDialog();
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

  void _showSuccessDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.green, size: 48),
              ),
              const SizedBox(height: 20),
              Text("تم بنجاح!",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'Cairo')),
              const SizedBox(height: 10),
              Text("تم تغيير كلمة المرور بنجاح.\nيمكنك الآن تسجيل الدخول بكلمة المرور الجديدة.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: subColor,
                      height: 1.6,
                      fontFamily: 'Cairo')),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC00),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("حسناً",
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Cairo')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _chatIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    const yellow = Color(0xFFFFCC00);

    final strength = _getStrength(_newCtrl.text);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text("تغيير كلمة المرور",
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Cairo')),
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // ── أيقونة ──
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? yellow.withValues(alpha: 0.12)
                      : const Color(0xFFFEF9E7),
                  boxShadow: [
                    BoxShadow(
                      color: yellow.withValues(alpha: isDark ? 0.2 : 0.35),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(Icons.lock_person_rounded,
                    size: 48,
                    color: isDark ? yellow : const Color(0xFFD4AC0D)),
              ),

              const SizedBox(height: 24),

              Text("تغيير كلمة المرور",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'Cairo')),
              const SizedBox(height: 8),
              Text("اختر كلمة مرور قوية تحمي حسابك",
                  style: TextStyle(
                      fontSize: 13,
                      color: subColor,
                      fontFamily: 'Cairo')),

              const SizedBox(height: 36),

              // ── كلمة المرور الحالية ──
              _buildField(
                label: "كلمة المرور الحالية",
                controller: _currentCtrl,
                hint: "••••••••",
                icon: Icons.lock_outline_rounded,
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                textColor: textColor,
                isDark: isDark,
              ),

              const SizedBox(height: 20),

              // ── كلمة المرور الجديدة ──
              _buildField(
                label: "كلمة المرور الجديدة",
                controller: _newCtrl,
                hint: "••••••••",
                icon: Icons.key_rounded,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                textColor: textColor,
                isDark: isDark,
                onChanged: (_) => setState(() {}),
              ),

              // ── مؤشر القوة ──
              if (_newCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildStrengthBar(strength, isDark),
              ],

              const SizedBox(height: 20),

              // ── تأكيد كلمة المرور ──
              _buildField(
                label: "تأكيد كلمة المرور الجديدة",
                controller: _confirmCtrl,
                hint: "••••••••",
                icon: Icons.shield_rounded,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                textColor: textColor,
                isDark: isDark,
                trailingIcon: _confirmCtrl.text.isNotEmpty
                    ? (_confirmCtrl.text == _newCtrl.text
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded)
                    : null,
                trailingColor: _confirmCtrl.text == _newCtrl.text
                    ? Colors.green
                    : Colors.redAccent,
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 20),

              // ── حقل Chat ID ──
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4, bottom: 8),
                  child: Text("Telegram Chat ID",
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textColor,
                          fontFamily: 'Cairo')),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.shade300),
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    controller: _chatIdController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textColor, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: "أدخل Chat ID",
                      hintStyle: TextStyle(
                          color: textColor.withValues(alpha: 0.35),
                          fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                      prefixIcon: Icon(Icons.telegram_rounded,
                          color: Colors.blue.shade400, size: 22),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 44),

              // ── زر الحفظ ──
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
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
                            Icon(Icons.save_rounded,
                                color: Colors.black, size: 22),
                            SizedBox(width: 10),
                            Text("حفظ التغييرات",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    fontFamily: 'Cairo')),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 14),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("إلغاء",
                    style: TextStyle(
                        color: subColor,
                        fontSize: 15,
                        fontFamily: 'Cairo')),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStrengthBar(_PasswordStrength strength, bool isDark) {
    final labels = {
      _PasswordStrength.weak: 'ضعيفة',
      _PasswordStrength.medium: 'متوسطة',
      _PasswordStrength.strong: 'قوية',
    };
    final colors = {
      _PasswordStrength.weak: Colors.redAccent,
      _PasswordStrength.medium: Colors.orange,
      _PasswordStrength.strong: Colors.green,
    };
    final values = {
      _PasswordStrength.weak: 0.33,
      _PasswordStrength.medium: 0.66,
      _PasswordStrength.strong: 1.0,
    };

    final color = colors[strength]!;
    final value = values[strength]!;
    final label = labels[strength]!;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor:
                  isDark ? Colors.white12 : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text("قوة: $label",
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo')),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
    required Color textColor,
    required bool isDark,
    IconData? trailingIcon,
    Color? trailingColor,
    ValueChanged<String>? onChanged,
  }) {
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.shade100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: textColor,
                  fontFamily: 'Cairo')),
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
            controller: controller,
            obscureText: obscure,
            onChanged: onChanged,
            style: TextStyle(color: textColor, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: textColor.withValues(alpha: 0.35), fontSize: 14),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: InputBorder.none,
              prefixIcon: Icon(icon,
                  color: isDark
                      ? const Color(0xFFFFCC00)
                      : const Color(0xFFD4AC0D),
                  size: 22),
              suffixIcon: trailingIcon != null
                  ? Icon(trailingIcon, color: trailingColor, size: 22)
                  : IconButton(
                      icon: Icon(
                          obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: textColor.withValues(alpha: 0.4),
                          size: 22),
                      onPressed: onToggle,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _PasswordStrength { none, weak, medium, strong }
