import 'package:flutter/material.dart';
// ✅ تم إضافة استدعاء واجهة التحقق (تأكدي من المسار الصحيح بملفاتك)
import 'otp_screen.dart';

class EditPhoneScreen extends StatefulWidget {
  const EditPhoneScreen({super.key});

  @override
  State<EditPhoneScreen> createState() => _EditPhoneScreenState();
}

class _EditPhoneScreenState extends State<EditPhoneScreen> {
  // 🌟 متغير لحفظ رمز الدولة المختار
  String _selectedCountryCode = '+966';

  // 🌟 قائمة برموز الدول المتاحة للاختيار (فيك تعدليها وتزيدي عليها)
  final List<String> _countryCodes = [
    '+966', // السعودية
    '+971', // الإمارات
    '+965', // الكويت
    '+974', // قطر
    '+968', // عُمان
    '+973', // البحرين
    '+20', // مصر
    '+963', // سوريا
    '+962', // الأردن
    '+961', // لبنان
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            // ✅ تم التعديل هنا: استخدام arrow_back ليؤشر لليمين بشكل صحيح في الواجهة العربية
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'تعديل رقم الهاتف',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // 1. الأيقونة المضيئة (Glowing Icon)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF6E300).withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.phone_iphone,
                  size: 40,
                  color: Color(0xFFF6E300),
                ),
              ),
              const SizedBox(height: 30),

              // 2. النصوص
              const Text(
                'رقم الهاتف الجديد',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'يرجى إدخال رقم هاتفك الجديد. سنقوم بإرسال رمز تحقق\nبرسالة نصية (SMS) لتأكيد الرقم.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 40),

              // 3. حقل إدخال رقم الجوال
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'رقم الجوال',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // استخدمنا LTR هون لأن الأرقام ومفتاح الدولة دايماً من اليسار لليمين
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    // 🌟 مفتاح الدولة (تحول لقائمة منسدلة Dropdown)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical:
                            11, // قللنا البادينج شوي ليناسب حجم الدروب داون
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCountryCode,
                          isDense: true,
                          icon: Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          items: _countryCodes.map((String code) {
                            return DropdownMenuItem<String>(
                              value: code,
                              child: Text(code),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCountryCode = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // حقل الإدخال
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const TextField(
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: '50 123 4567',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 4. الزر الأصفر
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // ✅ تم ربط الزر بواجهة رمز التحقق مع دالة الرجوع المزدوج
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OTPScreen(
                          appBarTitle: "تأكيد الهاتف",
                          message:
                              "تم إرسال الرمز المكون من 4 أرقام إلى رقم\nهاتفك الجديد",
                          // 🌟 أمر الرجوع خطوتين للوراء مع رسالة نجاح
                          onConfirm: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "تم تغيير رقم الهاتف بنجاح! ✅",
                                  textAlign: TextAlign.center,
                                ),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            int count = 0;
                            Navigator.of(context).popUntil((_) => count++ >= 2);
                          },
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF6E300),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'إرسال رمز التحقق',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
}
