import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/widgets/admin_speed_dial.dart';
import 'package:edu_pridge_flutter/services/admin_services.dart';
import 'package:edu_pridge_flutter/screens/admin/nav_bar/home_screen.dart';
import 'package:edu_pridge_flutter/screens/admin/nav_bar/profile_screen.dart';
import 'package:edu_pridge_flutter/screens/admin/nav_bar/notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/admin/nav_bar/messages_screen.dart';
import 'add_department_dialog.dart';
import 'department_setup_wizard.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final List<String> departments = [
    "جميع الأقسام",
    "دورات مستقلة (بدون قسم)",
    "نظم معلومات",
    "طبي",
    "هندسي",
    "تجاري"
  ];

  final List<String> formDepartments = [
    "نظم معلومات",
    "طبي",
    "هندسي",
    "تجاري"
  ];

  final List<String> formYears = ["سنة اولى", "سنة تانية"];
  final List<String> formSemesters = ["فصل أول", "فصل ثاني"];

  String selectedDept = "جميع الأقسام";
  List<dynamic> allDepartmentsApi = [];
  List<dynamic> allProgramsList = [];
  List<dynamic> filteredProgramsList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    int? deptId;
    bool isIndependent = selectedDept == "دورات مستقلة (بدون قسم)";

    if (selectedDept != "جميع الأقسام" && !isIndependent && allDepartmentsApi.isNotEmpty) {
      final deptObj = allDepartmentsApi.firstWhere(
        (d) => d['name'].toString().trim().contains(selectedDept) || selectedDept.contains(d['name'].toString().trim()),
        orElse: () => null,
      );
      if (deptObj != null) {
        deptId = deptObj['department_id'];
      }
    }

    final data = await AdminServices().getSemestersSubjects(departmentId: deptId);
    if (data != null) {
      setState(() {
        allDepartmentsApi = data['departments'] ?? [];
        allProgramsList = data['programs'] ?? [];
        _applyFilter(deptId, isIndependent);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  void _applyFilter(int? deptId, bool isIndependent) {
    if (isIndependent) {
      filteredProgramsList = allProgramsList.where((p) => p['department_id'] == null).toList();
    } else if (selectedDept == "جميع الأقسام" || deptId == null) {
      filteredProgramsList = allProgramsList;
    } else {
      filteredProgramsList = allProgramsList.where((p) => p['department_id'] == deptId).toList();
    }
  }

  void _navigateToNavScreen(int index) {
    Widget screen;
    switch (index) {
      case 0:
        screen = const AdminHomeScreen();
        break;
      case 1:
        screen = const AdminMessagesScreen();
        break;
      case 2:
        screen = const AdminNotificationsScreen();
        break;
      case 3:
        screen = const AdminProfileScreen();
        break;
      default:
        screen = const AdminHomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showAddCourseModal(BuildContext context, bool isDark, Color primaryYellow) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final modalDepartments = ["بدون قسم محدد (دورة مستقلة)", ...formDepartments];
    String modalDept = "بدون قسم محدد (دورة مستقلة)";
    String modalYear = formYears.first;
    String modalSemester = formSemesters.first;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: EdgeInsets.fromLTRB(20, 15, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.add_circle, color: primaryYellow, size: 28),
                            const SizedBox(width: 10),
                            Text(
                              "إضافة دورة جديدة",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("اسم الدورة", isDark ? Colors.white : Colors.black),
                            TextField(
                              controller: titleController,
                              decoration: InputDecoration(
                                hintText: "أدخل اسم الدورة (مثال: برمجيات الويب)",
                                filled: true,
                                fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 15),

                            _buildLabel("وصف الدورة", isDark ? Colors.white : Colors.black),
                            TextField(
                              controller: descriptionController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: "أدخل وصف مختصر للدورة",
                                filled: true,
                                fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 15),

                            _buildLabel("القسم", isDark ? Colors.white : Colors.black),
                            _buildDropdown(
                              hint: "اختر القسم",
                              value: modalDept,
                              items: modalDepartments,
                              onChanged: (val) {
                                if (val != null) setModalState(() => modalDept = val);
                              },
                              isDark: isDark,
                              cardColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                            ),
                            const SizedBox(height: 15),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel("السنة الدراسية", isDark ? Colors.white : Colors.black),
                                      _buildDropdown(
                                        hint: "اختر السنة",
                                        value: modalYear,
                                        items: formYears,
                                        onChanged: (val) {
                                          if (val != null) setModalState(() => modalYear = val);
                                        },
                                        isDark: isDark,
                                        cardColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel("الفصل الدراسي", isDark ? Colors.white : Colors.black),
                                      _buildDropdown(
                                        hint: "اختر الفصل",
                                        value: modalSemester,
                                        items: formSemesters,
                                        onChanged: (val) {
                                          if (val != null) setModalState(() => modalSemester = val);
                                        },
                                        isDark: isDark,
                                        cardColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (titleController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("يرجى إدخال اسم الدورة")),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);
                              try {
                                int? dId;
                                if (modalDept != "بدون قسم محدد (دورة مستقلة)") {
                                  final deptObj = allDepartmentsApi.firstWhere(
                                    (d) => d['name'].toString().trim().contains(modalDept) || modalDept.contains(d['name'].toString().trim()),
                                    orElse: () => null,
                                  );
                                  dId = deptObj != null ? deptObj['department_id'] : null;
                                }
                                final yearVal = modalYear == "سنة اولى" ? "1" : "2";
                                final semVal = modalSemester == "فصل أول" ? 1 : 2;

                                final success = await AdminServices().createCourse({
                                  "title": titleController.text.trim(),
                                  "description": descriptionController.text.trim(),
                                  "year": yearVal,
                                  "semester_id": semVal,
                                  "department_id": dId,
                                });

                                if (success) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("تم إضافة الدورة الجديدة بنجاح")),
                                  );
                                  _loadData();
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("حدث خطأ أثناء إضافة الدورة: $e")),
                                );
                              } finally {
                                setModalState(() => isSaving = false);
                              }
                            },
                      icon: isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.check, color: Colors.black),
                      label: Text(
                        isSaving ? "جاري الحفظ..." : "إضافة الدورة وحفظها",
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryYellow,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAssignHodModal(BuildContext context, bool isDark, Color primaryYellow) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final hodData = await AdminServices().getAssignHodData();
    Navigator.pop(context); // close loader

    if (hodData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تعذر جلب بيانات رؤساء الأقسام")),
      );
      return;
    }

    final deptList = (hodData['departments'] as List<dynamic>?) ?? [];
    final teachersList = (hodData['teachers'] as List<dynamic>?) ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.all(20),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.manage_accounts_rounded, color: primaryYellow, size: 28),
                            const SizedBox(width: 10),
                            Text(
                              "تخصيص وتنسيق رؤساء الأقسام",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: deptList.length,
                        itemBuilder: (context, index) {
                          final dept = deptList[index];
                          final deptName = dept['name'] ?? 'قسم بدون اسم';
                          final hodName = dept['current_hod_name'] ?? 'غير مخصص حالياً';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: primaryYellow.withValues(alpha: 0.2),
                                      child: const Icon(Icons.domain, color: Colors.black),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            deptName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            "رئيس القسم الحالي: $hodName",
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: hodName.contains("غير مخصص") ? Colors.redAccent : Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => _showEditHodDialog(context, dept, teachersList, isDark, primaryYellow),
                                  icon: const Icon(Icons.edit, size: 16, color: Colors.black),
                                  label: const Text("تعديل رئيس القسم", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryYellow,
                                    minimumSize: const Size(double.infinity, 42),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditHodDialog(BuildContext context, Map<String, dynamic> dept, List<dynamic> teachersList, bool isDark, Color primaryYellow) {
    int activeTab = 0; // 0 = استاذ موجود، 1 = جديد
    int? selectedTeacherId;
    String selectedHodDeptName = dept['name'] ?? formDepartments.first;

    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();

    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredTeachers = teachersList.where((t) {
              final tDept = t['department']?.toString().trim() ?? '';
              return tDept.contains(selectedHodDeptName) || selectedHodDeptName.contains(tDept);
            }).toList();

            final deptObj = allDepartmentsApi.firstWhere(
              (d) => d['name'].toString().trim().contains(selectedHodDeptName) || selectedHodDeptName.contains(d['name'].toString().trim()),
              orElse: () => dept,
            );
            final currentDeptId = deptObj['department_id'] ?? dept['department_id'];

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: EdgeInsets.fromLTRB(20, 15, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "تعديل رئيس قسم: $selectedHodDeptName",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // ─── تبديل الخيارين ───
                    Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => activeTab = 0),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: activeTab == 0 ? primaryYellow : Colors.transparent,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Text(
                                  "استاذ موجود بالمؤسسة",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: activeTab == 0 ? Colors.black : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => activeTab = 1),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: activeTab == 1 ? primaryYellow : Colors.transparent,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Text(
                                  "إضافة رئيس قسم جديد",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: activeTab == 1 ? Colors.black : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    Expanded(
                      child: SingleChildScrollView(
                        child: activeTab == 0
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("اختر القسم المراد تخصيصه", isDark ? Colors.white : Colors.black),
                                  const SizedBox(height: 5),
                                  _buildDropdown(
                                    hint: "اختر القسم",
                                    value: selectedHodDeptName,
                                    items: formDepartments,
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() {
                                          selectedHodDeptName = val;
                                          selectedTeacherId = null;
                                        });
                                      }
                                    },
                                    isDark: isDark,
                                    cardColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                                  ),
                                  const SizedBox(height: 15),

                                  _buildLabel("اختر المعلم المراد تعيينه (أساتذة $selectedHodDeptName)", isDark ? Colors.white : Colors.black),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 15),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white10 : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<int>(
                                        value: selectedTeacherId,
                                        hint: Text(
                                          filteredTeachers.isEmpty
                                              ? "لا يوجد أساتذة مخصصين لقسم $selectedHodDeptName"
                                              : "اختر من أساتذة قسم $selectedHodDeptName",
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        isExpanded: true,
                                        dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                                        items: (filteredTeachers.isNotEmpty ? filteredTeachers : teachersList).map((t) {
                                          final deptLabel = t['department'] != null ? " (${t['department']})" : "";
                                          return DropdownMenuItem<int>(
                                            value: t['user_id'],
                                            child: Text("${t['full_name'] ?? 'بدون اسم'}$deptLabel", style: const TextStyle(fontSize: 13)),
                                          );
                                        }).toList(),
                                        onChanged: (val) => setModalState(() => selectedTeacherId = val),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("القسم المراد تخصيصه", isDark ? Colors.white : Colors.black),
                                  const SizedBox(height: 5),
                                  _buildDropdown(
                                    hint: "اختر القسم",
                                    value: selectedHodDeptName,
                                    items: formDepartments,
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() => selectedHodDeptName = val);
                                      }
                                    },
                                    isDark: isDark,
                                    cardColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                                  ),
                                  const SizedBox(height: 15),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildLabel("الاسم الأول", isDark ? Colors.white : Colors.black),
                                            TextField(
                                              controller: firstNameCtrl,
                                              decoration: InputDecoration(
                                                hintText: "الاسم الأول",
                                                filled: true,
                                                fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildLabel("الاسم الثاني", isDark ? Colors.white : Colors.black),
                                            TextField(
                                              controller: lastNameCtrl,
                                              decoration: InputDecoration(
                                                hintText: "اسم العائلة",
                                                filled: true,
                                                fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildLabel("البريد الإلكتروني", isDark ? Colors.white : Colors.black),
                                  TextField(
                                    controller: emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      hintText: "example@domain.com",
                                      filled: true,
                                      fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildLabel("اسم المستخدم", isDark ? Colors.white : Colors.black),
                                  TextField(
                                    controller: usernameCtrl,
                                    decoration: InputDecoration(
                                      hintText: "username",
                                      filled: true,
                                      fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildLabel("رقم الهاتف", isDark ? Colors.white : Colors.black),
                                  TextField(
                                    controller: phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      hintText: "09xxxxxxxx",
                                      filled: true,
                                      fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildLabel("كلمة المرور", isDark ? Colors.white : Colors.black),
                                  TextField(
                                    controller: passwordCtrl,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      hintText: "******",
                                      filled: true,
                                      fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildLabel("تأكيد كلمة المرور", isDark ? Colors.white : Colors.black),
                                  TextField(
                                    controller: confirmPasswordCtrl,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      hintText: "******",
                                      filled: true,
                                      fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              try {
                                bool success = false;
                                if (activeTab == 0) {
                                  if (selectedTeacherId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("يرجى اختيار المعلم أولاً")),
                                    );
                                    return;
                                  }
                                  success = await AdminServices().assignHodExisting(currentDeptId, selectedTeacherId!);
                                } else {
                                  if (passwordCtrl.text != confirmPasswordCtrl.text) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("كلمتا المرور غير متطابقتين")),
                                    );
                                    return;
                                  }
                                  success = await AdminServices().assignHodNew({
                                    'department_id': currentDeptId,
                                    'first_name': firstNameCtrl.text.trim(),
                                    'last_name': lastNameCtrl.text.trim(),
                                    'email': emailCtrl.text.trim(),
                                    'username': usernameCtrl.text.trim(),
                                    'phone': phoneCtrl.text.trim(),
                                    'password': passwordCtrl.text,
                                    'password_confirmation': confirmPasswordCtrl.text,
                                  });
                                }

                                if (success) {
                                  Navigator.pop(context); // close edit sheet
                                  Navigator.pop(context); // close assign hod sheet
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("تم تعيين رئيس القسم بنجاح")),
                                  );
                                  _loadData();
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("حدث خطأ أثناء التعيين: $e")),
                                );
                              } finally {
                                setModalState(() => isSubmitting = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryYellow,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : Text(
                              activeTab == 0 ? "تعيين رئيس القسم" : "إنشاء وتعيين رئيس القسم",
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final primaryYellow = const Color(0xFFFFCC00);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            "الدورات",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: textColor),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
              icon: Icon(Icons.settings_outlined, color: textColor),
              tooltip: "الإعدادات",
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🌟 الخيارات العلوية: إضافة دورة جديدة، تخصيص رئيس قسم، وإضافة قسم جديد 🌟
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            "إضافة دورة جديدة",
                            Icons.add_circle_outline,
                            primaryYellow,
                            () => _showAddCourseModal(context, isDark, primaryYellow),
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            "تخصيص رئيس قسم",
                            Icons.manage_accounts_outlined,
                            Colors.blueAccent,
                            () => _showAssignHodModal(context, isDark, primaryYellow),
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            "إضافة قسم جديد",
                            Icons.domain_add,
                            const Color(0xFF10B981),
                            () async {
                              final result = await showDialog<dynamic>(
                                context: context,
                                builder: (_) => const AddDepartmentDialog(),
                              );
                              if (result != null && result is Map<String, dynamic>) {
                                await _loadData();
                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => DepartmentSetupWizard(
                                      departmentId: result['department_id'],
                                      departmentName: result['name'] ?? '',
                                      onFinished: () => _loadData(),
                                    ),
                                  );
                                }
                              }
                            },
                            isDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ─── فلترة الأقسام ───
                    _buildLabel("القسم", textColor),
                    _buildDropdown(
                      hint: "اختر القسم للفلترة",
                      value: selectedDept,
                      items: departments,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => selectedDept = val);
                          _loadData();
                        }
                      },
                      isDark: isDark,
                      cardColor: cardColor,
                    ),

                    const SizedBox(height: 25),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "قائمة الدورات المتاحة",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        Text(
                          "${filteredProgramsList.length} دورة",
                          style: TextStyle(color: Colors.blue.shade400, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    if (isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
                    else if (filteredProgramsList.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(30), child: Text("لا توجد دورات للقسم المحدد")))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredProgramsList.length,
                        itemBuilder: (context, index) {
                          final prog = filteredProgramsList[index];
                          final progName = prog['name'] ?? 'دورة بدون اسم';
                          final deptName = prog['department_name'] ?? 'عام';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: primaryYellow.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(Icons.school_outlined, color: Colors.black),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        progName,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "القسم: $deptName",
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            // الشريط السفلي
            CustomBottomNav(
              currentIndex: 0,
              centerButton: const AdminSpeedDial(),
              onHomeTap: () => _navigateToNavScreen(0),
              onMessagesTap: () => _navigateToNavScreen(1),
              onNotificationsTap: () => _navigateToNavScreen(2),
              onProfileTap: () => _navigateToNavScreen(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color textColor) => Padding(
        padding: const EdgeInsets.only(bottom: 5, right: 5),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
        ),
      );

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
    required Color cardColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          hint: Text(hint, style: const TextStyle(fontSize: 13)),
          isExpanded: true,
          dropdownColor: cardColor,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isDark ? color : Colors.black87, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}