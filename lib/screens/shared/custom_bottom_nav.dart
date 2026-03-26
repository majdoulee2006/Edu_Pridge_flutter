import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Widget centerButton;
  final VoidCallback? onHomeTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onMessagesTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.centerButton,
    this.onHomeTap,
    this.onProfileTap,
    this.onNotificationsTap,
    this.onMessagesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. الشريط السفلي العائم
          Positioned(
            bottom: 20,
            left: 18, // 🌟 تم تقليل الهامش الأيسر ليعرض الشريط 🌟
            right: 18, // 🌟 تم تقليل الهامش الأيمن ليعرض الشريط 🌟
            child: CustomPaint(
              painter: NotchedBarPainter(),
              child: SizedBox(
                height: 60,
                child: Row(
                  // 🌟 استخدمنا spaceEvenly لتتوزع الأيقونات بشكل متساوٍ على العرض الجديد 🌟
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      currentIndex == 0 ? Icons.home : Icons.home_outlined,
                      'الرئيسية',
                      0,
                      onHomeTap,
                    ),
                    _buildNavItem(
                      currentIndex == 1 ? Icons.person : Icons.person_outline,
                      'الملف',
                      1,
                      onProfileTap,
                    ),

                    const SizedBox(width: 65), // مساحة للزر والحفرة

                    _buildNavItem(
                      currentIndex == 2
                          ? Icons.notifications
                          : Icons.notifications_none,
                      'الإشعارات',
                      2,
                      onNotificationsTap,
                    ),
                    _buildNavItem(
                      currentIndex == 3
                          ? Icons.chat_bubble
                          : Icons.chat_bubble_outline,
                      'الرسائل',
                      3,
                      onMessagesTap,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. الزر المركزي (Speed Dial)
          Positioned.fill(child: centerButton),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    VoidCallback? onTap,
  ) {
    bool isActive = currentIndex == index;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent, // مساحة ضغط مريحة
        width: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.black : Colors.grey,
              size: 26, // 🌟 كبرنا الأيقونة نتفة صغيرة لتناسب العرض الجديد 🌟
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// --- الرسام المخصص لقص الشريط الأبيض ---
// ==========================================
class NotchedBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final double radius = 30.0;
    final double notchRadius = 36.0;
    final double center = size.width / 2;

    path.moveTo(radius, 0);
    path.lineTo(center - notchRadius, 0);

    // رسم الحفرة
    path.arcToPoint(
      Offset(center + notchRadius, 0),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    path.lineTo(size.width - radius, 0);
    path.arcToPoint(
      Offset(size.width, radius),
      radius: Radius.circular(radius),
    );
    path.lineTo(size.width, size.height - radius);
    path.arcToPoint(
      Offset(size.width - radius, size.height),
      radius: Radius.circular(radius),
    );
    path.lineTo(radius, size.height);
    path.arcToPoint(
      Offset(0, size.height - radius),
      radius: Radius.circular(radius),
    );
    path.lineTo(0, radius);
    path.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius));
    path.close();

    // ظل خفيف جداً للشريط
    canvas.drawPath(
      path.shift(const Offset(0, -3)),
      Paint()
        ..color = Colors.black.withOpacity(0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
