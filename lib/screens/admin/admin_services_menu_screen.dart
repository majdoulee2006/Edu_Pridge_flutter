import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/about_app_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/privacy_policy_screen.dart';
import 'package:edu_pridge_flutter/screens/student/student_services_menu_screen.dart';
import 'package:edu_pridge_flutter/screens/admin/admin_student_services_screen.dart';
import 'package:edu_pridge_flutter/services/admin_services.dart';
import 'package:edu_pridge_flutter/screens/admin/center_icons/courses/department_setup_wizard.dart';

class AdminServicesMenuScreen extends StatelessWidget {
  const AdminServicesMenuScreen({super.key});

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
                      isAr ? "خدمات وقائمة الإدارة العامة" : "Admin Services & Menu",
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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
                      // القسم الأول: الإدارة الأكاديمية والهيكلية
                      _buildSectionTitle(
                        isAr ? "الإدارة الأكاديمية والهيكلية" : "Academic & Structure Management",
                        subColor,
                      ),
                      const SizedBox(height: 10),

                      _buildServiceCard(
                        icon: Icons.domain_add_rounded,
                        iconColor: const Color(0xFFFFCC00),
                        title: isAr ? "إضافة قسم أكاديمي جديد" : "Add New Academic Department",
                        subtitle: isAr
                            ? "إنشاء قسم جديد وإضافته للنظام لتوزيع المواد ورؤساء الأقسام"
                            : "Create and register a new department in the system",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => _showAddDepartmentDialog(context, isDark, cardColor, textColor, isAr),
                      ),

                      const SizedBox(height: 20),

                      // القسم الثاني: الخدمات والطلبات الطلابية الإلكترونية
                      _buildSectionTitle(
                        isAr ? "الخدمات والطلبات الطلابية" : "Student Services & Requests",
                        subColor,
                      ),
                      const SizedBox(height: 10),

                      _buildServiceCard(
                        icon: Icons.gavel_rounded,
                        iconColor: const Color(0xFFFFCC00),
                        title: isAr ? "طلبات الاسترحام" : "Mercy Petitions",
                        subtitle: isAr
                            ? "مراجعة واعتماد طلبات الاعذار الطبية ومراجعة الدرجات"
                            : "Review and approve medical excuses and re-exams",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminStudentServicesScreen(
                              serviceType: 'mercy',
                              titleAr: 'طلبات الاسترحام',
                              titleEn: 'Mercy Petitions',
                            ),
                          ),
                        ),
                      ),

                      _buildServiceCard(
                        icon: Icons.badge_rounded,
                        iconColor: const Color(0xFFFFCC00),
                        title: isAr ? "طلبات الوثائق الطلابية" : "Student Documents Requests",
                        subtitle: isAr
                            ? "مراجعة وتصديق استخراج كشوفات العلامات وشهادات القيد"
                            : "Review and approve transcript & certificate requests",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminStudentServicesScreen(
                              serviceType: 'document',
                              titleAr: 'طلبات الوثائق الطلابية',
                              titleEn: 'Student Documents Requests',
                            ),
                          ),
                        ),
                      ),

                      _buildServiceCard(
                        icon: Icons.assignment_turned_in_rounded,
                        iconColor: const Color(0xFFFFCC00),
                        title: isAr ? "امتحانات الإكمال" : "Makeup Exam Requests",
                        subtitle: isAr
                            ? "مراجعة واعتماد طلبات إجراء امتحانات الإكمال للمواد"
                            : "Review and approve makeup exam requests",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminStudentServicesScreen(
                              serviceType: 'makeup',
                              titleAr: 'امتحانات الإكمال',
                              titleEn: 'Makeup Exam Requests',
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // القسم الثاني: الإعدادات العامة والمعلومات
                      _buildSectionTitle(
                        isAr ? "إعدادات عامة ومعلومات" : "General Settings & Info",
                        subColor,
                      ),
                      const SizedBox(height: 10),

                      _buildServiceCard(
                        icon: Icons.settings_rounded,
                        iconColor: const Color(0xFFFFCC00),
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
                            ? "معلومات عن نظام إدارة شؤون المعهد والنسخة الحالية"
                            : "Information about institute management system & version",
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
    required Color cardColor,
    required Color textColor,
    required Color subColor,
    required bool isAr,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              color: subColor,
              fontSize: 12,
            ),
          ),
        ),
        trailing: Icon(
          isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
          color: subColor,
        ),
      ),
    );
  }

  void _showAddDepartmentDialog(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color textColor,
    bool isAr,
  ) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCC00).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.domain_add_rounded, color: Color(0xFFFFCC00)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isAr ? "إضافة قسم أكاديمي جديد" : "Add New Department",
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: isAr ? "اسم القسم *" : "Department Name *",
                          labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.business_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return isAr ? "يرجى إدخال اسم القسم" : "Department name is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        maxLines: 3,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: isAr ? "الوصف (اختياري)" : "Description (Optional)",
                          labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.description_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    isAr ? "إلغاء" : "Cancel",
                    style: TextStyle(color: textColor.withOpacity(0.7)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() => isSubmitting = true);
                            final createdDept = await AdminServices().createDepartment({
                              'name': nameController.text.trim(),
                              'description': descController.text.trim().isEmpty ? null : descController.text.trim(),
                            });
                            setState(() => isSubmitting = false);
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              if (createdDept != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isAr ? "تم إنشاء القسم الجديد بنجاح!" : "Department created successfully!",
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                // Show setup wizard
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => DepartmentSetupWizard(
                                    departmentId: createdDept['department_id'],
                                    departmentName: createdDept['name'] ?? '',
                                    onFinished: () {},
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isAr ? "فشل إنشاء القسم، يرجى المحاولة لاحقاً" : "Failed to create department",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          isAr ? "إضافة" : "Add",
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
