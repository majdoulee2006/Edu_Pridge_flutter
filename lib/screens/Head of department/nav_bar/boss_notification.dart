import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_home.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_profile.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_massega.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/center_icons/leave_requests_screen.dart';
import '../../../widgets/boss_center_icon.dart';

// 🌟 نموذج بيانات الإشعار (Notification Model)
// يمكنك مستقبلاً نقله لملف منفصل في مجلد models
class BossNotification {
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool hasButtons;
  final bool isUnread;
  final String type; // مثل 'leave', 'admin', 'meeting'

  BossNotification({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.hasButtons = false,
    this.isUnread = false,
    this.type = 'general',
  });
}

class BossNotificationScreen extends StatefulWidget {
  const BossNotificationScreen({super.key});

  @override
  State<BossNotificationScreen> createState() => _BossNotificationScreenState();
}

class _BossNotificationScreenState extends State<BossNotificationScreen> {
  // 🚀 قائمة الحسابات/الإشعارات (محاكاة لجلب البيانات من API أو Database)
  final List<BossNotification> notifications = [
    BossNotification(
      title: "طلب مغادرة ساعية",
      description: "د. محمد الفهد يطلب مغادرة لمدة ساعتين لظروف خاصة.",
      time: "منذ 5 د",
      icon: Icons.access_time_filled,
      iconColor: const Color(0xFFD4E000),
      hasButtons: true,
      isUnread: true,
      type: 'leave',
    ),
    BossNotification(
      title: "طلب إجازة اعتيادية",
      description: "أ. سارة العمر • لمدة 3 أيام تبدأ من يوم الأحد القادم",
      time: "10:30 ص",
      icon: Icons.calendar_month,
      iconColor: Colors.purple,
      isUnread: true,
      type: 'leave',
    ),
    BossNotification(
      title: "تنبيه إداري عاجل",
      description: "يرجى الانتهاء من رصد درجات أعمال السنة.",
      time: "08:00 ص",
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.orange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context, isDark),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("اليوم", hasAction: true),

                          // 🔄 عرض الإشعارات باستخدام Map لتحويل القائمة إلى Widgets
                          ...notifications.map((notification) => _handleNotificationClick(
                            context,
                            notification,
                            _buildNotificationCard(
                              cardColor,
                              isDark,
                              notification.iconColor,
                              icon: notification.icon,
                              title: notification.title,
                              description: notification.description,
                              time: notification.time,
                              hasButtons: notification.hasButtons,
                              isUnread: notification.isUnread,
                            ),
                          )),

                          const SizedBox(height: 150),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              CustomBottomNav(
                currentIndex: 2,
                centerButton: const Boss_Center_Icon(),
                onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DeptHeadHomeScreen())),
                onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BossProfileScreen())),
                onNotificationsTap: () {},
                onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BossMessageScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🛠️ منطق الضغط على الإشعار للربط مع واجهات الحسابات/الإجازات
  Widget _handleNotificationClick(BuildContext context, BossNotification notification, Widget child) {
    return GestureDetector(
      onTap: () {
        if (notification.type == 'leave') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LeaveRequestsScreen(fromSource: "notifications"),
            ),
          );
        }
        // يمكن إضافة شروط أخرى لأنواع إشعارات مختلفة هنا
      },
      child: child,
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_forward, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DeptHeadHomeScreen())),
          ),
          const Text("الإشعارات", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen(userName: "أحمد عبدالله", userRole: "رئيس قسم"))),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
              child: const Icon(Icons.settings_outlined, color: Colors.grey, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool hasAction = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          if (hasAction)
            GestureDetector(
              onTap: () {
                setState(() {
                  // منطق تصفير الإشعارات برمجياً
                });
              },
              child: Text("تحديد الكل كمقروء", style: TextStyle(color: Colors.yellow[700], fontSize: 13, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Color cardColor, bool isDark, Color iconColor,
      {required IconData icon, required String title, required String description,
        required String time, bool hasButtons = false, bool isUnread = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        if (isUnread)
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          if (hasButtons) ...[
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBtn("موافقة", const Color(0xFFD4E000), Colors.black),
                const SizedBox(width: 12),
                _buildBtn("رفض", Colors.grey.withValues(alpha: 0.1), isDark ? Colors.white : Colors.black),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildBtn(String text, Color bg, Color txtColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(text, style: TextStyle(color: txtColor, fontWeight: FontWeight.bold, fontSize: 14))),
      ),
    );
  }
}