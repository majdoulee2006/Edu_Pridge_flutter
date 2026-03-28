import 'package:edu_pridge_flutter/screens/parents/center_icons/permissions_screen/permissions_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/center_icons/reports_screen/reports_screen.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../screens/parents/center_icons/parents_assignments_screen/parents_assignment_screen.dart';
import '../screens/parents/center_icons/performance_screen/performance_screen.dart';

class Parents_Center_Icon extends StatefulWidget {
  const Parents_Center_Icon({super.key});

  @override
  State<Parents_Center_Icon> createState() => _Parents_Center_IconState();
}

class _Parents_Center_IconState extends State<Parents_Center_Icon>
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
    // 🌟 التحقق من الثيم لتحديد الألوان بدقة 🌟
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // تحديد لون خلفية المروحة
    final Color menuBgColor = isDark
        ? Theme.of(context).cardColor
        : Colors.white;
    // تحديد لون النصوص
    final Color itemTextColor = isDark ? Colors.white : Colors.black87;
    // تحديد لون الخطوط الفاصلة
    final Color separatorColor = isDark
        ? Colors.grey.shade800
        : Colors.grey.shade300;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 🌟 نستخدم AnimatedBuilder لتحديث الحركة 60 مرة بالثانية 🌟
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
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
                      child: Container(
                        color: Colors.black.withAlpha(125),
                      ), // 125 تعادل 0.5 تقريباً
                    ),
                  ),

                  // 2. القائمة المنبثقة (نصف الدائرة تُرسم تدريجياً وتدعم الثيم)
                  Positioned(
                    bottom: 45,
                    child: CustomPaint(
                      size: const Size(320, 160),
                      painter: MenuBackgroundPainter(
                        progress: _animationController.value,
                        bgColor: menuBgColor, // 🌟 نمرر اللون الذكي للخلفية
                        lineColor:
                            separatorColor, // 🌟 نمرر لون الخط الفاصل الذكي
                      ),
                      child: SizedBox(
                        width: 320,
                        height: 160,
                        child: Stack(
                          children: [
                            // 🌟 إضافة أزرار الأهل مع تمرير لون النص المتجاوب 🌟
                            _buildMenuItem(
                              'تقارير',
                              Icons.description_outlined,
                              Colors.greenAccent,
                              22.5,
                              0.0, // يبدأ فوراً
                              0.4, // ينتهي عند 40% من وقت الحركة
                              itemTextColor,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ReportsScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              'أذونات',
                              Icons.verified_outlined,
                              Colors.purpleAccent,
                              67.5,
                              0.2, // يبدأ متأخراً قليلاً
                              0.6,
                              itemTextColor,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PermissionsScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              'واجبات',
                              Icons.assignment_turned_in_outlined,
                              Colors.blueAccent,
                              112.5,
                              0.4,
                              0.8,
                              itemTextColor,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ParentsAssignmentsScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              'أداء',
                              Icons.trending_up_rounded,
                              Colors.orangeAccent,
                              157.5,
                              0.6, // يبدأ أخيراً
                              1.0,
                              itemTextColor,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PerformanceScreen(),
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
            bottom: 50, // 🌟 مرفوع ليتناسب مع الشريط السفلي الجديد
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
                  color:
                      Colors.black, // الأيقونة دائماً سوداء لتباينها مع الأصفر
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 دالة بناء العناصر مع الحركة التدريجية وتجاوب الألوان 🌟
  Widget _buildMenuItem(
    String title,
    IconData icon,
    Color color,
    double angleInDegrees,
    double startAnim,
    double endAnim,
    Color textColor, // 🌟 لون النص الذكي
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
            _toggleMenu(); // إغلاق القائمة أولاً
            onTapAction(); // تنفيذ عملية النقل للشاشة المطلوبة
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
                    color: textColor, // 🌟 يتجاوب مع الـ Dark Mode
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
  final Color bgColor; // 🌟 لون الخلفية الذكي
  final Color lineColor; // 🌟 لون الخط الذكي

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

    // رسم نصف الدائرة بشكل تدريجي من اليمين إلى اليسار
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height),
        radius: size.height,
      ),
      0.0, // نقطة البداية
      -math.pi * progress, // مقدار الالتفاف
      true,
      fillPaint,
    );

    // 🌟 حساب قيمة ألفا للخطوط بدلاً من Opacity لتجنب التحذيرات 🌟
    int alphaValue = (255 * 0.2 * progress).toInt();
    Paint linePaintPaint = Paint()
      ..color = lineColor
          .withAlpha(alphaValue) // خطوط فاصلة أنيقة وذكية
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
    // يجب إعادة الرسم في كل إطار من الحركة أو عند تغير اللون
    return oldDelegate.progress != progress ||
        oldDelegate.bgColor != bgColor ||
        oldDelegate.lineColor != lineColor;
  }
}
