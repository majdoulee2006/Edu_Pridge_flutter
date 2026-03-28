import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/widgets/student_speed_dial.dart';

import 'student_home_screen.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Directionality(
        textDirection: TextDirection.rtl, // دعم الواجهة العربية
        child: Scaffold(
          backgroundColor: isDark
              ? Theme.of(context).scaffoldBackgroundColor
              : const Color(0xFFFAFAFA), // متجاوب
          appBar: AppBar(
            backgroundColor: isDark
                ? Theme.of(context).scaffoldBackgroundColor
                : const Color(0xFFFAFAFA),
            elevation: 0,
            // ✅ تم تعديل سهم الرجوع ليؤشر لليمين بشكل صحيح
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentHomeScreen(),
                ),
              ),
            ),
            title: Text(
              'الإشعارات',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            // أيقونة الإعدادات على اليسار
            actions: [
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: isDark ? Colors.white : Colors.black,
                  size: 26,
                ),
                onPressed: () {
                  // ✅ تم تفعيل الربط مع واجهة الإعدادات
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: _buildCustomTabBar(),
            ),
          ),
          body: Stack(
            children: [
              const TabBarView(
                children: [
                  _AcademicNotificationsView(),
                  _AdministrativeNotificationsView(),
                ],
              ),

              // 🌟 استدعاء الشريط الموحد هنا بدلاً من الأكواد الطويلة 🌟
              CustomBottomNav(
                currentIndex: 2, // 2 = الإشعارات مفعّلة
                centerButton: const CustomSpeedDialEduBridge(),
                onHomeTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentHomeScreen(),
                  ),
                ),
                onProfileTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                ),
                onNotificationsTap: () {}, // نحن بالفعل هنا
                onMessagesTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MessagesScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Builder(
      // 🌟 استخدمنا Builder لجلب الثيم بدون تغيير الدالة 🌟
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          height: 50,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withAlpha(20)
                : const Color(0xFFF2F2F2), // متجاوب
            borderRadius: BorderRadius.circular(30),
          ),
          child: TabBar(
            indicator: BoxDecoration(
              color: const Color(0xFFEFFF00), // اللون الأصفر المعتمد
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12), // متجاوب وآمن
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: Colors.black,
            unselectedLabelColor: isDark
                ? Colors.grey.shade400
                : Colors.grey.shade600,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent, // إخفاء الخط السفلي الافتراضي
            tabs: const [
              Tab(text: 'رسائل أكاديمية'),
              Tab(text: 'رسائل إدارية'),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// --- واجهة الرسائل الأكاديمية ---
// ==========================================
class _AcademicNotificationsView extends StatelessWidget {
  const _AcademicNotificationsView();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: 120,
      ), // 🌟 زدنا الـ bottom padding لتجنب الشريط 🌟
      children: [
        _buildDateHeader('اليوم'),
        _buildNotificationCard(
          title: 'تم رفع وظيفة جديدة',
          subtitle:
              'قام الأستاذ أحمد برفع وظيفة جديدة في مادة الرياضيات المتقدمة. يرجى التسليم قبل...',
          time: 'منذ ساعتين',
          // رابط صورة افتراضي للمدربة للتجربة
          avatarUrl:
              'https://img.freepik.com/free-photo/portrait-expressive-young-woman_1258-48167.jpg',
          badgeIcon: Icons.assignment_outlined,
          badgeColor: Colors.blueAccent,
        ),
        _buildNotificationCard(
          title: 'تعيين البرنامج الامتحاني',
          subtitle:
              'تم اعتماد جدول الامتحانات النصفية للفصل الدراسي الحالي. اضغط للتفاصيل.',
          time: 'منذ 5 ساعات',
          icon: Icons.calendar_month_outlined,
          iconColor: Colors.indigo,
          iconBgColor: Colors.indigo.withAlpha(25), // متجاوب وآمن
        ),
        const SizedBox(height: 10),
        _buildDateHeader('أمس'),
        _buildNotificationCard(
          title: 'نتائج المشروع الفصلي',
          subtitle:
              'تم رصد درجات المشروع النهائي لمادة البرمجة ١٠١. يمكنك مراجعة الدرجة الآن.',
          time: 'أمس',
          // رابط صورة افتراضي للمدربة للتجربة
          avatarUrl:
              'https://img.freepik.com/free-photo/young-beautiful-woman-pink-warm-sweater-natural-look-smiling-portrait-isolated-long-hair_285396-896.jpg',
        ),
      ],
    );
  }
}

