import 'package:flutter/material.dart';

class AddAssignmentScreen extends StatefulWidget {
  const AddAssignmentScreen({super.key});

  @override
  State<AddAssignmentScreen> createState() => _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends State<AddAssignmentScreen> {
  @override
  Widget build(BuildContext context) {
    // الألوان الأساسية
    const Color primaryYellow = Color(0xFFEFFF00);

    // جلب ألوان الثيم (دعم Dark Mode تلقائياً)
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'إضافة تمرين منزلي',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.info_outline, color: textColor),
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // حقل عنوان التمرين
              _buildSectionLabel("عنوان التمرين", textColor),
              _buildTextField(
                context,
                hint: 'مثال: حل مسائل قوانين نيوتن',
                cardColor: cardColor,
                textColor: textColor,
              ),
              const SizedBox(height: 20),

              // حقل وصف التمرين
              _buildSectionLabel("وصف ومتطلبات التمرين", textColor),
              _buildTextField(
                context,
                hint:
                    'اكتب تفاصيل الواجب، الصفحات المطلوبة، أو أي تعليمات إضافية للطلاب...',
                maxLines: 5,
                cardColor: cardColor,
                textColor: textColor,
              ),
              const SizedBox(height: 20),

              // صف المادة والصف
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      label: 'المادة الدراسية',
                      hint: 'اختر المادة',
                      cardColor: cardColor,
                      textColor: textColor,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildDropdownField(
                      label: 'الصف / الشعبة',
                      hint: 'اختر الصف',
                      cardColor: cardColor,
                      textColor: textColor,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // صف التاريخ والوقت
              Row(
                children: [
                  Expanded(
                    child: _buildPickerField(
                      label: 'تاريخ التسليم النهائي',
                      hint: '2024/12/30',
                      icon: Icons.calendar_month_outlined,
                      cardColor: cardColor,
                      textColor: textColor,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildPickerField(
                      label: 'وقت التسليم',
                      hint: '11:59 PM',
                      icon: Icons.access_time,
                      cardColor: cardColor,
                      textColor: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // إرفاق ملفات
              _buildSectionLabel("المرفقات (صور، PDF، نماذج)", textColor),
              InkWell(
                onTap: () {}, // هنا تضاف وظيفة اختيار الملفات
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: primaryYellow.withOpacity(0.5),
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        color: primaryYellow,
                        size: 30,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اضغط لرفع الملفات المساعدة',
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // زر إضافة التمرين
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // منطق الحفظ هنا
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                    shadowColor: primaryYellow.withOpacity(0.3),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'نشر التمرين الآن',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.send_rounded, color: Colors.black, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- ويجيتات البناء المساعدة ---

  Widget _buildSectionLabel(String label, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 4),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String hint,
    int maxLines = 1,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        maxLines: maxLines,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: textColor.withOpacity(0.4), fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label, textColor),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: cardColor,
              hint: Text(
                hint,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor.withOpacity(0.5),
                ),
              ),
              items: const [],
              onChanged: (value) {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerField({
    required String label,
    required String hint,
    required IconData icon,
    required Color cardColor,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label, textColor),
        InkWell(
          onTap: () {}, // وظيفة اختيار التاريخ/الوقت
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 18, color: const Color(0xFFEFFF00)),
                Text(
                  hint,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
