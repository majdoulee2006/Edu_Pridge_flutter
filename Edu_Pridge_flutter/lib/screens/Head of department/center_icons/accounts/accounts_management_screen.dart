import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/widgets/boss_center_icon.dart';

import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_home.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_profile.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_notification.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_massega.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

import 'add_trainer_screen.dart';
import 'add_student_screen.dart';
import 'add_parent_screen.dart';

class AccountsManagementScreen extends StatefulWidget {
  const AccountsManagementScreen({super.key});

  @override
  State<AccountsManagementScreen> createState() => _AccountsManagementScreenState();
}

class _AccountsManagementScreenState extends State<AccountsManagementScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = Theme.of(context).cardColor;
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    const Color primaryYellow = Color(0xFFEFFF00);

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
                  _buildHeader(context, isDark, textColor),
                  const SizedBox(height: 10),
                  _buildProfessionalTabs(isDark, primaryYellow, cardColor),
                  const SizedBox(height: 25),
                  _buildAddButton(cardColor, textColor, primaryYellow),
                  const Expanded(
                    child: Center(
                      child: Opacity(
                        opacity: 0.5,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_outlined, size: 80),
                            SizedBox(height: 10),
                            Text("قائمة الحسابات ستظهر هنا..."),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              CustomBottomNav(
                currentIndex: 0,
                centerButton: const Boss_Center_Icon(),
                onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DeptHeadHomeScreen())),
                onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BossProfileScreen())),
                onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BossNotificationScreen())),
                onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BossMessageScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(Color cardColor, Color textColor, Color primary) {
    List<String> labels = ["إضافة حساب مدرب جديد", "إضافة حساب طالب جديد", "إضافة حساب ولي أمر"];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () {
          Widget targetScreen;
          if (selectedIndex == 0) {
            targetScreen = const AddTrainerScreen();
          } else if (selectedIndex == 1) {
            targetScreen = const AddStudentScreen();
          } else {
            targetScreen = const AddParentScreen();
          }
          Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen));
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
                decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                child: Icon(Icons.add, color: primary, size: 20),
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

  Widget _buildProfessionalTabs(bool isDark, Color primary, Color cardColor) {
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
                color: isActive ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white : Colors.black),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen(userName: "رئيس القسم", userRole: "إدارة النظام"))
              );
            },
          ),
          Text("إدارة الحسابات", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          IconButton(
            icon: Icon(Icons.arrow_forward, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}