// ==========================================
// --- واجهة الرسائل الإدارية ---
// ==========================================
class _AdministrativeNotificationsView extends StatelessWidget {
  const _AdministrativeNotificationsView();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: 120,
      ), // 🌟 زدنا الـ bottom padding لتجنب الشريط 🌟
      children: [
        _buildDateHeader('جديد'),
        _buildNotificationCard(
          title: 'تحديد عطلة رسمية',
          subtitle:
              'بمناسبة عيد المعلم، تعلن إدارة المعهد عن تعطيل الدوام الرسمي يوم الخميس القادم.',
          time: 'اليوم',
          icon: Icons.celebration_outlined,
          iconColor: Colors.purple,
          iconBgColor: Colors.purple.withAlpha(20), // متجاوب وآمن
        ),
        _buildNotificationCard(
          title: 'تمديد ساعات الدوام',
          subtitle:
              'تقرر تمديد دوام قسم شؤون الطلاب لاستقبال طلبات التسجيل حتى الساعة الرابعة عصراً.',
          time: 'أمس',
          icon: Icons.access_time_rounded,
          iconColor: Colors.deepOrange,
          iconBgColor: Colors.deepOrange.withAlpha(20), // متجاوب وآمن
        ),
        const SizedBox(height: 10),
        _buildDateHeader('الأسبوع الماضي'),
        _buildNotificationCard(
          title: 'تنبيه اشتراك',
          subtitle:
              'يرجى المبادرة بتسديد القسط الجامعي الثاني قبل نهاية الشهر الحالي لتجنب الغرامات...',
          time: 'الخميس',
          icon: Icons.payments_outlined,
          iconColor: Colors.redAccent,
          iconBgColor: Colors.redAccent.withAlpha(20), // متجاوب وآمن
        ),
      ],
    );
  }
}

// ==========================================
// --- ودجات مساعدة للمكونات ---
// ==========================================

Widget _buildDateHeader(String date) {
  return Builder(
    // 🌟 استخدمنا Builder لجلب الثيم بدون تغيير الدالة 🌟
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Padding(
        padding: const EdgeInsets.only(bottom: 15, right: 5),
        child: Text(
          date,
          style: TextStyle(
            color: isDark
                ? Colors.grey.shade400
                : Colors.grey.shade700, // متجاوب
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );
    },
  );
}

// دالة ذكية تدعم الأيقونات العادية أو الصور الشخصية مع الشارات (Badges)
Widget _buildNotificationCard({
  required String title,
  required String subtitle,
  required String time,
  IconData? icon,
  Color? iconColor,
  Color? iconBgColor,
  String? avatarUrl,
  IconData? badgeIcon,
  Color? badgeColor,
}) {
  return Builder(
    // 🌟 استخدمنا Builder لجلب الثيم بدون تغيير الدالة 🌟
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardColor : Colors.white, // متجاوب
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withAlpha(50)
                  : Colors.black.withAlpha(5), // متجاوب
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الأيقونة أو الصورة الشخصية
            Stack(
              clipBehavior: Clip.none,
              children: [
                if (avatarUrl != null)
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(avatarUrl),
                    backgroundColor: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                  )
                else if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          iconBgColor ??
                          (isDark
                              ? Colors.white.withAlpha(15)
                              : Colors.grey.shade100),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 26),
                  ),

                // الشارة (Badge) الصغيرة التي تظهر فوق الصورة
                if (badgeIcon != null)
                  Positioned(
                    bottom: -2,
                    left:
                        -2, // في الواجهة العربية، اليسار هو الزاوية السفلية المعاكسة
                    child: Container(
                      padding: const EdgeInsets.all(2), // إطار أبيض للشارة
                      decoration: BoxDecoration(
                        color: isDark
                            ? Theme.of(context).cardColor
                            : Colors.white, // إطار يطابق الكرت
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(badgeIcon, color: Colors.white, size: 12),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 15),

            // النصوص (العنوان، التفاصيل، والوقت)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark
                                ? Colors.white
                                : Colors.black87, // متجاوب
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600, // متجاوب
                      fontSize: 13,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
