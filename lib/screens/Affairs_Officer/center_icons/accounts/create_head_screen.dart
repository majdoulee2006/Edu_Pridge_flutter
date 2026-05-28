import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class CreateHeadScreen extends StatefulWidget {
  const CreateHeadScreen({super.key});

  @override
  State<CreateHeadScreen> createState() => _CreateHeadScreenState();
}

class _CreateHeadScreenState extends State<CreateHeadScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _selectedGender = 'ذكر';
  String? _selectedDepartment;

  final List<String> _departments = [
    'قسم علوم الحاسب',
    'قسم الهندسة',
    'قسم الطب',
    'قسم التمريض',
    'قسم الصيدلة',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color subColor = isDark ? Colors.grey.shade400 : Colors.grey;
    final Color fieldColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══════════════════════════════════════
                // الهيدر
                // ═══════════════════════════════════════
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(Icons.settings, color: textColor, size: 26),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        },
                      ),
                    ),
                    Text(
                      "إضافة رئيس قسم",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: textColor, size: 26),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ═══════════════════════════════════════
                // عنوان "البيانات الشخصية"
                // ═══════════════════════════════════════
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'البيانات الشخصية',
                    style: TextStyle(
                      fontSize: 14,
                      color: subColor,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ═══════════════════════════════════════
                // حقل الاسم الكامل
                // ═══════════════════════════════════════
                _buildTextField(
                  controller: _nameController,
                  hint: 'الاسم الكامل لرئيس القسم',
                  icon: Icons.person_outline,
                  fieldColor: fieldColor,
                  textColor: textColor,
                  subColor: subColor,
                ),

                const SizedBox(height: 12),

                // ═══════════════════════════════════════
                // حقل رقم الهاتف
                // ═══════════════════════════════════════
                _buildTextField(
                  controller: _idController,
                  hint: 'رقم الهاتف',
                  icon: Icons.phone_android_outlined,
                  fieldColor: fieldColor,
                  textColor: textColor,
                  subColor: subColor,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 12),

                // ═══════════════════════════════════════
                // حقل البريد الإلكتروني
                // ═══════════════════════════════════════
                _buildTextField(
                  controller: _emailController,
                  hint: 'البريد الإلكتروني المهني',
                  icon: Icons.alternate_email_outlined,
                  fieldColor: fieldColor,
                  textColor: textColor,
                  subColor: subColor,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 16),

                // ═══════════════════════════════════════
                // عنوان "تفاصيل إضافية"
                // ═══════════════════════════════════════
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'تفاصيل إضافية',
                    style: TextStyle(
                      fontSize: 14,
                      color: subColor,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ═══════════════════════════════════════
                // اختيار الجنس
                // ═══════════════════════════════════════
                Row(
                  children: [
                    // أنثى
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedGender = 'أنثى'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _selectedGender == 'أنثى'
                                ? const Color(0xFFFFCC00)
                                : fieldColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.female,
                                color: _selectedGender == 'أنثى'
                                    ? Colors.black
                                    : subColor,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'أنثى',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedGender == 'أنثى'
                                      ? Colors.black
                                      : textColor,
                                  fontFamily: 'Noto Sans Arabic',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ذكر
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedGender = 'ذكر'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _selectedGender == 'ذكر'
                                ? const Color(0xFFFFCC00)
                                : fieldColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.male,
                                color: _selectedGender == 'ذكر'
                                    ? Colors.black
                                    : subColor,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ذكر',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedGender == 'ذكر'
                                      ? Colors.black
                                      : textColor,
                                  fontFamily: 'Noto Sans Arabic',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ═══════════════════════════════════════
                // حقل تاريخ الميلاد
                // ═══════════════════════════════════════
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime(1990),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.dark(
                              primary: const Color(0xFFFFCC00),
                              onPrimary: Colors.black,
                              surface: cardColor,
                              onSurface: textColor,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        _birthDateController.text =
                        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: _buildTextField(
                      controller: _birthDateController,
                      hint: 'تاريخ الميلاد',
                      icon: Icons.calendar_today_outlined,
                      fieldColor: fieldColor,
                      textColor: textColor,
                      subColor: subColor,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ═══════════════════════════════════════
                // قائمة القسم المسؤول عنه
                // ═══════════════════════════════════════
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: fieldColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedDepartment,
                      hint: Text(
                        'القسم المسؤول عنه',
                        style: TextStyle(
                          color: subColor,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      icon: Icon(Icons.arrow_drop_down, color: subColor),
                      dropdownColor: cardColor,
                      style: TextStyle(
                        color: textColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                      items: _departments.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDepartment = newValue;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ═══════════════════════════════════════
                // عنوان "أمان الحساب"
                // ═══════════════════════════════════════
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'أمان الحساب',
                    style: TextStyle(
                      fontSize: 14,
                      color: subColor,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ═══════════════════════════════════════
                // حقل كلمة المرور
                // ═══════════════════════════════════════
                _buildTextField(
                  controller: _passwordController,
                  hint: 'كلمة المرور',
                  icon: Icons.lock_outline,
                  fieldColor: fieldColor,
                  textColor: textColor,
                  subColor: subColor,
                  isPassword: true,
                ),

                const SizedBox(height: 12),

                // ═══════════════════════════════════════
                // حقل تأكيد كلمة المرور
                // ═══════════════════════════════════════
                _buildTextField(
                  controller: _confirmPasswordController,
                  hint: 'تأكيد كلمة المرور',
                  icon: Icons.verified_user_outlined,
                  fieldColor: fieldColor,
                  textColor: textColor,
                  subColor: subColor,
                  isPassword: true,
                ),

                const SizedBox(height: 24),

                // ═══════════════════════════════════════
                // زر الحفظ
                // ═══════════════════════════════════════
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: حفظ بيانات رئيس القسم
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('حفظ بيانات رئيس القسم - قريباً')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCC00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'اعتماد رئيس القسم',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Noto Sans Arabic',
                      ),
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

  // ═══════════════════════════════════════
  // حقل نصي موحّد
  // ═══════════════════════════════════════
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color fieldColor,
    required Color textColor,
    required Color subColor,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        textDirection: TextDirection.rtl,
        keyboardType: keyboardType,
        obscureText: isPassword,
        style: TextStyle(
          color: textColor,
          fontFamily: 'Noto Sans Arabic',
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: subColor,
            fontFamily: 'Noto Sans Arabic',
          ),
          prefixIcon: Icon(icon, color: subColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}