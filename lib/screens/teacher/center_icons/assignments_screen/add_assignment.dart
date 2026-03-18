import 'package:flutter/material.dart';

class AddAssignmentScreen extends StatefulWidget {
  const AddAssignmentScreen({super.key});

  @override
  State<AddAssignmentScreen> createState() => _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends State<AddAssignmentScreen> {
  @override
  Widget build(BuildContext context) {
    const Color mainAppColor = Color(0xFFF7F7F7);
    const Color activeTabColor = Color(0xFFEFFF00); // اللون الأصفر من التصميم
    const Color textDarkColor = Color(0xFF333333);
    const Color hintColor = Color(0xFF9E9E9E);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: mainAppColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: textDarkColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'إضافة تمرين منزلي',
            style: TextStyle(
              color: textDarkColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Tajawal',
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: textDarkColor),
              onPressed: () {},
            ),
          ],
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // حقل عنوان التمرين
              _buildTextField(hint: 'أدخل عنوان التمرين...'),
              const SizedBox(height: 20),

              const Text(
                'وصف التمرين',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Tajawal'),
              ),
              const SizedBox(height: 10),
              // حقل وصف التمرين (متعدد الأسطر)
              _buildTextField(hint: 'اكتب تفاصيل ومتطلبات التمرين هنا...', maxLines: 5),
              const SizedBox(height: 20),

              // صف المادة والصف
              Row(
                children: [
                  Expanded(child: _buildDropdownField(label: 'المادة', hint: 'اختر المادة')),
                  const SizedBox(width: 15),
                  Expanded(child: _buildDropdownField(label: 'الصف', hint: 'اختر الصف')),
                ],
              ),
              const SizedBox(height: 20),

              // صف التاريخ والوقت
              Row(
                children: [
                  Expanded(child: _buildPickerField(label: 'تاريخ التسليم', hint: 'mm/dd/yy', icon: Icons.calendar_today_outlined)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildPickerField(label: 'وقت التسليم', hint: '--:-- --', icon: Icons.access_time)),
                ],
              ),
              const SizedBox(height: 30),

              // إرفاق ملفات
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.withOpacity(0.3), style: BorderStyle.solid),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('إرفاق ملفات (اختياري)', style: TextStyle(color: hintColor, fontFamily: 'Tajawal')),
                    const SizedBox(width: 10),
                    Icon(Icons.attach_file, color: hintColor),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // زر إضافة التمرين
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeTabColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'إضافة التمرين',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Tajawal'),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.check_circle_outline, color: Colors.black),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ودجيت بناء حقول النص
  Widget _buildTextField({required String hint, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  // ودجيت بناء حقول الاختيار (Dropdown)
  Widget _buildDropdownField({required String label, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Tajawal')),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text(hint, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              items: [],
              onChanged: (value) {},
            ),
          ),
        ),
      ],
    );
  }

  // ودجيت بناء حقول التاريخ والوقت
  Widget _buildPickerField({required String label, required String hint, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Tajawal')),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: Colors.grey),
              Text(hint, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}