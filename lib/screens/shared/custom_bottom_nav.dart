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
    // 🌟 جلب حالة الثيم والألوان 🌟
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final Color activeColor = isDark ? const Color(0xFFEFFF00) : Colors.black;
    final Color inactiveColor = isDark
        ? Colors.grey.shade500
        : Colors.grey.shade400;

    return Positioned.fill(
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. الشريط السفلي العائم
          Positioned(
            bottom: 20,
            left: 18,
            right: 18,
            child: CustomPaint(
              // 🌟 تمرير اللون والوضع للرسام 🌟
              painter: NotchedBarPainter(bgColor: bgColor, isDark: isDark),
              child: SizedBox(
                height: 60,
                // 🌟 إضافة Directionality لضمان ترتيب الأيقونات من اليمين لليسار 🌟
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        currentIndex == 0 ? Icons.home : Icons.home_outlined,
                        'الرئيسية',
                        0,
                        onHomeTap,
                        activeColor,
                        inactiveColor,
                      ),
                      _buildNavItem(
                        currentIndex == 1 ? Icons.person : Icons.person_outline,
                        'الملف',
                        1,
                        onProfileTap,
                        activeColor,
                        inactiveColor,
                      ),

                      const SizedBox(width: 65), // مساحة للزر والحفرة

                      _buildNavItem(
                        currentIndex == 2
                            ? Icons.notifications
                            : Icons.notifications_none,
                        'الإشعارات',
                        2,
                        onNotificationsTap,
                        activeColor,
                        inactiveColor,
                      ),
                      _buildNavItem(
                        currentIndex == 3
                            ? Icons.chat_bubble
                            : Icons.chat_bubble_outline,
                        'الرسائل',
                        3,
                        onMessagesTap,
                        activeColor,
                        inactiveColor,
                      ),
                    ],
                  ),
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

  // 🌟 تعديل الـ NavItem ليقبل الألوان الذكية 🌟
  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    VoidCallback? onTap,
    Color activeColor,
    Color inactiveColor,
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
            Icon(icon, color: isActive ? activeColor : inactiveColor, size: 26),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? activeColor : inactiveColor,
                fontFamily: 'Tajawal', // دعم الخط
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// --- الرسام المخصص لقص الشريط ---
// ==========================================
class NotchedBarPainter extends CustomPainter {
  final Color bgColor;
  final bool isDark;

  // 🌟 استقبال المتغيرات 🌟
  NotchedBarPainter({required this.bgColor, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const double radius = 30.0;
    const double notchRadius = 36.0;
    final double center = size.width / 2;

    path.moveTo(radius, 0);
    path.lineTo(center - notchRadius, 0);

    // رسم الحفرة
    path.arcToPoint(
      Offset(center + notchRadius, 0),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );

    path.lineTo(size.width - radius, 0);
    path.arcToPoint(
      Offset(size.width, radius),
      radius: const Radius.circular(radius),
    );
    path.lineTo(size.width, size.height - radius);
    path.arcToPoint(
      Offset(size.width - radius, size.height),
      radius: const Radius.circular(radius),
    );
    path.lineTo(radius, size.height);
    path.arcToPoint(
      Offset(0, size.height - radius),
      radius: const Radius.circular(radius),
    );
    path.lineTo(0, radius);
    path.arcToPoint(
      const Offset(radius, 0),
      radius: const Radius.circular(radius),
    );
    path.close();

    // 🌟 ضبط الظل ليتناسب مع الوضع الليلي والنهاري 🌟
    if (isDark) {
      canvas.drawPath(
        path.shift(const Offset(0, 5)),
        Paint()
          ..color = Colors.black
              .withAlpha(100) // ظل أغمق للوضع الليلي
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
      );
    } else {
      canvas.drawPath(
        path.shift(const Offset(0, -3)),
        Paint()
          ..color = Colors.black
              .withAlpha(15) // ظل خفيف للوضع النهاري (بدل withOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // 🌟 رسم الشريط باللون المتجاوب 🌟
    canvas.drawPath(path, Paint()..color = bgColor);
  }

  @override
  // 🌟 إجبار الرسام على إعادة الرسم عند تغير الثيم 🌟
  bool shouldRepaint(covariant NotchedBarPainter oldDelegate) {
    return oldDelegate.bgColor != bgColor || oldDelegate.isDark != isDark;
  }
}
