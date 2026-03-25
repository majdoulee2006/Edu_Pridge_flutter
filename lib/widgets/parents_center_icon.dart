import 'package:edu_pridge_flutter/screens/parents/center_icons/permissions_screen/permissions_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/center_icons/reports_screen/reports_screen.dart';
import 'package:edu_pridge_flutter/widgets/teacher_speed_dial.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

import '../screens/parents/center_icons/parents_assignments_screen/parents_assignment_screen.dart';
import '../screens/parents/center_icons/performance_screen/performance_screen.dart';

class Parents_Center_Icon extends StatefulWidget {
  const Parents_Center_Icon({super.key});

  @override
  State<Parents_Center_Icon> createState() => _Parents_Center_IconState();
}

class _Parents_Center_IconState extends State<Parents_Center_Icon> with SingleTickerProviderStateMixin {
  bool isOpened = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
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
        // خلفية تغبيش خفيفة
        if (isOpened)
          GestureDetector(
            onTap: _toggle,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(color: Colors.transparent),
            ),
          ),

        // القوس الأبيض الخلفي
        Positioned(
          bottom: 35, // ضبط الارتفاع ليتناسب مع Notch الشريط السفلي
          child: ScaleTransition(
            scale: _animation,
            alignment: Alignment.bottomCenter,
            child: CustomPaint(
              size: const Size(320, 160),
              painter: HalfCirclePainter(),
            ),
          ),
        ),

        // الأيقونات موزعة بدقة لتنصف الأقسام
        _buildItem(Icons.trending_up_rounded, "أداء",  135, 170, Colors.orangeAccent, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PerformanceScreen()));

        }),
        _buildItem(Icons.assignment_turned_in_outlined, "واجبات ومشاريع",  115, 112, Colors.blueAccent, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ParentsAssignmentsScreen()));

        }),
        _buildItem(Icons.verified_outlined, "أذونات", 115, 65, Colors.purpleAccent, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PermissionsScreen()));

        }),
        _buildItem(Icons.description_outlined, "تقارير",135, 12, Colors.greenAccent, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen()));

        }),



// الزر الأصفر المركزي - ثابت في مكانه تماماً
     GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer( // استخدام AnimatedContainer يعطي سلاسة أكبر عند التغيير
              duration: const Duration(milliseconds: 200),
              width: 65,
              height: 65,
              // تم حذف المارجن من هنا لمنع القفزة
              decoration: BoxDecoration(
                color: const Color(0xFFEFFF00),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4)
                  )
                ],
              ),
              child: Icon(
                isOpened ? Icons.close : Icons.grid_view_rounded,
                color: Colors.black,
                size: 30,
                // إضافة مفتاح فريد يضمن عدم تحرك الأيقونة أثناء التبديل
                key: ValueKey<bool>(isOpened),
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
          bottom: 35 + y, // ينطلق من مستوى القوس الأبيض
          left: (MediaQuery.of(context).size.width / 2) - 35 - x,
          child: Opacity(
            opacity: _controller.value,
            child: GestureDetector(
              onTap: () { _toggle(); onTap(); },
              child: SizedBox(
                width: 70,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: color.withOpacity(0.1),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
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