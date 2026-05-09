import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/widgets/admin_speed_dial.dart';

import 'home_screen.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  int selectedTarget = 0;

  // متغيرات لـ "قسم"
  String? selectedDepartment;
  List<String> selectedCategories = [];

  // متغيرات لـ "أفراد"
  final TextEditingController searchController = TextEditingController();
  String? selectedDeptForIndividuals;
  String? selectedSpecialization;
  List<String> selectedRoles = [];
  List<String> selectedUsers = [];

  // الأقسام
  final List<String> departments = [
    "قسم الكومبيوتر ونظم المعلومات",
    "قسم الطبي",
    "قسم التجاري",
  ];

  List<String> getSpecializations(String? dept) {
    if (dept == "قسم الكومبيوتر ونظم المعلومات") {
      return ["المعلوماتية", "الاتصالات", "الإلكترون", "الذكاء الصناعي"];
    } else if (dept == "قسم الطبي") {
      return ["المخبري", "الصيدلة"];
    } else if (dept == "قسم التجاري") {
      return ["المحاسبة", "إدارة الأعمال"];
    }
    return [];
  }

  final List<String> roles = [
    "رئيس القسم",
    "معلمين",
    "طلاب",
    "أولياء أمور",
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final primaryYellow = const Color(0xFFEFFF00);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            if (!isDark) _buildGridBackground(),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(textColor),
                    const SizedBox(height: 20),

                    _buildSectionTitle("توجيه الرسالة إلى", primaryYellow),
                    const SizedBox(height: 15),

                    // خيارات التوجيه
                    Row(
                      children: [
                        _buildTargetCard("الجميع", Icons.group, 0, primaryYellow, cardColor, textColor),
                        const SizedBox(width: 10),
                        _buildTargetCard("قسم", Icons.business, 1, primaryYellow, cardColor, textColor),
                        const SizedBox(width: 10),
                        _buildTargetCard("أفراد", Icons.person_search, 2, primaryYellow, cardColor, textColor),
                      ],
                    ),

                    const SizedBox(height: 30),

                    if (selectedTarget == 1)
                      _buildDepartmentSection(cardColor, textColor, primaryYellow, isDark)
                    else if (selectedTarget == 2)
                      _buildIndividualsSection(cardColor, textColor, primaryYellow, isDark),

                    const SizedBox(height: 25),

                    _buildMessageForm(cardColor, textColor, primaryYellow, isDark),
                    const SizedBox(height: 25),

                    _buildSendButton(primaryYellow),
                  ],
                ),
              ),
            ),

            CustomBottomNav(
              currentIndex: 2,
              centerButton: const AdminSpeedDial(),
              onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminProfileScreen())),
              onNotificationsTap: () {},
              onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminMessagesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  // ====================== Header ======================
  Widget _buildHeader(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        Text(
          "الإشعارات الإدارية",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 26),
          onPressed: () {},
        ),
      ],
    );
  }

  // ====================== قسم ======================
  Widget _buildDepartmentSection(Color cardColor, Color textColor, Color yellow, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel("اختر القسم"),
        DropdownButtonFormField<String>(
          value: selectedDepartment,
          decoration: _inputDecoration("اختر القسم المستهدف", isDark),
          dropdownColor: cardColor,
          items: departments.map((dept) => DropdownMenuItem(value: dept, child: Text(dept))).toList(),
          onChanged: (value) => setState(() => selectedDepartment = value),
        ),
        const SizedBox(height: 25),

        _buildFieldLabel("الفئات المستهدفة داخل القسم"),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: roles.map((role) {
            bool isSelected = selectedCategories.contains(role);
            return FilterChip(
              label: Text(role),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) selectedCategories.add(role);
                  else selectedCategories.remove(role);
                });
              },
              backgroundColor: cardColor,
              selectedColor: yellow,
              checkmarkColor: Colors.black,
              labelStyle: TextStyle(color: isSelected ? Colors.black : textColor),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ====================== الأفراد ======================
  Widget _buildIndividualsSection(Color cardColor, Color textColor, Color yellow, bool isDark) {
    final specs = getSpecializations(selectedDeptForIndividuals);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel("بحث عن مستخدم"),
        TextField(
          controller: searchController,
          decoration: _inputDecoration("ابحث بالاسم أو البريد الإلكتروني...", isDark),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),

        _buildFieldLabel("اختر القسم"),
        DropdownButtonFormField<String>(
          value: selectedDeptForIndividuals,
          decoration: _inputDecoration("اختر القسم", isDark),
          dropdownColor: cardColor,
          items: departments.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) {
            setState(() {
              selectedDeptForIndividuals = v;
              selectedSpecialization = null;
            });
          },
        ),
        const SizedBox(height: 20),

        _buildFieldLabel("التخصص"),
        DropdownButtonFormField<String>(
          value: selectedSpecialization,
          decoration: _inputDecoration("اختر التخصص", isDark),
          dropdownColor: cardColor,
          items: specs.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => selectedSpecialization = v),
        ),
        const SizedBox(height: 25),

        _buildFieldLabel("نوع الحساب"),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: roles.map((role) {
            bool isSelected = selectedRoles.contains(role);
            return FilterChip(
              label: Text(role),
              selected: isSelected,
              onSelected: (sel) {
                setState(() {
                  if (sel) selectedRoles.add(role);
                  else selectedRoles.remove(role);
                });
              },
              backgroundColor: cardColor,
              selectedColor: yellow,
              checkmarkColor: Colors.black,
              labelStyle: TextStyle(color: isSelected ? Colors.black : textColor),
            );
          }).toList(),
        ),

        const SizedBox(height: 25),

        _buildFieldLabel("المستخدمون المطابقون (${selectedUsers.length})"),
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: 8,
            itemBuilder: (context, index) {
              final name = "مستخدم ${index + 1}";
              bool isSelected = selectedUsers.contains(name);
              return CheckboxListTile(
                dense: true,
                title: Text(name, style: TextStyle(color: textColor)),
                subtitle: Text("القسم • التخصص", style: TextStyle(color: textColor.withOpacity(0.7))),
                value: isSelected,
                activeColor: yellow,
                checkColor: Colors.black,
                onChanged: (val) {
                  setState(() {
                    if (val == true) selectedUsers.add(name);
                    else selectedUsers.remove(name);
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ====================== النموذج والأزرار ======================
  Widget _buildMessageForm(Color cardColor, Color textColor, Color yellow, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.06), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel("الموضوع"),
          TextField(decoration: _inputDecoration("أدخل عنواناً واضحاً للرسالة...", isDark)),
          const SizedBox(height: 20),
          _buildFieldLabel("نص الرسالة"),
          TextField(
            maxLines: 6,
            decoration: _inputDecoration("اكتب تفاصيل الرسالة الإدارية هنا...", isDark),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildAttachmentButton(Icons.attach_file, "ملف", isDark),
              const SizedBox(width: 10),
              _buildAttachmentButton(Icons.image_outlined, "صورة", isDark),
              const Spacer(),
              const Text("0 حرف", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton(Color yellow) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: yellow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: yellow.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("إرسال التعميم", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
          SizedBox(width: 10),
          Icon(Icons.send_rounded, color: Colors.black),
        ],
      ),
    );
  }

  // ====================== أدوات مساعدة ======================
  Widget _buildTargetCard(String label, IconData icon, int index, Color yellow, Color cardColor, Color textColor) {
    bool isSelected = selectedTarget == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTarget = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? yellow : cardColor,
            borderRadius: BorderRadius.circular(20),
            border: isSelected ? null : Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: isSelected ? [BoxShadow(color: yellow.withOpacity(0.3), blurRadius: 12)] : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.black : Colors.grey, size: 28),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.black : textColor)),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      filled: true,
      fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: const Color(0xFFEFFF00), width: 1.5),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 5),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildAttachmentButton(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color yellow) {
    return Row(
      children: [
        Icon(Icons.alternate_email, color: yellow, size: 18),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _buildGridBackground() {
    return Opacity(
      opacity: 0.03,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage("assets/images/grid.png"), repeat: ImageRepeat.repeat),
        ),
      ),
    );
  }
}