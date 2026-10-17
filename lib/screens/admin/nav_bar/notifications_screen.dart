import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/widgets/admin_speed_dial.dart';
import 'package:edu_pridge_flutter/services/admin_services.dart';

import 'home_screen.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final AdminServices _adminServices = AdminServices();

  int selectedTarget = 0;
  bool isLoadingData = true;
  bool isSending = false;

  // بيانات حقيقية من السيرفر
  List<dynamic> departments = [];
  List<dynamic> allUsers = [];

  // متغيرات لـ "قسم"
  int? selectedDepartmentId;
  List<String> selectedCategories = [];

  // متغيرات لـ "أفراد"
  final TextEditingController searchController = TextEditingController();
  int? selectedDeptForIndividuals;
  List<String> selectedRoles = [];
  List<int> selectedUsers = [];

  // نموذج الرسالة
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  final List<String> roleKeys = [
    "dept_head",
    "teachers",
    "students",
    "parents",
  ];

  bool get isAr => AppSettings.language.value == 'ar';

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    _loadData();
    messageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    searchController.dispose();
    subjectController.dispose();
    messageController.dispose();
    super.dispose();
  }

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  String _getRoleLabel(String key) {
    if (isAr) {
      switch (key) {
        case 'dept_head':
          return "رئيس القسم";
        case 'teachers':
          return "معلمين";
        case 'students':
          return "طلاب";
        case 'parents':
          return "أولياء أمور";
        default:
          return key;
      }
    } else {
      switch (key) {
        case 'dept_head':
          return "Dept Head";
        case 'teachers':
          return "Teachers";
        case 'students':
          return "Students";
        case 'parents':
          return "Parents";
        default:
          return key;
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => isLoadingData = true);
    final results = await Future.wait([
      _adminServices.getDepartments(),
      _adminServices.getUsers(all: true),
    ]);
    if (!mounted) return;
    setState(() {
      departments = results[0] ?? [];
      allUsers = results[1] ?? [];
      isLoadingData = false;
    });
  }

  int? _roleKeyToId(String key) {
    switch (key) {
      case 'dept_head':
        return 5;
      case 'teachers':
        return 2;
      case 'students':
        return 3;
      case 'parents':
        return 4;
    }
    return null;
  }

  int _toInt(dynamic v) => v is int ? v : int.parse(v.toString());

  List<dynamic> get _filteredIndividuals {
    final query = searchController.text.trim().toLowerCase();
    String? deptName;
    if (selectedDeptForIndividuals != null) {
      final match = departments.firstWhere(
        (d) => d['department_id'] == selectedDeptForIndividuals,
        orElse: () => null,
      );
      deptName = match?['name'];
    }
    final roleIds = selectedRoles.map(_roleKeyToId).whereType<int>().toSet();

    return allUsers.where((u) {
      final name = (u['full_name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      if (query.isNotEmpty && !name.contains(query) && !email.contains(query)) {
        return false;
      }
      if (deptName != null && u['department'] != deptName) return false;
      if (roleIds.isNotEmpty && !roleIds.contains(_toInt(u['role_id']))) {
        return false;
      }
      return true;
    }).toList();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _handleSend() async {
    final subject = subjectController.text.trim();
    final message = messageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      _showSnack(
        isAr
            ? 'يرجى تعبئة الموضوع ونص الرسالة'
            : 'Please fill in the subject and message body',
        isError: true,
      );
      return;
    }

    String recipientType;
    List<int>? targetDepartments;
    List<int>? targetUsers;

    if (selectedTarget == 0) {
      recipientType = 'all';
    } else if (selectedTarget == 1) {
      if (selectedDepartmentId == null) {
        _showSnack(
          isAr
              ? 'يرجى اختيار القسم المستهدف'
              : 'Please select the target department',
          isError: true,
        );
        return;
      }
      if (selectedCategories.isEmpty) {
        recipientType = 'departments';
        targetDepartments = [selectedDepartmentId!];
      } else {
        final deptMatch = departments.firstWhere(
          (d) => d['department_id'] == selectedDepartmentId,
          orElse: () => null,
        );
        final String? deptName = deptMatch?['name'];
        final roleIds =
            selectedCategories.map(_roleKeyToId).whereType<int>().toSet();
        final matched = allUsers
            .where((u) =>
                u['department'] == deptName &&
                roleIds.contains(_toInt(u['role_id'])))
            .map<int>((u) => _toInt(u['user_id']))
            .toList();
        if (matched.isEmpty) {
          _showSnack(
            isAr
                ? 'لا يوجد مستخدمون مطابقون لهذا الاختيار'
                : 'No users match this selection',
            isError: true,
          );
          return;
        }
        recipientType = 'individuals';
        targetUsers = matched;
      }
    } else {
      if (selectedUsers.isEmpty) {
        _showSnack(
          isAr
              ? 'يرجى اختيار مستخدم واحد على الأقل'
              : 'Please select at least one user',
          isError: true,
        );
        return;
      }
      recipientType = 'individuals';
      targetUsers = selectedUsers;
    }

    setState(() => isSending = true);
    try {
      final success = await _adminServices.sendBroadcast(
        recipientType: recipientType,
        subject: subject,
        message: message,
        targetDepartments: targetDepartments,
        targetUsers: targetUsers,
      );
      if (success) {
        _showSnack(
          isAr
              ? 'تم إرسال التعميم بنجاح'
              : 'Announcement sent successfully',
        );
        setState(() {
          subjectController.clear();
          messageController.clear();
          selectedCategories.clear();
          selectedRoles.clear();
          selectedUsers.clear();
          selectedDepartmentId = null;
          selectedDeptForIndividuals = null;
        });
      } else {
        _showSnack(
          isAr
              ? 'تعذر إرسال التعميم، حاول مرة أخرى'
              : 'Failed to send announcement, please try again',
          isError: true,
        );
      }
    } catch (e) {
      _showSnack(
        isAr ? 'حدث خطأ أثناء الإرسال: $e' : 'Error sending announcement: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black);
    const primaryYellow = Color(0xFFFFCC00);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            if (!isDark) _buildGridBackground(),

            SafeArea(
              child: isLoadingData
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryYellow),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(textColor),
                          const SizedBox(height: 20),

                          _buildSectionTitle(
                            isAr ? "توجيه الرسالة إلى" : "Direct Message To",
                            primaryYellow,
                          ),
                          const SizedBox(height: 15),

                          // خيارات التوجيه
                          Row(
                            children: [
                              _buildTargetCard(
                                isAr ? "الجميع" : "Everyone",
                                Icons.group,
                                0,
                                primaryYellow,
                                cardColor,
                                textColor,
                              ),
                              const SizedBox(width: 10),
                              _buildTargetCard(
                                isAr ? "قسم" : "Department",
                                Icons.business,
                                1,
                                primaryYellow,
                                cardColor,
                                textColor,
                              ),
                              const SizedBox(width: 10),
                              _buildTargetCard(
                                isAr ? "أفراد" : "Individuals",
                                Icons.person_search,
                                2,
                                primaryYellow,
                                cardColor,
                                textColor,
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          if (selectedTarget == 1)
                            _buildDepartmentSection(
                              cardColor,
                              textColor,
                              primaryYellow,
                              isDark,
                            )
                          else if (selectedTarget == 2)
                            _buildIndividualsSection(
                              cardColor,
                              textColor,
                              primaryYellow,
                              isDark,
                            ),

                          const SizedBox(height: 25),

                          _buildMessageForm(
                            cardColor,
                            textColor,
                            primaryYellow,
                            isDark,
                          ),
                          const SizedBox(height: 25),

                          _buildSendButton(primaryYellow),
                        ],
                      ),
                    ),
            ),

            CustomBottomNav(
              currentIndex: 2,
              centerButton: const AdminSpeedDial(),
              onHomeTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminHomeScreen(),
                ),
              ),
              onProfileTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminProfileScreen(),
                ),
              ),
              onNotificationsTap: () {},
              onMessagesTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminMessagesScreen(),
                ),
              ),
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
          icon: Icon(
            isAr ? Icons.arrow_back : Icons.arrow_back_ios_new,
            color: textColor,
            size: 26,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        Text(
          isAr ? "الإشعارات الإدارية" : "Administrative Notifications",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        const SizedBox(width: 26),
      ],
    );
  }

  // ====================== قسم ======================
  Widget _buildDepartmentSection(
    Color cardColor,
    Color textColor,
    Color yellow,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(isAr ? "اختر القسم" : "Select Department"),
        DropdownButtonFormField<int>(
          key: ValueKey(selectedDepartmentId),
          initialValue: selectedDepartmentId,
          decoration: _inputDecoration(
            isAr ? "اختر القسم المستهدف" : "Select Target Department",
            isDark,
          ),
          dropdownColor: cardColor,
          items: departments
              .map((dept) => DropdownMenuItem<int>(
                    value: _toInt(dept['department_id']),
                    child: Text(dept['name']?.toString() ?? ''),
                  ))
              .toList(),
          onChanged: (value) => setState(() => selectedDepartmentId = value),
        ),
        const SizedBox(height: 25),

        _buildFieldLabel(
          isAr
              ? "الفئات المستهدفة داخل القسم (اختياري — اتركها فارغة لإرسال للقسم كامل)"
              : "Target categories in department (Optional — leave empty for whole department)",
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: roleKeys.map((key) {
            bool isSelected = selectedCategories.contains(key);
            return FilterChip(
              label: Text(_getRoleLabel(key)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedCategories.add(key);
                  } else {
                    selectedCategories.remove(key);
                  }
                });
              },
              backgroundColor: cardColor,
              selectedColor: yellow,
              checkmarkColor: Colors.black,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : textColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ====================== الأفراد ======================
  Widget _buildIndividualsSection(
    Color cardColor,
    Color textColor,
    Color yellow,
    bool isDark,
  ) {
    final filtered = _filteredIndividuals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(isAr ? "بحث عن مستخدم" : "Search User"),
        TextField(
          controller: searchController,
          decoration: _inputDecoration(
            isAr
                ? "ابحث بالاسم أو البريد الإلكتروني..."
                : "Search by name or email...",
            isDark,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),

        _buildFieldLabel(isAr ? "اختر القسم" : "Select Department"),
        DropdownButtonFormField<int>(
          key: ValueKey(selectedDeptForIndividuals),
          initialValue: selectedDeptForIndividuals,
          decoration: _inputDecoration(
            isAr ? "كل الأقسام" : "All Departments",
            isDark,
          ),
          dropdownColor: cardColor,
          items: departments
              .map((d) => DropdownMenuItem<int>(
                    value: _toInt(d['department_id']),
                    child: Text(d['name']?.toString() ?? ''),
                  ))
              .toList(),
          onChanged: (v) => setState(() => selectedDeptForIndividuals = v),
        ),
        const SizedBox(height: 25),

        _buildFieldLabel(isAr ? "نوع الحساب" : "Account Type"),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: roleKeys.map((key) {
            bool isSelected = selectedRoles.contains(key);
            return FilterChip(
              label: Text(_getRoleLabel(key)),
              selected: isSelected,
              onSelected: (sel) {
                setState(() {
                  if (sel) {
                    selectedRoles.add(key);
                  } else {
                    selectedRoles.remove(key);
                  }
                });
              },
              backgroundColor: cardColor,
              selectedColor: yellow,
              checkmarkColor: Colors.black,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : textColor,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 25),

        _buildFieldLabel(
          isAr
              ? "المستخدمون المطابقون (${filtered.length}) — المحدد (${selectedUsers.length})"
              : "Matching Users (${filtered.length}) — Selected (${selectedUsers.length})",
        ),
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    isAr ? 'لا يوجد مستخدمون مطابقون' : 'No matching users',
                    style: TextStyle(color: textColor.withValues(alpha: 0.6)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    final int userId = _toInt(user['user_id']);
                    final bool isSelected = selectedUsers.contains(userId);
                    return CheckboxListTile(
                      dense: true,
                      title: Text(
                        user['full_name']?.toString() ??
                            (isAr ? 'مستخدم' : 'User'),
                        style: TextStyle(color: textColor),
                      ),
                      subtitle: Text(
                        "${user['department'] ?? ''} • ${user['role'] ?? ''}",
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                      value: isSelected,
                      activeColor: yellow,
                      checkColor: Colors.black,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selectedUsers.add(userId);
                          } else {
                            selectedUsers.remove(userId);
                          }
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
  Widget _buildMessageForm(
    Color cardColor,
    Color textColor,
    Color yellow,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(isAr ? "الموضوع" : "Subject"),
          TextField(
            controller: subjectController,
            decoration: _inputDecoration(
              isAr
                  ? "أدخل عنواناً واضحاً للرسالة..."
                  : "Enter a clear title for the message...",
              isDark,
            ),
          ),
          const SizedBox(height: 20),
          _buildFieldLabel(isAr ? "نص الرسالة" : "Message Body"),
          TextField(
            controller: messageController,
            maxLines: 6,
            decoration: _inputDecoration(
              isAr
                  ? "اكتب تفاصيل الرسالة الإدارية هنا..."
                  : "Write administrative message details here...",
              isDark,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Spacer(),
              Text(
                isAr
                    ? "${messageController.text.length} حرف"
                    : "${messageController.text.length} characters",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton(Color yellow) {
    return GestureDetector(
      onTap: isSending ? null : _handleSend,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: isSending ? yellow.withValues(alpha: 0.6) : yellow,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: yellow.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: isSending
              ? const [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.black,
                    ),
                  ),
                ]
              : [
                  Text(
                    isAr ? "إرسال التعميم" : "Send Announcement",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.send_rounded, color: Colors.black),
                ],
        ),
      ),
    );
  }

  // ====================== أدوات مساعدة ======================
  Widget _buildTargetCard(
    String label,
    IconData icon,
    int index,
    Color yellow,
    Color cardColor,
    Color textColor,
  ) {
    bool isSelected = selectedTarget == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTarget = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? yellow : cardColor,
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? null
                : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: yellow.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.black : Colors.grey,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black : textColor,
                ),
              ),
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFFFCC00), width: 1.5),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 5),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color yellow) {
    return Row(
      children: [
        Icon(Icons.alternate_email, color: yellow, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildGridBackground() {
    return Opacity(
      opacity: 0.03,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/grid.png"),
            repeat: ImageRepeat.repeat,
          ),
        ),
      ),
    );
  }
}
