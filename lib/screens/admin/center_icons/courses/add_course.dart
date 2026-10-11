import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/services/admin_services.dart';

class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  bool get isAr => AppSettings.language.value == 'ar';

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  List<dynamic> departments = [];
  List<dynamic> semesters = [];
  List<dynamic> teachers = [];

  String? selectedDepartmentName;
  int? selectedSemesterId;
  int? selectedTeacherId;
  String selectedLevel = "السنة الأولى";

  final List<String> levels = [
    "السنة الأولى",
    "السنة الثانية",
  ];

  bool isLoading = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    _loadMetadata();
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  String _getLevelLabel(String lvl) {
    if (!isAr) {
      if (lvl == "السنة الأولى") return "First Year";
      if (lvl == "السنة الثانية") return "Second Year";
    }
    return lvl;
  }

  Future<void> _loadMetadata() async {
    setState(() => isLoading = true);
    try {
      final deptsData = await AdminServices().getDepartments();
      if (deptsData != null) {
        departments = deptsData;
      }

      final semsData = await AdminServices().getSemesters();
      if (semsData != null) {
        semesters = semsData;
      }

      final usersData = await AdminServices().getUsers();
      if (usersData != null) {
        teachers = usersData.where((u) => u['role_id'] == 2 || u['role']?['name'] == 'teacher').toList();
      }
    } catch (e) {
      debugPrint("Error loading metadata: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _onSubmit() async {
    final title = nameController.text.trim();
    final desc = descriptionController.text.trim();

    if (title.isEmpty) {
      _showSnackBar(isAr ? "يرجى إدخال اسم الدورة/المادة" : "Please enter course / subject name");
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final data = {
        'title': title,
        'description': desc.isEmpty ? null : desc,
        'level': selectedLevel,
        'semester_id': selectedSemesterId,
      };

      if (selectedTeacherId != null) {
        final selectedTeacher = teachers.firstWhere((t) => t['user_id'] == selectedTeacherId, orElse: () => null);
        if (selectedTeacher != null && selectedTeacher['teacher'] != null) {
          final teacherId = selectedTeacher['teacher']['teacher_id'];
          data['teacher_ids'] = [teacherId];
        }
      }

      final success = await AdminServices().createCourse(data);
      if (success) {
        if (mounted) {
          _showSnackBar(isAr ? "تمت إضافة الدورة بنجاح" : "Course added successfully", isError: false);
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          _showSnackBar(isAr ? "فشل إضافة الدورة" : "Failed to add course");
        }
      }
    } catch (e) {
      debugPrint("Error creating course: $e");
      if (mounted) {
        _showSnackBar(isAr ? "حدث خطأ أثناء إضافة الدورة" : "An error occurred while adding course");
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
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
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(isAr ? "إضافة دورة جديدة" : "Add New Course", style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(isAr ? Icons.arrow_forward : Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : isSubmitting
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(isAr ? "اسم المادة / الدورة (إجباري)" : "Subject / Course Name (Required)", textColor),
                        _buildTextField(
                          controller: nameController,
                          hint: isAr ? "مثال: البرمجة غرضية التوجه" : "e.g. Object-Oriented Programming",
                          icon: Icons.edit,
                          cardColor: cardColor,
                        ),
                        const SizedBox(height: 20),

                        _buildLabel(isAr ? "السنة الأكاديمية" : "Academic Year", textColor),
                        _buildDropdownField(levels, selectedLevel, (val) => setState(() => selectedLevel = val!), cardColor, textColor, labelMapper: _getLevelLabel),
                        const SizedBox(height: 20),

                        _buildLabel(isAr ? "الفصل الدراسي" : "Semester", textColor),
                        _buildSemesterDropdown(cardColor, textColor),
                        const SizedBox(height: 20),

                        _buildLabel(isAr ? "مدرس المادة" : "Course Teacher", textColor),
                        _buildTeacherDropdown(cardColor, textColor),
                        const SizedBox(height: 20),

                        _buildLabel(isAr ? "وصف الدورة" : "Course Description", textColor),
                        _buildTextField(
                          controller: descriptionController,
                          hint: isAr ? "اكتب وصفاً محتوياً على المنهج الدراسي والأهداف..." : "Write a description including curriculum and goals...",
                          maxLines: 4,
                          icon: Icons.description,
                          cardColor: cardColor,
                        ),
                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _onSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryYellow,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isAr ? "إضافة الدورة" : "Add Course",
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.add, color: Colors.black),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildLabel(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 5, left: 5),
      child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    IconData? icon,
    required Color cardColor,
  }) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          suffixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
    Color cardColor,
    Color textColor, {
    String Function(String)? labelMapper,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: cardColor,
          style: TextStyle(color: textColor, fontFamily: 'Cairo'),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(labelMapper != null ? labelMapper(e) : e),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSemesterDropdown(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedSemesterId,
          hint: Text(isAr ? "اختر الفصل الدراسي للربط" : "Select semester to link"),
          isExpanded: true,
          dropdownColor: cardColor,
          style: TextStyle(color: textColor, fontFamily: 'Cairo'),
          items: semesters.map((e) {
            final activeLabel = (e['is_active'] == 1 || e['is_active'] == true)
                ? (isAr ? ' (نشط)' : ' (Active)')
                : '';
            return DropdownMenuItem<int>(
              value: e['semester_id'],
              child: Text("${e['name']}$activeLabel"),
            );
          }).toList(),
          onChanged: (v) => setState(() => selectedSemesterId = v),
        ),
      ),
    );
  }

  Widget _buildTeacherDropdown(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedTeacherId,
          hint: Text(isAr ? "تعيين مدرس للدورة" : "Assign teacher to course"),
          isExpanded: true,
          dropdownColor: cardColor,
          style: TextStyle(color: textColor, fontFamily: 'Cairo'),
          items: teachers.map((e) {
            return DropdownMenuItem<int>(
              value: e['user_id'],
              child: Text(e['full_name'] ?? ''),
            );
          }).toList(),
          onChanged: (v) => setState(() => selectedTeacherId = v),
        ),
      ),
    );
  }
}