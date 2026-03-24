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

  // --- Controllers ولي أمر ---
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentChildIdController = TextEditingController(); // الرقم الجامعي للابن 1
  final _parentPasswordController = TextEditingController();
  final _parentConfirmPasswordController = TextEditingController();

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
    _parentChildIdController.dispose();
    _parentPasswordController.dispose();
    _parentConfirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // لضمان دعم اللغة العربية بشكل كامل
      child: Scaffold(
        body: Container(
          // خلفية مدمجة خفيفة جداً كما في التصميم
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. الترويسة (زر الرجوع + العنوان)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward, color: Colors.black, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      Text(
                        isStudent ? 'إنشاء حساب طالب' : 'إنشاء حساب ولي أمر',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // 2. زر التبديل (Toggle Switch) المطابق للصورة
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        // زر طالب (يمين)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isStudent = true),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isStudent ? primaryYellow : Colors.transparent,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'طالب',
                                style: TextStyle(
                                  color: isStudent ? Colors.black : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // زر ولي أمر (يسار)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isStudent = false),
                            child: Container(
                              decoration: BoxDecoration(
                                color: !isStudent ? primaryYellow : Colors.transparent,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'ولي أمر',
                                style: TextStyle(
                                  color: !isStudent ? Colors.black : Colors.grey[600],
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
                  const SizedBox(height: 30),

                  // 3. الحقول (بناءً على اختيار التوجل)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isStudent ? _buildStudentForm() : _buildParentForm(),
                  ),

                  const SizedBox(height: 10),

                  // 4. زر إنشاء حساب (الأصفر العريض)
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        // منطق التسجيل
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryYellow,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('إنشاء حساب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. رابط تسجيل الدخول في الأسفل
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'تسجيل الدخول',
                        style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
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
  // --- فورم الطالب (نسخة طبق الأصل) ---
  // ==========================================
  Widget _buildStudentForm() {
    return Column(
      key: const ValueKey('student'),
      children: [
        _buildInputField(label: 'الاسم الكامل', hint: 'الاسم الثلاثي', icon: Icons.person_outline, controller: _studentNameController),
        _buildInputField(label: 'البريد الإلكتروني', hint: 'student@example.com', icon: Icons.mail_outline, controller: _studentEmailController),
        _buildInputField(label: 'رقم الهاتف', hint: '05xxxxxxxx', icon: Icons.smartphone, controller: _studentPhoneController),
        _buildInputField(label: 'الرقم الجامعي', hint: 'مثال: 20230001', icon: Icons.badge_outlined, controller: _studentIdController),
        
        _buildInputField(label: 'القسم', hint: 'اختر القسم', icon: Icons.domain, isDropdown: true, dropdownItems: ['هندسة', 'طب', 'علوم']),
        _buildInputField(label: 'الدورة', hint: 'اختر الدورة', icon: Icons.school_outlined, isDropdown: true, dropdownItems: ['دورة 1', 'دورة 2']),
        
        _buildInputField(label: 'كلمة المرور', hint: '........', icon: Icons.lock_outline, controller: _studentPasswordController, isPassword: true),
        _buildInputField(label: 'تأكيد كلمة المرور', hint: '........', icon: Icons.check_circle_outline, controller: _studentConfirmPasswordController, isPassword: true),
      ],
    );
  }

  // ==========================================
  // --- فورم ولي الأمر (نسخة طبق الأصل) ---
  // ==========================================
  Widget _buildParentForm() {
    return Column(
      key: const ValueKey('parent'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(label: 'الاسم الكامل', hint: 'الاسم الثلاثي', icon: Icons.person_outline, controller: _parentNameController),
        _buildInputField(label: 'رقم الهاتف', hint: '05xxxxxxxx', icon: Icons.smartphone, controller: _parentPhoneController),
        _buildInputField(label: 'عدد الأبناء في المعهد', hint: 'اختر العدد', icon: Icons.people_outline, isDropdown: true, dropdownItems: ['1', '2', '3', '4']),
        
        // القسم المخصص: أرقام هوية الطلاب
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text('أرقام هوية الطلاب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
                  SizedBox(width: 8),
                  Icon(Icons.school, color: primaryYellow, size: 20),
                ],
              ),
              const SizedBox(height: 15),
              _buildInputField(label: 'الرقم الجامعي للابن 1', hint: 'مثال: 20230001', controller: _parentChildIdController, icon: null),
            ],
          ),
        ),

        _buildInputField(label: 'كلمة المرور', hint: '........', icon: Icons.lock_outline, controller: _parentPasswordController, isPassword: true),
        _buildInputField(label: 'تأكيد كلمة المرور', hint: '........', icon: Icons.check_circle_outline, controller: _parentConfirmPasswordController, isPassword: true),
      ],
    );
  }

  // ==========================================
  // --- دالة بناء الحقول المخصصة ---
  // ==========================================
  Widget _buildInputField({
    required String label,
    required String hint,
    IconData? icon, // اختياري في حال لم نرد أيقونة
    TextEditingController? controller,
    bool isPassword = false,
    bool isDropdown = false,
    List<String>? dropdownItems,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // التسمية فوق الحقل
          Padding(
            padding: const EdgeInsets.only(right: 5.0, bottom: 8.0),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black),
            ),
          ),
          // الحقل الأبيض مع الظل الناعم
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
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                      prefixIcon: icon != null ? Icon(icon, color: Colors.grey, size: 20) : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    ),
                    icon: const Padding(
                      padding: EdgeInsets.only(left: 15.0),
                      child: Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ),
                    items: dropdownItems?.map((String val) {
                      return DropdownMenuItem<String>(
                        value: val,
                        child: Text(val, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {},
                  )
                : TextField(
                    controller: controller,
                    obscureText: isPassword,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                      prefixIcon: icon != null ? Icon(icon, color: Colors.grey, size: 20) : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: icon != null ? 15 : 18),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}