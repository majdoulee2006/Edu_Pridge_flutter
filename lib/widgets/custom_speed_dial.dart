import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

// ✅ ملاحظة: تأكد من صحة مسارات الملفات أدناه حسب مشروعك
import '../screens/teacher/center_icons/assignments_screen/assignments_screen.dart';
import '../screens/teacher/center_icons/attendance_screen/attendance_screen.dart';
import '../screens/teacher/center_icons/lectures_Screen/lectures_Screen.dart';
import '../screens/teacher/center_icons/scedual_screen/scedual_screen.dart';

class CustomSpeedDialEduBridge extends StatefulWidget {
  const CustomSpeedDialEduBridge({super.key});

  @override
  State<CustomSpeedDialEduBridge> createState() => _CustomSpeedDialEduBridgeState();
}

class _CustomSpeedDialEduBridgeState extends State<CustomSpeedDialEduBridge> with SingleTickerProviderStateMixin {
  bool isOpened = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350)
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() => setState(() {
    isOpened = !isOpened;
    isOpened ? _controller.forward() : _controller.reverse();
  });

  @override
  Widget build(BuildContext context) {
    // حساب الأبعاد بناءً على حجم الشاشة
    double dialWidth = MediaQuery.of(context).size.width * 0.90;
    double dialRadius = dialWidth / 2;

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
              size: Size(dialWidth, dialRadius),
              painter: HalfCirclePainter(),
            ),
          ),
        ),

        // توزيع الأيقونات في نصف الدائرة
        _buildItem(context, Icons.how_to_reg, "الحضور", dialRadius * 0.75, 155, Colors.green, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AttendanceScreen()));
        }),
        _buildItem(context, Icons.play_circle_fill, "المحاضرات", dialRadius * 0.75, 110, Colors.purple, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const LecturesScreen()));
        }),
        _buildItem(context, Icons.assignment, "الواجبات", dialRadius * 0.75, 70, Colors.blue, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AssignmentsScreen()));
        }),
        _buildItem(context, Icons.calendar_month, "الجدول", dialRadius * 0.75, 25, Colors.orange, () {
          // تأكد من اسم كلاس الجدول في مشروعك
          Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherScheduleScreen()));
        }),

        // الزر الأساسي (النبض)
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 65,
            height: 65,
            margin: const EdgeInsets.only(bottom: 5),
            decoration: const BoxDecoration(
              color: Color(0xFFEFFF00),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
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

  Widget _buildItem(BuildContext context, IconData icon, String label, double radius, double angleDeg, Color color, VoidCallback onTap) {
    double rad = angleDeg * math.pi / 180;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        double x = math.cos(rad) * radius * _animation.value;
        double y = math.sin(rad) * radius * _animation.value;

        return Positioned(
          bottom: 40 + y,
          left: (MediaQuery.of(context).size.width / 2) - 30 - x,
          child: Opacity(
            opacity: _controller.value,
            child: GestureDetector(
              onTap: () {
                _toggle();
                onTap();
              },
              child: SizedBox(
                width: 60,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 28),
                    const SizedBox(height: 2),
                    Text(label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                  ],
                ),
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
    final paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height)
      ..arcTo(Rect.fromLTWH(0, 0, size.width, size.height * 2), math.pi, math.pi, false)
      ..close();
    canvas.drawShadow(path, Colors.black26, 10, false);
    canvas.drawPath(path, paint);

    // رسم الخطوط الفاصلة في المروحة
    final linePaint = Paint()..color = Colors.grey.withOpacity(0.1)..strokeWidth = 1.0;
    final center = Offset(size.width / 2, size.height);
    for (var angle in [45.0, 90.0, 135.0]) {
      final rad = angle * math.pi / 180;
      canvas.drawLine(center, Offset(center.dx - (size.width / 2) * math.cos(rad), center.dy - (size.width / 2) * math.sin(rad)), linePaint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}