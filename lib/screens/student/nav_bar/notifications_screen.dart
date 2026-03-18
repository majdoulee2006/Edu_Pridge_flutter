import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/widgets/student_speed_dial.dart'; 
import 'student_home_screen.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textDark), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentHomeScreen()))),
            title: const Text('الإشعارات', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
            centerTitle: true,
            bottom: PreferredSize(preferredSize: const Size.fromHeight(60), child: _buildCustomTabBar()),
          ),
          body: Stack(
            children: [
              const TabBarView(children: [_AcademicNotificationsView(), _AdministrativeNotificationsView()]),
              Align(alignment: Alignment.bottomCenter, child: _buildFloatingBottomNavBar(context)),
              
              // الزر الأصفر الحقيقي مغلف بـ Positioned.fill
              Positioned.fill(
                child: const StudentSpeedDial(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 45,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: TabBar(
        indicator: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(25)),
        labelColor: AppColors.textDark,
        unselectedLabelColor: Colors.grey,
        tabs: const [Tab(text: 'رسائل أكاديمية'), Tab(text: 'رسائل إدارية')],
      ),
    );
  }

  Widget _buildFloatingBottomNavBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      height: 70,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(35), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_outlined, 'الرئيسية', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentHomeScreen()))),
          _buildNavItem(Icons.person_outline, 'الملف', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))),
          const SizedBox(width: 70), // مساحة للزر الحقيقي
          _buildNavItem(Icons.notifications, 'الإشعارات', true, () {}),
          _buildNavItem(Icons.chat_bubble_outline, 'المراسلات', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MessagesScreen()))),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: isActive ? AppColors.textDark : Colors.grey, size: 26), Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? AppColors.textDark : Colors.grey))]));
  }
}

class _AcademicNotificationsView extends StatelessWidget {
  const _AcademicNotificationsView();
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [_buildDateHeader('اليوم'), _buildNotificationCard(title: 'تم رفع وظيفة جديدة', subtitle: 'قام الأستاذ أحمد برفع وظيفة جديدة في مادة الرياضيات المتقدمة...', time: 'منذ ساعتين', icon: Icons.assignment, iconColor: Colors.blue)]);
  }
}

class _AdministrativeNotificationsView extends StatelessWidget {
  const _AdministrativeNotificationsView();
  @override
  Widget build(BuildContext context) => const Center(child: Text('لا يوجد رسائل إدارية حالياً'));
}

Widget _buildDateHeader(String date) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(date, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)));

Widget _buildNotificationCard({required String title, required String subtitle, required String time, required IconData icon, required Color iconColor}) {
  return Container(margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 28)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10))]), const SizedBox(height: 5), Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 2)]))]));
}