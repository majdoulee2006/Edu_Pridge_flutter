import 'package:flutter/material.dart';
import 'otp_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  bool isStudent = true;

  // اللون الأصفر الأساسي للهوية البصرية
  static const Color primaryYellow = Color(0xFFF6E300);

  // --- Controllers طالب ---
  final _studentNameController = TextEditingController();
  final _studentEmailController = TextEditingController();
  final _studentPhoneController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _studentPasswordController = TextEditingController();
  final _studentConfirmPasswordController = TextEditingController();

  final List<String> _courseItems = [
    'HEADER:نظم المعلومات', 'معلوماتية', 'ذكاء صنعي', 'الكترون', 'اتصالات',
    'HEADER:طبي', 'مساعد مخبري', 'مساعد صيدلي',
    'HEADER:تجاري', 'محاسبة', 'مصارف', 'إدارة الاعمال', 'تجارة الالكترونية',
    'HEADER:هندسي', 'مساعد مهندس عمارة', 'مساعد مهندس مدني', 'ديكور و إعلان', 'جرافيك ديزاين',
  ];

  // --- Controllers ولي أمر ---
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentPasswordController = TextEditingController();
  final _parentConfirmPasswordController = TextEditingController();

  int _selectedChildrenCount = 1;
  final List<TextEditingController> _parentChildIdControllers = [TextEditingController()];

  @override
  void dispose() {
    // التخلص من جميع الـ Controllers
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
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [Colors.black, scaffoldBg]
                  : [const Color(0xFFFCFAEE), Colors.white],
              stops: const [0.0, 0.2],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  // 1. زر التبديل (Toggle Switch)
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

                  // 2. القسم العلوي (الأيقونة والنصوص)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Column(
                      key: ValueKey<bool>(isStudent),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.amber.withValues(alpha: 0.1) : primaryYellow.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryYellow.withValues(alpha: isDark ? 0.2 : 0.4),
                                blurRadius: 40,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            isStudent ? Icons.school_outlined : Icons.family_restroom,
                            size: 45,
                            color: isDark ? primaryYellow : const Color(0xFF9E7300),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isStudent ? 'ملف الطالب' : 'مرحباً بك',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isStudent ? 'أدخل بياناتك الجامعية لإنشاء الحساب' : 'أنشئ حسابك لمتابعة المسيرة التعليمية لأبنائك',
                          style: TextStyle(fontSize: 14, color: subTextColor),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),

                  // 3. الحقول
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isStudent ? _buildStudentForm(textColor, subTextColor, cardColor) : _buildParentForm(textColor, subTextColor, cardColor),
                  ),

                  const SizedBox(height: 30),

                  // 4. زر إنشاء حساب
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OTPScreen(
                              appBarTitle: "التحقق من الحساب",
                              message: "تم إرسال رمز التحقق المكون من 4 أرقام لتأكيد حسابك",
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryYellow,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back, size: 22),
                          SizedBox(width: 10),
                          Text('إنشاء حساب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 5. رابط تسجيل الدخول
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          text: 'لديك حساب بالفعل؟ ',
                          style: TextStyle(color: subTextColor, fontSize: 14, fontWeight: FontWeight.w600),
                          children: [
                            TextSpan(
                              text: 'تسجيل الدخول',
                              style: TextStyle(
                                color: isDark ? primaryYellow : const Color(0xFFD4AC0D),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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
          decoration: BoxDecoration(
            color: isActive ? primaryYellow : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentForm(Color textColor, Color subTextColor, Color cardColor) {
    return Column(
      key: const ValueKey('student'),
      children: [
        _buildInputField(label: 'الاسم الكامل', hint: 'الاسم الرباعي', icon: Icons.person_outline, controller: _studentNameController, textColor: textColor, cardColor: cardColor),
        _buildInputField(label: 'رقم الهاتف', hint: '05xxxxxxxx', icon: Icons.phone_enabled_outlined, controller: _studentPhoneController, textColor: textColor, cardColor: cardColor),
        _buildInputField(label: 'الرقم الجامعي', hint: '12345678', icon: Icons.badge_outlined, controller: _studentIdController, textColor: textColor, cardColor: cardColor),
        _buildInputField(label: 'البريد الإلكتروني', hint: 'example@university.edu', icon: Icons.email_outlined, controller: _studentEmailController, isEmail: true, textColor: textColor, cardColor: cardColor),
        Row(
          children: [
            Expanded(child: _buildInputField(label: 'القسم', hint: 'اختر...', isDropdown: true, dropdownItems: ['تجاري', 'هندسي', 'طبي', 'نظم المعلومات'], textColor: textColor, cardColor: cardColor)),
            const SizedBox(width: 15),
            Expanded(child: _buildInputField(label: 'الفرع / الدورة', hint: 'اختر...', isDropdown: true, dropdownItems: _courseItems, textColor: textColor, cardColor: cardColor)),
          ],
        ),
        _buildInputField(label: 'كلمة المرور', hint: '........', icon: Icons.lock_outline, controller: _studentPasswordController, isPassword: true, textColor: textColor, cardColor: cardColor),
        _buildInputField(label: 'تأكيد كلمة المرور', hint: '........', icon: Icons.check_circle_outline, controller: _studentConfirmPasswordController, isPassword: true, textColor: textColor, cardColor: cardColor),
      ],
    );
  }

  Widget _buildParentForm(Color textColor, Color subTextColor, Color cardColor) {
    return Column(
      key: const ValueKey('parent'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(label: 'الاسم الكامل', hint: 'الاسم الثلاثي', icon: Icons.person_outline, controller: _parentNameController, textColor: textColor, cardColor: cardColor),
        _buildInputField(label: 'رقم الهاتف', hint: '05xxxxxxxx', icon: Icons.phone_enabled_outlined, controller: _parentPhoneController, textColor: textColor, cardColor: cardColor),
        _buildInputField(
          label: 'عدد الأبناء في المعهد', hint: 'اختر العدد', icon: Icons.people_outline, isDropdown: true, dropdownItems: ['1', '2', '3', '4', '5'],
          value: _selectedChildrenCount.toString(), textColor: textColor, cardColor: cardColor,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                int newCount = int.parse(val);
                if (newCount > _parentChildIdControllers.length) {
                  for (int i = _parentChildIdControllers.length; i < newCount; i++) { _parentChildIdControllers.add(TextEditingController()); }
                } else if (newCount < _parentChildIdControllers.length) {
                  for (int i = _parentChildIdControllers.length - 1; i >= newCount; i--) { _parentChildIdControllers[i].dispose(); _parentChildIdControllers.removeAt(i); }
                }
                _selectedChildrenCount = newCount;
              });
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Row(
            children: [
              Text('أرقام هوية الطلاب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
              const SizedBox(width: 8),
              const Icon(Icons.school, color: primaryYellow, size: 20),
            ],
          ),
        ),
        ...List.generate(_selectedChildrenCount, (index) {
          return _buildInputField(label: 'الرقم الجامعي للابن ${index + 1}', hint: 'مثال: 12345678', controller: _parentChildIdControllers[index], icon: Icons.badge_outlined, textColor: textColor, cardColor: cardColor);
        }),
        const SizedBox(height: 10),
        _buildInputField(label: 'كلمة المرور', hint: '........', icon: Icons.lock_outline, controller: _parentPasswordController, isPassword: true, textColor: textColor, cardColor: cardColor),
        _buildInputField(label: 'تأكيد كلمة المرور', hint: '........', icon: Icons.check_circle_outline, controller: _parentConfirmPasswordController, isPassword: true, textColor: textColor, cardColor: cardColor),
      ],
    );
  }

  Widget _buildInputField({
    required String label, required String hint, IconData? icon, TextEditingController? controller,
    bool isPassword = false, bool isDropdown = false, bool isEmail = false, List<String>? dropdownItems,
    String? value, Function(String?)? onChanged, required Color textColor, required Color cardColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 5.0, bottom: 8.0),
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor.withValues(alpha: 0.8))),
          ),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: textColor.withValues(alpha: 0.1)),
            ),
            child: isDropdown
                ? DropdownButtonFormField<String>(
              dropdownColor: Theme.of(context).cardColor,
              isExpanded: true,
              value: value,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade500, size: 20) : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
              ),
              icon: const Padding(padding: EdgeInsets.only(left: 15.0), child: Icon(Icons.keyboard_arrow_down, color: Colors.grey)),
              items: dropdownItems?.map((String val) {
                bool isHeader = val.startsWith('HEADER:');
                String displayText = isHeader ? val.substring(7) : val;
                return DropdownMenuItem<String>(
                  value: val,
                  enabled: !isHeader,
                  child: Text(displayText, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: isHeader ? FontWeight.w900 : FontWeight.normal, color: isHeader ? primaryYellow : textColor)),
                );
              }).toList(),
              onChanged: onChanged ?? (val) {},
            )
                : TextField(
              controller: controller,
              obscureText: isPassword,
              style: TextStyle(color: textColor),
              textAlign: isEmail ? TextAlign.left : TextAlign.right,
              keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade500, size: 20) : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: icon != null ? 16 : 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}