import 'package:flutter/material.dart';
// استيراد الشاشات والقطع اللازمة
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_messages_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_profile_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../../widgets/parents_center_icon.dart';

class ParentsNotificationsScreen extends StatefulWidget {
  const ParentsNotificationsScreen({super.key});

  @override
  State<ParentsNotificationsScreen> createState() => _ParentsNotificationsScreenState();
}

class _ParentsNotificationsScreenState extends State<ParentsNotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    // 🎨 تعريف الألوان المتجاوبة
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: _buildAppBar(context, textColor, cardColor),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _buildSectionHeader("اليوم", textColor),
                _buildNotificationCard(
                  context: context,
                  title: "غياب",
                  time: "08:30 ص",
                  content: "تم تسجيل غياب للطالب أحمد محمد عن الحصة الأولى.",
                  footer: "يرجى التواصل مع المشرف",
                  icon: Icons.close_rounded,
                  iconColor: Colors.red,
                  accentColor: Colors.red,
                  showWarning: true,
                  cardColor: cardColor,
                  textColor: textColor,
                ),
                _buildEventCard(
                  context: context,
                  title: "موعد اختبار",
                  subtitle: "الفيزياء التطبيقية - سارة محمد",
                  time: "10:00 ص",
                  date: "غداً، 15 مايو",
                  location: "القاعة 4",
                  icon: Icons.assignment_outlined,
                  iconColor: Colors.purple,
                  accentColor: Colors.purple,
                  cardColor: cardColor,
                  textColor: textColor,
                ),
                const SizedBox(height: 20),
                _buildSectionHeader("الأمس", textColor),
                _buildNotificationCard(
                  context: context,
                  title: "فعالية جديدة",
                  time: "02:15 م",
                  content: "ندوة: الذكاء الاصطناعي في التعليم",
                  footer: "20 مايو • مسرح المعهد",
                  icon: Icons.calendar_today_outlined,
                  iconColor: Colors.blue,
                  accentColor: Colors.blue,
                  footerIcon: Icons.location_on_outlined,
                  cardColor: cardColor,
                  textColor: textColor,
                ),
                const SizedBox(height: 120), // مساحة للشريط السفلي
              ],
            ),

            // 2. الشريط السفلي الموحد
            CustomBottomNav(
              currentIndex: 2, // رقم صفحة الإشعارات
              centerButton: const Parents_Center_Icon(),
              onHomeTap: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const ParentsHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const ParentsProfileScreen())),
              onNotificationsTap: () {
                // نحن هنا بالفعل
              },
              onMessagesTap: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const ParentsMessagesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color textColor, Color cardColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        "الإشعارات",
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
      leading: IconButton(
        icon: Icon(Icons.settings_outlined, color: textColor.withValues(alpha: 0.6)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.arrow_forward, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Text(title, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: textColor.withValues(alpha: 0.1), thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required String title,
    required String time,
    required String content,
    required Color cardColor,
    required Color textColor,
    String? footer,
    required IconData icon,
    required Color iconColor,
    required Color accentColor,
    bool showWarning = false,
    IconData? footerIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned(
              right: 0, top: 0, bottom: 0,
              child: Container(width: 5, color: accentColor),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                            _buildTimeBadge(time, textColor),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(content, style: TextStyle(color: textColor.withValues(alpha: 0.7), height: 1.4)),
                        if (footer != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(footerIcon ?? Icons.info_outline, color: showWarning ? iconColor : Colors.grey, size: 14),
                              const SizedBox(width: 5),
                              Text(footer, style: TextStyle(color: showWarning ? iconColor : Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String time,
    required String date,
    required String location,
    required IconData icon,
    required Color iconColor,
    required Color accentColor,
    required Color cardColor,
    required Color textColor,
  }) {
    return _buildNotificationCard(
      context: context,
      title: title,
      time: time,
      content: subtitle,
      icon: icon,
      iconColor: iconColor,
      accentColor: accentColor,
      footer: "$date • $location",
      footerIcon: Icons.calendar_today,
      cardColor: cardColor,
      textColor: textColor,
    );
  }

  Widget _buildTimeBadge(String time, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: textColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
      child: Text(time, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 10)),
    );
  }
}