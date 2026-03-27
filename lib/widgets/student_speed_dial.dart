import 'package:flutter/material.dart';
import 'dart:math' as math;

// 🌟 مسارات شاشات المعلم (نفسها اللي بكودك ما انحذف منها شي) 🌟
import '../screens/teacher/center_icons/assignments_screen/assignments_screen.dart';
import '../screens/teacher/center_icons/attendance_screen/attendance_screen.dart';
import '../screens/teacher/center_icons/lectures_Screen/lectures_Screen.dart';
import '../screens/teacher/center_icons/scedual_screen/scedual_screen.dart';

class CustomSpeedDialEduBridge extends StatefulWidget {
  const CustomSpeedDialEduBridge({super.key});

  @override
  State<CustomSpeedDialEduBridge> createState() => _CustomSpeedDialEduBridgeState();
}

class _CustomSpeedDialEduBridgeState extends State<CustomSpeedDialEduBridge>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // 🌟 التوقيت التدريجي المريح (400ms) 🌟
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
    // 🌟 التحقق من الثيم لتحديد ألوان القائمة المنبثقة 🌟
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // تحديد لون خلفية نصف الدائرة
    final Color menuBgColor = isDark ? Theme.of(context).cardColor : Colors.white;
    // تحديد لون نصوص الأزرار
    final Color itemTextColor = isDark ? Colors.white : Colors.black87;
    // تحديد لون الخطوط الفاصلة
    final Color separatorColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

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
              if (_animationController.value == 0.0) {
                return const SizedBox.shrink();
              }

              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // 1. الطبقة الشفافة السوداء (تظهر تدريجياً)
                  GestureDetector(
                    onTap: _toggleMenu,
                    child: Opacity(
                      opacity: _animationController.value,
                      child: Container(color: Colors.black.withAlpha(125)), // 125 تعادل 0.5 opacity تقريباً
                    ),
                  ),

                  // 2. القائمة المنبثقة (نصف الدائرة تُرسم تدريجياً)
                  Positioned(
                    bottom: 45,
                    child: CustomPaint(
                      size: const Size(320, 160),
                      painter: MenuBackgroundPainter(
                        progress: _animationController.value,
                        bgColor: menuBgColor, // 🌟 تمرير لون الخلفية
                        lineColor: separatorColor, // 🌟 تمرير لون الخط الفاصل
                      ),
                      child: SizedBox(
                        width: 320,
                        height: 160,
                        child: Stack(
                          children: [
                            // 🌟 إضافة الأزرار وتمرير لون النص المتجاوب 🌟
                            _buildMenuItem(
                              'الجدول',
                              Icons.calendar_month_outlined,
                              Colors.orange,
                              22.5,
                              0.0, // يبدأ فوراً
                              0.4, // ينتهي عند 40% من وقت الحركة
                              itemTextColor,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const TeacherScheduleScreen(),
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
                              itemTextColor,
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
                              itemTextColor,
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
                              itemTextColor,
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

          // 3. الزر الأصفر المركزي (الأساسي) - مرفوع لـ 50 مثل الطالب
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

  // 🌟 دالة بناء العناصر مع دعم لون النص المتجاوب 🌟
  Widget _buildMenuItem(
    String title,
    IconData icon,
    Color color,
    double angleInDegrees,
    double startAnim,
    double endAnim,
    Color textColor, // 🌟 المعامل الجديد للون النص
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
            _toggleMenu(); // يغلق القائمة أولاً
            onTapAction(); // ينفذ الانتقال للشاشة
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
                    color: textColor, // 🌟 تطبيق لون النص المتجاوب
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
  final double progress; // قيمة الحركة
  final Color bgColor;   // 🌟 لون الخلفية الذكي
  final Color lineColor; // 🌟 لون الخط الذكي

  MenuBackgroundPainter({
    required this.progress,
    required this.bgColor,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint fillPaint = Paint()
      ..color = bgColor // 🌟 استخدام لون الخلفية المتجاوب
      ..style = PaintingStyle.fill;

    // رسم نصف الدائرة بشكل تدريجي من اليمين إلى اليسار
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

    // 🌟 استخدام withAlpha بدلاً من withOpacity لتجنب التحذيرات
    int alphaValue = (255 * progress).toInt();
    Paint linePaintPaint = Paint()
      ..color = lineColor.withAlpha(alphaValue) // شفافة في البداية وتوضح تدريجياً
      ..strokeWidth = 1.5;

    Offset center = Offset(size.width / 2, size.height);
    List<double> angles = [math.pi / 4, math.pi / 2, 3 * math.pi / 4];

    for (double angle in angles) {
      // لا نرسم الخط الفاصل إلا إذا وصلت الدائرة إليه
      if (math.pi * progress >= angle) {
        double dx = center.dx + size.height * math.cos(angle);
        double dy = center.dy - size.height * math.sin(angle);
        canvas.drawLine(center, Offset(dx, dy), linePaintPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MenuBackgroundPainter oldDelegate) {
    // يجب إعادة الرسم في كل إطار من الحركة أو عند تغير الثيم
    return oldDelegate.progress != progress ||
           oldDelegate.bgColor != bgColor ||
           oldDelegate.lineColor != lineColor;
  }
}