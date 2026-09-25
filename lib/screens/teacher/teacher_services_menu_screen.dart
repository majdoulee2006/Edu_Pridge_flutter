import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/about_app_screen.dart';
import 'package:edu_pridge_flutter/widgets/logout_icon_button.dart';
import 'package:edu_pridge_flutter/screens/teacher/profile_screen.dart';

class TeacherServicesMenuScreen extends StatelessWidget {
  final String teacherName;

  const TeacherServicesMenuScreen({super.key, this.teacherName = 'معلم'});

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
                      isAr ? "خيارات الحساب والإعدادات" : "Account & Settings",
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
                      // Section Header
                      _buildSectionTitle(
                        isAr ? "القائمة العامة والخيارات" : "General Menu & Options",
                        subColor,
                      ),
                      const SizedBox(height: 12),

                      // 1. الإعدادات
                      _buildServiceCard(
                        icon: Icons.settings_outlined,
                        iconColor: const Color(0xFFFFCC00),
                        title: isAr ? "الإعدادات العامة" : "General Settings",
                        subtitle: isAr
                            ? "المظهر الداكن، حجم الخط، الإشعارات والأصوات"
                            : "Dark mode, font size, notifications & sound",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              userName: teacherName.isNotEmpty ? teacherName : 'معلم',
                              userRole: "مدرس",
                              onProfileTap: () {
                                Navigator.pop(context);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      // 2. حول المنصة وفريق التطوير
                      _buildServiceCard(
                        icon: Icons.auto_awesome_rounded,
                        iconColor: const Color(0xFFFFCC00),
                        title: isAr ? "حول المنصة وفريق التطوير" : "About Platform & Dev Team",
                        subtitle: isAr
                            ? "فريق التطوير، الرؤية، وسياسة الخصوصية والتواصل"
                            : "Development team, vision, privacy & contact",
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

                      // 3. تسجيل الخروج
                      _buildServiceCard(
                        icon: Icons.logout_rounded,
                        iconColor: Colors.red,
                        title: isAr ? "تسجيل الخروج" : "Logout",
                        subtitle: isAr ? "الخروج من الحساب الحالي" : "Sign out of your account",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => showLogoutConfirmation(context, isAr),
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
