import 'package:edu_pridge_flutter/core/constants/feature_flags.dart';
import 'package:edu_pridge_flutter/screens/shared/follow_up_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/about_app_screen.dart';
import 'package:edu_pridge_flutter/widgets/logout_icon_button.dart';
import 'package:edu_pridge_flutter/screens/teacher/profile_screen.dart';
import 'package:edu_pridge_flutter/screens/teacher/study_teacher_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/screens/teacher/attendance_flags_screen.dart';
import 'package:edu_pridge_flutter/screens/teacher/exam_rooms_screen.dart';

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

                      // لوحة المتابعة (للمرشد): تُخفى عن المعلم غير المرشد
                      FutureBuilder<bool>(
                        future: SharedPreferences.getInstance().then((p) => p.getBool('is_advisor') ?? true),
                        builder: (context, snap) => snap.data == false
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildServiceCard(
                                  icon: Icons.dashboard_customize_rounded,
                                  iconColor: const Color(0xFFFFCC00),
                                  title: isAr ? "لوحة المتابعة" : "Follow-up Dashboard",
                                  subtitle: isAr
                                      ? "طلابك ومقرراتهم: من يحتاج انتباهك اليوم؟"
                                      : "Your students and their courses: who needs attention today?",
                                  cardColor: cardColor,
                                  textColor: textColor,
                                  subColor: subColor,
                                  isAr: isAr,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const FollowUpDashboardScreen(basePath: 'teacher')),
                                  ),
                                ),
                              ),
                      ),

                      // رفيق المذاكرة: مسودات يولّدها الذكاء الاصطناعي ويعتمدها المعلم (معطّل مؤقتاً)
                      if (kStudyCompanionUi)
                      _buildServiceCard(
                        icon: Icons.auto_stories_rounded,
                        iconColor: const Color(0xFFFFCC00),
                        title: isAr ? "رفيق المذاكرة" : "Study Companion",
                        subtitle: isAr
                            ? "حوّل محاضرتك إلى ملخص وبطاقات وأسئلة، راجعها واعتمدها للطلاب"
                            : "Turn a lecture into a summary, flashcards and questions you review and approve",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TeacherStudyListScreen()),
                        ),
                      ),

                      // الامتحانات والمراقبة (الجدول الامتحاني المعتمد)
                      _buildServiceCard(
                        icon: Icons.fact_check_rounded,
                        iconColor: const Color(0xFFFFCC00),
                        title: isAr ? "الامتحانات والمراقبة" : "Exams & Invigilation",
                        subtitle: isAr
                            ? "قاعات مراقبتك وقوائم طلابها، وقاعات تقييمات مقرراتك"
                            : "Your invigilation rooms with student lists, and your courses' exam rooms",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TeacherExamRoomsScreen()),
                        ),
                      ),

                      // اشتباهات الحضور (مراجعة الأنماط المشبوهة)
                      _buildServiceCard(
                        icon: Icons.manage_search_rounded,
                        iconColor: const Color(0xFFFFCC00),
                        title: isAr ? "اشتباهات الحضور" : "Attendance Flags",
                        subtitle: isAr
                            ? "راجع حالات الحضور المشبوهة التي رصدها النظام بعد إغلاق الجلسات"
                            : "Review suspicious attendance patterns detected after sessions close",
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isAr: isAr,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AttendanceFlagsScreen()),
                        ),
                      ),

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
