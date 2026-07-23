import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/services/student_services.dart';
import 'package:edu_pridge_flutter/screens/student/student_service_requests_list_screen.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

// ─── StudentServicesMenuScreen ──────────────────────────────────────────────
class StudentServicesMenuScreen extends StatelessWidget {
  const StudentServicesMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.isDarkMode,
      builder: (context, isDark, _) => ValueListenableBuilder<double>(
        valueListenable: AppSettings.fontSize,
        builder: (context, fontScale, _) => ValueListenableBuilder<String>(
          valueListenable: AppSettings.language,
          builder: (context, lang, _) {
            final isAr = lang == 'ar';
            final bgColor = isDark ? const Color(0xFF121212) : AppColors.background;
            final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
            final textColor = isDark ? Colors.white : AppColors.textDark;
            final subColor = isDark ? Colors.grey.shade400 : AppColors.textGrey;

            return Directionality(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(fontScale)),
                child: Scaffold(
                  backgroundColor: bgColor,
                  appBar: AppBar(
                    backgroundColor: cardColor,
                    elevation: 0,
                    centerTitle: true,
                    title: Text(
                      isAr ? "الخدمات الطلابية" : "Student Services",
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    leading: IconButton(
                      icon: Icon(
                        isAr ? Icons.arrow_forward : Icons.arrow_back,
                        color: textColor,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  body: ListView(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // القسم الأول: الخدمات الإدارية والطلبات
                      _buildSectionTitle(isAr ? "الخدمات والطلبات الإلكترونية" : "E-Services & Requests", subColor),
                      const SizedBox(height: 10),

                      _buildServiceCard(
                        icon: Icons.gavel_rounded,
                        iconColor: const Color(0xFFFFCC00),
                        title: isAr ? "تقديم طلب استرحام" : "Submit Mercy Petition",
                        subtitle: isAr
                            ? "تقديم طلب عذر طبي، إعادة اختبار، أو مراجعة درجات"
                            : "Submit medical excuses, re-exams, or grade appeals",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentServiceRequestsListScreen(
                              serviceType: 'mercy',
                              titleAr: 'طلبات الاسترحام',
                              titleEn: 'Mercy Petitions',
                              formScreen: MercyPetitionFormScreen(),
                            ),
                          ),
                        ),
                      ),

                      _buildServiceCard(
                        icon: Icons.badge_rounded,
                        iconColor: const Color(0xFFFFCC00),
                        title: isAr ? "استخراج الوثائق الطلابية" : "Extract Student Documents",
                        subtitle: isAr
                            ? "استخراج شهادة قيد، كشف علامات، ومستندات أخرى"
                            : "Request certificates, transcripts, and more",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentServiceRequestsListScreen(
                              serviceType: 'document',
                              titleAr: 'الوثائق الطلابية',
                              titleEn: 'Student Documents',
                              formScreen: LostItemReplacementFormScreen(),
                            ),
                          ),
                        ),
                      ),

                      _buildServiceCard(
                        icon: Icons.assignment_turned_in_rounded,
                        iconColor: const Color(0xFFFFCC00),
                        title: isAr ? "تقديم طلب امتحان إكمال" : "Makeup Exam Request",
                        subtitle: isAr
                            ? "تقديم طلب لإجراء امتحان إكمال للمواد التي لم تنجح بها"
                            : "Submit a request to take a makeup exam",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentServiceRequestsListScreen(
                              serviceType: 'makeup',
                              titleAr: 'امتحانات الإكمال',
                              titleEn: 'Makeup Exams',
                              formScreen: MakeupExamFormScreen(),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),
                      // القسم الثاني: الإعدادات والدعم
                      _buildSectionTitle(isAr ? "إعدادات عامة ومعلومات" : "General Settings & Info", subColor),
                      const SizedBox(height: 10),

                      _buildServiceCard(
                        icon: Icons.settings_rounded,
                        iconColor: AppColors.accent,
                        title: isAr ? "الإعدادات" : "Settings",
                        subtitle: isAr
                            ? "تغيير المظهر، حجم الخط، الإشعارات، واللغة"
                            : "Change theme, font size, notifications, and language",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        ),
                      ),

                      _buildServiceCard(
                        icon: Icons.info_rounded,
                        iconColor: Colors.orange,
                        title: isAr ? "حول التطبيق" : "About App",
                        subtitle: isAr
                            ? "معلومات عن نظام إدارة شؤون الطلاب والنسخة الحالية"
                            : "Information about student management system & version",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AboutAppScreen()),
                        ),
                      ),

                      _buildServiceCard(
                        icon: Icons.privacy_tip_rounded,
                        iconColor: Colors.purple,
                        title: isAr ? "سياسة الاستخدام والخصوصية" : "Privacy Policy & Terms",
                        subtitle: isAr
                            ? "الشروط والسياسات الخاصة باستخدام تطبيق Edu-Bridge"
                            : "Terms of use and privacy policy of Edu-Bridge",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color subColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: subColor,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color cardColor,
    required Color textColor,
    required Color subColor,
    required bool isAr,
  }) {
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.08)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: subColor,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isAr ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded,
                  color: subColor.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── MercyPetitionFormScreen ────────────────────────────────────────────────
class MercyPetitionFormScreen extends StatefulWidget {
  const MercyPetitionFormScreen({super.key});

  @override
  State<MercyPetitionFormScreen> createState() => _MercyPetitionFormScreenState();
}

class _MercyPetitionFormScreenState extends State<MercyPetitionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCourse;
  String? _selectedPetitionType;
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  List<String> _courses = [];
  bool _isLoadingCourses = true;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    final data = await StudentServices().getCourses();
    if (data != null && mounted) {
      setState(() {
        _courses = (data as List).map((e) => e['title'].toString()).toList();
        _isLoadingCourses = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoadingCourses = false;
      });
    }
  }

  final List<String> _petitionTypes = [
    "تقديم طلب تظلم",
    "تقديم طلب استرحام",
    "تقديم طلب للعودة إلى المعهد",
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submitForm(bool isAr) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      
      String details = "نوع الطلب: $_selectedPetitionType\nالمادة: $_selectedCourse\nالسبب/التفاصيل: ${_reasonController.text}";
      
      final result = await ApiService().submitStudentServiceRequest('mercy', details);
      
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      
      if (result != null && result['success'] == true) {
        _showSuccessDialog(isAr);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? "حدث خطأ أثناء الإرسال" : "Submission failed")),
        );
      }
    }
  }

  void _showSuccessDialog(bool isAr) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0x1A008080),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: const Color(0xFFFFCC00), size: 60),
              ),
              const SizedBox(height: 20),
              Text(
                isAr ? "تم إرسال الطلب بنجاح" : "Request Submitted Successfully",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                isAr
                    ? "تم تسجيل طلب الاسترحام الخاص بك وإحالته للموظف المختص. يمكنك متابعة حالته لاحقاً."
                    : "Your petition has been registered and forwarded to the concerned officer. You can track its status later.",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCC00),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(context); // إغلاق الحوار
                  Navigator.pop(context, true); // العودة للشاشة السابقة وتحديث القائمة
                },
                child: Text(
                  isAr ? "حسنًا" : "OK",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.isDarkMode,
      builder: (context, isDark, _) => ValueListenableBuilder<String>(
        valueListenable: AppSettings.language,
        builder: (context, lang, _) {
          final isAr = lang == 'ar';
          final bgColor = isDark ? const Color(0xFF121212) : AppColors.background;
          final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
          final textColor = isDark ? Colors.white : AppColors.textDark;
          final subColor = isDark ? Colors.grey.shade400 : AppColors.textGrey;

          return Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              backgroundColor: bgColor,
              appBar: AppBar(
                backgroundColor: cardColor,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  isAr ? "تقديم طلب استرحام" : "Mercy Petition",
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                leading: IconButton(
                  icon: Icon(isAr ? Icons.arrow_forward : Icons.arrow_back, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // بطاقة التعليمات
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCC00).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFFFFCC00).withOpacity(0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: const Color(0xFFFFCC00), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr ? "إرشادات تقديم الطلب" : "Application Instructions",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: const Color(0xFFFFCC00),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isAr
                                        ? "يرجى ملء النموذج بدقة وإرفاق المستندات الداعمة (مثل التقارير الطبية) لتسريع عملية المراجعة واتخاذ القرار."
                                        : "Please fill the form accurately and attach supporting documents (e.g. medical reports) to expedite the review process.",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFFFFCC00).withOpacity(0.4) : const Color(0xFFFFCC00),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      // نوع الاسترحام
                      Text(
                        isAr ? "نوع طلب الاسترحام *" : "Petition Type *",
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedPetitionType,
                        hint: Text(isAr ? "اختر نوع الطلب" : "Select petition type", style: TextStyle(color: subColor, fontSize: 14)),
                        dropdownColor: cardColor,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (value) => value == null ? (isAr ? "هذا الحقل مطلوب" : "Required field") : null,
                        items: _petitionTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedPetitionType = val),
                      ),
                      const SizedBox(height: 20),

                      // المادة المرتبطة بالطلب
                      if (_selectedPetitionType != "تقديم طلب للعودة إلى المعهد") ...[
                        Text(
                          isAr ? "المادة/المقرر الدراسي المرتبط بالطلب *" : "Associated Course *",
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedCourse,
                          hint: _isLoadingCourses 
                              ? Text(isAr ? "جاري تحميل المواد..." : "Loading courses...", style: TextStyle(color: subColor, fontSize: 14))
                              : Text(isAr ? "اختر المقرر الدراسي" : "Select course", style: TextStyle(color: subColor, fontSize: 14)),
                          dropdownColor: cardColor,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: cardColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          validator: (value) => value == null ? (isAr ? "هذا الحقل مطلوب" : "Required field") : null,
                          items: _courses.map((course) {
                            return DropdownMenuItem<String>(
                              value: course,
                              child: Text(course),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedCourse = val),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // سبب الاسترحام بالتفصيل
                      Text(
                        isAr ? "تفاصيل وأسباب طلب الاسترحام *" : "Details & Reason for Petition *",
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 5,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: cardColor,
                          hintText: isAr
                              ? "اكتب هنا تفاصيل طلبك والسبب الداعي للاسترحام بالتفصيل..."
                              : "Describe the details and reasons of your petition...",
                          hintStyle: TextStyle(color: subColor, fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return isAr ? "يرجى شرح السبب" : "Please explain the reason";
                          }
                          if (value.trim().length < 15) {
                            return isAr ? "يجب أن يحتوي الوصف على 15 حرفاً على الأقل" : "Must be at least 15 characters";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      // زر الإرسال
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFCC00),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          onPressed: _isSubmitting ? null : () => _submitForm(isAr),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                )
                              : Text(
                                  isAr ? "إرسال الطلب" : "Submit Request",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── LostItemReplacementFormScreen ──────────────────────────────────────────
class LostItemReplacementFormScreen extends StatefulWidget {
  const LostItemReplacementFormScreen({super.key});

  @override
  State<LostItemReplacementFormScreen> createState() => _LostItemReplacementFormScreenState();
}

class _LostItemReplacementFormScreenState extends State<LostItemReplacementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _selectedItems = [];
  final TextEditingController _descController = TextEditingController();
  bool _isSubmitting = false;
  bool _agreedToFees = false;

  final List<String> _items = [
    "استخراج شهادة بدل ضائع",
    "استخراج وثيقة كشف علامات",
    "توصيف المنهاج",
    "عدد ساعات التدريس",
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _submitForm(bool isAr) async {
    if (_formKey.currentState!.validate() && _selectedItems.isNotEmpty && _agreedToFees) {
      setState(() => _isSubmitting = true);
      
      String details = "الوثائق: ${_selectedItems.join(', ')}\nملاحظات: ${_descController.text}";
      
      final result = await ApiService().submitStudentServiceRequest('document', details);
      
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      
      if (result != null && result['success'] == true) {
        _showSuccessDialog(isAr);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? "حدث خطأ أثناء الإرسال" : "Submission failed")),
        );
      }
    }
  }

  void _showSuccessDialog(bool isAr) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC00).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: const Color(0xFFFFCC00), size: 60),
              ),
              const SizedBox(height: 20),
              Text(
                isAr ? "تم تسجيل الطلب" : "Request Registered",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                isAr
                    ? "تم استلام طلب استخراج بدل فاقد بنجاح، يرجى مراجعة قسم الشؤون لتأكيد السداد واستلام المستند."
                    : "Lost item replacement request received. Please visit student affairs to confirm payment and collect the document.",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCC00),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(context); // إغلاق الحوار
                  Navigator.pop(context, true); // العودة للشاشة السابقة وتحديث القائمة
                },
                child: Text(
                  isAr ? "حسنًا" : "OK",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.isDarkMode,
      builder: (context, isDark, _) => ValueListenableBuilder<String>(
        valueListenable: AppSettings.language,
        builder: (context, lang, _) {
          final isAr = lang == 'ar';
          final bgColor = isDark ? const Color(0xFF121212) : AppColors.background;
          final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
          final textColor = isDark ? Colors.white : AppColors.textDark;
          final subColor = isDark ? Colors.grey.shade400 : AppColors.textGrey;

          return Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              backgroundColor: bgColor,
              appBar: AppBar(
                backgroundColor: cardColor,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  isAr ? "استخراج الوثائق الطلابية" : "Extract Documents",
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                leading: IconButton(
                  icon: Icon(isAr ? Icons.arrow_forward : Icons.arrow_back, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // معلومات الرسوم والتعليمات
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCC00).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFFFFCC00).withOpacity(0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.payment_rounded, color: const Color(0xFFFFCC00), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr ? "الرسوم والمستندات المطلوبة" : "Fees & Required Documents",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: const Color(0xFFFFCC00),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isAr
                                        ? "تخضع هذه الخدمة لرسوم إدارية رمزية تُسدد في خزينة الجامعة، وسيتطلب الأمر صورة شخصية حديثة عند إصدار البطاقة الجامعية البديلة."
                                        : "This service is subject to nominal administrative fees payable at the university cashier. A recent photo is required for ID cards.",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFFFFCC00).withOpacity(0.4) : const Color(0xFFFFCC00),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      // اختيار المستندات المطلوبة
                      Text(
                        isAr ? "اختر المستندات المطلوبة *" : "Select Items to Request *",
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: _items.map((item) {
                            final isSelected = _selectedItems.contains(item);
                            return CheckboxListTile(
                              title: Text(item, style: TextStyle(color: textColor, fontSize: 14)),
                              value: isSelected,
                              activeColor: const Color(0xFFFFCC00),
                              checkColor: Colors.black,
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              onChanged: (bool? val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedItems.add(item);
                                  } else {
                                    _selectedItems.remove(item);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      if (_selectedItems.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, right: 16, left: 16),
                          child: Text(
                            isAr ? "يرجى اختيار مستند واحد على الأقل" : "Please select at least one document",
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // شرح تفاصيل الطلب
                      Text(
                        isAr ? "تفاصيل إضافية (اختياري)" : "Additional Details (Optional)",
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: cardColor,
                          hintText: isAr
                              ? "يرجى كتابة أي تفاصيل إضافية تود إرفاقها مع الطلب..."
                              : "Please write any additional details...",
                          hintStyle: TextStyle(color: subColor, fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _agreedToFees,
                              activeColor: const Color(0xFFFFCC00),
                              onChanged: (val) {
                                setState(() => _agreedToFees = val ?? false);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _agreedToFees = !_agreedToFees);
                              },
                              child: Text(
                                isAr
                                    ? "وأنا على استعداد لدفع كل ما يترتب علي من رسوم مقابل ذلك"
                                    : "I am ready to pay all the fees incurred for this.",
                                style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // زر الإرسال
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFCC00),
                            disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          onPressed: (_isSubmitting || !_agreedToFees || _selectedItems.isEmpty) 
                              ? null 
                              : () => _submitForm(isAr),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                )
                              : Text(
                                  isAr ? "تقديم الطلب" : "Submit Request",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── MakeupExamFormScreen ──────────────────────────────────────────
class MakeupExamFormScreen extends StatefulWidget {
  const MakeupExamFormScreen({super.key});

  @override
  State<MakeupExamFormScreen> createState() => _MakeupExamFormScreenState();
}

class _MakeupExamFormScreenState extends State<MakeupExamFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _selectedCourses = [];
  final TextEditingController _descController = TextEditingController();
  bool _isSubmitting = false;

  List<String> _availableCourses = [];
  bool _isLoadingCourses = true;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    final data = await StudentServices().getCourses();
    if (data != null && mounted) {
      setState(() {
        _availableCourses = (data as List).map((e) => e['title'].toString()).toList();
        _isLoadingCourses = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoadingCourses = false;
      });
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _submitForm(bool isAr) async {
    if (_formKey.currentState!.validate() && _selectedCourses.isNotEmpty) {
      setState(() => _isSubmitting = true);
      
      String details = "المواد: ${_selectedCourses.join(', ')}\nالسبب: ${_descController.text}";
      
      final result = await ApiService().submitStudentServiceRequest('makeup', details);
      
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      
      if (result != null && result['success'] == true) {
        _showSuccessDialog(isAr);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? "حدث خطأ أثناء الإرسال" : "Submission failed")),
        );
      }
    }
  }

  void _showSuccessDialog(bool isAr) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC00).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFFFFCC00), size: 60),
              ),
              const SizedBox(height: 20),
              Text(
                isAr ? "تم تسجيل الطلب" : "Request Registered",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                isAr
                    ? "تم استلام طلب امتحان الإكمال بنجاح، سيتم مراجعته وإعلامك بالنتيجة قريباً."
                    : "Makeup exam request received. We will review it and notify you soon.",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCC00),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: Text(
                  isAr ? "حسنًا" : "OK",
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.isDarkMode,
      builder: (context, isDark, _) => ValueListenableBuilder<String>(
        valueListenable: AppSettings.language,
        builder: (context, lang, _) {
          final isAr = lang == 'ar';
          final bgColor = isDark ? const Color(0xFF121212) : AppColors.background;
          final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
          final textColor = isDark ? Colors.white : AppColors.textDark;
          final subColor = isDark ? Colors.grey.shade400 : AppColors.textGrey;

          return Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              backgroundColor: bgColor,
              appBar: AppBar(
                backgroundColor: cardColor,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  isAr ? "طلب امتحان إكمال" : "Makeup Exam Request",
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                leading: IconButton(
                  icon: Icon(isAr ? Icons.arrow_forward : Icons.arrow_back, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCC00).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFFFFCC00).withOpacity(0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFFFFCC00), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr ? "تعليمات طلب امتحان الإكمال" : "Instructions",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFFFFCC00),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isAr
                                        ? "يمكنك تقديم طلب امتحان إكمال فقط للمواد التي لم تنجح بها في الفصل السابق."
                                        : "You can only request a makeup exam for courses you failed in the previous semester.",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFFFFCC00).withOpacity(0.4) : const Color(0xFFFFCC00),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      Text(
                        isAr ? "اختر المواد *" : "Select Courses *",
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: _isLoadingCourses 
                          ? Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Center(child: CircularProgressIndicator(color: const Color(0xFFFFCC00))),
                            )
                          : Column(
                          children: _availableCourses.map((course) {
                            final isSelected = _selectedCourses.contains(course);
                            return CheckboxListTile(
                              title: Text(course, style: TextStyle(color: textColor, fontSize: 14)),
                              value: isSelected,
                              activeColor: const Color(0xFFFFCC00),
                              checkColor: Colors.black,
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              onChanged: (bool? val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedCourses.add(course);
                                  } else {
                                    _selectedCourses.remove(course);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      if (_selectedCourses.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, right: 16, left: 16),
                          child: Text(
                            isAr ? "يرجى اختيار مادة واحدة على الأقل" : "Please select at least one course",
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 20),

                      Text(
                        isAr ? "تفاصيل إضافية (اختياري)" : "Additional Details (Optional)",
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: cardColor,
                          hintText: isAr
                              ? "اكتب أي تفاصيل تريد إضافتها..."
                              : "Write any additional details...",
                          hintStyle: TextStyle(color: subColor, fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFCC00),
                            disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          onPressed: (_isSubmitting || _selectedCourses.isEmpty) 
                              ? null 
                              : () => _submitForm(isAr),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                )
                              : Text(
                                  isAr ? "تقديم الطلب" : "Submit Request",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── AboutAppScreen ─────────────────────────────────────────────────────────
class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.isDarkMode,
      builder: (context, isDark, _) => ValueListenableBuilder<String>(
        valueListenable: AppSettings.language,
        builder: (context, lang, _) {
          final isAr = lang == 'ar';
          final bgColor = isDark ? const Color(0xFF121212) : AppColors.background;
          final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
          final textColor = isDark ? Colors.white : AppColors.textDark;
          final subColor = isDark ? Colors.grey.shade400 : AppColors.textGrey;

          return Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              backgroundColor: bgColor,
              appBar: AppBar(
                backgroundColor: cardColor,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  isAr ? "حول التطبيق" : "About App",
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                leading: IconButton(
                  icon: Icon(isAr ? Icons.arrow_forward : Icons.arrow_back, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // شعار التطبيق
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.school_rounded, size: 60, color: Colors.black),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Edu-Bridge",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Version 1.1.0",
                        style: TextStyle(color: subColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      isAr
                          ? "تطبيق Edu-Bridge هو المنصة التعليمية والإدارية الرسمية لتسهيل التواصل والخدمات الجامعية بين الطلاب، أولياء الأمور، المحاضرين، وإدارة شؤون الطلاب."
                          : "Edu-Bridge is the official educational & administrative platform designed to bridge communication and services between students, parents, lecturers, and student affairs.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textColor, fontSize: 14, height: 1.6),
                    ),
                    const SizedBox(height: 35),
                    Divider(color: Colors.grey.withOpacity(0.2)),
                    const SizedBox(height: 20),
                    _buildFeatureRow(
                      icon: Icons.check_circle_rounded,
                      title: isAr ? "متابعة الواجبات والمحاضرات" : "Assignments & Lectures",
                      desc: isAr ? "مشاهدة الجداول اليومية والمهام الأكاديمية المطلوبة وتتبعها." : "View daily schedules and track academic deliverables.",
                      textColor: textColor,
                      subColor: subColor,
                    ),
                    _buildFeatureRow(
                      icon: Icons.qr_code_scanner_rounded,
                      title: isAr ? "تسجيل حضور ذكي" : "Smart Attendance Tracking",
                      desc: isAr ? "تسجيل الحضور والغياب الذكي عبر الـ QR وتأكيد الهوية البيومترية." : "Register attendance securely via QR and face verification.",
                      textColor: textColor,
                      subColor: subColor,
                    ),
                    _buildFeatureRow(
                      icon: Icons.mark_chat_unread_rounded,
                      title: isAr ? "تواصل مباشر وفوري" : "Real-time Messaging",
                      desc: isAr ? "إمكانية المراسلة والتواصل مع الهيئة التدريسية والإدارة بسهولة." : "Direct chat and communication channel with teachers and administration.",
                      textColor: textColor,
                      subColor: subColor,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      isAr ? "© ٢٠٢٦ مشروع تخرج Edu-Bridge. جميع الحقوق محفوظة." : "© 2026 Edu-Bridge Graduation Project. All rights reserved.",
                      style: TextStyle(color: subColor, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String desc,
    required Color textColor,
    required Color subColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFFCC00), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 12, color: subColor, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PrivacyPolicyScreen ────────────────────────────────────────────────────
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.isDarkMode,
      builder: (context, isDark, _) => ValueListenableBuilder<String>(
        valueListenable: AppSettings.language,
        builder: (context, lang, _) {
          final isAr = lang == 'ar';
          final bgColor = isDark ? const Color(0xFF121212) : AppColors.background;
          final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
          final textColor = isDark ? Colors.white : AppColors.textDark;
          final subColor = isDark ? Colors.grey.shade400 : AppColors.textGrey;

          return Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              backgroundColor: bgColor,
              appBar: AppBar(
                backgroundColor: cardColor,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  isAr ? "سياسة الاستخدام والخصوصية" : "Privacy Policy",
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                leading: IconButton(
                  icon: Icon(isAr ? Icons.arrow_forward : Icons.arrow_back, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? "شروط الاستخدام وسياسة الخصوصية" : "Terms & Privacy Policy Statement",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAr ? "آخر تحديث: يوليو ٢٠٢٦" : "Last updated: July 2026",
                      style: TextStyle(color: subColor, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    _buildPolicySection(
                      title: isAr ? "١. جمع البيانات الشخصية" : "1. Collection of Personal Data",
                      content: isAr
                          ? "نقوم بجمع البيانات اللازمة لتسيير العملية التعليمية فقط، ويشمل ذلك الاسم، الرقم الجامعي، سجل الحضور والغياب، والمستوى الدراسي للطلبة لضمان جودة الخدمة."
                          : "We collect data required solely for managing the educational process, including name, student ID, attendance records, and academic levels to ensure quality service.",
                      textColor: textColor,
                    ),
                    _buildPolicySection(
                      title: isAr ? "٢. التحقق البيومتري والوجه" : "2. Biometric Verification & Face IDs",
                      content: isAr
                          ? "عند استخدام ميزة تسجيل الحضور والغياب الذكية القائمة على مسح الوجه، تتم معالجة البيانات والتحقق من الهوية محلياً على جهاز المستخدم أو تشفير بصمة الوجه كقيم مشفرة لا تسمح بإعادة بناء ملامح الوجه."
                          : "When using smart attendance with face verification, data verification is processed locally or stored as encrypted embeddings to guarantee that facial structures cannot be reconstructed.",
                      textColor: textColor,
                    ),
                    _buildPolicySection(
                      title: isAr ? "٣. حماية وأمن المعلومات" : "3. Information Security & Protection",
                      content: isAr
                          ? "نحن ملتزمون بتطبيق أعلى المعايير الأمنية لحماية بياناتكم من الوصول غير المصرح به أو التعديل أو التسريب عبر استخدام بروتوكولات اتصال مشفرة وحفظ البيانات في خوادم آمنة."
                          : "We are committed to applying high security standards to protect your data from unauthorized access, modification, or leakage through secure transmission protocols and database encryptions.",
                      textColor: textColor,
                    ),
                    _buildPolicySection(
                      title: isAr ? "٤. التحديثات والتعديلات" : "4. Policy Amendments",
                      content: isAr
                          ? "قد نقوم بتحديث هذه السياسة من وقت لآخر لمواكبة التغييرات التشريعية أو التقنية في الجامعة. يُرجى مراجعة هذه الصفحة دورياً للاطلاع على أي تحديثات."
                          : "We may update this policy periodically to align with legislative or technical improvements in the university. Please check this page regularly for updates.",
                      textColor: textColor,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPolicySection({
    required String title,
    required String content,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFFFFCC00)),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.8), height: 1.6),
          ),
        ],
      ),
    );
  }
}


