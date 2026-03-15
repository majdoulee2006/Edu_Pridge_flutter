import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

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
    // تم تفعيل الأنيميشن هنا ليتجنب الخطأ
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
    double dialWidth = MediaQuery.of(context).size.width * 0.95;
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

        if (isOpened) ...[
          _buildItem(Icons.how_to_reg, "الحضور", dialRadius * 0.72, 157.5, Colors.green),
          _buildItem(Icons.play_circle_fill, "المحاضرات", dialRadius * 0.72, 112.5, Colors.purple),
          _buildItem(Icons.assignment, "الواجبات", dialRadius * 0.72, 67.5, Colors.blue),
          _buildItem(Icons.calendar_month, "الجدول", dialRadius * 0.72, 22.5, Colors.orange),
        ],

        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 70,
            height: 70,
            margin: const EdgeInsets.only(bottom: 5),
            decoration: const BoxDecoration(
              color: Color(0xFFEFFF00),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Icon(
              isOpened ? Icons.close : Icons.grid_view_rounded,
              color: Colors.black,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(IconData icon, String label, double radius, double angleDeg, Color color) {
    double rad = (180 - angleDeg) * math.pi / 180;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        double x = math.cos(rad) * radius * _animation.value;
        double y = math.sin(rad) * radius * _animation.value;

        return Positioned(
          bottom: 45 + y,
          left: (MediaQuery.of(context).size.width / 2) - 30 - x,
          child: Opacity(
            opacity: _controller.value,
            child: SizedBox(
              width: 60,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 30),
                  const SizedBox(height: 2),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.2)),
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
    final paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height)
      ..arcTo(Rect.fromLTWH(0, 0, size.width, size.height * 2), math.pi, math.pi, false)
      ..close();
    canvas.drawShadow(path, Colors.black26, 10, false);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}