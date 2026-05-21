import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🌟 استدعاء الشريط الموحد وزر المعلم 🌟
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../../../widgets/teacher_speed_dial.dart';

// استدعاء الشاشات للتنقل من الشريط السفلي
import '../../messages_screen.dart';
import '../../notifications_screen.dart';
import '../../profile_screen.dart';
import '../../teacher_home.dart';

class TeacherScheduleScreen extends StatefulWidget {
  const TeacherScheduleScreen({super.key});

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
  int selectedDayIndex = 0;
  int _todayIndex = 0; // index اليوم الحالي في القائمة (-1 إذا كان جمعة/سبت)
  bool _isLoading = false;
  Map<String, dynamic> _scheduleData = {};

  List<Map<String, dynamic>> days = [];

  // الأسبوع: الأحد (7) ← الخميس (4) فقط
  static const Map<int, String> _arabicDayNames = {
    1: 'الاثنين', 2: 'الثلاثاء', 3: 'الأربعاء', 4: 'الخميس',
    7: 'الأحد',
  };

  @override
  void initState() {
    super.initState();
    _generateDays();
    _fetchSchedule();
  }

  void _generateDays() {
    final now = DateTime.now();

    // إيجاد يوم الأحد للأسبوع الحالي (weekday: 7=أحد, 1=اثنين ... 4=خميس)
    final int daysFromSunday = (now.weekday == 7) ? 0 : now.weekday;
    final sunday = now.subtract(Duration(days: daysFromSunday));

    // توليد 5 أيام فقط: الأحد (0) → الخميس (4)
    days = List.generate(5, (i) {
      final d = sunday.add(Duration(days: i));
      return {
        "name":   _arabicDayNames[d.weekday]!,
        "day":    d.day,
        "dayKey": _arabicDayNames[d.weekday]!,
        "date":   d,
      };
    });

    // تحديد اليوم المحدد والـ todayIndex
    if (now.weekday == 7) {
      // الأحد → index 0
      _todayIndex = 0;
    } else if (now.weekday <= 4) {
      // الاثنين(1)→1, الثلاثاء(2)→2, الأربعاء(3)→3, الخميس(4)→4
      _todayIndex = now.weekday;
    } else {
      // الجمعة أو السبت → لا يوم حالي ضمن أيام العمل
      _todayIndex = -1;
    }

    selectedDayIndex = (_todayIndex == -1) ? 4 : _todayIndex;
  }

  Future<void> _fetchSchedule() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await Dio().get(
        "${ApiService().baseUrl}/teacher/schedule",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _scheduleData = Map<String, dynamic>.from(response.data['data'] ?? {});
        });
      }
    } catch (e) {
      debugPrint('⛔ Schedule Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    return '${parts[0]}:${parts[1]}';
  }

  bool _isNow(String startTime, String endTime) {
    try {
      final now = TimeOfDay.now();
      final sp = startTime.split(':');
      final ep = endTime.split(':');
      final nowMin   = now.hour * 60 + now.minute;
      final startMin = int.parse(sp[0]) * 60 + int.parse(sp[1]);
      final endMin   = int.parse(ep[0]) * 60 + int.parse(ep[1]);
      return nowMin >= startMin && nowMin <= endMin;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 جلب ألوان الثيم للـ Dark Mode 🌟
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: bgColor, // 🌟 دعم الثيم
      extendBody: true,
      appBar: AppBar(
        backgroundColor: cardColor, // 🌟 دعم الثيم
        elevation: 0,
        // 🌟 تفعيل زر الإعدادات بشكل صحيح 🌟
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "جدولي",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textColor),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),

      // 🌟 التغليف بـ Stack و Directionality لترتيب الشريط والمحتوى 🌟
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            // 1. محتوى الشاشة الأساسي
            ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCC00),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {},
                    child: const Text(
                      "جدول الحصص",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // شريط الأيام
                SizedBox(
                  height: 74,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: days.length,
                    separatorBuilder: (context, i) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final isSelected = index == selectedDayIndex;
                      final item = days[index];
                      return GestureDetector(
                        onTap: () => setState(() => selectedDayIndex = index),
                        child: Container(
                          width: 68,
                          decoration: BoxDecoration(
                            // 🌟 الكرت يتجاوب مع الثيم إذا لم يكن محدداً
                            color: isSelected
                                ? const Color(0xFFFFCC00)
                                : cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item["name"],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  // 🌟 الدائرة الداخلية تتجاوب مع الثيم
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  "${item["day"]}",
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // عنوان اليوم
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    days.isNotEmpty
                        ? "${selectedDayIndex == _todayIndex ? 'اليوم' : days[selectedDayIndex]['name']}: ${(days[selectedDayIndex]['date'] as DateTime).day} ${_monthName((days[selectedDayIndex]['date'] as DateTime).month)}"
                        : '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // كروت الحصص — ديناميكية من الـ API
                if (_isLoading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Color(0xFFFFCC00)),
                  ))
                else ..._buildDayCards(context),
                const SizedBox(height: 120), // مساحة لتجنب الشريط السفلي
              ],
            ),

            // 2. الشريط السفلي الموحد (متموضع في الأسفل)
            CustomBottomNav(
              currentIndex: -1,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherHomeScreen(),
                ),
              ),
              onProfileTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              ),
              onNotificationsTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              ),
              onMessagesTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MessagesScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const names = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
                   'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return names[month];
  }

  List<Widget> _buildDayCards(BuildContext context) {
    if (days.isEmpty) return [];
    final dayKey = days[selectedDayIndex]['dayKey'] as String;
    final rawList = _scheduleData[dayKey] as List? ?? [];
    final classes = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    if (classes.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              'لا توجد حصص هذا اليوم',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ];
    }

    return classes.map((cls) {
      final start = cls['start_time'] as String? ?? '';
      final end   = cls['end_time']   as String? ?? '';
      final room  = cls['room']       as String? ?? '';
      return _buildClassCard(
        context,
        now:        _isNow(start, end),
        title:      cls['course_name'] as String? ?? '',
        subtitle:   room,
        time:       '${_formatTime(start)} - ${_formatTime(end)}',
        icon:       Icons.menu_book_outlined,
        avatars:    0,
        actionText: null,
      );
    }).toList();
  }

  // 🌟 تعديل الـ Widget ليدعم الثيم وتمرير الـ context 🌟
  Widget _buildClassCard(
    BuildContext context, {
    required bool now,
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required int avatars,
    String? actionText,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor, // 🌟 لون الكرت من الثيم
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (now)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCC00),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    "الآن",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              if (now) const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ), // 🌟 لون النص
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ), // 🌟 خلفية الأيقونة
                child: Icon(icon, color: Colors.grey, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (avatars > 0)
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: const Color(0xFFE3F2FD),
                          child: const Text(
                            "أ",
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 12,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: const Color(0xFFF3E5F5),
                            child: const Text(
                              "م",
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF9C27B0),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 24,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: const Color(0xFFFFEBEE),
                            child: const Text(
                              "س",
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFF44336),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      width: 36,
                    ), // مسافة لتجنب التداخل مع الصور المتراكبة
                    Text(
                      "+$avatars",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              const Spacer(),
              Icon(Icons.schedule, size: 18, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(time, style: TextStyle(color: textColor)), // 🌟 لون الوقت
            ],
          ),
          if (actionText != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ), // 🌟 خلفية الزر
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    actionText,
                    style: TextStyle(color: textColor),
                  ), // 🌟 لون نص الزر
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
