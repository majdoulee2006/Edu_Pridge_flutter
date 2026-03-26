import 'package:flutter/material.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  // تحديد حالة التوجل (طالب = true، ولي أمر = false)
  bool isStudent = true;

  // اللون الأصفر المطابق للصور
  static const Color primaryYellow = Color(0xFFF6E300);

  // --- Controllers طالب ---
  final _studentNameController = TextEditingController();
  final _studentEmailController = TextEditingController();
  final _studentPhoneController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _studentPasswordController = TextEditingController();
  final _studentConfirmPasswordController = TextEditingController();

  // 🌟 القائمة الشاملة للدورات مع الأقسام (الكلمات التي تبدأ بـ HEADER: ستظهر كعنوان عريض)
  final List<String> _courseItems = [
    'HEADER:نظم المعلومات',
    'معلوماتية',
    'ذكاء صنعي',
    'الكترون',
    'اتصالات',
    'HEADER:طبي',
    'مساعد مخبري',
    'مساعد صيدلي',
    'HEADER:تجاري',
    'محاسبة',
    'مصارف',
    'إدارة الاعمال',
    'تجارة الالكترونية',
    'HEADER:هندسي',
    'مساعد مهندس عمارة',
    'مساعد مهندس مدني',
    'ديكور و إعلان',
    'جرافيك ديزاين',
  ];

  // --- Controllers ولي أمر ---
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentPasswordController = TextEditingController();
  final _parentConfirmPasswordController = TextEditingController();

  // قائمة Controllers للرقم الجامعي للأبناء
  int _selectedChildrenCount = 1;
  final List<TextEditingController> _parentChildIdControllers = [
    TextEditingController(),
  ];

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

    for (var controller in _parentChildIdControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // لضمان دعم اللغة العربية بشكل كامل
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFCFAEE), Colors.white],
              stops: [0.0, 0.2],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10), // مسافة علوية بديلة لسهم الرجوع
                  // 1. زر التبديل (Toggle Switch)
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isStudent = true),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isStudent
                                    ? primaryYellow
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'طالب',
                                style: TextStyle(
                                  color: isStudent
                                      ? Colors.black
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isStudent = false),
                            child: Container(
                              decoration: BoxDecoration(
                                color: !isStudent
                                    ? primaryYellow
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'ولي أمر',
                                style: TextStyle(
                                  color: !isStudent
                                      ? Colors.black
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),

                  // 2. القسم العلوي (الأيقونة والنصوص)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Column(
                      key: ValueKey<bool>(isStudent),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: primaryYellow.withOpacity(0.15),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryYellow.withOpacity(0.4),
                                blurRadius: 40,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            isStudent
                                ? Icons.school_outlined
                                : Icons.family_restroom,
                            size: 45,
                            color: const Color(0xFF9E7300),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isStudent ? 'ملف الطالب' : 'مرحباً بك',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isStudent
                              ? 'أدخل بياناتك الجامعية لإنشاء الحساب'
                              : 'أنشئ حسابك لمتابعة المسيرة التعليمية لأبنائك',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),

                  // 3. الحقول
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isStudent ? _buildStudentForm() : _buildParentForm(),
                  ),

                  const SizedBox(height: 10),

                  // 4. زر إنشاء حساب
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryYellow,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'إنشاء حساب',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. رابط تسجيل الدخول
                  Center(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pop(context), // العودة لشاشة تسجيل الدخول
                      child: const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // --- فورم الطالب ---
  // ==========================================
  Widget _buildStudentForm() {
    return Column(
      key: const ValueKey('student'),
      children: [
        _buildInputField(
          label: 'الاسم الكامل',
          hint: 'الاسم الثلاثي',
          icon: Icons.person_outline,
          controller: _studentNameController,
        ),
        _buildInputField(
          label: 'البريد الإلكتروني',
          hint: 'student@example.com',
          icon: Icons.mail_outline,
          controller: _studentEmailController,
        ),
        _buildInputField(
          label: 'رقم الهاتف',
          hint: '05xxxxxxxx',
          icon: Icons.smartphone,
          controller: _studentPhoneController,
        ),
        _buildInputField(
          label: 'الرقم الجامعي',
          hint: 'مثال: 12345678',
          icon: Icons.badge_outlined,
          controller: _studentIdController,
        ),

        Row(
          children: [
            // القسم على اليمين
            Expanded(
              child: _buildInputField(
                label: 'القسم',
                hint: 'اختر...',
                isDropdown: true,
                dropdownItems: ['تجاري', 'هندسي', 'طبي', 'نظم المعلومات'],
              ),
            ),
            const SizedBox(width: 15),
            // الدورة على اليسار (مع القائمة المخصصة للعناوين)
            Expanded(
              child: _buildInputField(
                label: 'الفرع / الدورة',
                hint: 'اختر...',
                isDropdown: true,
                dropdownItems: _courseItems,
              ),
            ),
          ],
        ),

        _buildInputField(
          label: 'كلمة المرور',
          hint: '........',
          icon: Icons.lock_outline,
          controller: _studentPasswordController,
          isPassword: true,
        ),
        _buildInputField(
          label: 'تأكيد كلمة المرور',
          hint: '........',
          icon: Icons.check_circle_outline,
          controller: _studentConfirmPasswordController,
          isPassword: true,
        ),
      ],
    );
  }

  // ==========================================
  // --- فورم ولي الأمر ---
  // ==========================================
  Widget _buildParentForm() {
    return Column(
      key: const ValueKey('parent'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          label: 'الاسم الكامل',
          hint: 'الاسم الثلاثي',
          icon: Icons.person_outline,
          controller: _parentNameController,
        ),
        _buildInputField(
          label: 'رقم الهاتف',
          hint: '05xxxxxxxx',
          icon: Icons.smartphone,
          controller: _parentPhoneController,
        ),

        _buildInputField(
          label: 'عدد الأبناء في المعهد',
          hint: 'اختر العدد',
          icon: Icons.people_outline,
          isDropdown: true,
          dropdownItems: ['1', '2', '3', '4', '5'],
          value: _selectedChildrenCount.toString(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                int newCount = int.parse(val);
                if (newCount > _parentChildIdControllers.length) {
                  for (
                    int i = _parentChildIdControllers.length;
                    i < newCount;
                    i++
                  ) {
                    _parentChildIdControllers.add(TextEditingController());
                  }
                } else if (newCount < _parentChildIdControllers.length) {
                  for (
                    int i = _parentChildIdControllers.length - 1;
                    i >= newCount;
                    i--
                  ) {
                    _parentChildIdControllers[i].dispose();
                    _parentChildIdControllers.removeAt(i);
                  }
                }
                _selectedChildrenCount = newCount;
              });
            }
          },
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Row(
            children: const [
              Text(
                'أرقام هوية الطلاب',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.school, color: primaryYellow, size: 20),
            ],
          ),
        ),
        ...List.generate(_selectedChildrenCount, (index) {
          return _buildInputField(
            label: 'الرقم الجامعي للابن ${index + 1}',
            hint: 'مثال: 12345678',
            controller: _parentChildIdControllers[index],
            icon: Icons.badge_outlined,
          );
        }),

        const SizedBox(height: 10),
        _buildInputField(
          label: 'كلمة المرور',
          hint: '........',
          icon: Icons.lock_outline,
          controller: _parentPasswordController,
          isPassword: true,
        ),
        _buildInputField(
          label: 'تأكيد كلمة المرور',
          hint: '........',
          icon: Icons.check_circle_outline,
          controller: _parentConfirmPasswordController,
          isPassword: true,
        ),
      ],
    );
  }

  // ==========================================
  // --- دالة بناء الحقول المخصصة ---
  // ==========================================
  Widget _buildInputField({
    required String label,
    required String hint,
    IconData? icon,
    TextEditingController? controller,
    bool isPassword = false,
    bool isDropdown = false,
    List<String>? dropdownItems,
    String? value,
    Function(String?)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 5.0, bottom: 8.0),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isDropdown
                ? DropdownButtonFormField<String>(
                    value: value,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                      prefixIcon: icon != null
                          ? Icon(icon, color: Colors.grey, size: 20)
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 15,
                      ),
                    ),
                    icon: const Padding(
                      padding: EdgeInsets.only(left: 15.0),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                    ),
                    // 🌟 هنا السحر: تفريق العناوين عن الدورات العادية 🌟
                    items: dropdownItems?.map((String val) {
                      bool isHeader = val.startsWith('HEADER:');
                      String displayText = isHeader ? val.substring(7) : val;

                      return DropdownMenuItem<String>(
                        value: val,
                        enabled: !isHeader, // يمنع الضغط على العناوين
                        child: Text(
                          displayText,
                          style: TextStyle(
                            fontSize: isHeader ? 16 : 14,
                            fontWeight: isHeader
                                ? FontWeight.w900
                                : FontWeight.normal,
                            color: isHeader ? Colors.black : Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: onChanged ?? (val) {},
                  )
                : TextField(
                    controller: controller,
                    obscureText: isPassword,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                      prefixIcon: icon != null
                          ? Icon(icon, color: Colors.grey, size: 20)
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: icon != null ? 15 : 18,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
