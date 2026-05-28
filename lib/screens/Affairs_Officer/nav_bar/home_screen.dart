import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/widgets/Affairs_Officer_speed_dial.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';

import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/profile_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/notifications_screen.dart';

class AffairsOfficerHomeScreen extends StatefulWidget {
  const AffairsOfficerHomeScreen({super.key});

  @override
  State<AffairsOfficerHomeScreen> createState() => _AffairsOfficerHomeScreenState();
}

class _AffairsOfficerHomeScreenState extends State<AffairsOfficerHomeScreen> {
  final List<Map<String, dynamic>> newsList = [
    {
      'title': 'تم إصدار جدول الامتحانات النهائية للفصل الدراسي الأول',
      'content': 'يرجى من جميع الطلاب مراجعة الجدول الدراسي والتأكد من توقيت الامتحانات والقاعات المخصصة.',
      'hasBadge': true,
      'badgeText': 'إعلان عام',
      'time': '1 week ago • إدارة المعهد التقني',
    },
    {
      'title': 'ورشة عمل حول مهارات البحث العلمي',
      'content': 'ندعو جميع الطلاب للحضور والمشاركة في ورشة العمل التي ستقام في مبنى الأنشطة.',
      'hasBadge': true,
      'badgeText': 'إعلان عام',
      'time': '1 week ago • إدارة المعهد التقني',
    },
  ];

  Future<void> _mockRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 نفس ألوان SettingsScreen بالضبط
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor   = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subColor  = isDark ? Colors.grey.shade400 : Colors.grey;

    final isAr = AppSettings.language.value == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- الهيدر ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? "أهلاً، محمد المحمد" : "Hello, Mohammed",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFCC00),
                                fontFamily: 'Noto Sans Arabic',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAr ? "لوحة تحكم الطلاب" : "Student Affairs Dashboard",
                              style: TextStyle(
                                fontSize: 14,
                                color: subColor,
                                fontFamily: 'Noto Sans Arabic',
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: Color(0xFFFFCC00),
                            size: 28,
                          ),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                          },
                        ),
                      ],
                    ),
                  ),

                  // --- كل المحتوى داخل ListView ---
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _mockRefresh,
                      color: const Color(0xFFFFCC00),
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
                        itemCount: newsList.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFCC00),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "آخر الأخبار",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      fontFamily: 'Noto Sans Arabic',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return _buildImageStyleCard(
                            newsList[index - 1],
                            cardColor: cardColor,
                            textColor: textColor,
                            subColor: subColor,
                            isDark: isDark,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // شريط التنقل السفلي
            CustomBottomNav(
              currentIndex: 0,
              centerButton: AffairsOfficerSpeedDial(),
              onHomeTap: () {
              },
              onProfileTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AffairsOfficerProfileScreen()),
                );
              },
              onNotificationsTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AffairsOfficerNotificationsScreen()),
                );
              },
              onMessagesTap: () {
                // أضف شاشة الرسائل لاحقاً إن وجدت
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('قريباً...'), duration: Duration(seconds: 1)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageStyleCard(
    Map<String, dynamic> data, {
    required Color cardColor,
    required Color textColor,
    required Color subColor,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 10),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الجزء العلوي
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                colors: [
                  isDark ? const Color(0xFF0A2F23) : const Color(0xFFE8F5E9),
                  isDark ? const Color(0xFF051812) : const Color(0xFFC8E6C9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        (isDark ? const Color(0xFF0A2F23) : const Color(0xFFE8F5E9)).withOpacity(0.8),
                        (isDark ? const Color(0xFF051812) : const Color(0xFFC8E6C9)).withOpacity(0.9),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                if (data['hasBadge'] == true)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1F2E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data['badgeText']!,
                        style: TextStyle(
                          color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // الجزء السفلي
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? '',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.4,
                    fontFamily: 'Noto Sans Arabic',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data['content'] ?? '',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: subColor,
                    height: 1.6,
                    fontFamily: 'Noto Sans Arabic',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 14,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                    Text(
                      data['time'] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: subColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
