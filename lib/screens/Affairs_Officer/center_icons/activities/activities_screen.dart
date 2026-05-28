import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/widgets/Affairs_Officer_speed_dial.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/home_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/profile_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/messages_screen.dart';

// TODO: صفحة إضافة حدث (بتعملها لاحقاً)
// import 'package:edu_pridge_flutter/screens/Affairs_Officer/center_icons/activities/add_activity_screen.dart';

class AffairsOfficerActivitiesScreen extends StatefulWidget {
  const AffairsOfficerActivitiesScreen({super.key});

  @override
  State<AffairsOfficerActivitiesScreen> createState() => _AffairsOfficerActivitiesScreenState();
}

class _AffairsOfficerActivitiesScreenState extends State<AffairsOfficerActivitiesScreen> {
  // 🔹 الفلتر الحالي (الكل، القادمة، المكتملة، رحلات)
  String _currentFilter = 'الكل';

  final List<String> _filters = ['الكل', 'القادمة', 'المكتملة', 'رحلات'];

  // 🔹 بيانات الأنشطة
  final List<Map<String, dynamic>> activities = [
    {
      'title': 'زيارة المتحف الوطني',
      'category': 'رحلة مدرسية',
      'categoryColor': Colors.blue,
      'date': 'أكتوبر 25',
      'day': '25',
      'month': 'أكتوبر',
      'time': '08:00 ص',
      'location': 'وسط المدينة',
      'icon': Icons.directions_bus_filled_outlined,
      'iconColor': Colors.blue,
    },
    {
      'title': 'مجلس الطلاب الشهري',
      'category': 'اجتماع',
      'categoryColor': Colors.purple,
      'date': 'أكتوبر 28',
      'day': '28',
      'month': 'أكتوبر',
      'time': '10:00 ص',
      'location': 'القاعة 4',
      'icon': Icons.groups_outlined,
      'iconColor': Colors.purple,
      'urgent': true,
    },
    {
      'title': 'تطوير المهارات القيادية',
      'category': 'ورشة عمل',
      'categoryColor': Colors.orange,
      'date': 'نوفمبر 02',
      'day': '02',
      'month': 'نوفمبر',
      'time': '09:30 ص',
      'location': 'المكتبة',
      'icon': Icons.lightbulb_outline,
      'iconColor': Colors.orange,
    },
    {
      'title': 'نهائي دوري المدرسة',
      'category': 'رياضة',
      'categoryColor': Colors.green,
      'date': 'سبتمبر 20',
      'day': '20',
      'month': 'سبتمبر',
      'time': '04:00 م',
      'location': 'الملعب',
      'icon': Icons.sports_soccer_outlined,
      'iconColor': Colors.green,
      'status': 'منتهي',
    },
  ];

  // 🔹 تصفية الأنشطة
  List<Map<String, dynamic>> get _filteredActivities {
    if (_currentFilter == 'الكل') return activities;
    if (_currentFilter == 'رحلات') {
      return activities.where((a) => a['category'] == 'رحلة مدرسية').toList();
    }
    if (_currentFilter == 'القادمة') {
      return activities.where((a) => a['status'] != 'منتهي').toList();
    }
    if (_currentFilter == 'المكتملة') {
      return activities.where((a) => a['status'] == 'منتهي').toList();
    }
    return activities;
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 نفس ألوان وثيم باقي المشروع
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subColor = isDark ? Colors.grey.shade400 : Colors.grey;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // ═══════════════════════════════════════
                  // الهيدر: زر رجوع (يمين) | العنوان (وسط) | إعدادات (يسار)
                  // ═══════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // ✅ زر الإعدادات على اليسار
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: Icon(
                              Icons.settings,
                              color: textColor,
                              size: 26,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsScreen()),
                              );
                            },
                          ),
                        ),
                        // عنوان "أنشطة" بالمنتصف - حجم 20
                        Text(
                          "الأنشطة",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                        // ✅ زر الرجوع على اليمين - سهم للخلف
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

                  // ═══════════════════════════════════════
                  // شريط الفلاتر (الكل، القادمة، المكتملة، رحلات)
                  // ═══════════════════════════════════════
                  Container(
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final isSelected = _currentFilter == filter;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentFilter = filter;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(left: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFCC00)
                                  : cardColor,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: const Color(0xFFFFCC00).withOpacity(0.4),  // ← أصفر
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                                  : [
                                BoxShadow(
                                  color: Colors.black.withAlpha(isDark ? 20 : 5),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.black : textColor,
                                fontFamily: 'Noto Sans Arabic',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ═══════════════════════════════════════
                  // قائمة الأنشطة
                  // ═══════════════════════════════════════
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
                      itemCount: _filteredActivities.length,
                      itemBuilder: (context, index) {
                        return _buildActivityCard(
                          _filteredActivities[index],
                          cardColor: cardColor,
                          textColor: textColor,
                          subColor: subColor,
                          isDark: isDark,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ═══════════════════════════════════════
            // زر الإضافة (+) أسفل اليمين
            // ═══════════════════════════════════════
            Positioned(
              bottom: 100,
              right: 20,
              child: FloatingActionButton(
                onPressed: () {
                  // TODO: الانتقال لصفحة إضافة حدث
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => const AddActivityScreen()),
                  // );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('إضافة نشاط جديد - قريباً')),
                  );
                },
                backgroundColor: const Color(0xFFFFCC00),
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.add,
                  color: Colors.black,
                  size: 28,
                ),
              ),
            ),

            // ═══════════════════════════════════════
            // الشريط السفلي الجاهز
            // ═══════════════════════════════════════
            CustomBottomNav(
              currentIndex: 0,
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
              onNotificationsTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AffairsOfficerNotificationsScreen()),
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

  // ═══════════════════════════════════════
  // بطاقة النشاط (بدون: خط هامش + التفاصيل + عدد المسجلين + صور)
  // ═══════════════════════════════════════
  Widget _buildActivityCard(
      Map<String, dynamic> data, {
        required Color cardColor,
        required Color textColor,
        required Color subColor,
        required bool isDark,
      }) {
    final Color categoryColor = data['categoryColor'] as Color;
    final bool isUrgent = data['urgent'] == true;
    final bool isDone = data['status'] == 'منتهي';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══ التاريخ (يمين) ═══
            Container(
              width: 65,
              height: 70,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data['month'],
                    style: TextStyle(
                      fontSize: 11,
                      color: subColor,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data['day'],
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // ═══ المحتوى (وسط) ═══
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // التصنيف + الأيقونة
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          data['category'],
                          style: TextStyle(
                            fontSize: 11,
                            color: categoryColor,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                      ),
                      if (isUrgent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'مطلوب الحضور !',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Noto Sans Arabic',
                            ),
                          ),
                        ),
                      ],
                      if (isDone) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'منتهي',
                            style: TextStyle(
                              fontSize: 11,
                              color: subColor,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Noto Sans Arabic',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  // عنوان النشاط
                  Text(
                    data['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                  const SizedBox(height: 8),
                  // الوقت + الموقع
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: subColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data['time'],
                        style: TextStyle(
                          fontSize: 12,
                          color: subColor,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: subColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data['location'],
                        style: TextStyle(
                          fontSize: 12,
                          color: subColor,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ═══ الأيقونة (يسار) ═══
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                data['icon'],
                color: categoryColor,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}