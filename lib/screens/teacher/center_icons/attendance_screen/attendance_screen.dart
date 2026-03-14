import 'package:flutter/material.dart';

import '../../../../widgets/custom_speed_dial.dart';
import '../../messages_screen.dart';
import '../../profile_screen.dart';
import '../../teacher_home.dart';

void main() {
runApp(const MyApp());
}

class MyApp extends StatelessWidget {
const MyApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
home: AttendanceScreen(),
);
}
}

class AttendanceScreen extends StatelessWidget {
const AttendanceScreen({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xfff5f5f5),

appBar: AppBar(
backgroundColor: Colors.white,
elevation: 0,
centerTitle: true,
title: const Text(
"تسجيل الحضور والغياب",
style: TextStyle(
color: Colors.black,
fontWeight: FontWeight.bold,
),
),
leading: const Icon(Icons.settings, color: Colors.black),
actions: const [
Padding(
padding: EdgeInsets.only(right: 10),
child: Icon(Icons.arrow_forward_ios, color: Colors.black),
)
],
),

body: SingleChildScrollView(
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
children: [

/// الكارد الاول
Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(20),
),

child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [

const Text(
"إعدادات الجلسة",
style: TextStyle(
color: Colors.grey,
fontSize: 14,
),
),

const SizedBox(height: 10),

const Text("المادة الدراسية"),

const SizedBox(height: 6),

Container(
padding: const EdgeInsets.symmetric(horizontal: 12),
decoration: BoxDecoration(
color: const Color(0xfff2f2f2),
borderRadius: BorderRadius.circular(12),
),
child: DropdownButton(
isExpanded: true,
underline: SizedBox(),
hint: Text("اختر المادة"),
items: [],
onChanged: null,
),
),

const SizedBox(height: 16),

const Text("القاعة / الصف"),

const SizedBox(height: 6),

Container(
padding: const EdgeInsets.symmetric(horizontal: 12),
decoration: BoxDecoration(
color: const Color(0xfff2f2f2),
borderRadius: BorderRadius.circular(12),
),
child: DropdownButton(
isExpanded: true,
underline: SizedBox(),
hint: Text("اختر القاعة"),
items: [],
onChanged: null,
),
),

const SizedBox(height: 20),

SizedBox(
width: double.infinity,
height: 50,
child: ElevatedButton.icon(
icon: const Icon(Icons.play_arrow, color: Colors.black),
label: const Text(
"بدء الجلسة",
style: TextStyle(
color: Colors.black,
fontWeight: FontWeight.bold,
),
),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.
 yellow,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(30),
),
),
onPressed: () {},
),
)
],
),
),

const SizedBox(height: 25),

/// العنوان
const Row(
children: [
Expanded(child: Divider()),
Padding(
padding: EdgeInsets.symmetric(horizontal: 10),
child: Text(
"الرمز النشط",
style: TextStyle(color: Colors.grey),
),
),
Expanded(child: Divider()),
],
),

const SizedBox(height: 15),

/// كارد QR
Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(20),
),

child: Column(
children: [

Container(
padding: const EdgeInsets.symmetric(
horizontal: 12, vertical: 6),
decoration: BoxDecoration(
color: const Color(0xffeef5ee),
borderRadius: BorderRadius.circular(20),
),
child: const Text(
"مباشر - المرحلة 1 من 2",
style: TextStyle(color: Colors.green),
),
),

const SizedBox(height: 10),

const Text(
"رمز الحضور",
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 5),

const Text(
"اطلب من الطلاب مسح الرمز أدناه لتسجيل الحضور",
textAlign: TextAlign.center,
style: TextStyle(color: Colors.grey),
),

const SizedBox(height: 20),

Container(
padding: const EdgeInsets.all(10),
decoration: BoxDecoration(
border: Border.all(
color: Colors.yellow,
width: 2,
style: BorderStyle.solid,
),
borderRadius: BorderRadius.circular(12),
),
child: Image.asset(
'assets/images/qr.png',
height: 150,
),
),

const SizedBox(height: 20),

SizedBox(
width: double.infinity,
child: OutlinedButton(
onPressed: () {},
child: const Text("المرحلة التالية (الغياب)"),
),
),

const SizedBox(height: 10),

const Text(
"إنهاء الجلسة وإغلاق السجل",
style: TextStyle(color: Colors.red),
)
],
),
),
],
),
),
),


  // الزر الدائري الأوسط
  floatingActionButton: const CustomSpeedDial(),
  floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

  // شريط التنقل السفلي المفعل بالكامل
  bottomNavigationBar: _buildBottomNav(context),
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