import 'package:flutter/material.dart';
import 'dart:math' as math;

// ملاحظة: استبدل هذه المسارات بمسارات الشاشات الحقيقية في مشروعك لاحقاً
// import '../screens/head_of_department/management/teachers_manage_screen.dart';
// import '../screens/head_of_department/reports/department_reports_screen.dart';

class Boss_Center_Icon extends StatefulWidget {
  const Boss_Center_Icon({super.key});

  @override
  State<Boss_Center_Icon> createState() => _Boss_Center_IconState();
}

class _Boss_Center_IconState extends State<Boss_Center_Icon>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color menuBgColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final Color itemTextColor = isDark ? Colors.white : Colors.black87;
    final Color separatorColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              if (_animationController.value == 0.0) return const SizedBox.shrink();

              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  GestureDetector(
                    onTap: _toggleMenu,
                    child: Opacity(
                      opacity: _animationController.value,
                      child: Container(color: Colors.black.withAlpha(125)),
                    ),
                  ),
                  Positioned(
                    bottom: 45,
                    child: CustomPaint(
                      size: const Size(320, 160),
                      painter: MenuBackgroundPainter(
                        progress: _animationController.value,
                        bgColor: menuBgColor,
                        lineColor: separatorColor,
                      ),
                      child: SizedBox(
                        width: 320,
                        height: 160,
                        child: Stack(
                          children: [
                            // 1. زر المدرسين (إدارة الكادر)
                            _buildMenuItem(
                              'المدرسين',
                              Icons.groups_outlined,
                              Colors.blueAccent,
                              22.5,
                              0.0,
                              0.4,
                              itemTextColor,
                                  () {
                                // Navigator.push(...)
                              },
                            ),
                            // 2. زر الجداول (تنظيم الوقت)
                            _buildMenuItem(
                              'الجداول',
                              Icons.calendar_month_outlined,
                              Colors.orangeAccent,
                              67.5,
                              0.2,
                              0.6,
                              itemTextColor,
                                  () {
                                // Navigator.push(...)
                              },
                            ),
                            // 3. زر الإحصائيات (تقارير القسم)
                            _buildMenuItem(
                              'تقارير',
                              Icons.bar_chart_rounded,
                              Colors.greenAccent,
                              112.5,
                              0.4,
                              0.8,
                              itemTextColor,
                                  () {
                                // Navigator.push(...)
                              },
                            ),
                            // 4. زر الإعدادات/القرارات (إدارة القسم)
                            _buildMenuItem(
                              'القرارات',
                              Icons.gavel_rounded,
                              Colors.redAccent,
                              157.5,
                              0.6,
                              1.0,
                              itemTextColor,
                                  () {
                                // Navigator.push(...)
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
          Positioned(
            bottom: 50,
            child: GestureDetector(
              onTap: _toggleMenu,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 60,
                width: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFFF00),
                  shape: BoxShape.circle,
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

  Widget _buildMenuItem(
      String title,
      IconData icon,
      Color color,
      double angleInDegrees,
      double startAnim,
      double endAnim,
      Color textColor,
      VoidCallback onTapAction,
      ) {
    double angleInRadians = angleInDegrees * math.pi / 180.0;
    double radius = 100.0;
    double x = 160 + radius * math.cos(angleInRadians);
    double y = 160 - radius * math.sin(angleInRadians);

    Animation<double> scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(startAnim, endAnim, curve: Curves.easeOutBack),
    );

    return Positioned(
      left: x - 35,
      top: y - 35,
      child: ScaleTransition(
        scale: scaleAnimation,
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
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'Cairo', // تأكد من استخدام خطك المعتمد
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

// --- الرسام المخصص (نفسه تماماً لضمان التطابق) ---
class MenuBackgroundPainter extends CustomPainter {
  final double progress;
  final Color bgColor;
  final Color lineColor;

  MenuBackgroundPainter({
    required this.progress,
    required this.bgColor,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint fillPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height),
        radius: size.height,
      ),
      0.0,
      -math.pi * progress,
      true,
      fillPaint,
    );

    int alphaValue = (255 * 0.2 * progress).toInt();
    Paint linePaintPaint = Paint()
      ..color = lineColor.withAlpha(alphaValue)
      ..strokeWidth = 1.5;

    Offset center = Offset(size.width / 2, size.height);
    List<double> angles = [math.pi / 4, math.pi / 2, 3 * math.pi / 4];

    for (double angle in angles) {
      if (math.pi * progress >= angle) {
        double dx = center.dx + size.height * math.cos(angle);
        double dy = center.dy - size.height * math.sin(angle);
        canvas.drawLine(center, Offset(dx, dy), linePaintPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MenuBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.bgColor != bgColor ||
        oldDelegate.lineColor != lineColor;
  }
}