import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/about_app_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/privacy_policy_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/center_icons/academic_card/parent_children_academic_card_screen.dart';

class ParentServicesMenuScreen extends StatelessWidget {
  final String parentName;

  const ParentServicesMenuScreen({super.key, this.parentName = 'ولي أمر'});

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
                      // Section 1: Academic Services for Children
                      _buildSectionTitle(
                        isAr ? "خدمات الأبناء الأكاديمية" : "Children Academic Services",
                        subColor,
                      ),
                      const SizedBox(height: 12),

                      _buildServiceCard(
                        icon: Icons.history_edu_rounded,
                        iconColor: const Color(0xFFFFCC00),
                        title: isAr ? "كشف علامات الأبناء" : "Children Academic Card",
                        subtitle: isAr
                            ? "متابعة كشوفات الدرجات والمعدل الأكاديمي للأبناء وتصديرها PDF و Excel"
                            : "View children course grades, GPA, and export PDF/Excel",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ParentChildrenAcademicCardScreen(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section 2: General Settings & Info
                      _buildSectionTitle(
                        isAr ? "إعدادات عامة ومعلومات" : "General Settings & Info",
                        subColor,
                      ),
                      const SizedBox(height: 12),

                      _buildServiceCard(
                        icon: Icons.settings_outlined,
                        iconColor: const Color(0xFFFFCC00),
                        title: isAr ? "الإعدادات العامة" : "General Settings",
                        subtitle: isAr
                            ? "تعديل اللغة، المظهر الداكن، والإشعارات"
                            : "Change language, dark theme, and notifications",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              userName: parentName,
                              userRole: "ولي أمر",
                            ),
                          ),
                        ),
                      ),

                      _buildServiceCard(
                        icon: Icons.info_outline_rounded,
                        iconColor: const Color(0xFFFFCC00),
                        title: isAr ? "حول التطبيق" : "About App",
                        subtitle: isAr
                            ? "معلومات عن منصة إديو بريدج وإصدار التطبيق"
                            : "Information about Edu Bridge platform and app version",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutAppScreen(),
                          ),
                        ),
                      ),

                      _buildServiceCard(
                        icon: Icons.privacy_tip_outlined,
                        iconColor: const Color(0xFFFFCC00),
                        title: isAr ? "سياسة استخدام التطبيق" : "Privacy Policy & Usage",
                        subtitle: isAr
                            ? "شروط الاستخدام وسياسة الخصوصية وحماية البيانات"
                            : "Terms of service, privacy policy & data protection",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacyPolicyScreen(),
                          ),
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


  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: textColor,
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
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: subColor,
                height: 1.3,
              ),
            ),
          ),
          trailing: Icon(
            isAr ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios,
            size: 16,
            color: subColor,
          ),
        ),
      ),
    );
  }
}
