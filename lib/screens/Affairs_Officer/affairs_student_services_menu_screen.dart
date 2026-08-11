import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/about_app_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/privacy_policy_screen.dart';
import 'package:edu_pridge_flutter/screens/admin/admin_student_services_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/center_icons/academic_card/affairs_academic_card_screen.dart';

class AffairsStudentServicesMenuScreen extends StatelessWidget {
  const AffairsStudentServicesMenuScreen({super.key});

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
                      isAr ? "قائمة الخدمات والإعدادات" : "Services & Settings Menu",
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
                      _buildSectionTitle(
                        isAr ? "طلبات الطلاب والخدمات الإلكترونية" : "Student Electronic Services",
                        subColor,
                      ),
                      const SizedBox(height: 12),

                      _buildServiceCard(
                        icon: Icons.history_edu_rounded,
                        iconColor: const Color(0xFFFFCC00),
                        title: isAr ? "استعلام كشف العلامات" : "Academic Card Search",
                        subtitle: isAr
                            ? "البحث عن بطاقات الطلاب حسب القسم والدورة وتصديرها PDF و Excel"
                            : "Search student academic cards by department/batch & export PDF/Excel",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AffairsAcademicCardScreen(),
                          ),
                        ),
                      ),

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

                      _buildServiceCard(
                        icon: Icons.phonelink_erase_rounded,
                        iconColor: const Color(0xFFFFCC00),
                        title: isAr ? "طلبات فك قفل الجهاز" : "Device Reset Requests",
                        subtitle: isAr
                            ? "مراجعة واعتماد طلبات الطلاب لفك ربط/قفل الجهاز وتصفيره"
                            : "Review and approve student device unlock requests",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminStudentServicesScreen(
                              serviceType: 'device_reset',
                              titleAr: 'طلبات فك قفل الجهاز',
                              titleEn: 'Device Reset Requests',
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
}
