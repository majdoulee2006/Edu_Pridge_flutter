import 'package:flutter/material.dart';

import '../../../../widgets/custom_speed_dial.dart';
import '../../messages_screen.dart';
import '../../profile_screen.dart';
import '../../teacher_home.dart';

// ملاحظة: قد تحتاجين لتثبيت مكتبة font_awesome_flutter لإظهار الأيقونات المخصصة تماماً كما في الصورة.
// سأستخدم أيقونات Flutter العادية المشابهة لتبسيط الكود، ولكن يمكنكِ استبدالها بـ FaIcon.
// إذا أردتِ استخدام FaIcon، قومي بإضافة السطر التالي في pubspec.yaml:
// dependencies:
//   font_awesome_flutter: ^10.1.0

class AssignmentsScreen extends StatefulWidget {
const AssignmentsScreen({Key? key}) : super(key: key);

@override
State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
int _currentIndex = 1; // جعل "الملف الشخصي" هو العنصر النشط

@override
Widget build(BuildContext context) {
// الألوان المستوحاة من الصورة
const Color mainAppColor = Color(0xFFF7F7F7); // خلفية التطبيق البيضاء المائلة للصفرة
const Color cardColor = Colors.white; // خلفية البطاقات
const Color activeTabColor = Color(0xFFF0E35F); // اللون الأصفر الداكن للتبويب النشط
const Color activeGlowColor = Color(0xFFFDF7B8); // الظل الأصفر (Glow) للعنصر النشط
const Color textDarkColor = Color(0xFF333333); // لون النص الداكن
const Color textGreyColor = Color(0xFF777777); // لون النص الرمادي
const Color badgeActiveColor = Color(0xFFFFEB3B); // لون شارة "نشط"
const Color badgeGradingColor = Color(0xFFFFD180); // لون شارة "قيد التصحيح"
const Color badgeGradedColor = Color(0xFFC8E6C9); // لون شارة "تم التصحيح"

return Directionality(
textDirection: TextDirection.rtl, // لضبط الواجهة باللغة العربية
child: Scaffold(
backgroundColor: mainAppColor,
appBar: AppBar(
backgroundColor: Colors.transparent,
elevation: 0,
leading: IconButton(
icon: Icon(Icons.arrow_back, color: textDarkColor),
onPressed: () {},
),
title: Text(
'الواجبات والمشاريع',
style: TextStyle(color: textDarkColor, fontWeight: FontWeight.bold, fontSize: 18),
),
actions: [
IconButton(
icon: Icon(Icons.settings, color: textDarkColor),
onPressed: () {},
),
],
centerTitle: true,
),
body: Column(
children: [
// تبويبات (الكل، الردود)
Container(
decoration: BoxDecoration(
border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
),
child: Row(
children: [
_buildTab('الكل', active: true, activeColor: activeTabColor),
_buildTab('الردود', active: false, activeColor: activeTabColor),
],
),
),
const SizedBox(height: 16),

// قائمة البطاقات
Expanded(
child: ListView(
padding: const EdgeInsets.symmetric(horizontal: 16),
children: [
// بطاقة الواجب النشط مع الظل (Glow)
_buildAssignmentCard(
title: 'واجب الفيزياء: الطاقة',
subject: 'الفيزياء | الصف 11 - ب',
date: '2023-11-15',
progress: '24/30',
icon: Icons.list_alt_outlined, // استخدمي FaIcon(FontAwesomeIcons.clipboardList) لشبه أكبر
statusBadge: _buildStatusBadge('نشط', badgeActiveColor, Colors.black),
hasGlow: true,
glowColor: activeGlowColor,
),
const SizedBox(height: 12),

// بطاقة المشروع
_buildAssignmentCard(
title: 'مشروع التخرج الفصلي',
subject: 'العلوم العامة | الصف 10 - أ',
date: '2023-11-20',
progress: '5/28',
icon: Icons.science_outlined, // استخدمي FaIcon(FontAwesomeIcons.flask)
),
const SizedBox(height: 12),

// بطاقة الاختبار القصير
 _buildAssignmentCard(
title: 'اختبار قصير: الدوال',
subject: 'الرياضيات | الصف 12 - أ',
date: '2023-10-30',
progress: '15/28 مصحح',
icon: Icons.assignment_outlined, // استخدمي FaIcon(FontAwesomeIcons.solidFileLines)
statusBadge: _buildStatusBadge('قيد التصحيح', badgeGradingColor, Color(0xFFC62828)), // لون نص أحمر غامق
),
const SizedBox(height: 12),

// بطاقة واجب القراءة
_buildAssignmentCard(
title: 'واجب القراءة والاستيعاب',
subject: 'اللغة العربية | الصف 9 - ج',
date: '2023-10-15',
progress: '30/30',
icon: Icons.check_circle_outline, // استخدمي FaIcon(FontAwesomeIcons.checkDouble)
iconColor: Colors.green,
statusBadge: _buildStatusBadge('تم\nالتصحيح', badgeGradedColor, Color(0xFF1B5E20)), // لون نص أخضر غامق
),
const SizedBox(height: 80), // مساحة للـ FloatingActionButton
],
),
),
],
),




  // الزر الدائري الأوسط
  floatingActionButton: const CustomSpeedDial(),
  floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

  // شريط التنقل السفلي المفعل بالكامل
  bottomNavigationBar: _buildBottomNav(context),
),
);
}

// ويجيت لبناء التبويبات العلوي (الكل، الردود)
Widget _buildTab(String text, {required bool active, required Color activeColor}) {
return Expanded(
child: Column(
children: [
Padding(
padding: const EdgeInsets.symmetric(vertical: 16),
child: Text(
text,
style: TextStyle(
color: active ? activeColor : Colors.grey,
fontWeight: active ? FontWeight.bold : FontWeight.normal,
fontSize: 16,
),
),
),
if (active)
Container(
height: 3,
width: 60,
color: activeColor,
),
],
),
);
}

// ويجيت لبناء شارات الحالة (نشط، قيد التصحيح، تم التصحيح)
Widget _buildStatusBadge(String text, Color bgColor, Color textColor) {
return Container(
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
decoration: BoxDecoration(
color: bgColor,
borderRadius: BorderRadius.circular(8),
),
child: Text(
text,
textAlign: TextAlign.center,
style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
),
);
}

// ويجيت لبناء بطاقة الواجب
Widget _buildAssignmentCard({
required String title,
required String subject,
required String date,
required String progress,
required IconData icon,
Widget? statusBadge,
bool hasGlow = false,
Color glowColor = Colors.white,
Color iconColor = const Color(0xFFF0E35F), // اللون الأصفر كافتراضي للأيقونة
}) {
return Container(
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(16),
// تأثير الـ Glow في البطاقة الأولى
boxShadow: hasGlow
? [
BoxShadow(
color: glowColor.withOpacity(0.8),
spreadRadius: 3,
blurRadius: 7,
offset: const Offset(0, 0),
),
]
    : [
BoxShadow(
 color: Colors.grey.shade100,
spreadRadius: 1,
blurRadius: 3,
offset: const Offset(0, 2),
),
],
),
child: ListTile(
contentPadding: const EdgeInsets.all(16),
leading: Icon(icon, size: 36, color: iconColor), // الأيقونة على اليسار
title: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Expanded(
child: Text(
title,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333)),
),
),
if (statusBadge != null) statusBadge,
],
),
const SizedBox(height: 4),
Text(
subject,
style: const TextStyle(color: Color(0xFF777777), fontSize: 13),
),
],
),
subtitle: Column(
children: [
const SizedBox(height: 16),
const Divider(color: Color(0xFFEEEEEE), height: 1),
const SizedBox(height: 12),
Row(
children: [
const Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFF777777)),
const Spacer(),
Row(
children: [
Text(progress, style: const TextStyle(color: Color(0xFF777777), fontSize: 13)),
const SizedBox(width: 4),
const Icon(Icons.group_outlined, size: 18, color: Color(0xFF777777)),
],
),
const SizedBox(width: 16),
Row(
children: [
Text(date, style: const TextStyle(color: Color(0xFF777777), fontSize: 13)),
const SizedBox(width: 4),
const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF777777)),
],
),
],
),
],
),
),
);
}

  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      height: 70,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(context, Icons.home_outlined, "الرئيسية", false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherHomeScreen()))),
            _navItem(context, Icons.person_outline, "الملف", false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))),
            const SizedBox(width: 40),
            _navItem(context, Icons.notifications, "الإشعارات", true, onTap: () {}),
            _navItem(context, Icons.chat_bubble_outline, "الرسائل", false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MessagesScreen()))),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, bool active, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? const Color(0xFFEFFF00) : Colors.grey),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: active ? const Color(0xFFEFFF00) : Colors.grey,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }


}