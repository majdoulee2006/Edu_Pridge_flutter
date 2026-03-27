import 'package:flutter/material.dart';

// 🌟 استدعاء المكونات الموحدة 🌟
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../../../widgets/teacher_speed_dial.dart';

// استدعاء الشاشات
import '../../messages_screen.dart';
import '../../notifications_screen.dart';
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
    // الألوان الأساسية
    const Color primaryYellow = Color(0xFFEFFF00);
    const Color activeTabColor = Color(0xFFF0E35F);

    // جلب ألوان الثيم
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
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
              'الواجبات والمشاريع',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            bottom: TabBar(
              indicatorColor: primaryYellow,
              indicatorWeight: 3,
              labelColor: isDark ? primaryYellow : Colors.black,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              tabs: const [
                Tab(text: 'قائمة الواجبات'),
                Tab(text: 'ردود الطلاب'),
              ],
            ),
          ),
          body: Stack(
            children: [
              // 1. محتوى التبويبات
              TabBarView(
                children: [
                  _buildAllAssignmentsList(
                    context,
                    cardColor,
                    textColor,
                    isDark,
                  ),
                  const AllResponsesScreen(), // تأكدي من تحديث هذه الشاشة أيضاً لاحقاً
                ],
              ),

              // 2. زر الإضافة العائم (Side FAB)
              Positioned(
                bottom: 100, // مرفوع قليلاً عن الـ Bottom Nav
                left: 20, // في جهة اليسار لأن التطبيق RTL
                child: FloatingActionButton(
                  heroTag: "add_assignment_btn",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddAssignmentScreen(),
                      ),
                    );
                  },
                  backgroundColor: primaryYellow,
                  elevation: 6,
                  child: const Icon(Icons.add, color: Colors.black, size: 30),
                ),
              ),

              // 3. الشريط السفلي الموحد
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
      ),
    );
  }

  Widget _buildAllAssignmentsList(
    BuildContext context,
    Color cardColor,
    Color textColor,
    bool isDark,
  ) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        _buildAssignmentCard(
          context,
          title: 'واجب الفيزياء: الطاقة',
          subject: 'الفيزياء | الصف 11 - B',
          date: '2023-11-15',
          progress: '24/30 طالب قدم الحل',
          icon: Icons.bolt_rounded,
          statusText: 'نشط',
          statusColor: Colors.green,
          cardColor: cardColor,
          textColor: textColor,
          isDark: isDark,
          hasGlow: true,
        ),
        const SizedBox(height: 12),
        _buildAssignmentCard(
          context,
          title: 'مشروع التخرج الفصلي',
          subject: 'العلوم العامة | الصف 10 - أ',
          date: '2023-11-20',
          progress: '5/28 طالب قدم الحل',
          icon: Icons.science_outlined,
          statusText: 'قيد الإنتظار',
          statusColor: Colors.orange,
          cardColor: cardColor,
          textColor: textColor,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildAssignmentCard(
          context,
          title: 'اختبار قصير: الدوال',
          subject: 'الرياضيات | الصف 12 - أ',
          date: '2023-10-30',
          progress: '15/28 مصحح',
          icon: Icons.functions_rounded,
          statusText: 'قيد التصحيح',
          statusColor: Colors.blue,
          cardColor: cardColor,
          textColor: textColor,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildAssignmentCard(
          context,
          title: 'واجب القراءة والاستيعاب',
          subject: 'اللغة العربية | الصف 9 - ج',
          date: '2023-10-15',
          progress: '30/30 مكتمل',
          icon: Icons.menu_book_rounded,
          statusText: 'مكتمل',
          statusColor: Colors.grey,
          cardColor: cardColor,
          textColor: textColor,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildAssignmentCard(
    BuildContext context, {
    required String title,
    required String subject,
    required String date,
    required String progress,
    required IconData icon,
    required String statusText,
    required Color statusColor,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
    bool hasGlow = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: hasGlow
            ? Border.all(
                color: const Color(0xFFEFFF00).withOpacity(0.5),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: hasGlow
                ? const Color(0xFFEFFF00).withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: const Color(0xFFF0E35F),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: textColor,
                              ),
                            ),
                            Text(
                              subject,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(statusText, statusColor),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, thickness: 0.5),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: textColor.withOpacity(0.5),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Icon(
                            Icons.people_outline,
                            size: 16,
                            color: textColor.withOpacity(0.5),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            progress,
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_back_ios,
                        size: 14,
                        color: textColor.withOpacity(0.3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
