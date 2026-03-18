import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/student_speed_dial.dart';
// مسارات شاشات الـ nav_bar
import '../../nav_bar/student_home_screen.dart';
import '../../nav_bar/profile_screen.dart';
import '../../nav_bar/notifications_screen.dart';
import '../../nav_bar/messages_screen.dart';

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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFDFD), // لون خلفية أبيض مكسور
        appBar: AppBar(
          backgroundColor: const Color(0xFFFDFDFD),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('الجداول الدراسية', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: () {},
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. التاب العلوي (الحصص / الامتحانات)
                _buildCustomTabBar(),
                
                // المحتوى يتغير حسب التاب المختار
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _selectedTab == 0 ? _buildClassSchedule() : _buildExamSchedule(),
                  ),
                ),
              ],
            ),
            
            // الشريط السفلي والزر الأصفر المنبثق
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildFloatingBottomNavBar(context),
            ),
            const Positioned.fill(
              child: StudentSpeedDial(),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // رمادي فاتح جداً
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
    bool isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEFFF00) : Colors.transparent, // الأصفر الفاقع للفعال
            borderRadius: BorderRadius.circular(25),
            boxShadow: isActive ? [BoxShadow(color: const Color(0xFFEFFF00).withOpacity(0.4), blurRadius: 10)] : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // 2. واجهة "جدول الحصص" (الرئيسية في الصورة)
  // ----------------------------------------------------------------
  Widget _buildClassSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        // شريط التواريخ الأفقي
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
        
        // عنوان "برنامج اليوم" مع التاغ
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('برنامج اليوم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFEBEBEB), borderRadius: BorderRadius.circular(15)),
                child: const Text('3 حصص متبقية', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),

        // التايم لاين (الخط الزمني) والكروت
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
            physics: const BouncingScrollPhysics(),
            children: [
              // الحصة الأولى (عادية)
              _buildTimelineItem(
                time: '08:00', amPm: 'ص', isCurrentTime: false,
                card: _buildClassCard(
                  title: 'الرياضيات المتقدمة',
                  instructor: 'د. أحمد علي',
                  location: 'القاعة A',
                  tagText: '90 دقيقة',
                  icon: Icons.calculate_outlined,
                  iconColor: Colors.blue.shade700,
                  iconBgColor: Colors.blue.shade50,
                  isActive: false,
                ),
              ),
              
              // الحصة الثانية (جاري الآن - حدود صفراء)
              _buildTimelineItem(
                time: '09:30', amPm: 'ص', isCurrentTime: true,
                card: _buildClassCard(
                  title: 'الفيزياء التطبيقية',
                  instructor: 'أ. سارة محمد',
                  location: 'المختبر 2',
                  tagText: 'جاري الآن',
                  tagColor: Colors.black87,
                  tagBgColor: const Color(0xFFEFFF00),
                  icon: Icons.science,
                  iconColor: Colors.purple.shade600,
                  iconBgColor: Colors.purple.shade50,
                  isActive: true,
                ),
              ),

              // الاستراحة (كرت مختلف)
              _buildTimelineItem(
                time: '11:00', amPm: 'ص', isCurrentTime: false, isBreak: true,
                card: _buildBreakCard(),
              ),

              // الحصة الثالثة
              _buildTimelineItem(
                time: '11:30', amPm: 'ص', isCurrentTime: false, isLast: true,
                card: _buildClassCard(
                  title: 'علوم الحاسوب',
                  instructor: 'م. خالد يوسف',
                  location: 'معمل الحاسوب',
                  tagText: '90 دقيقة',
                  icon: Icons.computer,
                  iconColor: Colors.teal.shade700,
                  iconBgColor: Colors.teal.shade50,
                  isActive: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // دائرة التاريخ
  Widget _buildDateCircle({required String day, required String date, required int index}) {
    bool isSelected = _selectedDateIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedDateIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(left: 12),
        width: 70, height: 95,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFFF00) : Colors.white,
          borderRadius: BorderRadius.circular(35),
          border: isSelected ? null : Border.all(color: Colors.grey.shade200),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFEFFF00).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(day, style: TextStyle(color: isSelected ? Colors.black87 : Colors.grey, fontSize: 11)),
            const SizedBox(height: 5),
            Text(date, style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            // النقطة السوداء تحت الرقم في حال كان محدد
            if (isSelected) Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle))
            else const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // بناء عنصر التايم لاين (الوقت على اليمين والكرت على اليسار)
  Widget _buildTimelineItem({required String time, required String amPm, required bool isCurrentTime, required Widget card, bool isBreak = false, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عمود الوقت والخط الزمني (يمين)
        SizedBox(
          width: 55,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: isCurrentTime ? BoxDecoration(color: const Color(0xFFEFFF00), borderRadius: BorderRadius.circular(10)) : null,
                child: Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              Text(amPm, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 5),
              // الخط الزمني العمودي
              if (!isLast) Container(width: 1.5, height: isBreak ? 70 : 130, color: Colors.grey.shade300), 
            ],
          ),
        ),
        const SizedBox(width: 15),
        // كرت الحصة (يسار)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: card,
          ),
        ),
      ],
    );
  }

  // تصميم كرت الحصة العادي والفعال
  Widget _buildClassCard({required String title, required String instructor, required String location, required String tagText, Color? tagColor, Color? tagBgColor, required IconData icon, required Color iconColor, required Color iconBgColor, required bool isActive}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: isActive ? Border.all(color: const Color(0xFFEFFF00), width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // التاغ (90 دقيقة أو جاري الآن)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: tagBgColor ?? const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
                child: Text(tagText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tagColor ?? Colors.black54)),
              ),
              // أيقونة المادة مع القائمة (3 نقاط)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.more_horiz, color: Colors.grey),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text(instructor, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(width: 15),
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text(location, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // تصميم كرت الاستراحة
  Widget _buildBreakCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F4), // لون بيج فاتح للاستراحة
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              const Text('استراحة الغداء', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
              const SizedBox(height: 4),
              Text('الكافتيريا الرئيسية', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 25),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.coffee, color: Colors.deepOrange, size: 22),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------
  // 3. واجهة "جدول الامتحانات" (مؤقتة لتأكيد عمل التاب)
  // ----------------------------------------------------------------
  Widget _buildExamSchedule() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 15),
          Text('لا توجد امتحانات في هذا اليوم', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------
  // 4. الشريط السفلي الموحد
  // ----------------------------------------------------------------
  Widget _buildFloatingBottomNavBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_outlined, 'الرئيسية', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentHomeScreen()))),
          _buildNavItem(Icons.person_outline, 'حسابي', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))),
          const SizedBox(width: 70), // مساحة للزر المنبثق
          _buildNavItem(Icons.notifications_none, 'إشعارات', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()))),
          _buildNavItem(Icons.mail_outline, 'مراسلات', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MessagesScreen()))),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? Colors.black : Colors.grey, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.black : Colors.grey)),
        ],
      ),
    );
  }
}