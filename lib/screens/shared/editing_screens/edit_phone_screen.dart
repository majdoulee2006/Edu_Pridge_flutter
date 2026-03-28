import 'package:flutter/material.dart';
// تأكدي من أن ملف otp_screen يدعم الثيم الداكن أيضاً
import 'otp_screen.dart';

class EditPhoneScreen extends StatefulWidget {
  const EditPhoneScreen({super.key});

  @override
  State<EditPhoneScreen> createState() => _EditPhoneScreenState();
}

class _EditPhoneScreenState extends State<EditPhoneScreen> {
  // متغير لحفظ رمز الدولة المختار
  String _selectedCountryCode = '+966';

  // قائمة برموز الدول المتاحة
  final List<String> _countryCodes = [
    '+966', '+971', '+965', '+974', '+968', '+973', '+20', '+963', '+962', '+961',
  ];

  @override
  Widget build(BuildContext context) {
    // 🎨 استخراج ألوان الثيم الحالي
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor; // لون الحقول في الوضع الداكن
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final primaryYellow = const Color(0xFFF6E300);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'تعديل رقم الهاتف',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // 1. الأيقونة المضيئة (تتأثر بالثيم)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryYellow.withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.phone_iphone,
                  size: 40,
                  color: primaryYellow,
                ),
              ),
              const SizedBox(height: 30),

              // 2. النصوص
              Text(
                'رقم الهاتف الجديد',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'يرجى إدخال رقم هاتفك الجديد. سنقوم بإرسال رمز تحقق\nبرسالة نصية (SMS) لتأكيد الرقم.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: subTextColor, height: 1.5),
              ),
              const SizedBox(height: 40),

              // 3. عنوان الحقل
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'رقم الجوال',
                  style: TextStyle(
                    fontSize: 12,
                    color: subTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // حقل إدخال رقم الجوال (LTR للأرقام)
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    // مفتاح الدولة (Dropdown)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: cardColor,
                        border: Border.all(color: textColor.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCountryCode,
                          isDense: true,
                          dropdownColor: cardColor, // لون القائمة المنسدلة في الداكن
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: subTextColor,
                            size: 18,
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          items: _countryCodes.map((String code) {
                            return DropdownMenuItem<String>(
                              value: code,
                              child: Text(code),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() => _selectedCountryCode = newValue);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // حقل الإدخال النصي
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          border: Border.all(color: textColor.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: '50 123 4567',
                            hintStyle: TextStyle(
                              color: textColor.withValues(alpha: 0.3),
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OTPScreen(
                          appBarTitle: "تأكيد الهاتف",
                          message: "تم إرسال الرمز المكون من 4 أرقام إلى رقم\nهاتفك الجديد",
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
                    backgroundColor: primaryYellow,
                    foregroundColor: Colors.black, // النص يبقى أسود للوضوح على الأصفر
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'إرسال رمز التحقق',
                    style: TextStyle(
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