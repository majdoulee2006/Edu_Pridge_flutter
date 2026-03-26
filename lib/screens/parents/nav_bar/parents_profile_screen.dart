import 'package:flutter/material.dart';

// مسارات واجهات التعديل المشتركة
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_email_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_phone_screen.dart';
// ✅ تم استدعاء واجهة تغيير كلمة المرور
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_password_screen.dart';

// مسارات واجهات ولي الأمر
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_messages_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_notifications_screen.dart';

// مسارات الودجات والمصادقة
import '../../../widgets/parents_center_icon.dart';

class ParentsProfileScreen extends StatelessWidget {
  const ParentsProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr, // التزام كامل باليمين لليسار
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFDFD),
        appBar: _buildAppBar(context),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 30),

              _buildSectionTitle("معلومات التواصل"),
              _buildInfoCard([
                _buildClickableRow(
                  "رقم الهاتف",
                  "4567 123 050",
                  Icons.phone_android_rounded,
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditPhoneScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 70),
                _buildClickableRow(
                  "البريد الإلكتروني",
                  "ahmed.ali@institute.edu",
                  Icons.alternate_email_rounded,
                  Colors.blue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditEmailScreen(),
                      ),
                    );
                  },
                ),
              ]),

              const SizedBox(height: 25),
              _buildSectionTitle("البيانات الأكاديمية"),
              _buildInfoCard([
                _buildStaticRow(
                  "القسم",
                  "هندسة الحاسوب",
                  Icons.account_balance_rounded,
                  Colors.purple,
                ),
                const Divider(height: 1, indent: 70),
                _buildStaticRow(
                  "السنة الدراسية / الفرع",
                  "السنة الثالثة",
                  Icons.auto_awesome_mosaic_rounded,
                  Colors.orange,
                ),
              ]),

              const SizedBox(height: 25),
              _buildSectionTitle("تفاصيل شخصية"),
              _buildInfoCard([
                _buildClickableRow(
                  "تاريخ الميلاد",
                  "15 مايو 2002",
                  Icons.cake_rounded,
                  Colors.pink,
                  () {
                    print("تعديل التاريخ");
                  },
                ),
                const Divider(height: 1, indent: 70),
                _buildStaticRow(
                  "الجنس",
                  "ذكر",
                  Icons.wc_rounded,
                  Colors.indigo,
                ),
                const Divider(height: 1, indent: 70),
                _buildStaticRow(
                  "الأبناء",
                  "2 - أحمد، سارة",
                  Icons.family_restroom_rounded,
                  Colors.teal,
                ),
              ]),

              const SizedBox(height: 25),
              _buildSectionTitle("الأمان والإعدادات"),
              _buildClickableSettingCard(
                "تغيير كلمة المرور",
                Icons.lock_reset_rounded,
                Colors.redAccent,
                () {
                  // ✅ تم ربط الزر هنا لينقلنا لواجهة تغيير كلمة السر اللي صممناها
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditPasswordScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),

        floatingActionButton: const Parents_Center_Icon(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  // --- الهيدر العلوي ---
  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomLeft,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEFFF00), width: 3),
              ),
              child: const CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(
                  'https://via.placeholder.com/150',
                ),
              ),
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFEFFF00),
              child: IconButton(
                icon: const Icon(
                  Icons.camera_alt,
                  size: 18,
                  color: Colors.black,
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        const Text(
          "أحمد محمد علي",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const Text(
          "ولي أمر الطالب",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  // --- صف تفاعلي قابل للضغط (تعديل) ---
  Widget _buildClickableRow(
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 22,
              color: color.withOpacity(0.6),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 15),
            _buildColoredIcon(icon, color),
          ],
        ),
      ),
    );
  }

  // --- صف ثابت (للمعلومات المحمية) ---
  Widget _buildStaticRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: Colors.black12,
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),
          _buildColoredIcon(icon, color),
        ],
      ),
    );
  }

  // --- كرت الإعدادات القابل للضغط ---
  Widget _buildClickableSettingCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: color),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(width: 15),
            _buildColoredIcon(icon, color),
          ],
        ),
      ),
    );
  }

  // --- ويدجت الأيقونة الملونة ---
  Widget _buildColoredIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 22, color: color),
    );
  }

  // --- عناصر المساعدة ---
  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 10, bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15),
        ],
        border: Border.all(color: Colors.grey.shade50),
      ),
      child: Column(children: children),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        "الملف الشخصي",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      height: 70,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(
              context,
              Icons.home_outlined,
              "الرئيسية",
              false,
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ParentsHomeScreen(),
                ),
              ),
            ),
            _navItem(
              context,
              Icons.person_outline,
              "الملف",
              true,
              onTap: () {},
            ), // خليت أيقونة الملف نشطة
            const SizedBox(width: 40),
            _navItem(
              context,
              Icons.notifications_none,
              "الإشعارات",
              false,
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ParentsNotificationsScreen(),
                ),
              ),
            ),
            _navItem(
              context,
              Icons.chat_bubble_outline,
              "الرسائل",
              false,
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ParentsMessagesScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    String label,
    bool active, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? const Color(0xFFEFFF00) : Colors.grey),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: active ? const Color(0xFFEFFF00) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
