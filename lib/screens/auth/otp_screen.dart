import 'package:flutter/material.dart';

import 'dart:async';

import 'package:dio/dio.dart';

import 'login_screen.dart'; // تأكدي أن المسار واسم الملف صحيحين



class OTPScreen extends StatefulWidget {

  final String email;

  final String appBarTitle;

  final String message;



  const OTPScreen({

    super.key,

    required this.email,

    this.appBarTitle = "التحقق من الحساب",

    this.message = "تم إرسال رمز التحقق إلى بريدك الإلكتروني",

  });



  @override

  State<OTPScreen> createState() => _OTPScreenState();

}



class _OTPScreenState extends State<OTPScreen> {

  int _counter = 59;

  Timer? _timer;

  bool _isLoading = false;



// متحكمات المربعات الأربعة

  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());

  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());



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



// 🚀 دالة التحقق من الرمز المعدلة

  Future<void> _handleVerifyOtp() async {

    String otpCode = _controllers.map((controller) => controller.text).join().trim();



    if (otpCode.length < 4) {

      _showMessage("يرجى إدخال الرمز كاملاً", isError: true);

      return;

    }



    setState(() => _isLoading = true);



    try {

      Dio dio = Dio();

// ملاحظة: للويب نستخدم 127.0.0.1، للأندرويد 10.0.2.2

      String url = "http://127.0.0.1:8000/api/verify-otp";



      var response = await dio.post(

        url,

        data: {

          "email": widget.email,

          "otp": otpCode,

        },

        options: Options(

          headers: {

            "Accept": "application/json",

            "Content-Type": "application/json",

          },

        ),

      );



// ✅ فحص الحالة بشكل آمن لتجنب خطأ Type Mismatch

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {

        _showMessage("تم التحقق بنجاح! جاري تحويلك...", isError: false);



        await Future.delayed(const Duration(seconds: 1));



        if (!mounted) return;



// 🔄 الانتقال وحذف الشاشة الحالية من الذاكرة

        Navigator.pushAndRemoveUntil(

          context,

          MaterialPageRoute(builder: (context) => const LoginScreen()),

              (route) => false,

        );

      }

    } on DioException catch (e) {

// قراءة رسالة الخطأ وتحويلها لنص بأمان

      String msg = e.response?.data['message']?.toString() ?? "الرمز الذي أدخلته غير صحيح";

      _showMessage(msg, isError: true);

    } catch (e) {

      debugPrint("🚨 Error details: $e");

      _showMessage("حدث خطأ تقني في معالجة البيانات", isError: true);

    } finally {

      if (mounted) setState(() => _isLoading = false);

    }

  }



  void _showMessage(String message, {bool isError = true}) {

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Cairo')),

        backgroundColor: isError ? Colors.redAccent : Colors.green,

        behavior: SnackBarBehavior.floating,

        duration: const Duration(seconds: 2),

      ),

    );

  }



  @override

  void dispose() {

    _timer?.cancel();

    for (var controller in _controllers) { controller.dispose(); }

    for (var node in _focusNodes) { node.dispose(); }

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    const primaryYellow = Color(0xFFEFFF00);



    return Scaffold(

      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(

        backgroundColor: Colors.transparent,

        elevation: 0,

        centerTitle: true,

        title: Text(widget.appBarTitle, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Cairo')),

        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),

      ),

      body: Directionality(

        textDirection: TextDirection.rtl,

        child: SingleChildScrollView(

          padding: const EdgeInsets.symmetric(horizontal: 25),

          child: Column(

            children: [

              const SizedBox(height: 30),

              Icon(Icons.mark_email_read_outlined, size: 80, color: isDark ? primaryYellow : const Color(0xFFD4AC0D)),

              const SizedBox(height: 30),

              Text("أدخل رمز التحقق", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Cairo')),

              const SizedBox(height: 15),

              Text("${widget.message}\n${widget.email}", textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 14, height: 1.6, fontFamily: 'Cairo')),

              const SizedBox(height: 40),



              Row(

                mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                children: List.generate(4, (index) => _otpBox(index)),

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

                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),

                  ),

                  child: _isLoading

                      ? const CircularProgressIndicator(color: Colors.black)

                      : const Text("تأكيد الرمز", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildResendSection(bool isDark, Color primaryYellow, Color textColor) {

    return Column(

      children: [

        Text("لم يصلك الرمز؟", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13, fontFamily: 'Cairo')),

        Row(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            TextButton(

              onPressed: _counter == 0 ? () {

                _startTimer();

// هنا يمكن استدعاء دالة API لإعادة الإرسال

              } : null,

              child: Text("إعادة إرسال الرمز", style: TextStyle(color: _counter == 0 ? (isDark ? primaryYellow : Colors.black) : Colors.grey, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),

            ),

            const SizedBox(width: 5),

            Text("00:${_counter.toString().padLeft(2, '0')}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),

          ],

        ),

      ],

    );

  }



  Widget _otpBox(int index) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(

      height: 70, width: 65,

      decoration: BoxDecoration(

        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],

        borderRadius: BorderRadius.circular(15),

        border: Border.all(color: _controllers[index].text.isNotEmpty ? const Color(0xFFEFFF00) : Colors.transparent, width: 2),

      ),

      child: TextField(

        controller: _controllers[index],

        focusNode: _focusNodes[index],

        autofocus: index == 0,

        textAlign: TextAlign.center,

        keyboardType: TextInputType.number,

        maxLength: 1,

        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),

        decoration: const InputDecoration(counterText: "", border: InputBorder.none),

        onChanged: (value) {

          if (value.isNotEmpty && index < 3) {

            _focusNodes[index + 1].requestFocus();

          } else if (value.isEmpty && index > 0) {

            _focusNodes[index - 1].requestFocus();

          }

          setState(() {});

        },

      ),

    );

  }

}