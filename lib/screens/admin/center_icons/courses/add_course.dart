import 'package:flutter/material.dart';

class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedDepartment;
  DateTime? startDate;
  String selectedDuration = "4 أسابيع";

  final List<String> departments = [
    "قسم الكومبيوتر ونظم المعلومات",
    "قسم الطبي",
    "قسم التجاري",
    "قسم اللغة الإنجليزية",
    "إدارة الأعمال",
  ];

  final List<String> durations = [
    "2 أسابيع", "4 أسابيع", "6 أسابيع", "8 أسابيع", "12 أسبوع", "16 أسبوع",
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final primaryYellow = const Color(0xFFEFFF00);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header المخصص حسب طلبك
                _buildHeader(textColor),

                const SizedBox(height: 30),

                _buildLabel("اسم الدورة", textColor),
                _buildTextField(
                  controller: nameController,
                  hint: "مثال: إدارة المشاريع الاحترافية",
                  icon: Icons.edit,
                  cardColor: cardColor,
                ),

                const SizedBox(height: 20),
                _buildLabel("القسم", textColor),
                _buildDropdownField(cardColor, textColor),

                const SizedBox(height: 20),
                _buildLabel("وصف الدورة", textColor),
                _buildTextField(
                  controller: descriptionController,
                  hint: "اكتب وصفاً مختصراً عن محتوى الدورة وأهدافها...",
                  maxLines: 4,
                  icon: Icons.description,
                  cardColor: cardColor,
                ),

                const SizedBox(height: 25),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("تاريخ البدء", textColor),
                          _buildDateField(cardColor),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("مدة الدورة", textColor),
                          _buildDurationDropdown(cardColor, textColor),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("تمت إضافة الدورة بنجاح")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryYellow,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("إضافة الدورة",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                        SizedBox(width: 8),
                        Icon(Icons.add, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ====================== Header حسب طلبك ======================
  Widget _buildHeader(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        Text(
          "إضافة دورة جديدة",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 26),
          onPressed: () {},
        ),
      ],
    );
  }

  // ====================== باقي الدوال ======================
  Widget _buildLabel(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 5),
      child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    IconData? icon,
    required Color cardColor,
  }) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          suffixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildDropdownField(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedDepartment,
          hint: const Text("اختر القسم التابع للدورة"),
          isExpanded: true,
          dropdownColor: cardColor,
          style: TextStyle(color: textColor),
          items: departments.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => selectedDepartment = v),
        ),
      ),
    );
  }

  Widget _buildDateField(Color cardColor) {
    return GestureDetector(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2024),
          lastDate: DateTime(2027),
        );
        if (picked != null) setState(() => startDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.grey),
            const SizedBox(width: 10),
            Text(
              startDate == null ? "mm/dd/yyyy" : "${startDate!.toLocal()}".split(' ')[0],
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationDropdown(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedDuration,
          isExpanded: true,
          dropdownColor: cardColor,
          style: TextStyle(color: textColor),
          items: durations.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (v) => setState(() => selectedDuration = v!),
        ),
      ),
    );
  }
}