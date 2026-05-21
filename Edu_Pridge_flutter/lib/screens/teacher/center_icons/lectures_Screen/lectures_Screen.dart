import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:flutter/material.dart';

// 🌟 استدعاء الشريط الموحد وزر المعلم 🌟
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../../../widgets/teacher_speed_dial.dart';

// استدعاء الشاشات للتنقل من الشريط السفلي
import '../../messages_screen.dart';
import '../../notifications_screen.dart';
import '../../profile_screen.dart';
import '../../teacher_home.dart';

class LecturesScreen extends StatelessWidget {
  const LecturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // الألوان الثابتة المستخدمة في التصميم
    const Color primaryYellow = Color(0xFFEFFF00);

    // 🌟 جلب ألوان الثيم للـ Dark Mode 🌟
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'إضافة محاضرة',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.settings_outlined, color: textColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),

        body: Stack(
          children: [
            // 1. محتوى الشاشة الأساسي
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),

                  // عنوان المحاضرة
                  _buildLabel('عنوان المحاضرة', textColor),
                  // ✅ تم تمرير context هنا
                  _buildTextField(
                    context: context,
                    hint: 'أدخل عنوان المحاضرة هنا',
                  ),

                  const SizedBox(height: 20),

                  // المادة والصف في سطر واحد
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('المادة', textColor),
                            // ✅ تم تمرير context هنا
                            _buildDropdownField(
                              context: context,
                              hint: 'اختر المادة',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('الصف', textColor),
                            // ✅ تم تمرير context هنا
                            _buildDropdownField(
                              context: context,
                              hint: 'اختر الصف',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // زر إرفاق ملف المحاضرة
                  Container(
                    width: double.infinity,
                    height: 65,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: primaryYellow.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryYellow.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.attach_file,
                            color: textColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'إرفاق ملف المحاضرة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // زر إضافة محاضرة الكبير
                  GestureDetector(
                    onTap: () {
                      // منطق الإضافة
                    },
                    child: Container(
                      width: double.infinity,
                      height: 65,
                      decoration: BoxDecoration(
                        color: primaryYellow,
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: primaryYellow.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          // ✅ تم إزالة const من هنا لحل مشكلة تعارض الأيقونات
                          children: [
                            const Icon(
                              Icons.add_circle,
                              color: Colors.black,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'إضافة المحاضرة',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),

            // 2. الشريط السفلي الموحد
            Align(
              alignment: Alignment.bottomCenter,
              child: CustomBottomNav(
                currentIndex: -1,
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

  Widget _buildLabel(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required String hint,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFEEEEEE),
        ),
      ),
      child: TextField(
        textAlign: TextAlign.center,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBCBCBC), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required BuildContext context,
    required String hint,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFEEEEEE),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(
            hint,
            style: const TextStyle(color: Color(0xFFBCBCBC), fontSize: 14),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF777777)),
          items: const [],
          dropdownColor: cardColor,
          onChanged: (value) {},
        ),
      ),
    );
  }
}
