import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/widgets/Affairs_Officer_speed_dial.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/home_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/profile_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/messages_screen.dart';

import 'package:edu_pridge_flutter/screens/Affairs_Officer/center_icons/activities/add_activity_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/center_icons/activities/edit_activity_screen.dart';

import 'package:edu_pridge_flutter/services/affairs_services.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

class AffairsOfficerActivitiesScreen extends StatefulWidget {
  const AffairsOfficerActivitiesScreen({super.key});

  @override
  State<AffairsOfficerActivitiesScreen> createState() => _AffairsOfficerActivitiesScreenState();
}

class _AffairsOfficerActivitiesScreenState extends State<AffairsOfficerActivitiesScreen> {
  bool get isAr => AppSettings.language.value == 'ar';
  int _selectedFilterIndex = 0;

  List<dynamic> _activities = [];
  bool _isLoading = true;

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    _loadActivities();
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    super.dispose();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    await ApiService.init();
    final data = await AffairsServices().getActivities();
    if (mounted) {
      setState(() {
        _activities = data ?? [];
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredActivities {
    final now = DateTime.now();
    if (_selectedFilterIndex == 1) { // Upcoming
      return _activities.where((a) {
        final dateStr = a['event_date'] ?? a['created_at'] ?? '';
        try {
          return DateTime.parse(dateStr).isAfter(now);
        } catch (_) { return true; }
      }).toList();
    }
    if (_selectedFilterIndex == 2) { // Completed
      return _activities.where((a) {
        final dateStr = a['event_date'] ?? a['created_at'] ?? '';
        try {
          return DateTime.parse(dateStr).isBefore(now);
        } catch (_) { return false; }
      }).toList();
    }
    return _activities;
  }

  Future<void> _editActivity(Map<String, dynamic> data) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditActivityScreen(activity: data),
      ),
    );
    if (result == true) {
      _loadActivities();
    }
  }

  Future<void> _deleteActivity(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(isAr ? 'تأكيد الحذف' : 'Confirm Delete', style: const TextStyle(fontFamily: 'Noto Sans Arabic')),
          content: Text(isAr ? 'هل أنت متأكد من حذف هذا النشاط؟' : 'Are you sure you want to delete this activity?', style: const TextStyle(fontFamily: 'Noto Sans Arabic')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isAr ? 'إلغاء' : 'Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isAr ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      final ok = await AffairsServices().deleteActivity(id);
      if (ok && mounted) {
        _loadActivities();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr ? 'تم حذف النشاط بنجاح' : 'Activity deleted successfully',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Noto Sans Arabic'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 نفس ألوان وثيم باقي المشروع
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subColor = isDark ? Colors.grey.shade400 : Colors.grey;

    final filterLabels = [
      isAr ? 'الكل' : 'All',
      isAr ? 'القادمة' : 'Upcoming',
      isAr ? 'المكتملة' : 'Completed',
    ];

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 90),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddActivityScreen()),
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
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // ═══════════════════════════════════════
                  // الهيدر: زر رجوع | العنوان | إعدادات
                  // ═══════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // زر الإعدادات
                        Align(
                          alignment: isAr ? Alignment.centerLeft : Alignment.centerRight,
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
                        // عنوان "أنشطة"
                        Text(
                          isAr ? "الأنشطة" : "Activities",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                        // زر الرجوع
                        Align(
                          alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                          child: IconButton(
                            icon: Icon(
                              isAr ? Icons.arrow_back : Icons.arrow_forward,
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
                  // شريط الفلاتر
                  // ═══════════════════════════════════════
                  Container(
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: filterLabels.length,
                      itemBuilder: (context, index) {
                        final label = filterLabels[index];
                        final isSelected = _selectedFilterIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFilterIndex = index;
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.only(
                              left: isAr ? 10 : 0,
                              right: isAr ? 0 : 10,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFCC00)
                                  : cardColor,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: const Color(0xFFFFCC00).withValues(alpha: 0.4),
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
                              label,
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
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                        : _filteredActivities.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey.shade400),
                                    const SizedBox(height: 12),
                                    Text(
                                      isAr ? 'لا توجد أنشطة منشورة بعد' : 'No activities published yet',
                                      style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontFamily: 'Noto Sans Arabic'),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadActivities,
                                color: const Color(0xFFFFCC00),
                                child: ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
                                  itemCount: _filteredActivities.length,
                                  itemBuilder: (context, index) {
                                    final activity = _filteredActivities[index];
                                    return _buildActivityCard(
                                      activity,
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
  // بطاقة النشاط
  // ═══════════════════════════════════════
  Widget _buildActivityCard(
      Map<String, dynamic> data, {
        required Color cardColor,
        required Color textColor,
        required Color subColor,
        required bool isDark,
      }) {
    
    // إعداد المتغيرات من بيانات السيرفر
    final String title = data['title'] ?? '';
    final String category = data['category'] ?? (isAr ? 'عام' : 'General');
    final String time = data['event_time'] ?? '';
    final String location = data['location'] ?? (isAr ? 'غير محدد' : 'Not specified');
    final int id = data['id'] ?? data['announcement_id'] ?? 0;
    
    final String audience = data['target_audience'] == 'students'
        ? (isAr ? 'طلاب' : 'Students')
        : data['target_audience'] == 'teachers'
            ? (isAr ? 'معلمين' : 'Teachers')
            : data['target_audience'] == 'heads'
                ? (isAr ? 'رؤساء أقسام' : 'Department Heads')
                : (isAr ? 'الجميع' : 'Everyone');
    
    String deptText = '';
    if (data['department_name'] != null) {
      deptText = isAr ? ' | قسم: ${data['department_name']}' : ' | Dept: ${data['department_name']}';
    }
    String courseText = '';
    if (data['course_name'] != null) {
      courseText = isAr ? ' | دورة: ${data['course_name']}' : ' | Course: ${data['course_name']}';
    }
    
    // التعامل مع التاريخ
    String day = '--';
    String monthStr = '--';
    final dateStr = data['event_date'] ?? data['created_at'];
    if (dateStr != null && dateStr.toString().isNotEmpty) {
      try {
        final DateTime d = DateTime.parse(dateStr);
        day = d.day.toString().padLeft(2, '0');
        final monthsAr = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
        final monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final months = isAr ? monthsAr : monthsEn;
        if (d.month >= 1 && d.month <= 12) {
          monthStr = months[d.month - 1];
        } else {
          monthStr = d.month.toString();
        }
      } catch (_) {}
    }

    final Color categoryColor = Colors.blue;
    final defaultAuthor = isAr ? 'شؤون الطلاب' : 'Student Affairs';
    final author = data['author_name'] ?? data['publisher_name'] ?? data['created_by'] ?? defaultAuthor;

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
            // التاريخ
            Container(
              width: 65,
              height: 70,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    monthStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: subColor,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    day,
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

            // المحتوى
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 11,
                            color: categoryColor,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCC00).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$audience$deptText$courseText',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFFFFCC00) : Colors.brown.shade800,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      if (time.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: subColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 12,
                                color: subColor,
                                fontFamily: 'Noto Sans Arabic',
                              ),
                            ),
                          ],
                        ),
                      if (location.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: subColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              location,
                              style: TextStyle(
                                fontSize: 12,
                                color: subColor,
                                fontFamily: 'Noto Sans Arabic',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: subColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${isAr ? 'نشر بواسطة:' : 'Published by:'} $author",
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
                ],
              ),
            ),

            // الأزرار
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    color: Colors.blue,
                    iconSize: 20,
                    onPressed: () => _editActivity(data),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    iconSize: 20,
                    onPressed: () => _deleteActivity(id),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}