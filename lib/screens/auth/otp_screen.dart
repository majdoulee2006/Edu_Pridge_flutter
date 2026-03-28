import 'package:flutter/material.dart';
import 'dart:async';

class OTPScreen extends StatefulWidget {
  final String appBarTitle;
  final String message;
  final VoidCallback? onConfirm;

  const OTPScreen({
    super.key,
    this.appBarTitle = "التحقق من الحساب",
    this.message = "تم إرسال رمز التحقق المكون من 4 أرقام إلى رقم\nهاتفك المسجل +966 5X XXX XXXX",
    this.onConfirm,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  int _counter = 59;
  Timer? _timer; // جعل التايمر قابل للإلغاء بشكل آمن

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel(); // إلغاء أي تايمر سابق لتجنب التداخل
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_counter > 0) {
        if (mounted) setState(() => _counter--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 استخراج ألوان الثيم الحالي
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey;
    final primaryYellow = const Color(0xFFEFFF00);
    final containerBg = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF2F3F4);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.appBarTitle,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.amber.withValues(alpha: 0.1) : const Color(0xFFFEF9E7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.chat_bubble_rounded,
                    size: 45,
                    color: isDark ? primaryYellow : const Color(0xFFD4AC0D),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "أدخل رمز التحقق",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 15),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),

              // صناديق OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _otpBox(context, first: true, last: false),
                  _otpBox(context, first: false, last: false),
                  _otpBox(context, first: false, last: false),
                  _otpBox(context, first: false, last: true),
                ],
              ),

              const SizedBox(height: 30),
              Text(
                "لم يصلك الرمز؟",
                style: TextStyle(color: subTextColor, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _counter == 0
                        ? () {
                      setState(() => _counter = 59);
                      _startTimer();
                    }
                        : null,
                    child: Text(
                      "إعادة إرسال الرمز",
                      style: TextStyle(
                        color: _counter == 0 ? (isDark ? primaryYellow : Colors.black) : Colors.grey,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: _counter == 0 ? (isDark ? primaryYellow : Colors.black) : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: containerBg,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      "00:${_counter.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      if (widget.onConfirm != null) {
                        widget.onConfirm!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryYellow,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.black, size: 20),
                        SizedBox(width: 10),
                        Text(
                          "تأكيد الرمز",
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
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

  Widget _otpBox(BuildContext context, {required bool first, required bool last}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Container(
      height: 70,
      width: 65,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFF2F3F4),
          width: 2,
        ),
      ),
      child: TextField(
        autofocus: true,
        onChanged: (value) {
          if (value.length == 1 && last == false) {
            FocusScope.of(context).nextFocus();
          }
          if (value.isEmpty && first == false) {
            FocusScope.of(context).previousFocus();
          }
        },
        showCursor: false,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
      ),
    );
  }
}