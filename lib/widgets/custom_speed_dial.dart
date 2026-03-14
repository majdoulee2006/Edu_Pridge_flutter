import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../core/constants/app_colors.dart';
import '../screens/teacher/center_icons/assignments_screen/assignments_screen.dart';
import '../screens/teacher/center_icons/attendance_screen/attendance_screen.dart';
import '../screens/teacher/center_icons/lectures_Screen/lectures_Screen.dart';
import '../screens/teacher/center_icons/scedual_screen/scedual_screen.dart';
// استيراد الصفحات - تأكدي من صحة المسارات في مشروعك

class CustomSpeedDial extends StatefulWidget {
const CustomSpeedDial({super.key});

@override
State<CustomSpeedDial> createState() => _CustomSpeedDialState();
}

class _CustomSpeedDialState extends State<CustomSpeedDial> with SingleTickerProviderStateMixin {
bool isOpened = false;
late AnimationController _controller;
late Animation<double> _animation;

@override
void initState() {
super.initState();
_controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
_animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
}

void _toggle() => setState(() {
isOpened = !isOpened;
isOpened ? _controller.forward() : _controller.reverse();
});

@override
void dispose() {
_controller.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Stack(
alignment: Alignment.bottomCenter,
clipBehavior: Clip.none,
children: [
if (isOpened)
GestureDetector(
onTap: _toggle,
child: BackdropFilter(
filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
child: Container(color: Colors.black.withOpacity(0.1)),
),
),

Positioned(
bottom: 35,
child: ScaleTransition(
scale: _animation,
alignment: Alignment.bottomCenter,
child: CustomPaint(
size: const Size(320, 160),
painter: HalfCirclePainter(),
),
),
),

// الأيقونات مع الروابط الصحيحة
_buildItem(Icons.how_to_reg, "الحضور", 115, 155, Colors.green, () {
 Navigator.push(context, MaterialPageRoute(builder: (context) => const AttendanceScreen()));
}),
_buildItem(Icons.play_circle_fill, "المحاضرات", 115, 115, Colors.purple, () {
Navigator.push(context, MaterialPageRoute(builder: (context) => const LecturesScreen()));
}),
_buildItem(Icons.assignment, "الواجبات", 115, 65, Colors.blue, () {
 Navigator.push(context, MaterialPageRoute(builder: (context) => const AssignmentsScreen()));
}),
_buildItem(Icons.calendar_month, "الجدول", 115, 25, Colors.orange, () {
Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherScheduleScreen()));
}),

GestureDetector(
onTap: _toggle,
child: Container(
width: 65,
height: 65,
margin: const EdgeInsets.only(bottom: 5),
decoration: BoxDecoration(
color: const Color(0xFFEFFF00),
shape: BoxShape.circle,
boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
),
child: Icon(
isOpened ? Icons.close : Icons.grid_view_rounded,
color: Colors.black,
size: 30,
),
),
),
],
);
}

Widget _buildItem(IconData icon, String label, double radius, double angleDegrees, Color color, VoidCallback onTap) {
final double angle = angleDegrees * math.pi / 180;
return AnimatedBuilder(
animation: _animation,
builder: (context, child) {
double x = _animation.value * radius * math.cos(angle);
double y = _animation.value * radius * math.sin(angle);
return Positioned(
bottom: 35 + y,
left: (MediaQuery.of(context).size.width / 2) - 30 - x,
child: Opacity(
opacity: _controller.value,
child: GestureDetector(
onTap: () {
_toggle(); // إغلاق المروحة
onTap();   // الانتقال للصفحة
},
child: Column(
 children: [
Icon(icon, color: color, size: 28),
Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
],
),
),
),
);
},
);
}
}

class HalfCirclePainter extends CustomPainter {
@override
void paint(Canvas canvas, Size size) {
final paint = Paint()
..color = Colors.white
..style = PaintingStyle.fill;

final path = Path()
..moveTo(0, size.height)
..arcTo(Rect.fromLTWH(0, 0, size.width, size.height * 2), math.pi, math.pi, false)
..close();

canvas.drawShadow(path, Colors.black.withOpacity(0.5), 10, true);
canvas.drawPath(path, paint);

final linePaint = Paint()
..color = Colors.grey.withOpacity(0.2)
..strokeWidth = 1.2;

final center = Offset(size.width / 2, size.height);
for (var angle in [45.0, 90.0, 135.0]) {
final rad = angle * math.pi / 180;
final dx = (size.width / 2) * math.cos(rad);
final dy = (size.width / 2) * math.sin(rad);
canvas.drawLine(center, Offset(center.dx - dx, center.dy - dy), linePaint);
}
}

@override
bool shouldRepaint(CustomPainter oldDelegate) => false;
}