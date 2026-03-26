import 'package:flutter/material.dart';
import 'dart:async';

class OTPScreen extends StatefulWidget {
  // 🌟 متغيرات جديدة عشان الواجهة تصير مرنة وتناسب كل الحالات 🌟
  final String appBarTitle;
  final String message;
  final VoidCallback? onConfirm;

  const OTPScreen({
    super.key,
    // قيم افتراضية عشان ما يضرب الكود القديم
    this.appBarTitle = "التحقق من الحساب",
    this.message =
        "تم إرسال رمز التحقق المكون من 4 أرقام إلى رقم\nهاتفك المسجل +966 5X XXX XXXX",
    this.onConfirm,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  int _counter = 59;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_counter > 0) {
        setState(() => _counter--);
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.appBarTitle, // 🌟 النص متغير حسب الحالة
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons
                .arrow_back, // ✅ تم تعديل السهم ليؤشر لليمين في الواجهة العربية
            color: Colors.black,
          ),
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
                    color: const Color(0xFFFEF9E7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    size: 45,
                    color: Color(0xFFD4AC0D),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "أدخل رمز التحقق",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Text(
                widget.message, // 🌟 الرسالة متغيرة
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),

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
              const Text(
                "لم يصلك الرمز؟",
                style: TextStyle(color: Colors.grey, fontSize: 13),
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
                        color: _counter == 0 ? Colors.black : Colors.grey,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F3F4),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      "00:${_counter.toString().padLeft(2, '0')}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
                      // 🌟 إذا تم تمرير دالة خاصة، بنفذها، وإلا بنرجع خطوة لورا
                      if (widget.onConfirm != null) {
                        widget.onConfirm!();
                      } else {
                        Navigator.pop(
                          context,
                        ); // يرجع للشاشة اللي استدعته (بروفايل أو غيره)
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFFF00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.black,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "تأكيد الرمز", // 🌟 خليتها عامة لتناسب الكل
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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

  Widget _otpBox(
    BuildContext context, {
    required bool first,
    required bool last,
  }) {
    return Container(
      height: 70,
      width: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFF2F3F4), width: 2),
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
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
