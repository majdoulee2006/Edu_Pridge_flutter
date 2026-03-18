import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/widgets/student_speed_dial.dart'; 
import 'student_home_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.settings, color: AppColors.textDark), onPressed: () {}),
          title: const Text('المراسلات', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [IconButton(icon: const Icon(Icons.arrow_forward, color: AppColors.textDark), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentHomeScreen())))],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _buildChatCategories(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: 8,
                    itemBuilder: (context, index) => _buildChatItem(name: index == 0 ? 'د. سارة الأحمد' : 'أحمد محمود', message: 'شكراً لك أحمد...', time: '12:40 م', unreadCount: index < 2 ? 1 : 0, isOnline: index % 2 == 0),
                  ),
                ),
              ],
            ),
            Align(alignment: Alignment.bottomCenter, child: _buildFloatingBottomNavBar(context)),
            
            // الزر الأصفر الإضافي (الزائد) الموجود في صورتك
            Positioned(bottom: 100, left: 20, child: FloatingActionButton(backgroundColor: AppColors.accent, child: const Icon(Icons.add, color: Colors.black), onPressed: () {})),

            // الزر الأصفر الحقيقي مغلف بـ Positioned.fill
            Positioned.fill(
              child: const StudentSpeedDial(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatCategories() {
    return Container(height: 50, margin: const EdgeInsets.symmetric(vertical: 10), child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: [_buildCategoryChip('الكل', true), _buildCategoryChip('المدرسين', false), _buildCategoryChip('الزملاء', false)]));
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(margin: const EdgeInsets.only(left: 10), padding: const EdgeInsets.symmetric(horizontal: 20), decoration: BoxDecoration(color: isSelected ? AppColors.accent : Colors.white, borderRadius: BorderRadius.circular(25)), child: Center(child: Text(label, style: const TextStyle(fontSize: 13))));
  }

  Widget _buildChatItem({required String name, required String message, required String time, required int unreadCount, required bool isOnline}) {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: ListTile(leading: CircleAvatar(radius: 28, child: const Icon(Icons.person)), title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(message, maxLines: 1), trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(time, style: const TextStyle(fontSize: 11)), if (unreadCount > 0) CircleAvatar(radius: 10, backgroundColor: AppColors.accent, child: Text('1', style: TextStyle(fontSize: 10)))])));
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
          _buildNavItem(Icons.notifications_none, 'الإشعارات', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()))),
          _buildNavItem(Icons.chat_bubble, 'المراسلات', true, () {}),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: isActive ? AppColors.textDark : Colors.grey, size: 26), Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? AppColors.textDark : Colors.grey))]));
  }
}