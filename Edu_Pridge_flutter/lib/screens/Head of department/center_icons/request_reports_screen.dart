import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/widgets/boss_center_icon.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

// استيراد شاشات التنقل لرئيس القسم
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_home.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_profile.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_notification.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_massega.dart';

class ReportRequestScreen extends StatefulWidget {
  const ReportRequestScreen({super.key});

  @override
  State<ReportRequestScreen> createState() => _ReportRequestScreenState();
}

class _ReportRequestScreenState extends State<ReportRequestScreen> {
  String? selectedTrainer;
  bool isAcademicSelected = true;

  @override
  Widget build(BuildContext context) {
    // 🌟 جلب الألوان من الثيم الحالي للجهاز 🌟
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = Theme.of(context).scaffoldBackgroundColor; // يأخذ لون الخلفية من النظام
    final Color cardColor = Theme.of(context).cardColor; // لون البطاقات (أبيض أو رمادي غامق)
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final Color fieldColor = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF5F7F9);

    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  _buildAppBar(context, textColor, cardColor),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          // 1. قسم الطالب المعني
                          _buildSectionCard(
                            title: "الطالب المعني",
                            icon: Icons.person_search_outlined,
                            iconColor: const Color(0xFFF1C40F),
                            cardColor: cardColor,
                            textColor: textColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCustomTextField(
                                  hint: "ابحث باسم الطالب أو الرقم الأكاديمي...",
                                  icon: Icons.search,
                                  fieldColor: fieldColor,
                                ),
                                const SizedBox(height: 15),
                                Text("مقترحات سريعة", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _buildQuickSuggest("أحمد محمد", fieldColor, textColor),
                                    const SizedBox(width: 10),
                                    _buildQuickSuggest("فيصل العتيبي", fieldColor, textColor),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // 2. قسم المدرب المسؤول
                          _buildSectionCard(
                            title: "المدرب المسؤول",
                            icon: Icons.group_outlined,
                            iconColor: Colors.blueAccent,
                            cardColor: cardColor,
                            textColor: textColor,
                            child: _buildCustomDropdown(fieldColor, textColor),
                          ),

                          // 3. قسم تفاصيل التقرير
                          _buildSectionCard(
                            title: "تفاصيل التقرير",
                            icon: Icons.assignment_outlined,
                            iconColor: Colors.purpleAccent,
                            cardColor: cardColor,
                            textColor: textColor,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    _buildTypeSelectionCard("أداء أكاديمي", Icons.school_outlined, isAcademicSelected, cardColor, textColor, () {
                                      setState(() => isAcademicSelected = true);
                                    }),
                                    const SizedBox(width: 15),
                                    _buildTypeSelectionCard("سلوك وحضور", Icons.psychology_outlined, !isAcademicSelected, cardColor, textColor, () {
                                      setState(() => isAcademicSelected = false);
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text("ملاحظات إضافية (اختياري)", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                ),
                                const SizedBox(height: 10),
                                _buildCustomTextField(
                                  hint: "اكتب أي نقاط ترغب في التركيز عليها...",
                                  maxLines: 3,
                                  fieldColor: fieldColor,
                                ),
                              ],
                            ),
                          ),

                          // 🚀 زر إرسال الطلب (أصفر ثابت حسب ثيمك)
                          const SizedBox(height: 10),
                          _buildSubmitButton(),
                          const SizedBox(height: 130),
                        ],
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

  Widget _buildAppBar(BuildContext context, Color textColor, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleActionBtn(Icons.settings_outlined, cardColor, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(userName: "رئيس القسم", userRole: "إدارة")));
          }),
          Column(
            children: [
              Text("طلب التقارير", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Cairo')),
              Text("تقديم طلب تقرير عن أداء طالب", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontFamily: 'Cairo')),
            ],
          ),
          _buildCircleActionBtn(Icons.arrow_forward, cardColor, () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildCircleActionBtn(IconData icon, Color cardColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardColor,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        ),
        child: Icon(icon, color: Theme.of(context).iconTheme.color, size: 22),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Color iconColor, required Widget child, required Color cardColor, required Color textColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo', color: textColor)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 25),
          child,
        ],
      ),
    );
  }

  Widget _buildCustomTextField({required String hint, IconData? icon, int maxLines = 1, required Color fieldColor}) {
    return TextField(
      maxLines: maxLines,
      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey, size: 20) : null,
        filled: true,
        fillColor: fieldColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildCustomDropdown(Color fieldColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: fieldColor, borderRadius: BorderRadius.circular(20)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: Theme.of(context).cardColor,
          hint: const Text("اختر المدرب من القائمة...", style: TextStyle(fontSize: 13, color: Colors.grey)),
          value: selectedTrainer,
          items: ["المهندس أحمد رامي", "الدكتور سليم حمد"].map((String v) => DropdownMenuItem(value: v, child: Text(v, style: TextStyle(color: textColor)))).toList(),
          onChanged: (val) => setState(() => selectedTrainer = val),
        ),
      ),
    );
  }

  Widget _buildQuickSuggest(String name, Color fieldColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: fieldColor, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(name, style: TextStyle(fontSize: 12, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildTypeSelectionCard(String title, IconData icon, bool isSelected, Color cardColor, Color textColor, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: isSelected ? const Color(0xFFEFFF00) : Colors.grey.withOpacity(0.2), width: 2),
            boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFEFFF00).withOpacity(0.2), blurRadius: 10)] : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black) : Colors.grey, size: 28),
              const SizedBox(height: 10),
              Text(title, style: TextStyle(fontSize: 13, color: textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFEFFF00),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFFEFFF00).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: const Center(
        child: Text("إرسال الطلب للمدرب", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
      ),
    );
  }
}