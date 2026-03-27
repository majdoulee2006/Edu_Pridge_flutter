import 'package:flutter/material.dart';
// 🌟 استدعي مسار شاشة تسجيل الدخول تبعتك هون (عدلي المسار حسب مشروعك) 🌟
import 'package:edu_pridge_flutter/screens/auth/login_screen.dart';

// 🌟 كلاس لإدارة الإعدادات العامة على مستوى التطبيق كله 🌟
class AppSettings {
  static ValueNotifier<bool> isDarkMode = ValueNotifier(false);
  static ValueNotifier<double> fontSize = ValueNotifier(
    1.0,
  ); // 1.0 هو الحجم الطبيعي
}

class SettingsScreen extends StatefulWidget {
  // 🌟 متغيرات لتمرير بيانات الأكتور (طالب، مدرس، إلخ) 🌟
  final String userName;
  final String userRole;
  final String profileImageUrl;
  final VoidCallback? onProfileTap;

  const SettingsScreen({
    super.key,
    // قيم افتراضية عشان ما يضرب الكود القديم عند الاستدعاء
    this.userName = "أ. أحمد محمد",
    this.userRole = "عضو هيئة تدريس",
    this.profileImageUrl = 'https://via.placeholder.com/150',
    this.onProfileTap,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isNotificationsEnabled = true;
  bool _isSoundsEnabled = true;
  bool _isVibrationEnabled = false;

  @override
  Widget build(BuildContext context) {
    // 🌟 نستخدم ValueListenableBuilder ليتحدث المظهر فوراً عند التغيير 🌟
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.isDarkMode,
      builder: (context, isDark, child) {
        return ValueListenableBuilder<double>(
          valueListenable: AppSettings.fontSize,
          builder: (context, fontScale, child) {
            // 🌟 تعريف الألوان بناءً على الوضع (فاتح / داكن) 🌟
            final bgColor = isDark
                ? const Color(0xFF121212)
                : const Color(0xFFFBFBF9);
            final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
            final textColor = isDark ? Colors.white : Colors.black;
            final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey;

            // 🌟 تطبيق تغيير حجم الخط على هذه الشاشة 🌟
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(fontScale)),
              child: Scaffold(
                backgroundColor: bgColor,
                appBar: AppBar(
                  backgroundColor: cardColor,
                  elevation: 0,
                  title: Text(
                    "الإعدادات",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                body: Directionality(
                  textDirection: TextDirection.rtl,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // كرت البروفايل العلوي (صار تفاعلي وديناميكي)
                        _buildProfileCard(cardColor, textColor, subtitleColor),
                        const SizedBox(height: 25),

                        _buildSectionTitle("المظهر", subtitleColor),
                        _buildFontSizeSlider(cardColor, textColor),
                        _buildSwitchTile(
                          Icons.dark_mode_outlined,
                          "الوضع الداكن",
                          isDark,
                          (val) => AppSettings.isDarkMode.value =
                              val, // 🌟 يغير الثيم فوراً
                          cardColor,
                          textColor,
                        ),

                        const SizedBox(height: 25),
                        _buildSectionTitle("اللغة", subtitleColor),
                        _buildLanguageTile(cardColor, textColor),

                        const SizedBox(height: 25),
                        _buildSectionTitle("الإشعارات", subtitleColor),
                        _buildSwitchTile(
                          Icons.notifications_none_outlined,
                          "تفعيل الإشعارات",
                          _isNotificationsEnabled,
                          (val) =>
                              setState(() => _isNotificationsEnabled = val),
                          cardColor,
                          textColor,
                        ),
                        _buildSwitchTile(
                          Icons.volume_up_outlined,
                          "الأصوات",
                          _isSoundsEnabled,
                          (val) => setState(() => _isSoundsEnabled = val),
                          cardColor,
                          textColor,
                        ),
                        _buildSwitchTile(
                          Icons.vibration_outlined,
                          "الاهتزاز",
                          _isVibrationEnabled,
                          (val) => setState(() => _isVibrationEnabled = val),
                          cardColor,
                          textColor,
                        ),

                        const SizedBox(height: 40),

                        // قسم شعار التطبيق والإصدار
                        _buildAppInfoSection(textColor, subtitleColor),

                        const SizedBox(height: 30),

                        // زر تسجيل الخروج
                        _buildLogoutButton(context), // ✅ مررنا الـ context هنا
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🌟 الكرت صار ياخد بياناته من الـ Widget وبيضغط لحتى يروح للبروفايل 🌟
  Widget _buildProfileCard(
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    return InkWell(
      onTap: widget.onProfileTap, // الانتقال للبروفايل
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(widget.profileImageUrl),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.userRole,
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeSlider(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.text_fields, color: textColor),
              const SizedBox(width: 10),
              Text(
                "حجم الخط",
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          Slider(
            value: AppSettings.fontSize.value,
            min: 0.8, // أصغر خط
            max: 1.2, // أكبر خط
            divisions: 2, // 3 حالات: صغير (0.8)، متوسط (1.0)، كبير (1.2)
            activeColor: const Color(0xFFEFFF00),
            inactiveColor: Colors.grey[300],
            onChanged: (val) {
              AppSettings.fontSize.value = val; // 🌟 يغير حجم الخط فوراً
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("صغير", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text("متوسط", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text("كبير", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    bool value,
    Function(bool) onChanged,
    Color cardColor,
    Color textColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        leading: Icon(icon, color: textColor),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        trailing: Switch(
          value: value,
          activeColor: Colors.black,
          activeTrackColor: const Color(0xFFEFFF00),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLanguageTile(Color cardColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        leading: Icon(Icons.language, color: textColor),
        title: Text(
          "لغة التطبيق",
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "عربي",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoSection(Color textColor, Color subtitleColor) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFFF00),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.school, size: 40, color: Colors.black),
          ),
          const SizedBox(height: 15),
          Text(
            "Edu-Bridge",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "التطبيق الرسمي لإدارة شؤون الطلاب\nوالمحاضرات والواجبات.",
            textAlign: TextAlign.center,
            style: TextStyle(color: subtitleColor, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Version 1.0.2",
              style: TextStyle(
                color: subtitleColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ زر تسجيل الخروج مع نافذة التأكيد (Confirmation Dialog)
  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () {
        // 🌟 إظهار نافذة التأكيد قبل تسجيل الخروج 🌟
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Directionality(
              textDirection:
                  TextDirection.rtl, // لضمان دعم اللغة العربية في النافذة
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 10),
                    Text(
                      "تسجيل الخروج",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                content: const Text(
                  "هل أنت متأكد أنك تريد تسجيل الخروج من الحساب؟",
                  style: TextStyle(fontSize: 15),
                ),
                actions: [
                  // خيار (لا)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // إغلاق النافذة فقط
                    },
                    child: const Text(
                      "لا، تراجع",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // خيار (نعم)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      // 1. أولاً بنغلق النافذة المنبثقة
                      Navigator.pop(context);

                      // 2. بنمسح كل الواجهات وبننقله لواجهة تسجيل الدخول
                      // ⚠️ شيلي الـ التعليقات (/* و */) وفعلي الكود تحت بعد ما تظبطي مسار صفحة الدخول فوق
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ), // تأكدي من اسم الواجهة هون
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: const Text(
                      "نعم، خروج",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE), // لون أحمر فاتح جداً خلف الزر
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10),
            Text(
              "تسجيل الخروج",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 10),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: subtitleColor),
      ),
    );
  }
}
