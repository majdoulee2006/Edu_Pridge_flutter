import 'package:flutter/material.dart';
import 'dart:async';

class OTPScreen extends StatefulWidget {
  final String appBarTitle;
  final String message;
  final IconData icon;
  // يرجع null عند النجاح، أو نص الخطأ عند الفشل
  final Future<String?> Function(String otp) onVerify;
  final Future<void> Function()? onResend;

  const OTPScreen({
    super.key,
    this.appBarTitle = "التحقق",
    this.message = "أدخل رمز التحقق المكون من 6 أرقام",
    this.icon = Icons.mark_email_read_outlined,
    required this.onVerify,
    this.onResend,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  int _counter = 59;
  Timer? _timer;
  bool _isVerifying = false;
  bool _isResending = false;

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
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_counter > 0) {
        if (mounted) setState(() => _counter--);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _handleVerify() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      _showSnack("يرجى إدخال الرمز كاملاً (6 أرقام)", isError: true);
      return;
    }

    setState(() => _isVerifying = true);

    final error = await widget.onVerify(code);

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (error == null) {
      // نجاح - ارجع بنتيجة true
      Navigator.pop(context, true);
    } else {
      _showSnack(error, isError: true);
      // امسح الأرقام وعيد التركيز
      for (var c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _handleResend() async {
    if (widget.onResend == null) {
      _startTimer();
      return;
    }
    setState(() => _isResending = true);
    try {
      await widget.onResend!();
      _startTimer();
      for (var c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      _showSnack("تم إعادة إرسال الرمز", isError: false);
    } catch (_) {
      _showSnack("تعذّر إعادة الإرسال، حاول مجدداً", isError: true);
    } finally {
      if (mounted) setState(() => _isResending = false);
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
          title: Text(widget.appBarTitle,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Cairo')),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // ── أيقونة مضيئة ──
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
                      color: yellow.withValues(alpha: isDark ? 0.25 : 0.4),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(widget.icon,
                    size: 48,
                    color: isDark ? yellow : const Color(0xFFD4AC0D)),
              ),

              const SizedBox(height: 28),

              Text("أدخل رمز التحقق",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'Cairo')),
              const SizedBox(height: 10),
              Text(widget.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: subColor,
                      fontSize: 14,
                      height: 1.6,
                      fontFamily: 'Cairo')),

              const SizedBox(height: 44),

              // ── 6 خانات OTP ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (i) => _buildBox(i, isDark, textColor)),
              ),

              const SizedBox(height: 36),

              // ── إعادة الإرسال ──
              Column(
                children: [
                  Text("لم يصلك الرمز؟",
                      style: TextStyle(
                          color: subColor,
                          fontSize: 13,
                          fontFamily: 'Cairo')),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isResending)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFFFFCC00)),
                        )
                      else
                        GestureDetector(
                          onTap: _counter == 0 ? _handleResend : null,
                          child: Text("إعادة إرسال الرمز",
                              style: TextStyle(
                                  color: _counter == 0
                                      ? (isDark ? yellow : Colors.black87)
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  decoration: _counter == 0
                                      ? TextDecoration.underline
                                      : TextDecoration.none,
                                  fontFamily: 'Cairo')),
                        ),
                      const SizedBox(width: 10),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFFF2F3F4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "00:${_counter.toString().padLeft(2, '0')}",
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _counter > 0
                                  ? (isDark ? yellow : const Color(0xFFD4AC0D))
                                  : Colors.grey,
                              fontFamily: 'Cairo'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 52),

              // ── زر التأكيد ──
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    disabledBackgroundColor: yellow.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2.5))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_rounded,
                                color: Colors.black, size: 22),
                            SizedBox(width: 10),
                            Text("تأكيد الرمز",
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

  Widget _buildBox(int i, bool isDark, Color textColor) {
    final filled = _controllers[i].text.isNotEmpty;
    return SizedBox(
      width: 50,
      height: 58,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark
              ? (filled
                  ? const Color(0xFFFFCC00).withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.05))
              : (filled ? const Color(0xFFFEFDE1) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled
                ? const Color(0xFFFFCC00)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.grey.shade300),
            width: filled ? 2 : 1.5,
          ),
        ),
        child: TextField(
          controller: _controllers[i],
          focusNode: _focusNodes[i],
          autofocus: i == 0,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87),
          decoration: const InputDecoration(
              counterText: "", border: InputBorder.none),
          onChanged: (v) {
            if (v.isNotEmpty && i < 5) {
              _focusNodes[i + 1].requestFocus();
            } else if (v.isEmpty && i > 0) {
              _focusNodes[i - 1].requestFocus();
            }
            setState(() {});
          },
        ),
      ),
    );
  }
}
