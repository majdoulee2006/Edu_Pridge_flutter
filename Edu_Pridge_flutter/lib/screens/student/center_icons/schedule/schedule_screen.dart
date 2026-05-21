import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:flutter/material.dart';
import '../../../../widgets/student_speed_dial.dart';
// مسارات شاشات الـ nav_bar
import '../../nav_bar/student_home_screen.dart';
import '../../nav_bar/profile_screen.dart';
import '../../nav_bar/notifications_screen.dart';
import '../../nav_bar/messages_screen.dart';
// استدعاء واجهة الإعدادات وتفاصيل الدردشة
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/student/nav_bar/chat_detail_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedTab = 0; // 0 = جدول الحصص، 1 = جدول الامتحانات
  int _selectedDateIndex = 1; // 1 = الاثنين (افتراضياً كما في الصورة)

  // قائمة أيام الأسبوع للتواريخ
  final List<Map<String, String>> _dates = [
    {'day': 'الأحد', 'date': '12'},
    {'day': 'الاثنين', 'date': '13'},
    {'day': 'الثلاثاء', 'date': '14'},
    {'day': 'الأربعاء', 'date': '15'},
    {'day': 'الخميس', 'date': '16'},
  ];

  @override
  Widget build(BuildContext context) {
    // 🌟 جلب حالة الوضع الليلي 🌟
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFFDFDFD);
    final textColor = isDark ? Colors.white : Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor, // 🌟 لون متجاوب
        appBar: AppBar(
          backgroundColor: bgColor, // 🌟 لون متجاوب
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor), // 🌟 أيقونة متجاوبة
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'الجداول الدراسية',
            style: TextStyle(
              color: textColor, // 🌟 نص متجاوب
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.settings, color: textColor), // 🌟 أيقونة متجاوبة
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCustomTabBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _selectedTab == 0
                        ? _buildClassSchedule()
                        : _buildExamSchedule(),
                  ),
                ),
              ],
            ),

            // 🌟 استدعاء الشريط الموحد هنا (-1 لأنها واجهة فرعية) 🌟
            CustomBottomNav(
              currentIndex: -1,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentHomeScreen(),
                ),
              ),
              onProfileTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ),
              onNotificationsTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              ),
              onMessagesTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MessagesScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // 1. التاب العلوي
  // ----------------------------------------------------------------
  Widget _buildCustomTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(15)
            : const Color(0xFFF5F5F5), // 🌟 لون متجاوب
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildTabItem(title: 'جدول الحصص', index: 0),
          _buildTabItem(title: 'جدول الامتحانات', index: 1),
        ],
      ),
    );
  }

  Widget _buildTabItem({required String title, required int index}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFEFFF00)
                : Colors.transparent, // الأصفر الفاقع للفعال
            borderRadius: BorderRadius.circular(25),
            boxShadow: isActive
                ? [
              BoxShadow(
                color: const Color(
                  0xFFEFFF00,
                ).withAlpha(100), // 🌟 بديل withOpacity
                blurRadius: 10,
              ),
            ]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? Colors.black87
                    : (isDark
                    ? Colors.grey.shade400
                    : Colors.black87), // 🌟 نص متجاوب
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // 2. واجهة "جدول الحصص"
  // ----------------------------------------------------------------
  Widget _buildClassSchedule() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedDayName = _dates[_selectedDateIndex]['day']!;

    List<Widget> currentSchedule = _selectedDateIndex == 1
        ? [
      _buildTimelineItem(
        time: '08:00',
        amPm: 'ص',
        isCurrentTime: false,
        card: _buildClassCard(
          title: 'الرياضيات المتقدمة',
          instructor: 'د. أحمد علي',
          instructorId: 1, // 🌟 تمت الإضافة
          location: 'القاعة A',
          tagText: '90 دقيقة',
          icon: Icons.calculate_outlined,
          iconColor: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
          iconBgColor: isDark
              ? Colors.blue.withAlpha(30)
              : Colors.blue.shade50,
          isActive: false,
        ),
      ),
      _buildTimelineItem(
        time: '09:30',
        amPm: 'ص',
        isCurrentTime: true,
        card: _buildClassCard(
          title: 'الفيزياء التطبيقية',
          instructor: 'أ. سارة محمد',
          instructorId: 2, // 🌟 تمت الإضافة
          location: 'المختبر 2',
          tagText: 'جاري الآن',
          tagColor: Colors.black87,
          tagBgColor: const Color(0xFFEFFF00),
          icon: Icons.science,
          iconColor: isDark
              ? Colors.purple.shade300
              : Colors.purple.shade600,
          iconBgColor: isDark
              ? Colors.purple.withAlpha(30)
              : Colors.purple.shade50,
          isActive: true,
        ),
      ),
      _buildTimelineItem(
        time: '11:00',
        amPm: 'ص',
        isCurrentTime: false,
        isBreak: true,
        card: _buildBreakCard(),
      ),
      _buildTimelineItem(
        time: '11:30',
        amPm: 'ص',
        isCurrentTime: false,
        isLast: true,
        card: _buildClassCard(
          title: 'علوم الحاسوب',
          instructor: 'م. خالد يوسف',
          instructorId: 4, // 🌟 تمت الإضافة
          location: 'معمل الحاسوب',
          tagText: '90 دقيقة',
          icon: Icons.computer,
          iconColor: isDark ? Colors.teal.shade300 : Colors.teal.shade700,
          iconBgColor: isDark
              ? Colors.teal.withAlpha(30)
              : Colors.teal.shade50,
          isActive: false,
        ),
      ),
    ]
        : [
      _buildTimelineItem(
        time: '10:00',
        amPm: 'ص',
        isCurrentTime: false,
        card: _buildClassCard(
          title: 'اللغة الإنجليزية',
          instructor: 'د. ليلى حسن',
          instructorId: 3, // 🌟 تمت الإضافة
          location: 'القاعة B',
          tagText: 'ساعتان',
          icon: Icons.language,
          iconColor: isDark ? Colors.red.shade300 : Colors.red.shade700,
          iconBgColor: isDark
              ? Colors.red.withAlpha(30)
              : Colors.red.shade50,
          isActive: false,
        ),
      ),
      _buildTimelineItem(
        time: '12:00',
        amPm: 'م',
        isCurrentTime: false,
        isLast: true,
        card: _buildClassCard(
          title: 'أساسيات البرمجة',
          instructor: 'م. يوسف',
          instructorId: 5, // 🌟 تمت الإضافة
          location: 'المعمل 1',
          tagText: '90 دقيقة',
          icon: Icons.computer,
          iconColor: isDark ? Colors.teal.shade300 : Colors.teal.shade700,
          iconBgColor: isDark
              ? Colors.teal.withAlpha(30)
              : Colors.teal.shade50,
          isActive: false,
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: List.generate(_dates.length, (index) {
              return _buildDateCircle(
                day: _dates[index]['day']!,
                date: _dates[index]['date']!,
                index: index,
              );
            }),
          ),
        ),

        const SizedBox(height: 25),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'برنامج $selectedDayName',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black87, // 🌟 متجاوب
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(25)
                      : const Color(0xFFEBEBEB), // 🌟 متجاوب
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '${currentSchedule.length} حصص',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.grey.shade300
                        : Colors.black54, // 🌟 متجاوب
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Expanded(
          child: ListView(
            key: ValueKey<int>(_selectedDateIndex),
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
            physics: const BouncingScrollPhysics(),
            children: currentSchedule,
          ),
        ),
      ],
    );
  }

  // دائرة التاريخ
  Widget _buildDateCircle({
    required String day,
    required String date,
    required int index,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSelected = _selectedDateIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedDateIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(left: 12),
        width: 70,
        height: 95,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEFFF00)
              : (isDark
              ? Theme.of(context).cardColor
              : Colors.white), // 🌟 متجاوب
          borderRadius: BorderRadius.circular(35),
          border: isSelected
              ? null
              : Border.all(
            color: isDark
                ? Colors.white.withAlpha(20)
                : Colors.grey.shade200,
          ), // 🌟 متجاوب
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(
                0xFFEFFF00,
              ).withAlpha(100), // 🌟 بديل withOpacity
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day,
              style: TextStyle(
                color: isSelected ? Colors.black87 : Colors.grey,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              date,
              style: TextStyle(
                color: isSelected
                    ? Colors.black
                    : (isDark ? Colors.white : Colors.black), // 🌟 متجاوب
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            if (isSelected)
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String amPm,
    required bool isCurrentTime,
    required Widget card,
    bool isBreak = false,
    bool isLast = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 55,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: isCurrentTime
                    ? BoxDecoration(
                  color: const Color(0xFFEFFF00),
                  borderRadius: BorderRadius.circular(10),
                )
                    : null,
                child: Text(
                  time,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isCurrentTime
                        ? Colors.black
                        : (isDark ? Colors.white : Colors.black), // 🌟 متجاوب
                  ),
                ),
              ),
              Text(
                amPm,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 5),
              if (!isLast)
                Container(
                  width: 1.5,
                  height: isBreak ? 70 : 130,
                  color: isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade300, // 🌟 خط زمني متجاوب
                ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: card,
          ),
        ),
      ],
    );
  }

  // 🌟 النوافذ المنبثقة (Dialogs) للخيارات 🌟

  // 1. نافذة تفاصيل المادة
  void _showSubjectDetailsDialog(
      String title,
      String instructor,
      String location,
      String tagText,
      IconData icon,
      Color iconColor,
      Color iconBgColor,
      ) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: isDark
                ? Theme.of(context).cardColor
                : Colors.white, // 🌟 خلفية متجاوبة
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : Colors.black, // 🌟 متجاوب
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.grey),
                  title: const Text(
                    'أستاذ المادة',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  subtitle: Text(
                    instructor,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black, // 🌟 متجاوب
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.grey),
                  title: const Text(
                    'القاعة / الموقع',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  subtitle: Text(
                    location,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black, // 🌟 متجاوب
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.timer, color: Colors.grey),
                  title: const Text(
                    'مدة المحاضرة',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  subtitle: Text(
                    tagText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black, // 🌟 متجاوب
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'إغلاق',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black, // 🌟 متجاوب
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 2. نافذة ضبط تذكير (مع DatePicker و TimePicker)
  void _showReminderDialog(String title) {
    DateTime? selectedDate = DateTime.now();
    TimeOfDay? selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: isDark
                    ? Theme.of(context).cardColor
                    : Colors.white, // 🌟 متجاوب
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                title: Text(
                  'ضبط تذكير',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ), // 🌟 متجاوب
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المادة: $title',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    // زر اختيار التاريخ
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withAlpha(30)
                              : Colors.grey.shade300,
                        ), // ✅ تم التعديل هنا لـ side بدلاً من borderSide
                      ),
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Colors.blue,
                      ),
                      title: Text(
                        '${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ), // 🌟 متجاوب
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate!,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setStateBuilder(() => selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    // زر اختيار الوقت
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withAlpha(30)
                              : Colors.grey.shade300,
                        ), // ✅ تم التعديل هنا لـ side
                      ),
                      leading: const Icon(
                        Icons.access_time,
                        color: Colors.orange,
                      ),
                      title: Text(
                        selectedTime!.format(context),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ), // 🌟 متجاوب
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime!,
                        );
                        if (picked != null) {
                          setStateBuilder(() => selectedTime = picked);
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFFF00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم ضبط التذكير بنجاح'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: const Text(
                      'حفظ',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 3. نافذة تقديم عذر غياب مع قائمة المرفقات
  void _showAbsenceExcuseDialog(String title) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: isDark
                ? Theme.of(context).cardColor
                : Colors.white, // 🌟 متجاوب
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            title: Text(
              'تقديم عذر - $title',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ), // 🌟 متجاوب
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  maxLines: 3,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ), // 🌟 متجاوب
                  decoration: InputDecoration(
                    hintText: 'يرجى كتابة سبب الغياب أو التأخير...',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withAlpha(30)
                            : Colors.grey.shade300,
                      ), // 🌟 متجاوب
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withAlpha(30)
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                InkWell(
                  onTap: _showAttachmentOptions, // فتح قائمة اختيار الملفات
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withAlpha(30)
                            : Colors.grey.shade300,
                      ), // 🌟 متجاوب
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.blueGrey, // 🌟 متجاوب
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'إرفاق مستند أو صورة',
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.blueGrey, // 🌟 متجاوب
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFFF00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إرسال العذر بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text(
                  'إرسال العذر',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // قائمة المرفقات السفلية الخاصة بنافذة العذر
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? Theme.of(context).cardColor
                  : Colors.white, // 🌟 متجاوب
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'إرفاق ملف',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ), // 🌟 متجاوب
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachmentOption(
                      Icons.camera_alt,
                      'الكاميرا',
                      Colors.blue,
                    ),
                    _buildAttachmentOption(
                      Icons.photo_library,
                      'المعرض',
                      Colors.purple,
                    ),
                    _buildAttachmentOption(
                      Icons.insert_drive_file,
                      'مستند',
                      Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(IconData icon, String title, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // إغلاق القائمة السفلية
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم اختيار $title بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withAlpha(
                isDark ? 50 : 25,
              ), // 🌟 بديل withOpacity ومتجاوب
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDark ? color.withAlpha(200) : color,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ), // 🌟 متجاوب
          ),
        ],
      ),
    );
  }

  // تصميم كرت الحصة
  Widget _buildClassCard({
    required String title,
    required String instructor,
    required int instructorId, // 🌟 تمت الإضافة هنا
    required String location,
    required String tagText,
    Color? tagColor,
    Color? tagBgColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required bool isActive,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white, // 🌟 متجاوب
        borderRadius: BorderRadius.circular(25),
        border: isActive
            ? Border.all(color: const Color(0xFFEFFF00), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(50)
                : Colors.black.withAlpha(8), // 🌟 بديل withOpacity
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                  tagBgColor ??
                      (isDark
                          ? Colors.white.withAlpha(20)
                          : const Color(0xFFF5F5F5)), // 🌟 متجاوب
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tagText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color:
                    tagColor ??
                        (isDark ? Colors.white70 : Colors.black54), // 🌟 متجاوب
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 5),

                  // 🌟 قائمة الخيارات المنبثقة (الثلاث نقاط) المبرمجة بالكامل 🌟
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, color: Colors.grey),
                    color: isDark
                        ? Theme.of(context).cardColor
                        : Colors.white, // 🌟 قائمة متجاوبة
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    onSelected: (value) {
                      if (value == 'تفاصيل المادة') {
                        _showSubjectDetailsDialog(
                          title,
                          instructor,
                          location,
                          tagText,
                          icon,
                          iconColor,
                          iconBgColor,
                        );
                      } else if (value == 'مراسلة المدرس') {
                        // 🌟 الانتقال لواجهة الدردشة مع التمرير الصحيح 🌟
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              receiverId: instructorId, // 🌟 التعديل السحري هنا
                              name: instructor,
                              imageUrl:
                              'https://i.pravatar.cc/150?u=${instructor.hashCode}', // صورة افتراضية
                              isGroup: false,
                            ),
                          ),
                        );
                      } else if (value == 'ضبط تذكير') {
                        _showReminderDialog(title);
                      } else if (value == 'تقديم عذر غياب') {
                        _showAbsenceExcuseDialog(title);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                        value: 'تفاصيل المادة',
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'تفاصيل المادة',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'مراسلة المدرس',
                        child: Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 18,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'مراسلة المدرس',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'ضبط تذكير',
                        child: Row(
                          children: [
                            Icon(
                              Icons.alarm_add,
                              size: 18,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ضبط تذكير',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'تقديم عذر غياب',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_document,
                              size: 18,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'تقديم عذر غياب',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87, // 🌟 متجاوب
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text(
                instructor,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(width: 15),
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 5),
              Text(
                location,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // تصميم كرت الاستراحة
  Widget _buildBreakCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade900
            : const Color(0xFFF8F8F4), // 🌟 متجاوب
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                'استراحة الغداء',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black87, // 🌟 متجاوب
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'الكافتيريا الرئيسية',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 25),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.white, // 🌟 متجاوب
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.coffee, color: Colors.deepOrange, size: 22),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------
  // 3. واجهة "جدول الامتحانات"
  // ----------------------------------------------------------------
  Widget _buildExamSchedule() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 120),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الامتحانات النهائية',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : Colors.black87, // 🌟 متجاوب
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'جاري تنزيل جدول الامتحانات بصيغة PDF...',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF1E1E1E,
                  ), // أسود دائماً ليبرز فيه الأصفر
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25), // بديل withOpacity
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.download_rounded,
                      color: Color(0xFFEFFF00),
                      size: 16,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'PDF',
                      style: TextStyle(
                        color: Color(0xFFEFFF00),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _buildExamCard(
          time: '09:00 ص',
          title: 'الرياضيات المتقدمة',
          duration: 'ساعتان',
          location: 'القاعة الكبرى (A)',
          month: 'يونيو',
          dayNumber: '12',
          dayName: 'الأحد',
        ),
        _buildExamCard(
          time: '09:00 ص',
          title: 'الفيزياء التطبيقية',
          duration: 'ساعتان',
          location: 'مدرج العلوم 1',
          month: 'يونيو',
          dayNumber: '14',
          dayName: 'الثلاثاء',
        ),
        _buildExamCard(
          time: '11:00 ص',
          title: 'أساسيات البرمجة',
          duration: '90 دقيقة',
          location: 'معمل الحاسوب المركزي',
          month: 'يونيو',
          dayNumber: '16',
          dayName: 'الخميس',
        ),

        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.orange.withAlpha(20)
                : const Color(0xFFFFFDF0), // 🌟 متجاوب
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isDark
                  ? Colors.orange.withAlpha(50)
                  : const Color(0xFFFFF59D),
              width: 1.5,
            ), // 🌟 متجاوب
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFFF57C00),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'يرجى الحضور قبل موعد الامتحان بـ 15 دقيقة على الأقل وإحضار البطاقة الجامعية.',
                  style: TextStyle(
                    color: isDark
                        ? Colors.orange.shade400
                        : Colors.orange.shade800, // 🌟 متجاوب
                    fontSize: 11,
                    height: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExamCard({
    required String time,
    required String title,
    required String duration,
    required String location,
    required String month,
    required String dayNumber,
    required String dayName,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white, // 🌟 متجاوب
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(50)
                : Colors.black.withAlpha(8),
            blurRadius: 10,
          ), // 🌟 بديل withOpacity
        ],
      ),
      child: Row(
        children: [
          Text(
            time,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.red.withAlpha(30)
                        : const Color(0xFFFFEBEE), // 🌟 متجاوب
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'نهائي',
                    style: TextStyle(
                      color: isDark
                          ? Colors.red.shade300
                          : Colors.red, // 🌟 متجاوب
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87, // 🌟 متجاوب
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withAlpha(15)
                  : const Color(0xFFF9F9F9), // 🌟 متجاوب
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Text(
                  month,
                  style: const TextStyle(color: Colors.grey, fontSize: 9),
                ),
                const SizedBox(height: 2),
                Text(
                  dayNumber,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black, // 🌟 متجاوب
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dayName,
                  style: const TextStyle(color: Colors.grey, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}