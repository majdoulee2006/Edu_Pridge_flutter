import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);
  }

  void _toggle() => setState(() {
    isOpened = !isOpened;
    isOpened ? _controller.forward() : _controller.reverse();
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // 1. التغبيش الخلفي
        if (isOpened)
          GestureDetector(
            onTap: _toggle,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(width: MediaQuery.of(context).size.width, height: MediaQuery.of(context).size.height, color: Colors.transparent),
            ),
          ),

        // 2. القوس الأبيض (نصف دائرة فقط)
        Positioned(
          bottom: 0, // يبدأ من مستوى الزر
          child: ScaleTransition(
            scale: _animation,
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 320,
              height: 160, // نصف ارتفاع القطر ليظهر كنصف دائرة
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(160)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
            ),
          ),
        ),

        // 3. الأيقونات (توزيع مروحي فوق الزر)
        _buildItem(Icons.play_circle_fill, "المحاضرات", 120, 160, Colors.purple),
        _buildItem(Icons.assignment, "الواجبات", 120, 115, Colors.blue),
        _buildItem(Icons.calendar_month, "الجدول", 120, 65, Colors.orange),
        _buildItem(Icons.how_to_reg, "الحضور", 120, 20, Colors.green),

        // 4. الزر الأصفر مع أيقونة المربعات الأربعة
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: const BoxDecoration(color: Color(0xFFEFFF00), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)]),
            child: Icon(isOpened ? Icons.close : Icons.grid_view_rounded, color: Colors.black, size: 30),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(IconData icon, String label, double radius, double angleDegrees, Color color) {
    final double angle = angleDegrees * math.pi / 180;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        double x = _animation.value * radius * math.cos(angle);
        double y = _animation.value * radius * math.sin(angle);
        return Positioned(
          bottom: 40 + y,
          left: (MediaQuery.of(context).size.width / 2) - 25 - x,
          child: Opacity(
            opacity: _controller.value,
            child: Column(
              children: [
                Icon(icon, color: color, size: 28),
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
}