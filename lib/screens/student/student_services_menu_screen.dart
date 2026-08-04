import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/about_app_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/privacy_policy_screen.dart';
import 'package:edu_pridge_flutter/services/student_services.dart';
import 'package:edu_pridge_flutter/screens/student/student_service_requests_list_screen.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/grades/grades_screen.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/courses/courses_screen.dart';

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
                        Icons.arrow_back,
                        color: textColor,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  body: ListView(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // القسم الأول: الخدمات الأكاديمية والدرجات
                      _buildSectionTitle(isAr ? "الأكاديميات والدرجات" : "Academics & Grades", subColor),
                      const SizedBox(height: 10),

                      _buildServiceCard(
                        icon: Icons.grade_rounded,
                        iconColor: const Color(0xFF4CAF50),
                        title: isAr ? "كشف العلامات الأكاديمية" : "Academic Grades Transcript",
                        subtitle: isAr
                            ? "عرض تفصيلي لدرجات المواد والعملي والشفهي والنهائي"
                            : "Detailed view of course grades, oral, practical & finals",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GradesScreen()),
                        ),
                      ),

                      _buildServiceCard(
                        icon: Icons.menu_book_rounded,
                        iconColor: const Color(0xFF2196F3),
                        title: isAr ? "المواد الدراسية المسجلة" : "Enrolled Courses",
                        subtitle: isAr
                            ? "استعراض المواد والجدول والقاعات والمستندات"
                            : "View courses, timetable, classrooms & lecture files",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CoursesScreen()),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // القسم الثاني: الخدمات الإدارية والطلبات
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

                      _buildServiceCard(
                        icon: Icons.phonelink_lock_rounded,
                        iconColor: const Color(0xFFFFCC00),
                        title: isAr ? "تقديم طلب فك قفل الجهاز" : "Device Unlock Request",
                        subtitle: isAr
                            ? "تقديم طلب لشؤون الطلاب لفك قفل الحساب عن الجهاز القديم"
                            : "Submit request to unlock account from old device",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentServiceRequestsListScreen(
                              serviceType: 'device_reset',
                              titleAr: 'طلبات فك قفل الجهاز',
                              titleEn: 'Device Reset Requests',
                              formScreen: DeviceResetFormScreen(),
                            ),
                          ),
                        ),
                      ),

                      _buildServiceCard(
                        icon: Icons.face_retouching_natural_rounded,
                        iconColor: const Color(0xFFFFCC00),
                        title: isAr ? "طلب تحديث صورة بصمة الوجه" : "Face Photo Change Request",
                        subtitle: isAr
                            ? "تقديم طلب لتغيير صورة بصمة الوجه للتحقق عند تسجيل الحضور"
                            : "Request to update your face recognition photo for attendance",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FacePhotoChangeFormScreen(),
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
                  Icons.arrow_back,
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
                  icon: Icon(Icons.arrow_back, color: textColor),
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
                  icon: Icon(Icons.arrow_back, color: textColor),
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
                  icon: Icon(Icons.arrow_back, color: textColor),
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

// ─── DeviceResetFormScreen ──────────────────────────────────────────────────
class DeviceResetFormScreen extends StatefulWidget {
  const DeviceResetFormScreen({super.key});

  @override
  State<DeviceResetFormScreen> createState() => _DeviceResetFormScreenState();
}

class _DeviceResetFormScreenState extends State<DeviceResetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submitForm(bool isAr) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      String details = "طلب فك قفل الجهاز\nالسبب: ${_reasonController.text.trim()}";
      final result = await ApiService().submitStudentServiceRequest('device_reset', details);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (result != null && result['success'] == true) {
        _showSuccessDialog(isAr);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result?['message'] ?? (isAr ? "حدث خطأ أثناء تقديم الطلب" : "Submission failed"))),
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
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFFFFCC00), size: 60),
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
                    ? "تم تسجيل طلب فك قفل الجهاز الخاص بك وإحالته لشؤون الطلاب لمراجعته."
                    : "Your device reset request has been registered and sent to Student Affairs.",
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

          return Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              backgroundColor: bgColor,
              appBar: AppBar(
                backgroundColor: cardColor,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  isAr ? "طلب فك قفل الجهاز" : "Device Unlock Request",
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      isAr ? "سبب طلب فك القفل (إجباري)" : "Unlock Reason (Mandatory)",
                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 4,
                      style: TextStyle(color: textColor),
                      validator: (val) => val == null || val.trim().isEmpty ? (isAr ? "سبب الطلب مطلوب إجبارياً" : "Reason is required") : null,
                      decoration: InputDecoration(
                        hintText: isAr ? "يرجى توضيح سبب طلب فك القفل وتغيير الجهاز..." : "Explain why you need to unlock and change device...",
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCC00),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _isSubmitting ? null : () => _submitForm(isAr),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(
                              isAr ? "إرسال الطلب لشؤون الطلاب" : "Submit Request to Affairs",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                            ),
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
}

// ─── FacePhotoChangeFormScreen ──────────────────────────────────────────────
class FacePhotoChangeFormScreen extends StatefulWidget {
  const FacePhotoChangeFormScreen({super.key});

  @override
  State<FacePhotoChangeFormScreen> createState() => _FacePhotoChangeFormScreenState();
}

class _FacePhotoChangeFormScreenState extends State<FacePhotoChangeFormScreen> {
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = image.name;
      });
    }
  }

  void _submitPhoto(bool isAr) async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? "يرجى التقاط صورة أولاً" : "Please take a photo first")),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final success = await StudentServices().updateProfileImage(_imageBytes!, _imageName ?? 'face_photo.jpg');
      if (!mounted) return;
      setState(() => _isUploading = false);

      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFFFFCC00), size: 60),
                const SizedBox(height: 15),
                Text(
                  isAr ? "تم رفع الطلب بنجاح" : "Request Submitted",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  isAr
                      ? "تم إرسال صورة بصمة الوجه الجديدة إلى شؤون الطلاب لمطابقتها مع الصورة الحالية والاعتماد."
                      : "The new face photo has been submitted to Student Affairs for review and approval.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCC00)),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  },
                  child: Text(isAr ? "حسنًا" : "OK", style: const TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? "حدث خطأ أثناء رفع الصورة" : "Failed to upload photo")),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? "حدث خطأ: $e" : "Error: $e")),
      );
    }
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

          return Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              backgroundColor: bgColor,
              appBar: AppBar(
                backgroundColor: cardColor,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  isAr ? "طلب تغيير صورة بصمة الوجه" : "Face Photo Change Request",
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCC00).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFFFFCC00).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFFFFCC00)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isAr
                                ? "سيقوم موظف الشؤون بمطابقة صورتك الجديدة مع الصورة المسجلة لديه والموافقة عليها قبل اعتمادها في التحقق من الحضور."
                                : "Student affairs officer will compare your new photo with the stored one before approving.",
                            style: TextStyle(color: textColor, fontSize: 12, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Center(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFCC00), width: 3),
                        image: _imageBytes != null
                            ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _imageBytes == null
                          ? Icon(Icons.face_retouching_natural_rounded, size: 80, color: Colors.grey.shade400)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cardColor,
                        foregroundColor: const Color(0xFFFFCC00),
                        side: const BorderSide(color: Color(0xFFFFCC00)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: Text(isAr ? "التقاط صورة بالكاميرا الأمامية" : "Take Photo with Front Camera"),
                    ),
                  ),
                  const SizedBox(height: 35),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCC00),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _isUploading ? null : () => _submitPhoto(isAr),
                    child: _isUploading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text(
                            isAr ? "تقديم الطلب للمطابقة" : "Submit for Review",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


