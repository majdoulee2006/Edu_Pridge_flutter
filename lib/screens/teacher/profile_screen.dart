import 'package:flutter/material.dart';
import 'teacher_home.dart';
import 'notifications_screen.dart';
import 'messages_screen.dart';
// استيراد صفحة الإعدادات من المجلد المشترك
import '../shared/settings_screen.dart';
// 🌟 1. استدعاء الشريط الموحد 🌟
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
// 🌟 2. استدعاء زر المعلم الموحد 🌟
import '../../widgets/teacher_speed_dial.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🌟 جلب ألوان الثيم للـ Dark Mode 🌟
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // تم نقل زر الإعدادات ليكون في الجهة المقابلة للسهم في الـ RTL
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
        title: Text(
          "الملف الشخصي",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // زر الرجوع في التوجيه العربي يكون في الـ leading (جهة اليمين)
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const TeacherHomeScreen(),
              ),
            );
          },
        ),
      ),
      // 🌟 التعديل السحري هنا: استخدمنا Stack داخل الـ body 🌟
      body: Directionality(
        textDirection:
            TextDirection.rtl, // التوجيه العام للصفحة من اليمين لليسار
        child: Stack(
          children: [
            // 1. محتوى الشاشة الأساسي
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildAvatarSection(),
                  const SizedBox(height: 15),
                  Text(
                    "أحمد العبدالله",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Text(
                    "أستاذ مشارك - قسم علوم الحاسب",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 30),
                  _buildSectionTitle("البيانات الشخصية"),
                  _buildInfoTile(
                    context,
                    Icons.phone_outlined,
                    "رقم الهاتف",
                    "4567 123 55 966+",
                    true,
                  ),
                  _buildInfoTile(
                    context,
                    Icons.email_outlined,
                    "البريد الإلكتروني",
                    "ahmed@institute.edu",
                    true,
                  ),
                  const SizedBox(height: 25),
                  _buildSectionTitle("البيانات الأكاديمية"),
                  _buildInfoTile(
                    context,
                    Icons.apartment,
                    "القسم",
                    "كلية علوم الحاسب",
                    false,
                    isLocked: true,
                  ),
                  _buildSpecialTile(
                    context,
                    Icons.menu_book_outlined,
                    "المواد الدراسية",
                    "الفصل الحالي",
                    ["خوارزميات", "هياكل بيانات"],
                  ),
                  const SizedBox(height: 30),
                  _buildChangePasswordButton(context),
                  const SizedBox(
                    height: 120,
                  ), // مساحة إضافية للتمرير فوق البار السفلي
                ],
              ),
            ),

            // 2. الشريط السفلي الموحد (يطفو فوق المحتوى)
            CustomBottomNav(
              currentIndex: 1, // 1 = الملف مفعل
              centerButton:
                  const CustomSpeedDialEduBridge(), // زر المعلم الموحد
              onHomeTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherHomeScreen(),
                ),
              ),
              onProfileTap: () {}, // نحن في البروفايل أصلاً
              onNotificationsTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              ),
              onMessagesTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MessagesScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Stack(
      alignment: Alignment.bottomLeft, // نقل قلم التعديل لجهة اليسار في الـ RTL
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFEFFF00), width: 2),
          ),
          child: const CircleAvatar(radius: 55, backgroundColor: Colors.grey),
        ),
        const CircleAvatar(
          radius: 14,
          backgroundColor: Color(0xFFEFFF00),
          child: Icon(Icons.edit, size: 16, color: Colors.black),
        ),
      ],
    );
  }

  // 🌟 تعديل الـ Widget ليدعم الـ Theme 🌟
  Widget _buildInfoTile(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    bool isEditable, {
    bool isLocked = false,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.black54,
          ), // الأيقونة تبدأ من اليمين
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // المحاذاة لليمين (بداية العمود)
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFFB4B48E)),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isEditable)
            const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFB4B48E)),
          if (isLocked)
            const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  // 🌟 تعديل الـ Widget ليدعم الـ Theme 🌟
  Widget _buildSpecialTile(
    BuildContext context,
    IconData icon,
    String title,
    String subTitle,
    List<String> tags,
  ) {
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // لضمان بقاء المحتوى الداخلي لليمين
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.black54),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB4B48E),
                    ),
                  ),
                  Text(
                    subTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: tags
                .map(
                  (t) => Chip(
                    label: Text(t, style: const TextStyle(fontSize: 11)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // 🌟 تعديل الـ Widget ليدعم الـ Theme 🌟
  Widget _buildChangePasswordButton(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_reset, color: textColor),
          const SizedBox(width: 10),
          Text(
            "تغيير كلمة المرور",
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB4B48E),
          ),
        ),
      ),
    );
  }
}
