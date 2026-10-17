import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/services/affairs_services.dart';

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
  int? _selectedDepartmentId;
  List<dynamic> _departments = [];
  bool _isSubmitting = false;
  final AffairsServices _affairsServices = AffairsServices();

  bool get isAr => AppSettings.language.value == 'ar';

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final meta = await _affairsServices.getMetadata();
    if (!mounted) return;
    setState(() {
      _departments = (meta != null && meta['departments'] is List) ? meta['departments'] : [];
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage(isAr ? 'يرجى تعبئة الاسم والبريد وكلمة المرور' : 'Please fill name, email and password');
      return;
    }
    if (_selectedDepartmentId == null) {
      _showMessage(isAr ? 'يرجى اختيار القسم' : 'Please select a department');
      return;
    }
    if (password.length < 6) {
      _showMessage(isAr ? 'كلمة المرور يجب ألا تقل عن 6 أحرف' : 'Password must be at least 6 characters');
      return;
    }
    if (password != _confirmPasswordController.text) {
      _showMessage(isAr ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match');
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await _affairsServices.createAccount({
      'full_name': name,
      'email': email,
      'phone': _idController.text.trim(),
      'role_id': 5,
      'gender': _selectedGender,
      if (_birthDateController.text.isNotEmpty) 'birth_date': _birthDateController.text,
      'department_id': _selectedDepartmentId,
      'password': password,
    });
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    _showMessage(result['message']?.toString() ??
        (result['success'] == true ? 'تم إنشاء الحساب بنجاح.' : 'فشل إنشاء الحساب'));
    if (result['success'] == true) Navigator.pop(context);
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
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
      textDirection: isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr,
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
                      alignment: isAr ? Alignment.centerLeft : Alignment.centerRight,
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
                      isAr ? "إضافة رئيس قسم" : "Add Head of Department",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                    Align(
                      alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(isAr ? Icons.arrow_back : Icons.arrow_forward, color: textColor, size: 26),
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
                  alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    isAr ? 'البيانات الشخصية' : 'Personal Information',
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
                  hint: isAr ? 'الاسم الكامل لرئيس القسم' : 'Full Name of Department Head',
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
                  hint: isAr ? 'رقم الهاتف' : 'Phone Number',
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
                  hint: isAr ? 'البريد الإلكتروني المهني' : 'Professional Email',
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
                  alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    isAr ? 'تفاصيل إضافية' : 'Additional Details',
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
                                isAr ? 'أنثى' : 'Female',
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
                                isAr ? 'ذكر' : 'Male',
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
                      hint: isAr ? 'تاريخ الميلاد' : 'Date of Birth',
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
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _selectedDepartmentId,
                      hint: Text(
                        isAr ? 'القسم المسؤول عنه' : 'Department Responsible For',
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
                      items: _departments.map((dept) {
                        return DropdownMenuItem<int>(
                          value: int.tryParse(dept['department_id'].toString()),
                          child: Text(dept['name']?.toString() ?? ''),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedDepartmentId = newValue;
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
                  alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    isAr ? 'أمان الحساب' : 'Account Security',
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
                  hint: isAr ? 'كلمة المرور' : 'Password',
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
                  hint: isAr ? 'تأكيد كلمة المرور' : 'Confirm Password',
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
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCC00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : Text(
                      isAr ? 'اعتماد رئيس القسم' : 'Submit Department Head',
                      style: const TextStyle(
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
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
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