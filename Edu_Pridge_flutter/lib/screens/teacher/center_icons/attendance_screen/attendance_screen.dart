import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:flutter/material.dart';

// 🌟 استدعاء المكونات الموحدة 🌟
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../../../widgets/teacher_speed_dial.dart';

// استدعاء الشاشات للتنقل
import '../../messages_screen.dart';
import '../../notifications_screen.dart';
import '../../profile_screen.dart';
import '../../teacher_home.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // الألوان
    const Color primaryYellow = Color(0xFFEFFF00);

    // جلب ألوان الثيم
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.settings_outlined, color: textColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          title: Text(
            "تسجيل الحضور والغياب",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: textColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: Stack(
          children: [
            // 1. المحتوى الأساسي
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// كارد إعدادات الجلسة
                  _buildSessionSettingsCard(
                    context,
                    cardColor,
                    textColor,
                    primaryYellow,
                    isDark,
                  ),

                  const SizedBox(height: 25),

                  /// فاصل العنوان
                  _buildDividerWithText("الرمز النشط", textColor),

                  const SizedBox(height: 15),

                  /// كارد الـ QR والحالة
                  _buildQRCodeCard(
                    context,
                    cardColor,
                    textColor,
                    primaryYellow,
                    isDark,
                  ),

                  const SizedBox(height: 120), // مساحة للشريط السفلي
                ],
              ),
            ),

            // 2. الشريط السفلي الموحد
            Align(
              alignment: Alignment.bottomCenter,
              child: CustomBottomNav(
                currentIndex: -1, // شاشة فرعية
                centerButton: const CustomSpeedDialEduBridge(),
                onHomeTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TeacherHomeScreen(),
                  ),
                ),
                onProfileTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                ),
                onNotificationsTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                ),
                onMessagesTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MessagesScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- مكونات واجهة الحضور ---

  Widget _buildSessionSettingsCard(
    BuildContext context,
    Color cardColor,
    Color textColor,
    Color primaryYellow,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: primaryYellow, size: 20),
              const SizedBox(width: 8),
              const Text(
                "إعدادات الجلسة",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFieldLabel("المادة الدراسية", textColor),
          _buildModernDropdown(context, "اختر المادة", isDark),
          const SizedBox(height: 16),
          _buildFieldLabel("القاعة / الصف", textColor),
          _buildModernDropdown(context, "اختر القاعة", isDark),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_circle_fill, color: Colors.black),
              label: const Text(
                "بدء الجلسة الآن",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryYellow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeCard(
    BuildContext context,
    Color cardColor,
    Color textColor,
    Color primaryYellow,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(backgroundColor: Colors.green, radius: 4),
                SizedBox(width: 8),
                Text(
                  "مباشر - المرحلة 1 من 2",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Text(
            "رمز الحضور السريع",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "اطلب من الطلاب مسح الرمز أدناه لتسجيل الحضور",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 25),

          // إطار الـ QR الملون
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryYellow, width: 2),
            ),
            child: Image.asset(
              'assets/images/qr.png', // تأكدي من وجود الصورة في المسار
              height: 180,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.qr_code_2,
                size: 180,
                color: textColor.withOpacity(0.2),
              ),
            ),
          ),

          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryYellow),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: () {},
              child: Text(
                "المرحلة التالية (الغياب)",
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 15),
          TextButton(
            onPressed: () {},
            child: const Text(
              "إنهاء الجلسة وإغلاق السجل",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ويجيتات مساعدة
  Widget _buildFieldLabel(String label, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildModernDropdown(BuildContext context, String hint, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xfff2f2f2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton(
          isExpanded: true,
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          items: const [],
          onChanged: (val) {},
        ),
      ),
    );
  }

  Widget _buildDividerWithText(String text, Color textColor) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            text,
            style: TextStyle(
              color: textColor.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
