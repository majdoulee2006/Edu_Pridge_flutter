import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/firebase_auth_service.dart';
import 'package:edu_pridge_flutter/utils/network_helper.dart';

class PhoneAuthScreen extends StatefulWidget {
  /// رقم الهاتف (اختياري — إذا فُرِّر يُستخدم مباشرة، وإلا يُقرأ من SharedPreferences)
  final String? phoneNumber;

  /// يُستدعى بعد التحقق الناجح. إذا كان null يتم الـ pop تلقائياً.
  final void Function(UserCredential credential)? onVerified;

  const PhoneAuthScreen({super.key, this.phoneNumber, this.onVerified});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _service   = FirebaseAuthService();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();
  final _otpFocus  = FocusNode();

  bool   _codeSent = false;
  bool   _loading  = false;
  String _error    = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) {
      _phoneCtrl.text = widget.phoneNumber!;
    } else {
      final prefs = await SharedPreferences.getInstance();
      _phoneCtrl.text = prefs.getString('user_phone') ?? '';
    }
    if (_phoneCtrl.text.isNotEmpty) await _requestCode();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) { setState(() => _error = 'أدخل رقم الهاتف'); return; }

    if (!await NetworkHelper.hasInternet()) {
      setState(() => _error = 'لا يوجد اتصال بالإنترنت');
      return;
    }

    setState(() { _loading = true; _error = ''; });

    await _service.verifyPhoneNumber(
      phoneNumber: phone,
      onCodeSent: () {
        if (!mounted) return;
        setState(() { _codeSent = true; _loading = false; });
        FocusScope.of(context).requestFocus(_otpFocus);
        _showSnack('تم إرسال الرمز إلى $phone');
      },
      onError: (msg) {
        if (!mounted) return;
        setState(() { _error = msg; _loading = false; });
      },
      onAutoVerified: (cred) {
        if (!mounted) return;
        setState(() => _loading = false);
        _handleSuccess(cred);
      },
    );
  }

  Future<void> _confirmCode() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) { setState(() => _error = 'الرمز يجب أن يكون 6 أرقام'); return; }
    setState(() { _loading = true; _error = ''; });

    final cred = await _service.verifyOTP(
      otp: otp,
      onError: (msg) {
        if (!mounted) return;
        setState(() { _error = msg; _loading = false; });
      },
    );

    if (cred != null && mounted) {
      setState(() => _loading = false);
      _handleSuccess(cred);
    }
  }

  void _handleSuccess(UserCredential cred) {
    if (widget.onVerified != null) {
      widget.onVerified!(cred);
    } else {
      _showSnack('تم التحقق بنجاح ✓');
      Navigator.pop(context);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center),
        backgroundColor: msg.contains('✓') ? Colors.green : const Color(0xFFFFCC00),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_android, size: 40, color: Color(0xFFFFCC00)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _codeSent ? 'أدخل رمز التحقق' : 'التحقق برقم الهاتف',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 8),
              Text(
                _codeSent
                    ? 'أرسلنا رمزاً من 6 أرقام إلى ${_phoneCtrl.text}'
                    : 'سنرسل لك رمز التحقق عبر SMS',
                style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // رقم الهاتف (يظهر فقط إذا لم يُرسل الكود بعد)
              if (!_codeSent) ...[
                _label('رقم الهاتف', isDark),
                const SizedBox(height: 8),
                _field(controller: _phoneCtrl, hint: '+963XXXXXXXXX',
                    keyboardType: TextInputType.phone, isDark: isDark),
                const SizedBox(height: 20),
              ],

              // حقل OTP
              if (_codeSent) ...[
                _label('رمز التحقق', isDark),
                const SizedBox(height: 8),
                _field(
                  controller: _otpCtrl,
                  focusNode: _otpFocus,
                  hint: '• • • • • •',
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  isDark: isDark,
                  textAlign: TextAlign.center,
                  letterSpacing: 10,
                ),
              ],

              // رسالة الخطأ
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error, style: const TextStyle(color: Colors.red, fontSize: 13))),
                  ]),
                ),
              ],

              const SizedBox(height: 28),

              // زر رئيسي
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : (_codeSent ? _confirmCode : _requestCode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC00),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                      : Text(_codeSent ? 'تأكيد الرمز' : 'إرسال الرمز',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),

              // إعادة الإرسال
              if (_codeSent) ...[
                const SizedBox(height: 14),
                Center(
                  child: TextButton(
                    onPressed: _loading ? null : () => setState(() {
                      _codeSent = false; _otpCtrl.clear(); _error = '';
                    }),
                    child: const Text('إعادة الإرسال أو تغيير الرقم',
                        style: TextStyle(color: Color(0xFFFFCC00), fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, bool isDark) => Text(text,
    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700));

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    TextAlign textAlign = TextAlign.start,
    double letterSpacing = 0,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      maxLength: maxLength,
      textAlign: textAlign,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        letterSpacing: letterSpacing,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, letterSpacing: 0, fontSize: 14, fontWeight: FontWeight.normal),
        counterText: '',
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFFFCC00), width: 2)),
      ),
    );
  }
}
