import 'package:flutter/material.dart';

import '../../../../widgets/teacher_speed_dial.dart';
import '../../messages_screen.dart';
import '../../profile_screen.dart';
import '../../teacher_home.dart';
class LecturesScreen extends StatelessWidget {
const LecturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // الألوان المستخدمة في التصميم
    const Color primaryYellow = Color(0xFFF0E35F);
    const Color backgroundColor = Color(0xFFFCFCF9);
    const Color textColor = Color(0xFF333333);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'إضافة محاضرة',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              // عنوان المحاضرة
              _buildLabel('عنوان المحاضرة'),
              _buildTextField(hint: 'أدخل عنوان المحاضرة هنا'),

              const SizedBox(height: 20),

              // المادة والصف في سطر واحد
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('المادة'),
                        _buildDropdownField(hint: 'اختر المادة'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('الصف'),
                        _buildDropdownField(hint: 'اختر الصف'),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // زر إرفاق ملف المحاضرة
              Container(
                width: double.infinity,
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                    color: primaryYellow.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryYellow.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.attach_file, color: textColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'إرفاق ملف المحاضرة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // زر إضافة محاضرة الكبير
              GestureDetector(
                onTap: () {
                  // أضف منطق الإضافة هنا
                },
                child: Container(
                  width: double.infinity,
                  height: 65,
                  decoration: BoxDecoration(
                    color: primaryYellow,
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: primaryYellow.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_circle, color: Colors.black, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'إضافة المحاضرة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30), // مسافة إضافية في الأسفل
            ],
          ),
        ),
      ),
    );
  }

  // ويجيت لبناء التسمية فوق الحقول
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  // ويجيت بناء حقل النص
  Widget _buildTextField({required String hint}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: TextField(
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBCBCBC), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  // ويجيت بناء حقل الاختيار (Dropdown)
  Widget _buildDropdownField({required String hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(hint, style: const TextStyle(color: Color(0xFFBCBCBC), fontSize: 14)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF777777)),
          items: const [],
          onChanged: (value) {},
        ),
      ),
    );
  }
}