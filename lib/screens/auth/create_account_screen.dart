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

  static const Color primaryYellow = Color(0xFFF6E300);

  // المتحكمات بحقول الطالب
  final _studentNameController = TextEditingController();
  final _studentEmailController = TextEditingController();
  final _studentPhoneController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _studentPasswordController = TextEditingController();
  final _studentConfirmPasswordController = TextEditingController();

  final List<String> _courseItems = [
    'معلوماتية', 'ذكاء صنعي', 'الكترون', 'اتصالات',
    'مساعد مخبري', 'مساعد صيدلي',
    'محاسبة', 'مصارف', 'إدارة الاعمال', 'تجارة الالكترونية',
    'مساعد مهندس عمارة', 'مساعد مهندس مدني', 'ديكور و إعلان', 'جرافيك ديزاين',
  ];

  // المتحكمات بحقول ولي الأمر
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentPasswordController = TextEditingController();
  final _parentConfirmPasswordController = TextEditingController();

  int _selectedChildrenCount = 1;
  final List<TextEditingController> _parentChildIdControllers = [TextEditingController()];

  // دالة تسجيل الحساب والربط مع Laravel
  Future<void> _handleRegister() async {
    String p1 = isStudent ? _studentPasswordController.text : _parentPasswordController.text;
    String p2 = isStudent ? _studentConfirmPasswordController.text : _parentConfirmPasswordController.text;

    if (p1 != p2) {
      _showSnackBar('كلمات المرور غير متطابقة!');
      return;
    }

    if (isStudent && (selectedDept == null || selectedBranch == null)) {
      _showSnackBar('الرجاء اختيار القسم والفرع');
      return;
    }

    setState(() => isLoading = true);

    try {
      Dio dio = Dio();
      dio.options.headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      // الـ IP الجديد بناءً على ipconfig الخاص بكِ
      String url = "http://10.119.244.82:8000/api/register";
      Map<String, dynamic> data = {};

      if (isStudent) {
        data = {
          "full_name": _studentNameController.text.trim(),
          "email": _studentEmailController.text.trim(),
          "phone": _studentPhoneController.text.trim(),
          "university_id": _studentIdController.text.trim(),
          "department": selectedDept,
          "branch": selectedBranch,
          "password": _studentPasswordController.text,
          "role": "student",
        };
      } else {
        data = {
          "full_name": _parentNameController.text.trim(),
          "phone": _parentPhoneController.text.trim(),
          "email": "${_parentPhoneController.text.trim()}@parent.com",
          "children_ids": _parentChildIdControllers.map((c) => c.text.trim()).toList(),
          "password": _parentPasswordController.text,
          "role": "parent",
        };
      }

      var response = await dio.post(url, data: data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OTPScreen(
              appBarTitle: "التحقق من الحساب",
              message: "تم إنشاء الحساب بنجاح، أدخل رمز التحقق لتأكيد هويتك",
            ),
          ),
        );
      }
    } on DioException catch (e) {
      String errorMessage = "حدث خطأ في الاتصال بالسيرفر";
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = "انتهت مهلة الاتصال، تأكد من تشغيل السيرفر";
      } else if (e.response != null && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? "البيانات المدخلة غير صحيحة";
      }
      _showSnackBar(errorMessage);
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
        )
    );
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _studentEmailController.dispose();
    _studentPhoneController.dispose();
    _studentIdController.dispose();
    _studentPasswordController.dispose();
    _studentConfirmPasswordController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _parentPasswordController.dispose();
    _parentConfirmPasswordController.dispose();
    for (var controller in _parentChildIdControllers) { controller.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey;
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark ? [Colors.black, theme.scaffoldBackgroundColor] : [const Color(0xFFFCFAEE), Colors.white],
              stops: const [0.0, 0.2],
            ),
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
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        _toggleItem('طالب', isStudent, () => setState(() => isStudent = true)),
                        _toggleItem('ولي أمر', !isStudent, () => setState(() => isStudent = false)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: primaryYellow.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(isStudent ? Icons.school_outlined : Icons.family_restroom, size: 45, color: isDark ? primaryYellow : const Color(0xFF9E7300)),
                      ),
                      const SizedBox(height: 20),
                      Text(isStudent ? 'ملف الطالب' : 'مرحباً بك', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Cairo')),
                      const SizedBox(height: 8),
                      Text(
                        isStudent ? 'أدخل بياناتك الجامعية لإنشاء الحساب' : 'أنشئ حسابك لمتابعة المسيرة التعليمية لأبنائك',
                        style: TextStyle(fontSize: 14, color: subTextColor, fontFamily: 'Cairo'), textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),
                  isStudent ? _buildStudentForm(textColor, cardColor) : _buildParentForm(textColor, cardColor),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryYellow,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_alt_1_outlined, size: 22),
                          SizedBox(width: 10),
                          Text('إنشاء حساب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        text: 'لديك حساب بالفعل؟ ',
                        style: TextStyle(color: subTextColor, fontSize: 14, fontFamily: 'Cairo'),
                        children: [
                          TextSpan(text: 'تسجيل الدخول', style: TextStyle(color: isDark ? primaryYellow : const Color(0xFFD4AC0D), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
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
          decoration: BoxDecoration(color: isActive ? primaryYellow : Colors.transparent, borderRadius: BorderRadius.circular(25)),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(color: isActive ? Colors.black : Colors.grey, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        ),
      ),
    );
  }

  Widget _buildStudentForm(Color textColor, Color cardColor) {
    return Column(
      children: [
        _buildInputField(label: 'الاسم الكامل', hint: 'الاسم الرباعي', icon: Icons.person_outline, controller: _studentNameController, textColor: textColor, cardColor: cardColor),
        _buildInputField(label: 'رقم الهاتف', hint: '05xxxxxxxx', icon: Icons.phone_enabled_outlined, controller: _studentPhoneController, textColor: textColor, cardColor: cardColor),
        _buildInputField(label: 'الرقم الجامعي', hint: 'اسم المستخدم للدخول', icon: Icons.badge_outlined, controller: _studentIdController, textColor: textColor, cardColor: cardColor),
        _buildInputField(label: 'البريد الإلكتروني', hint: 'example@mail.com', icon: Icons.email_outlined, controller: _studentEmailController, isEmail: true, textColor: textColor, cardColor: cardColor),
        Row(
          children: [
            Expanded(child: _buildInputField(label: 'القسم', hint: 'اختر...', isDropdown: true, dropdownItems: ['تجاري', 'هندسي', 'طبي', 'نظم المعلومات'], value: selectedDept, onChanged: (val) => setState(() => selectedDept = val), textColor: textColor, cardColor: cardColor)),
            const SizedBox(width: 8),
            Expanded(child: _buildInputField(label: 'الفرع', hint: 'اختر...', isDropdown: true, dropdownItems: _courseItems, value: selectedBranch, onChanged: (val) => setState(() => selectedBranch = val), textColor: textColor, cardColor: cardColor)),
          ],
        ),
        _buildInputField(label: 'كلمة المرور', hint: '........', icon: Icons.lock_outline, controller: _studentPasswordController, isPassword: true, textColor: textColor, cardColor: cardColor),
        _buildInputField(label: 'تأكيد كلمة المرور', hint: '........', icon: Icons.check_circle_outline, controller: _studentConfirmPasswordController, isPassword: true, textColor: textColor, cardColor: cardColor),
      ],
    );
  }

  Widget _buildParentForm(Color textColor, Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(label: 'الاسم الكامل', hint: 'الاسم الثلاثي', icon: Icons.person_outline, controller: _parentNameController, textColor: textColor, cardColor: cardColor),
        _buildInputField(label: 'رقم الهاتف', hint: 'رقم الموبايل الشخصي', icon: Icons.phone_enabled_outlined, controller: _parentPhoneController, textColor: textColor, cardColor: cardColor),
        _buildInputField(
          label: 'عدد الأبناء', hint: 'اختر العدد', icon: Icons.people_outline, isDropdown: true, dropdownItems: ['1', '2', '3', '4'],
          value: _selectedChildrenCount.toString(), textColor: textColor, cardColor: cardColor,
          onChanged: (val) {
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
          },
        ),
        ...List.generate(_selectedChildrenCount, (index) => _buildInputField(label: 'الرقم الجامعي للابن ${index + 1}', hint: 'أدخل الرقم الجامعي', controller: _parentChildIdControllers[index], icon: Icons.badge_outlined, textColor: textColor, cardColor: cardColor)),
        _buildInputField(label: 'كلمة المرور', hint: '........', icon: Icons.lock_outline, controller: _parentPasswordController, isPassword: true, textColor: textColor, cardColor: cardColor),
        _buildInputField(label: 'تأكيد كلمة المرور', hint: '........', icon: Icons.check_circle_outline, controller: _parentConfirmPasswordController, isPassword: true, textColor: textColor, cardColor: cardColor),
      ],
    );
  }

  // تم تعديل الدالة لحل مشكلة isDark واستخدام withValues
  Widget _buildInputField({
    required String label, required String hint, IconData? icon, TextEditingController? controller,
    bool isPassword = false, bool isDropdown = false, bool isEmail = false, List<String>? dropdownItems,
    String? value, Function(String?)? onChanged, required Color textColor, required Color cardColor,
  }) {
    // حل مشكلة Undefined name 'isDark'
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor.withValues(alpha: 0.7), fontFamily: 'Cairo')),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(30), border: Border.all(color: textColor.withValues(alpha: 0.1))),
            child: isDropdown
                ? DropdownButtonFormField<String>(
              value: value,
              items: dropdownItems?.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, fontFamily: 'Cairo')))).toList(),
              onChanged: onChanged,
              decoration: InputDecoration(prefixIcon: Icon(icon, size: 18), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
              style: TextStyle(color: textColor, fontSize: 13),
              iconSize: 20,
              dropdownColor: isDark ? Colors.grey[900] : Colors.white,
            )
                : TextField(
              controller: controller,
              obscureText: isPassword,
              keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontFamily: 'Cairo'),
                prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade600),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              ),
              style: TextStyle(color: textColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}