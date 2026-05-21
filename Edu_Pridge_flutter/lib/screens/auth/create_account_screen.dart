import 'package:flutter/material.dart';
import 'otp_screen.dart';
import 'package:dio/dio.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  bool isStudent = true;
  bool isLoading = false;

  String? selectedDept;
  String? selectedBranch;
  String? selectedGender;
  String? selectedYear;
  DateTime? selectedBirthDate;

  static const Color primaryYellow = Color(0xFFF6E300);

  final Map<String, List<String>> _departmentData = {
    'نظم المعلومات': ['ذكاء صنعي', 'الكترون', 'معلوماتية', 'اتصالات'],
    'طبي': ['مساعد صيدلي', 'مساعد مخبري'],
    'تجاري': ['محاسبة', 'مصارف', 'إدارة اعمال', 'تجارة الكترونية'],
    'هندسي': ['مساعد مهندس ديكور', 'مساعد مهندس مدني', 'ديكور واعلان'],
  };

  final _studentNameController = TextEditingController();
  final _studentEmailController = TextEditingController();
  final _studentPhoneController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _studentPasswordController = TextEditingController();
  final _studentConfirmPasswordController = TextEditingController();

  final _parentNameController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentPasswordController = TextEditingController();
  final _parentConfirmPasswordController = TextEditingController();

  int _selectedChildrenCount = 1;
  final List<TextEditingController> _parentChildIdControllers = [TextEditingController()];

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: primaryYellow,
            onPrimary: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedBirthDate = picked);
  }

  Future<void> _handleRegister() async {
    String p1 = isStudent ? _studentPasswordController.text : _parentPasswordController.text;
    String p2 = isStudent ? _studentConfirmPasswordController.text : _parentConfirmPasswordController.text;

    if (p1 != p2) { _showSnackBar('كلمات المرور غير متطابقة!'); return; }

    String email = isStudent ? _studentEmailController.text.trim() : _parentEmailController.text.trim();
    if (email.isEmpty) { _showSnackBar('يرجى إدخال البريد الإلكتروني'); return; }

    if (isStudent && (selectedDept == null || selectedBranch == null || selectedGender == null || selectedYear == null || selectedBirthDate == null)) {
      _showSnackBar('يرجى إكمال كافة البيانات المطلوبة'); return;
    }

    setState(() => isLoading = true);

    try {
      Dio dio = Dio();
      String url = "http://127.0.0.1:8000/api/register";

      Map<String, dynamic> data = isStudent ? {
        "full_name": _studentNameController.text.trim(),
        "email": _studentEmailController.text.trim(),
        "phone": _studentPhoneController.text.trim(),
        "university_id": _studentIdController.text.trim(),
        "gender": selectedGender,
        "birth_date": selectedBirthDate.toString().split(' ')[0],
        "academic_year": selectedYear,
        "department": selectedDept,
        "branch": selectedBranch,
        "password": _studentPasswordController.text,
        "role": "student",
      } : {
        "full_name": _parentNameController.text.trim(),
        "email": _parentEmailController.text.trim(),
        "phone": _parentPhoneController.text.trim(),
        "children_ids": _parentChildIdControllers.map((c) => c.text.trim()).toList(),
        "password": _parentPasswordController.text,
        "role": "parent",
      };

      var response = await dio.post(url, data: data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(
              email: email,
              appBarTitle: "التحقق من الحساب",
            ),
          ),
        );
      }
    } on DioException catch (e) {
      _showSnackBar(e.response?.data['message'] ?? "خطأ في تسجيل البيانات");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark; // تم التعريف هنا
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark ? [Colors.black, theme.scaffoldBackgroundColor] : [const Color(0xFFFCFAEE), Colors.white],
                  stops: const [0.0, 0.2]
              )
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                children: [
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(25)
                    ),
                    child: Row(
                      children: [
                        _toggleItem('طالب', isStudent, () => setState(() => isStudent = true)),
                        _toggleItem('ولي أمر', !isStudent, () => setState(() => isStudent = false)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),
                  Icon(isStudent ? Icons.school_outlined : Icons.family_restroom, size: 60, color: primaryYellow),
                  const SizedBox(height: 15),
                  Text(isStudent ? 'بيانات الطالب' : 'بيانات ولي الأمر',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Cairo')),
                  const SizedBox(height: 35),

                  // 💡 تم تمرير isDark هنا للدوال الفرعية
                  isStudent ? _buildStudentForm(textColor, cardColor, isDark) : _buildParentForm(textColor, cardColor, isDark),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryYellow,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text('إنشاء حساب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Cairo')),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text.rich(
                        TextSpan(
                            text: 'لديك حساب بالفعل؟ ',
                            style: TextStyle(color: textColor.withOpacity(0.6), fontFamily: 'Cairo', fontSize: 14),
                            children: const [
                              TextSpan(text: 'تسجيل الدخول', style: TextStyle(color: primaryYellow, fontWeight: FontWeight.bold, decoration: TextDecoration.underline))
                            ]
                        )
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleItem(String title, bool isActive, VoidCallback onTap) {
    return Expanded(
        child: GestureDetector(
            onTap: onTap,
            child: Container(
                decoration: BoxDecoration(
                    color: isActive ? primaryYellow : Colors.transparent,
                    borderRadius: BorderRadius.circular(25)
                ),
                alignment: Alignment.center,
                child: Text(title, style: TextStyle(color: isActive ? Colors.black : Colors.grey, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))
            )
        )
    );
  }

  // 💡 أضفنا isDark كمعامل
  Widget _buildStudentForm(Color textColor, Color cardColor, bool isDark) {
    return Column(
      children: [
        _buildInputField(label: 'الاسم الكامل', hint: 'الاسم الرباعي', icon: Icons.person_outline, controller: _studentNameController, textColor: textColor, cardColor: cardColor, isDark: isDark),
        Row(
          children: [
            Expanded(child: _buildInputField(label: 'الجنس', hint: 'اختر', isDropdown: true, dropdownItems: ['ذكر', 'أنثى'], value: selectedGender, onChanged: (val) => setState(() => selectedGender = val), textColor: textColor, cardColor: cardColor, isDark: isDark)),
            const SizedBox(width: 10),
            Expanded(child: _buildInputField(label: 'السنة', hint: 'اختر', isDropdown: true, dropdownItems: ['أولى', 'ثانية'], value: selectedYear, onChanged: (val) => setState(() => selectedYear = val), textColor: textColor, cardColor: cardColor, isDark: isDark)),
          ],
        ),
        GestureDetector(
            onTap: _pickDate,
            child: AbsorbPointer(child: _buildInputField(label: 'تاريخ الميلاد', hint: selectedBirthDate == null ? 'حدد التاريخ' : "${selectedBirthDate!.toLocal()}".split(' ')[0], icon: Icons.calendar_today_outlined, textColor: textColor, cardColor: cardColor, isDark: isDark))
        ),
        _buildInputField(label: 'رقم الهاتف', hint: '09xxxxxxxx', icon: Icons.phone_enabled_outlined, controller: _studentPhoneController, textColor: textColor, cardColor: cardColor, isDark: isDark),
        _buildInputField(label: 'الرقم الجامعي', hint: 'رقم البطاقة الجامعية', icon: Icons.badge_outlined, controller: _studentIdController, textColor: textColor, cardColor: cardColor, isDark: isDark),
        _buildInputField(label: 'البريد الإلكتروني', hint: 'example@mail.com', icon: Icons.email_outlined, controller: _studentEmailController, textColor: textColor, cardColor: cardColor, isDark: isDark),
        Row(
          children: [
            Expanded(child: _buildInputField(label: 'القسم', hint: 'اختر القسم', isDropdown: true, dropdownItems: _departmentData.keys.toList(), value: selectedDept, onChanged: (val) { setState(() { selectedDept = val; selectedBranch = null; }); }, textColor: textColor, cardColor: cardColor, isDark: isDark)),
            const SizedBox(width: 10),
            Expanded(child: _buildInputField(label: 'الفرع', hint: 'اختر الفرع', isDropdown: true, dropdownItems: selectedDept == null ? [] : _departmentData[selectedDept!], value: selectedBranch, onChanged: (val) => setState(() => selectedBranch = val), textColor: textColor, cardColor: cardColor, isDark: isDark)),
          ],
        ),
        _buildInputField(label: 'كلمة المرور', hint: '........', icon: Icons.lock_outline, controller: _studentPasswordController, isPassword: true, textColor: textColor, cardColor: cardColor, isDark: isDark),
        _buildInputField(label: 'تأكيد كلمة المرور', hint: '........', icon: Icons.check_circle_outline, controller: _studentConfirmPasswordController, isPassword: true, textColor: textColor, cardColor: cardColor, isDark: isDark),
      ],
    );
  }

  // 💡 أضفنا isDark كمعامل
  Widget _buildParentForm(Color textColor, Color cardColor, bool isDark) {
    return Column(
      children: [
        _buildInputField(label: 'الاسم الكامل', hint: 'الاسم الثلاثي', icon: Icons.person_outline, controller: _parentNameController, textColor: textColor, cardColor: cardColor, isDark: isDark),
        _buildInputField(label: 'البريد الإلكتروني', hint: 'parent@example.com', icon: Icons.email_outlined, controller: _parentEmailController, textColor: textColor, cardColor: cardColor, isDark: isDark),
        _buildInputField(label: 'رقم الهاتف', hint: 'رقم الموبايل الشخصي', icon: Icons.phone_enabled_outlined, controller: _parentPhoneController, textColor: textColor, cardColor: cardColor, isDark: isDark),
        _buildInputField(label: 'عدد الأبناء', hint: 'العدد', isDropdown: true, dropdownItems: ['1', '2', '3', '4'], value: _selectedChildrenCount.toString(), textColor: textColor, cardColor: cardColor, isDark: isDark, onChanged: (val) {
          if (val != null) {
            setState(() {
              int newCount = int.parse(val);
              if (newCount > _parentChildIdControllers.length) {
                for (int i = _parentChildIdControllers.length; i < newCount; i++) { _parentChildIdControllers.add(TextEditingController()); }
              } else {
                for (int i = _parentChildIdControllers.length - 1; i >= newCount; i--) { _parentChildIdControllers.removeAt(i); }
              }
              _selectedChildrenCount = newCount;
            });
          }
        }),
        ...List.generate(_selectedChildrenCount, (index) => _buildInputField(label: 'الرقم الجامعي للابن ${index + 1}', hint: 'أدخل الرقم الجامعي', controller: _parentChildIdControllers[index], icon: Icons.badge_outlined, textColor: textColor, cardColor: cardColor, isDark: isDark)),
        _buildInputField(label: 'كلمة المرور', hint: '........', icon: Icons.lock_outline, controller: _parentPasswordController, isPassword: true, textColor: textColor, cardColor: cardColor, isDark: isDark),
        _buildInputField(label: 'تأكيد كلمة المرور', hint: '........', icon: Icons.check_circle_outline, controller: _parentConfirmPasswordController, isPassword: true, textColor: textColor, cardColor: cardColor, isDark: isDark),
      ],
    );
  }

  // 💡 أضفنا isDark هنا أيضاً
  Widget _buildInputField({required String label, required String hint, IconData? icon, TextEditingController? controller, bool isPassword = false, bool isDropdown = false, List<String>? dropdownItems, String? value, Function(String?)? onChanged, required Color textColor, required Color cardColor, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor.withOpacity(0.7), fontFamily: 'Cairo')),
          const SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(30), border: Border.all(color: textColor.withOpacity(0.1))),
            child: isDropdown
                ? DropdownButtonFormField<String>(
              initialValue: value,
              items: (dropdownItems ?? []).map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, fontFamily: 'Cairo')))).toList(),
              onChanged: onChanged,
              decoration: InputDecoration(prefixIcon: Icon(icon, size: 18), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 10)),
              dropdownColor: isDark ? Colors.grey[900] : Colors.white, // هنا استخدمنا isDark الممررة
              style: TextStyle(color: textColor, fontSize: 13),
            )
                : TextField(
              controller: controller, obscureText: isPassword,
              decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontFamily: 'Cairo'), prefixIcon: Icon(icon, size: 18), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
              style: TextStyle(color: textColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _studentNameController.dispose(); _studentEmailController.dispose(); _studentPhoneController.dispose();
    _studentIdController.dispose(); _studentPasswordController.dispose(); _studentConfirmPasswordController.dispose();
    _parentNameController.dispose(); _parentEmailController.dispose(); _parentPhoneController.dispose();
    _parentPasswordController.dispose(); _parentConfirmPasswordController.dispose();
    for (var c in _parentChildIdControllers) { c.dispose(); }
    super.dispose();
  }
}