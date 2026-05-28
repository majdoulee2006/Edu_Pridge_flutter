import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'otp_screen.dart';

class EditPhoneScreen extends StatefulWidget {
  const EditPhoneScreen({super.key});

  @override
  State<EditPhoneScreen> createState() => _EditPhoneScreenState();
}

class _EditPhoneScreenState extends State<EditPhoneScreen> {
  final _phoneController = TextEditingController();
  String _selectedCode = '+966';
  String _telegramChatId = '';
  bool _isLoading = false;

  static const _base = "http://127.0.0.1:8000/api";

  @override
  void initState() {
    super.initState();
    _loadTelegramId();
  }

  Future<void> _loadTelegramId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _telegramChatId = prefs.getString('telegram_chat_id') ?? '');
  }

  final List<Map<String, String>> _countries = [
    {'code': '+966', 'flag': '🇸🇦', 'name': 'السعودية'},
    {'code': '+971', 'flag': '🇦🇪', 'name': 'الإمارات'},
    {'code': '+965', 'flag': '🇰🇼', 'name': 'الكويت'},
    {'code': '+974', 'flag': '🇶🇦', 'name': 'قطر'},
    {'code': '+968', 'flag': '🇴🇲', 'name': 'عُمان'},
    {'code': '+973', 'flag': '🇧🇭', 'name': 'البحرين'},
    {'code': '+20',  'flag': '🇪🇬', 'name': 'مصر'},
    {'code': '+963', 'flag': '🇸🇾', 'name': 'سوريا'},
    {'code': '+962', 'flag': '🇯🇴', 'name': 'الأردن'},
    {'code': '+961', 'flag': '🇱🇧', 'name': 'لبنان'},
  ];

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 7) {
      _showSnack("يرجى إدخال رقم هاتف صحيح", isError: true);
      return;
    }
    if (_telegramChatId.isEmpty) {
      _showSnack("لم يتم العثور على Chat ID — سجّل الدخول من جديد", isError: true);
      return;
    }

    final fullPhone = '$_selectedCode$phone';
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

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
            appBarTitle: "تأكيد رقم الهاتف",
            message: "تم إرسال رمز التحقق عبر تيليغرام\nأدخله لتأكيد رقمك الجديد",
            icon: Icons.phone_iphone_rounded,
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
                // OTP صحيح — حدّث الرقم
                await Dio().post(
                  '$_base/profile/update',
                  data: {'phone': fullPhone},
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
        _showSnack("تم تغيير رقم الهاتف بنجاح ✓", isError: false);
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
          title: Text("تعديل رقم الهاتف",
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
                child: Icon(Icons.phone_iphone_rounded,
                    size: 52,
                    color: isDark ? yellow : const Color(0xFFD4AC0D)),
              ),

              const SizedBox(height: 28),

              Text("تغيير رقم الهاتف",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'Cairo')),
              const SizedBox(height: 10),
              Text(
                "أدخل رقم هاتفك الجديد\nسنرسل رمز تحقق للتأكيد",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: subColor,
                    height: 1.6,
                    fontFamily: 'Cairo'),
              ),

              const SizedBox(height: 44),

              // ── عنوان الحقل ──
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

              // ── حقل الرقم مع كود الدولة ──
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
                    // كود الدولة
                    GestureDetector(
                      onTap: () => _showCountryPicker(
                          context, textColor, cardColor, isDark),
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
                    // رقم الهاتف
                    Expanded(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                              color: textColor, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: "50 123 4567",
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

  void _showCountryPicker(
      BuildContext context, Color textColor, Color cardColor, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
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
}
