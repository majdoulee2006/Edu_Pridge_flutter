import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../screens/student/center_icons/assignments/assignments_screen.dart';
import '../screens/student/center_icons/attendance/attendance_screen.dart';
import '../screens/student/center_icons/lectures/lectures_screen.dart';
import '../screens/student/center_icons/schedule/schedule_screen.dart';

class StudentSpeedDial extends StatefulWidget {
  const StudentSpeedDial({super.key});

  @override
  State<StudentSpeedDial> createState() => _StudentSpeedDialState();
}

class _StudentSpeedDialState extends State<StudentSpeedDial>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // 🌟 زدنا الوقت لـ 400ms ليكون التأثير التدريجي واضحاً وجميلاً 🌟
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 🌟 نستخدم AnimatedBuilder لتحديث الحركة 60 مرة بالثانية 🌟
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              // إذا كانت القائمة مغلقة تماماً لا نعرض شيئاً
              if (_animationController.value == 0.0)
                return const SizedBox.shrink();

              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // 1. الطبقة الشفافة السوداء (تظهر تدريجياً)
                  GestureDetector(
                    onTap: _toggleMenu,
                    child: Opacity(
                      opacity: _animationController.value,
                      child: Container(color: Colors.black.withOpacity(0.5)),
                    ),
                  ),

                  // 2. القائمة المنبثقة (نصف الدائرة تُرسم تدريجياً)
                  Positioned(
                    bottom: 45,
                    child: CustomPaint(
                      size: const Size(320, 160),
                      painter: MenuBackgroundPainter(
                        _animationController.value,
                      ),
                      child: SizedBox(
                        width: 320,
                        height: 160,
                        child: Stack(
                          children: [
                            // 🌟 إضافة الأزرار مع توقيت تدريجي (Interval) 🌟
                            _buildMenuItem(
                              'الجدول',
                              Icons.calendar_month_outlined,
                              Colors.orange,
                              22.5,
                              0.0, // يبدأ فوراً
                              0.4, // ينتهي عند 40% من وقت الحركة
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ScheduleScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              'الواجبات',
                              Icons.assignment_outlined,
                              Colors.blue,
                              67.5,
                              0.2, // يبدأ متأخراً قليلاً
                              0.6,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AssignmentsScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              'المحاضرات',
                              Icons.play_circle_outline,
                              Colors.purple,
                              112.5,
                              0.4,
                              0.8,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const LecturesScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              'الحضور',
                              Icons.how_to_reg_outlined,
                              Colors.green,
                              157.5,
                              0.6, // يبدأ أخيراً
                              1.0,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AttendanceScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 3. الزر الأصفر المركزي (الأساسي)
          Positioned(
            bottom: 50, // 🌟 تم رفع الأيقونة قليلاً للأعلى (كانت 35) 🌟
            child: GestureDetector(
              onTap: _toggleMenu,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 60,
                width: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFFF00),
                  shape: BoxShape.circle,
                  // 🌟 تم إزالة boxShadow (التوهج) 🌟
                  // 🌟 تم إزالة border (الاطار الابيض) 🌟
                ),
                child: Icon(
                  _isOpen ? Icons.close : Icons.grid_view_rounded,
                  size: 28,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 دالة بناء العناصر مع الحركة التدريجية (Staggered Animation) 🌟
  Widget _buildMenuItem(
    String title,
    IconData icon,
    Color color,
    double angleInDegrees,
    double startAnim,
    double endAnim,
    VoidCallback onTapAction,
  ) {
    double angleInRadians = angleInDegrees * math.pi / 180.0;
    double radius = 100.0;

    double x = 160 + radius * math.cos(angleInRadians);
    double y = 160 - radius * math.sin(angleInRadians);

    // تجهيز حركة القفز الخاصة بهذا الزر تحديداً
    Animation<double> scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(startAnim, endAnim, curve: Curves.easeOutBack),
    );

    return Positioned(
      left: x - 35,
      top: y - 35,
      child: ScaleTransition(
        scale: scaleAnimation, // تطبيق الحركة على الزر
        child: GestureDetector(
          onTap: () {
            _toggleMenu();
            onTapAction();
          },
          child: SizedBox(
            width: 70,
            height: 70,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// --- الرسام المخصص لنصف الدائرة والخطوط ---
// ==========================================
class MenuBackgroundPainter extends CustomPainter {
  final double progress; // قيمة الحركة (من 0.0 إلى 1.0)

  MenuBackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    Paint fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 🌟 رسم نصف الدائرة بشكل تدريجي من اليمين إلى اليسار 🌟
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height),
        radius: size.height,
      ),
      0.0, // نقطة البداية (من اليمين)
      -math.pi * progress, // مقدار الالتفاف (يعتمد على الحركة)
      true,
      fillPaint,
    );

    Paint linePaint = Paint()
      ..color = Colors.grey.shade200
          .withOpacity(progress) // شفافة في البداية وتوضح تدريجياً
      ..strokeWidth = 1.5;

    Offset center = Offset(size.width / 2, size.height);
    List<double> angles = [math.pi / 4, math.pi / 2, 3 * math.pi / 4];

    for (double angle in angles) {
      // 🌟 لا نرسم الخط الفاصل إلا إذا وصلت الدائرة إليه 🌟
      if (math.pi * progress >= angle) {
        double dx = center.dx + size.height * math.cos(angle);
        double dy = center.dy - size.height * math.sin(angle);
        canvas.drawLine(center, Offset(dx, dy), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MenuBackgroundPainter oldDelegate) {
    // يجب إعادة الرسم في كل إطار من الحركة
    return oldDelegate.progress != progress;
  }
}
