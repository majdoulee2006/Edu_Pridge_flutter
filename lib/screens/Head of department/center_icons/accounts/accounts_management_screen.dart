import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/widgets/boss_center_icon.dart';

// استيراد واجهات الإضافة بناءً على تسلسل ملفاتك الجديد
import 'add_trainer_screen.dart';
import 'add_student_screen.dart';
import 'add_parent_screen.dart';

class AccountsManagementScreen extends StatefulWidget {
  const AccountsManagementScreen({super.key});

  @override
  State<AccountsManagementScreen> createState() => _AccountsManagementScreenState();
}

class _AccountsManagementScreenState extends State<AccountsManagementScreen> {
  // 0: مدرب/معلم، 1: طالب، 2: أهل
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    const primaryYellow = Color(0xFFEFFF00);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(textColor),
                  const SizedBox(height: 10),

                  // التبويبات (مدرب - طالب - أهل)
                  _buildProfessionalTabs(isDark, primaryYellow),

                  const SizedBox(height: 25),

                  // زر الإضافة الذي ينقلك للواجهة المناسبة
                  _buildAddButton(cardColor, textColor, primaryYellow),

                  const Expanded(
                    child: Center(
                      child: Opacity(
                        opacity: 0.5,
                        child: Text("قائمة الحسابات ستظهر هنا..."),
                      ),
                    ),
                  ),
                ],
              ),

              // شريط التنقل السفلي الموحد
              CustomBottomNav(
                currentIndex: 0,
                centerButton: const Boss_Center_Icon(),
                onHomeTap: () => Navigator.pop(context),
                onProfileTap: () {},
                onNotificationsTap: () {},
                onMessagesTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة زر الإضافة مع منطق الانتقال (Navigation Logic)
  Widget _buildAddButton(Color cardColor, Color textColor, Color primary) {
    List<String> labels = ["إضافة حساب مدرب جديد", "إضافة حساب طالب جديد", "إضافة حساب ولي أمر"];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () {
          // تحديد الواجهة الهدف بناءً على التبويب المختار
          Widget targetScreen;
          if (selectedIndex == 0) {
            targetScreen = const AddTrainerScreen();
          } else if (selectedIndex == 1) {
            targetScreen = const AddStudentScreen();
          } else {
            targetScreen = const AddParentScreen();
          }

          // الانتقال للواجهة المختارة
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetScreen),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withOpacity(0.5), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                child: const Icon(Icons.add, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                labels[selectedIndex],
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalTabs(bool isDark, Color primary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _tabItem("مدرب / معلم", 0, isDark, primary),
          _tabItem("طالب", 1, isDark, primary),
          _tabItem("أهل", 2, isDark, primary),
        ],
      ),
    );
  }

  Widget _tabItem(String title, int index, bool isDark, Color primary) {
    bool isActive = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isActive ? Colors.black : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.settings_outlined, size: 26),
          Text("إدارة الحسابات", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
          IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 20), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}