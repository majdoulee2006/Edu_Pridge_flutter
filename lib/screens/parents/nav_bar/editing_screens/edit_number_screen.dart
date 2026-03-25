import 'package:flutter/material.dart';

class EditNumberScreen extends StatefulWidget {
  const EditNumberScreen({super.key});

  @override
  State<EditNumberScreen> createState() => _EditNumberScreenState();
}

class _EditNumberScreenState extends State<EditNumberScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountryCode = "+966"; // كود الدولة الافتراضي كما في الصورة

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // التزام كامل باللغة العربية
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "تعديل رقم الهاتف",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            children: [
              const SizedBox(height: 50),

              // أيقونة الهاتف المركزية مع تأثير الدائرة الخلفية
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFFF00).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.phone_android_rounded,
                      color: Color(0xFFEFFF00),
                      size: 70,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // النصوص التوضيحية
              const Text(
                "رقم الهاتف الجديد",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "يرجى إدخال رقم هاتفك الجديد. سنقوم بإرسال رمز تحقق\nبرسالة نصية (SMS) لتأكيد الرقم.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 50),

              // عنوان حقل الإدخال
              const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 15, bottom: 8),
                  child: Text(
                    "رقم الجوال",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              // صف يحتوي على كود الدولة وحقل الرقم
              Row(
                children: [
                  // 1. اختيار كود الدولة (الجزء الصغير على اليمين)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey, size: 20),
                        const SizedBox(width: 5),
                        Text(
                          _selectedCountryCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 2. حقل إدخال الرقم (الجزء الأكبر)
                  Expanded(
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textAlign: TextAlign.left, // الأرقام تبدأ من اليسار دائماً
                        style: const TextStyle(fontSize: 18, letterSpacing: 1.2),
                        decoration: InputDecoration(
                          hintText: "50 123 4567",
                          hintStyle: TextStyle(color: Colors.grey.shade300),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              // زر "إرسال رمز التحقق"
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () {
                    // منطق الإرسال هنا
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFFF00),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "إرسال رمز التحقق",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward_rounded, size: 20),
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
}