import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:ui' as ui;

import 'package:edu_pridge_flutter/widgets/Affairs_Officer_speed_dial.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/home_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/profile_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/messages_screen.dart';

class AffairsOfficerCalendarScreen extends StatefulWidget {
  const AffairsOfficerCalendarScreen({super.key});

  @override
  State<AffairsOfficerCalendarScreen> createState() => _AffairsOfficerCalendarScreenState();
}

class _AffairsOfficerCalendarScreenState extends State<AffairsOfficerCalendarScreen> {
  // 🔹 التقويم الحقيقي
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 🔹 أحداث الشهر (مثال - تقدر تربطها بـ API)
  final Map<DateTime, List<Map<String, dynamic>>> _events = {
    DateTime(2026, 5, 15): [
      {
        'title': 'بدء تسجيل المواد',
        'subtitle': 'الفصل الدراسي الثاني لجميع التخصصات',
        'type': 'التسجيل',
        'color': Colors.blue,
      },
    ],
    DateTime(2026, 5, 25): [
      {
        'title': 'اختبارات المستوى',
        'subtitle': 'تحديد مستوى اللغة الإنجليزية للمستجدين',
        'type': 'الامتحانات',
        'color': Colors.orange,
      },
    ],
    DateTime(2026, 5, 30): [
      {
        'title': 'آخر موعد للانسحاب',
        'subtitle': 'الموعد النهائي للانسحاب من المقررات',
        'type': 'هام',
        'color': Colors.red,
      },
    ],
  };

  // 🔹 الحصول على الأحداث ليوم معين
  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 نفس ألوان وثيم باقي المشروع
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor   = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subColor  = isDark ? Colors.grey.shade400 : Colors.grey;

    return Directionality(
        textDirection: ui.TextDirection.rtl,
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
                        // عنوان "تقويم" بالمنتصف - حجم 20
                        Text(
                          "تقويم",
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
                  // التقويم الحقيقي
                  // ═══════════════════════════════════════
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
                      children: [
                        // بطاقة التقويم
                        Container(
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
                            padding: const EdgeInsets.all(12),
                            child: TableCalendar(
                              firstDay: DateTime.utc(2020, 1, 1),
                              lastDay: DateTime.utc(2030, 12, 31),
                              focusedDay: _focusedDay,
                              selectedDayPredicate: (day) {
                                return isSameDay(_selectedDay, day);
                              },
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                });
                              },
                              onPageChanged: (focusedDay) {
                                _focusedDay = focusedDay;
                              },
                              calendarFormat: CalendarFormat.month,
                              availableCalendarFormats: const {
                                CalendarFormat.month: 'شهر',
                              },
                              startingDayOfWeek: StartingDayOfWeek.saturday, // السبت أول يوم
                              locale: 'ar', // عربي
                              // ═══ تنسيق الهيدر (اسم الشهر + أزرار التنقل) ═══
                              headerStyle: HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                                titleTextStyle: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontFamily: 'Noto Sans Arabic',
                                ),
                                leftChevronIcon: Icon(
                                  Icons.arrow_back_ios,
                                  color: textColor,
                                  size: 20,
                                ),
                                rightChevronIcon: Icon(
                                  Icons.arrow_forward_ios,
                                  color: textColor,
                                  size: 20,
                                ),
                                headerPadding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              // ═══ تنسيق أيام الأسبوع ═══
                              daysOfWeekStyle: DaysOfWeekStyle(
                                weekdayStyle: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: subColor,
                                  fontFamily: 'Noto Sans Arabic',
                                ),
                                weekendStyle: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: subColor,
                                  fontFamily: 'Noto Sans Arabic',
                                ),
                              ),
                              // ═══ تنسيق الخلايا ═══
                              calendarStyle: CalendarStyle(
                                outsideDaysVisible: true,
                                weekendTextStyle: TextStyle(
                                  fontSize: 15,
                                  color: textColor,
                                  fontFamily: 'Noto Sans Arabic',
                                ),
                                defaultTextStyle: TextStyle(
                                  fontSize: 15,
                                  color: textColor,
                                  fontFamily: 'Noto Sans Arabic',
                                ),
                                outsideTextStyle: TextStyle(
                                  fontSize: 15,
                                  color: subColor.withOpacity(0.5),
                                  fontFamily: 'Noto Sans Arabic',
                                ),
                                todayDecoration: BoxDecoration(
                                  color: const Color(0xFFFFCC00).withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                todayTextStyle: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontFamily: 'Noto Sans Arabic',
                                ),
                                selectedDecoration: const BoxDecoration(
                                  color: Color(0xFF2196F3),
                                  shape: BoxShape.circle,
                                ),
                                selectedTextStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Noto Sans Arabic',
                                ),
                                cellMargin: const EdgeInsets.all(4),
                              ),
                              // ═══ علامات الأحداث (النقاط الملونة) ═══
                              calendarBuilders: CalendarBuilders(
                                markerBuilder: (context, date, events) {
                                  final dayEvents = _getEventsForDay(date);
                                  if (dayEvents.isEmpty) return const SizedBox.shrink();

                                  return Positioned(
                                    bottom: 1,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: dayEvents.take(3).map((event) {
                                        return Container(
                                          width: 5,
                                          height: 5,
                                          margin: const EdgeInsets.symmetric(horizontal: 1),
                                          decoration: BoxDecoration(
                                            color: event['color'] as Color,
                                            shape: BoxShape.circle,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ═══════════════════════════════════════
                        // عنوان "أحداث الشهر"
                        // ═══════════════════════════════════════
                        Row(
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
                              "أحداث الشهر",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontFamily: 'Noto Sans Arabic',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ═══════════════════════════════════════
                        // قائمة الأحداث (بدون سهم)
                        // ═══════════════════════════════════════
                        ..._buildEventList(cardColor, textColor, subColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ═══════════════════════════════════════
            // الشريط السفلي الجاهز
            // ═══════════════════════════════════════
            CustomBottomNav(
              currentIndex: 0, // الرئيسية (أو تقدر تحط index للتقويم لو عندك)
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
  // بناء قائمة الأحداث (بدون سهم)
  // ═══════════════════════════════════════
  List<Widget> _buildEventList(Color cardColor, Color textColor, Color subColor) {
    // نجمع كل الأحداث
    List<Map<String, dynamic>> allEvents = [];
    _events.forEach((date, events) {
      for (var event in events) {
        allEvents.add({
          ...event,
          'date': date,
        });
      }
    });

    // نرتب حسب التاريخ
    allEvents.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    return allEvents.map((event) {
      final DateTime date = event['date'];
      final String dayName = DateFormat('EEEE', 'ar').format(date);
      final int dayNumber = date.day;
      final Color eventColor = event['color'] as Color;

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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ═══ التاريخ (يمين) ═══
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: eventColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 11,
                        color: eventColor,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: eventColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // ═══ المحتوى (وسط) ═══
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // نوع الحدث + النقطة
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: eventColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          event['type'],
                          style: TextStyle(
                            fontSize: 12,
                            color: eventColor,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // عنوان الحدث
                    Text(
                      event['title'],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                    const SizedBox(height: 4),
                    // وصف الحدث
                    Text(
                      event['subtitle'],
                      style: TextStyle(
                        fontSize: 12,
                        color: subColor,
                        height: 1.4,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                  ],
                ),
              ),

              // ❌ شيلنا السهم من هون
            ],
          ),
        ),
      );
    }).toList();
  }
}