import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/widgets/Affairs_Officer_speed_dial.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';

import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/messages_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/home_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/profile_screen.dart';

class AffairsOfficerNotificationsScreen extends StatefulWidget {
  const AffairsOfficerNotificationsScreen({super.key});

  @override
  State<AffairsOfficerNotificationsScreen> createState() => _AffairsOfficerNotificationsScreenState();
}

class _AffairsOfficerNotificationsScreenState extends State<AffairsOfficerNotificationsScreen> {
  // بيانات الإشعارات مطابقة للصورة
  final List<Map<String, dynamic>> notifications = [
    {
      'title': 'إجازة طالب (تمت الموافقة)',
      'content': 'وافق رئيس القسم على طلب الإجازة للطالب عمر يوسف (الصف الثاني)، يرجى استكمال الإجراءات.',
      'time': '10:30 ص',
      'type': 'approval',
      'action': 'اتخاذ إجراء',
      'icon': Icons.school_outlined,
    },
    {
      'title': 'طلب إجازة ساعية',
      'content': 'الموظف خالد عبدالله يطلب مغادرة ساعية لظرف عائلي طارئ لمدة ساعتين.',
      'time': '09:15',
      'type': 'urgent',
      'action': 'عرض التفاصيل',
      'icon': Icons.info_outline,
    },
    {
      'title': 'طلب إجازة يومية',
      'content': 'الموظفة نورة سعد قدمت طلب إجازة ليوم الخميس القادم.',
      'time': '04:20 مس',
      'section': 'أمس',
      'type': 'normal',
      'action': null,
      'icon': Icons.calendar_today_outlined,
    },
    {
      'title': 'تحديث سياسة الإجازات',
      'content': 'تم تحديث اللائحة التنظيمية للإجازات الساعية. يرجى الاطلاع على البنود الجديدة في قائمة السياسات.',
      'time': '09:00 ص',
      'section': 'أمس',
      'type': 'policy',
      'action': null,
      'icon': Icons.settings_outlined,
    },
  ];

  // ألوان الإشعارات حسب النوع
  Color _getTypeColor(String type) {
    switch (type) {
      case 'approval':
        return const Color(0xFF2196F3);
      case 'urgent':
        return const Color(0xFFFF9800);
      case 'normal':
        return const Color(0xFF9C27B0);
      case 'policy':
        return const Color(0xFF607D8B);
      default:
        return const Color(0xFF2196F3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor   = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subColor  = isDark ? Colors.grey.shade400 : Colors.grey;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: Icon(
                              Icons.settings,
                              color: isDark ? const Color(0xFFFFCC00) : const Color(0xFFFFA000),
                              size: 28,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsScreen()),
                              );
                            },
                          ),
                        ),
                        Text(
                          "الإشعارات",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: textColor,
                              size: 26,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        if (index == 2) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8, bottom: 12, top: 8),
                                child: Text(
                                  "أمس",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: subColor,
                                    fontFamily: 'Noto Sans Arabic',
                                  ),
                                ),
                              ),
                              _buildNotificationCard(
                                notifications[index],
                                cardColor,
                                textColor,
                                subColor,
                              ),
                            ],
                          );
                        }
                        return _buildNotificationCard(
                          notifications[index],
                          cardColor,
                          textColor,
                          subColor,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            CustomBottomNav(
              currentIndex: 2,
              centerButton: AffairsOfficerSpeedDial(),
              onHomeTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AffairsOfficerHomeScreen()),
                );
              },
              onProfileTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AffairsOfficerProfileScreen()),
                );
              },
              onMessagesTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AffairsOfficerMessagesScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // بناء بطاقة الإشعار (تم تصغيرها)
  Widget _buildNotificationCard(
      Map<String, dynamic> data,
      Color cardColor,
      Color textColor,
      Color subColor,
      ) {
    final Color typeColor = _getTypeColor(data['type']);
    final bool hasAction = data['action'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['time'],
                            style: TextStyle(
                              fontSize: 10,
                              color: subColor,
                              fontFamily: 'Noto Sans Arabic',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['title'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontFamily: 'Noto Sans Arabic',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data['content'],
                            style: TextStyle(
                              fontSize: 12,
                              color: subColor,
                              height: 1.4,
                              fontFamily: 'Noto Sans Arabic',
                            ),
                          ),
                          if (hasAction) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: typeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  data['action'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: typeColor,
                                    fontFamily: 'Noto Sans Arabic',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        data['icon'],
                        color: typeColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}