import 'package:flutter/material.dart';

import '../../../../widgets/teacher_speed_dial.dart';
import '../../messages_screen.dart';
import '../../profile_screen.dart';
import '../../teacher_home.dart';
import 'responses/all_responses.dart';
import 'add_assignment.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  @override
  Widget build(BuildContext context) {
    const Color mainAppColor = Color(0xFFF7F7F7);
    const Color activeTabColor = Color(0xFFF0E35F);
    const Color activeGlowColor = Color(0xFFFDF7B8);
    const Color textDarkColor = Color(0xFF333333);
    const Color badgeActiveColor = Color(0xFFFFEB3B);
    const Color badgeGradingColor = Color(0xFFFFD180);
    const Color badgeGradedColor = Color(0xFFC8E6C9);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: mainAppColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: textDarkColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'الواجبات والمشاريع',
              style: TextStyle(color: textDarkColor, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Tajawal'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: textDarkColor),
                onPressed: () {},
              ),
            ],
            centerTitle: true,
            bottom: const TabBar(
              indicatorColor: activeTabColor,
              indicatorWeight: 3,
              labelColor: activeTabColor,
              unselectedLabelColor: Colors.grey,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Tajawal'),
              tabs: [
                Tab(text: 'الكل'),
                Tab(text: 'الردود'),
              ],
            ),
          ),
          body: Stack(
            children: [
              TabBarView(
                children: [
                  _buildAllAssignmentsList(activeGlowColor, badgeActiveColor, badgeGradingColor, badgeGradedColor),
                  const AllResponsesScreen(),
                ],
              ),
              // الزر الأصفر في الطرف اليمين
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  heroTag: "addBtn",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddAssignmentScreen()),
                    );
                  },
                  backgroundColor: const Color(0xFFEFFF00),
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, color: Colors.black, size: 30),
                ),
              ),
            ],
          ),
          floatingActionButton: const CustomSpeedDialEduBridge(),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: _buildBottomNav(context),
        ),
      ),
    );
  }

  Widget _buildAllAssignmentsList(Color activeGlowColor, Color badgeActiveColor, Color badgeGradingColor, Color badgeGradedColor) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        _buildAssignmentCard(
          title: 'واجب الفيزياء: الطاقة',
          subject: 'الفيزياء | الصف 11 - b',
          date: '2023-11-15',
          progress: '24/30',
          icon: Icons.list_alt_outlined,
          statusBadge: _buildStatusBadge('نشط', badgeActiveColor, Colors.black),
          hasGlow: true,
          glowColor: activeGlowColor,
        ),
        const SizedBox(height: 12),
        _buildAssignmentCard(
          title: 'مشروع التخرج الفصلي',
          subject: 'العلوم العامة | الصف 10 - أ',
          date: '2023-11-20',
          progress: '5/28',
          icon: Icons.science_outlined,
        ),
        const SizedBox(height: 12),
        _buildAssignmentCard(
          title: 'اختبار قصير: الدوال',
          subject: 'الرياضيات | الصف 12 - أ',
          date: '2023-10-30',
          progress: '15/28 مصحح',
          icon: Icons.assignment_outlined,
          statusBadge: _buildStatusBadge('قيد التصحيح', badgeGradingColor, const Color(0xFFC62828)),
        ),
        const SizedBox(height: 12),
        _buildAssignmentCard(
          title: 'واجب القراءة والاستيعاب',
          subject: 'اللغة العربية | الصف 9 - ج',
          date: '2023-10-15',
          progress: '30/30',
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          statusBadge: _buildStatusBadge('تم\nالتصحيح', badgeGradedColor, const Color(0xFF1B5E20)),
        ),
        const SizedBox(height: 80), // مساحة للـ FloatingActionButton
      ],
    );
  }

  Widget _buildStatusBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
    );
  }

  Widget _buildAssignmentCard({
    required String title,
    required String subject,
    required String date,
    required String progress,
    required IconData icon,
    Widget? statusBadge,
    bool hasGlow = false,
    Color glowColor = Colors.white,
    Color iconColor = const Color(0xFFF0E35F),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: glowColor.withAlpha(204),
                  spreadRadius: 3,
                  blurRadius: 7,
                  offset: const Offset(0, 0),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.grey.withAlpha(30),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 36, color: iconColor),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333), fontFamily: 'Tajawal'),
                  ),
                ),
                if (statusBadge != null) statusBadge,
              ],
            ),
            const SizedBox(height: 4),
            Text(subject, style: const TextStyle(color: Color(0xFF777777), fontSize: 13, fontFamily: 'Tajawal')),
          ],
        ),
        subtitle: Column(
          children: [
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFEEEEEE), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                // 1. التاريخ والأيقونة (أصبح في اليمين)
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF777777)),
                    const SizedBox(width: 4),
                    Text(date, style: const TextStyle(color: Color(0xFF777777), fontSize: 13, fontFamily: 'Tajawal')),
                  ],
                ),
                const SizedBox(width: 16),
                // 2. عدد الطلاب/التقدم
                Row(
                  children: [
                    const Icon(Icons.group_outlined, size: 18, color: Color(0xFF777777)),
                    const SizedBox(width: 4),
                    Text(progress, style: const TextStyle(color: Color(0xFF777777), fontSize: 13, fontFamily: 'Tajawal')),
                  ],
                ),
                const Spacer(),
                // 3. السهم (أصبح في أقصى اليسار)
                const Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFF777777)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      height: 70,
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(context, Icons.home_outlined, "الرئيسية", false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherHomeScreen()))),
          _navItem(context, Icons.person_outline, "الملف", false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))),
          const SizedBox(width: 40),
          _navItem(context, Icons.notifications_none, "الإشعارات", false, onTap: () {}),
          _navItem(context, Icons.chat_bubble_outline, "الرسائل", false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MessagesScreen()))),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, bool active, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? const Color(0xFFEFFF00) : Colors.grey),
          Text(label, style: TextStyle(fontSize: 10, color: active ? const Color(0xFFEFFF00) : Colors.grey, fontFamily: 'Tajawal')),
        ],
      ),
    );
  }
}