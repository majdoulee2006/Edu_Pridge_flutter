import 'package:edu_pridge_flutter/screens/student/center_icons/attendance/attendance_screen.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/lectures/lectures_screen.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/assignments/assignments_screen.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/schedule/schedule_screen.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../core/constants/app_colors.dart';

class StudentSpeedDial extends StatefulWidget {
  const StudentSpeedDial({super.key});

  @override
  State<StudentSpeedDial> createState() => _StudentSpeedDialState();
}

class _StudentSpeedDialState extends State<StudentSpeedDial> with SingleTickerProviderStateMixin {
  bool isOpened = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // حركة الارتداد (easeOutBack) بتعطي تأثير أنيميشن رائع
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
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
        // 1. التغبيش (Blur) مغطى على كامل الشاشة
        if (isOpened)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.white.withOpacity(0.4)), // تغبيش فاتح مثل صورتك
              ),
            ),
          ),

        // 2. نصف الدائرة البيضاء (كبرناها شوي عشان تسع الأيقونات)
        Positioned(
          bottom: 45, // رفعناها لتتمركز صح مع الزر
          child: ScaleTransition(
            scale: _animation,
            alignment: Alignment.bottomCenter,
            child: CustomPaint(
              size: const Size(330, 165), 
              painter: CleanHalfCirclePainter(),
            ),
          ),
        ),

        // 3. الأيقونات الأربعة (صغرنا مسافة الانتشار radius = 105 لتضل جوا)
        // الزوايا محسوبة بدقة (30، 70، 110، 150)
        _buildItem(Icons.person_add_alt_1, "الحضور", 105, 150, Colors.green, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AttendanceScreen()));
        }),
       _buildItem(Icons.play_circle_fill, "المحاضرات", 105, 110, Colors.purple, () {
         Navigator.push(context, MaterialPageRoute(builder: (context) => const LecturesScreen()));
       }),
       _buildItem(Icons.edit_document, "الواجبات", 105, 70, Colors.blue, () {
         Navigator.push(context, MaterialPageRoute(builder: (context) => const AssignmentsScreen()));
       }),
       _buildItem(Icons.calendar_month, "الجدول", 105, 30, Colors.orange, () {
         Navigator.push(context, MaterialPageRoute(builder: (context) => const ScheduleScreen()));
        }),

        // 4. الزر الأصفر المركزي مع أنيميشن الدوران
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 65, height: 65,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.accent, shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                if (isOpened) BoxShadow(color: AppColors.accent.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)
                else BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: child.key == const ValueKey('close') 
                    ? Tween<double>(begin: 0.5, end: 1).animate(anim) 
                    : Tween<double>(begin: 0.5, end: 1).animate(anim), 
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: isOpened
                  ? const Icon(Icons.close, key: ValueKey('close'), color: AppColors.textDark, size: 30)
                  : const Icon(Icons.grid_view_rounded, key: ValueKey('grid'), color: AppColors.textDark, size: 30),
            ),
          ),
        ),
      ],
    );
  }

  // دالة بناء وتحديد موقع كل أيقونة رياضياً
  Widget _buildItem(IconData icon, String label, double radius, double angleDegrees, Color color, VoidCallback onTap) {
    final double angle = angleDegrees * math.pi / 180;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        double x = _animation.value * radius * math.cos(angle);
        double y = _animation.value * radius * math.sin(angle);
        return Positioned(
          bottom: 28 + y, // نقطة الارتكاز المظبوطة
          right: (MediaQuery.of(context).size.width / 2) - 30 + x, // توسيط 100%
          child: Opacity(
            opacity: _controller.value,
            child: GestureDetector(
              onTap: () { 
                _toggle(); 
                onTap(); 
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      shape: BoxShape.circle, 
                      border: Border.all(color: color.withOpacity(0.2), width: 1.5), 
                      boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8)]
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// الرسام اللي بيرسم نصف الدائرة (بدون خطوط ليكون نظيف وأنيق)
class CleanHalfCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height)
      ..arcTo(Rect.fromLTWH(0, 0, size.width, size.height * 2), math.pi, math.pi, false)
      ..close();
    canvas.drawShadow(path, Colors.black.withOpacity(0.12), 15, true);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}