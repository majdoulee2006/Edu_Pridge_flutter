import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/widgets/admin_speed_dial.dart';
import 'package:edu_pridge_flutter/services/admin_services.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

// استيراد شاشات الشريط السفلي
import 'package:edu_pridge_flutter/screens/admin/nav_bar/home_screen.dart';
import 'package:edu_pridge_flutter/screens/admin/nav_bar/profile_screen.dart';
import 'package:edu_pridge_flutter/screens/admin/nav_bar/notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/admin/nav_bar/messages_screen.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  // 🌟 الأقسام الأربعة المطلوبة بالتحديد 🌟
  final List<String> departments = [
    "جميع الأقسام",
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

  final List<String> academicYears = ["جميع السنوات", "سنة اولى", "سنة تانية"];
  final List<String> formYears = ["سنة اولى", "سنة تانية"];
  final List<String> formSemesters = ["فصل أول", "فصل ثاني"];

  String selectedDept = "جميع الأقسام";
  String selectedYear = "جميع السنوات";
  String? selectedProgramName;
  int? selectedProgramId;
  int selectedSemesterIndex = 0; // 0 = الكل، 1 = فصل أول، 2 = فصل ثاني

  List<dynamic> allDepartmentsApi = [];
  List<dynamic> allProgramsApi = [];
  List<dynamic> filteredPrograms = [];
  List<dynamic> coursesList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    int? deptId;
    if (selectedDept != "جميع الأقسام" && allDepartmentsApi.isNotEmpty) {
      final deptObj = allDepartmentsApi.firstWhere(
        (d) => d['name'].toString().trim().contains(selectedDept) || selectedDept.contains(d['name'].toString().trim()),
        orElse: () => null,
      );
      if (deptObj != null) {
        deptId = deptObj['department_id'];
      }
    }

    String? yearParam;
    if (selectedYear == "سنة اولى") yearParam = "1";
    if (selectedYear == "سنة تانية") yearParam = "2";

    int? semParam;
    if (selectedSemesterIndex == 1) semParam = 1;
    if (selectedSemesterIndex == 2) semParam = 2;

    final data = await AdminServices().getSemestersSubjects(
      departmentId: deptId,
      programId: selectedProgramId,
      year: yearParam,
      semesterId: semParam,
    );

    if (data != null) {
      setState(() {
        allDepartmentsApi = data['departments'] ?? [];
        allProgramsApi = data['programs'] ?? [];
        coursesList = data['courses'] ?? [];
        _updateFilteredPrograms(deptId);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  void _updateFilteredPrograms(int? deptId) {
    if (deptId == null) {
      filteredPrograms = allProgramsApi;
    } else {
      filteredPrograms = allProgramsApi.where((p) => p['department_id'] == deptId).toList();
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

  Future<void> _downloadFile(String fileUrl, String fileName) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("جاري تحميل $fileName...")),
      );

      final fullUrl = ApiService.fixMediaUrl(fileUrl) ?? fileUrl;
      final dir = await getApplicationDocumentsDirectory();
      final savePath = "${dir.path}/$fileName";

      final dio = Dio();
      await dio.download(fullUrl, savePath);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم التحميل بنجاح")),
      );
      OpenFilex.open(savePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("فشل تحميل الملف: $e")),
      );
    }
  }

  void _showAddSubjectModal(BuildContext context, bool isDark, Color primaryYellow) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final hoursController = TextEditingController();

    String modalDept = formDepartments.first;
    String modalYear = formYears.first;
    String modalSemester = formSemesters.first;
    String? modalProgramName;
    int? modalProgramId;
    bool isSaving = false;

    List<dynamic> modalFilteredPrograms = [];

    void updateModalPrograms(StateSetter setModalState, String deptName) {
      final deptObj = allDepartmentsApi.firstWhere(
        (d) => d['name'].toString().trim().contains(deptName) || deptName.contains(d['name'].toString().trim()),
        orElse: () => null,
      );
      int? dId = deptObj != null ? deptObj['department_id'] : null;
      setModalState(() {
        if (dId != null) {
          modalFilteredPrograms = allProgramsApi.where((p) => p['department_id'] == dId).toList();
        } else {
          modalFilteredPrograms = allProgramsApi;
        }
        if (modalFilteredPrograms.isNotEmpty) {
          modalProgramName = modalFilteredPrograms.first['name'].toString();
          modalProgramId = modalFilteredPrograms.first['id'];
        } else {
          modalProgramName = null;
          modalProgramId = null;
        }
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (modalFilteredPrograms.isEmpty && allProgramsApi.isNotEmpty) {
              updateModalPrograms(setModalState, modalDept);
            }

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
                              "إضافة مادة جديدة",
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
                            _buildLabel("اسم المادة", isDark ? Colors.white : Colors.black),
                            TextField(
                              controller: titleController,
                              decoration: InputDecoration(
                                hintText: "أدخل اسم المادة (مثال: برمجيات 1)",
                                filled: true,
                                fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 15),

                            _buildLabel("وصف المادة", isDark ? Colors.white : Colors.black),
                            TextField(
                              controller: descriptionController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: "أدخل وصف مختصر للمادة",
                                filled: true,
                                fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 15),

                            _buildLabel("عدد الساعات المخصصة", isDark ? Colors.white : Colors.black),
                            TextField(
                              controller: hoursController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "مثال: 30",
                                filled: true,
                                fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 15),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel("القسم", isDark ? Colors.white : Colors.black),
                                      _buildDropdown(
                                        hint: "اختر القسم",
                                        value: modalDept,
                                        items: formDepartments,
                                        onChanged: (val) {
                                          if (val != null) {
                                            modalDept = val;
                                            updateModalPrograms(setModalState, modalDept);
                                          }
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
                                      _buildLabel("الدورة", isDark ? Colors.white : Colors.black),
                                      _buildDropdown(
                                        hint: "اختر الدورة",
                                        value: modalProgramName,
                                        items: modalFilteredPrograms.map((p) => p['name'].toString()).toList(),
                                        onChanged: (val) {
                                          setModalState(() {
                                            modalProgramName = val;
                                            final progObj = modalFilteredPrograms.firstWhere((p) => p['name'].toString() == val, orElse: () => null);
                                            modalProgramId = progObj != null ? progObj['id'] : null;
                                          });
                                        },
                                        isDark: isDark,
                                        cardColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                                  const SnackBar(content: Text("يرجى إدخال اسم المادة")),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);
                              try {
                                final yearVal = modalYear == "سنة اولى" ? "1" : "2";
                                final semVal = modalSemester == "فصل أول" ? 1 : 2;

                                final success = await AdminServices().createCourse({
                                  "title": titleController.text.trim(),
                                  "description": descriptionController.text.trim(),
                                  "hours": hoursController.text.trim(),
                                  "year": yearVal,
                                  "semester_id": semVal,
                                  "program_id": modalProgramId,
                                });

                                if (success) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("تم إضافة المادة الجديدة بنجاح")),
                                  );
                                  _loadData();
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("حدث خطأ أثناء إضافة المادة: $e")),
                                );
                              } finally {
                                setModalState(() => isSaving = false);
                              }
                            },
                      icon: isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.check, color: Colors.black),
                      label: Text(
                        isSaving ? "جاري الحفظ..." : "إضافة المادة وحفظها",
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

  void _showCourseDetailsModal(BuildContext context, Map<String, dynamic> course, bool isDark, Color primaryYellow) {
    final lessons = (course['lessons_list'] as List<dynamic>?) ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(20),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: primaryYellow.withValues(alpha: 0.2),
                      child: const Icon(Icons.book, color: Colors.black),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course['title'] ?? 'بدون عنوان',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            "المعلم: ${course['teacher_name'] ?? 'غير معين'} • ${course['semester_name'] ?? ''}",
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(height: 25),
                Text(
                  "المحاضرات والملفات المرفوعة (${lessons.length})",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: lessons.isEmpty
                      ? const Center(child: Text("لا توجد محاضرات مرفوعة لهذه المادة"))
                      : ListView.builder(
                          itemCount: lessons.length,
                          itemBuilder: (context, index) {
                            final lesson = lessons[index];
                            final title = lesson['title'] ?? 'محاضرة بدون عنوان';
                            final fileUrl = lesson['file_path'] ?? lesson['content_url'] ?? '';
                            final fileName = lesson['file_name'] ?? 'ملف_$index';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                                    child: const Icon(Icons.picture_as_pdf, color: Colors.blue),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        if (lesson['description'] != null)
                                          Text(
                                            lesson['description'],
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (fileUrl.toString().isNotEmpty)
                                    IconButton(
                                      onPressed: () => _downloadFile(fileUrl, fileName),
                                      icon: const Icon(Icons.download_rounded, color: Colors.amber),
                                      tooltip: "معاينة وتحميل",
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
          title: const Text("الفصول الدراسية والمواد", style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_forward)),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
              icon: const Icon(Icons.settings_outlined),
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
                    // ─── حاوية الفلاتر ───
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 10)],
                      ),
                      child: Column(
                        children: [
                          _buildLabel("القسم", textColor),
                          _buildDropdown(
                            hint: "اختر القسم",
                            value: selectedDept,
                            items: departments,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedDept = val;
                                  selectedProgramName = null;
                                  selectedProgramId = null;
                                });
                                _loadData();
                              }
                            },
                            isDark: isDark,
                            cardColor: cardColor,
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("السنة", textColor),
                                    _buildDropdown(
                                      hint: "اختر السنة",
                                      value: selectedYear,
                                      items: academicYears,
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => selectedYear = val);
                                          _loadData();
                                        }
                                      },
                                      isDark: isDark,
                                      cardColor: cardColor,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("الدورة", textColor),
                                    _buildDropdown(
                                      hint: "اختر الدورة",
                                      value: selectedProgramName,
                                      items: filteredPrograms.map((p) => p['name'].toString()).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          selectedProgramName = val;
                                          if (val != null) {
                                            final progObj = filteredPrograms.firstWhere((p) => p['name'].toString() == val, orElse: () => null);
                                            selectedProgramId = progObj != null ? progObj['id'] : null;
                                          } else {
                                            selectedProgramId = null;
                                          }
                                        });
                                        _loadData();
                                      },
                                      isDark: isDark,
                                      cardColor: cardColor,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ─── تبديل الفصول ───
                    Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          _buildSemesterTab("جميع الفصول", 0, primaryYellow),
                          _buildSemesterTab("فصل أول", 1, primaryYellow),
                          _buildSemesterTab("فصل ثاني", 2, primaryYellow),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("المواد الدراسية", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        Text("${coursesList.length} مادة", style: TextStyle(color: Colors.blue.shade400, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),

                    const SizedBox(height: 15),

                    if (isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
                    else if (coursesList.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(30), child: Text("لا توجد مواد مطابقة للفلتر المحدد")))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: coursesList.length,
                        itemBuilder: (context, index) {
                          final course = Map<String, dynamic>.from(coursesList[index]);
                          final title = course['title'] ?? 'مادة بدون عنوان';
                          final teacher = course['teacher_name'] ?? 'لم يتم تعيين معلم';
                          final lessonsCount = (course['lessons_list'] as List<dynamic>?)?.length ?? 0;

                          return GestureDetector(
                            onTap: () => _showCourseDetailsModal(context, course, isDark, primaryYellow),
                            child: Container(
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
                                  const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.grey),
                                  const Spacer(),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(teacher, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                          const SizedBox(width: 5),
                                          const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "$lessonsCount محاضرة مرفوعة",
                                        style: TextStyle(color: primaryYellow, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 15),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: primaryYellow.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Icon(Icons.book_outlined, color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            // 🌟 زر الزائد (+) العائم في أسفل اليسار لإضافة مادة جديدة 🌟
            Positioned(
              bottom: 100,
              left: 20,
              child: GestureDetector(
                onTap: () => _showAddSubjectModal(context, isDark, primaryYellow),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: primaryYellow,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.black, size: 30),
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

  Widget _buildSemesterTab(String label, int index, Color yellow) {
    bool isSelected = selectedSemesterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedSemesterIndex = index);
          _loadData();
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? yellow : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isSelected ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}