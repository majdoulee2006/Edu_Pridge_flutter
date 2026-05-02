import 'package:flutter/material.dart';

import 'organization/study_schedule_screen/create_new_schedule.dart';
import 'organization/study_schedule_screen/edit_of_table.dart';
import 'organization/study_schedule_screen/table_view.dart';

class MainOrganizationInterfaceScreen extends StatefulWidget {
  const MainOrganizationInterfaceScreen({super.key});

  @override
  State<MainOrganizationInterfaceScreen> createState() => _MainOrganizationInterfaceScreenState();
}

class _MainOrganizationInterfaceScreenState extends State<MainOrganizationInterfaceScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    const primaryYellow = Color(0xFFEFFF00);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, textColor, isDark),
              const SizedBox(height: 8),
              _buildTabs(cardColor, primaryYellow),
              const SizedBox(height: 20),
              Expanded(
                child: selectedIndex == 0
                    ? _buildStudyScheduleCards(context, cardColor, textColor, isDark, primaryYellow)
                    : _buildExamPlaceholder(textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color textColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 48),
          Text(
            'واجهة التنظيم',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: 'Cairo',
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(Color cardColor, Color primaryYellow) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 55,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          _tabItem('الجداول الدراسية', 0, primaryYellow),
          _tabItem('الجداول الامتحانية', 1, primaryYellow),
        ],
      ),
    );
  }

  Widget _tabItem(String title, int index, Color primaryYellow) {
    final isActive = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: isActive ? primaryYellow : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isActive ? Colors.black : Colors.grey,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudyScheduleCards(
    BuildContext context,
    Color cardColor,
    Color textColor,
    bool isDark,
    Color primaryYellow,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      children: [
        _actionCard(
          context: context,
          cardColor: cardColor,
          title: 'عرض الجدول الدراسي',
          subtitle: 'استعراض الجداول الحالية للشعب والمحاضرات.',
          icon: Icons.table_chart_outlined,
          iconColor: Colors.blueAccent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TableViewScreen()),
          ),
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        _actionCard(
          context: context,
          cardColor: cardColor,
          title: 'إنشاء جدول دراسي جديد',
          subtitle: 'إضافة 10 صفوف مواد مع أوقاتها وأساتذتها.',
          icon: Icons.add_card_rounded,
          iconColor: Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateNewScheduleScreen()),
          ),
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        _actionCard(
          context: context,
          cardColor: cardColor,
          title: 'تعديل الجدول الدراسي',
          subtitle: 'تحديث بيانات الجدول الموجود بسهولة.',
          icon: Icons.edit_note_outlined,
          iconColor: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditOfTableScreen(),
            ),
          ),
          isDark: isDark,
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primaryYellow.withOpacity(0.4)),
          ),
          child: Text(
            'اختر الخدمة من البطاقات الثلاث أعلاه للانتقال مباشرة إلى صفحة العرض أو الإنشاء أو التعديل.',
            style: TextStyle(
              color: textColor.withOpacity(0.85),
              fontSize: 12.5,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required BuildContext context,
    required Color cardColor,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildExamPlaceholder(Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Text(
          'سيتم إضافة واجهات الجدول الامتحاني هنا لاحقاً.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor.withOpacity(0.65),
            fontSize: 14,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }
}
