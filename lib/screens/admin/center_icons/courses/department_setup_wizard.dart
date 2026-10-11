import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/services/admin_services.dart';

class DepartmentSetupWizard extends StatefulWidget {
  final int departmentId;
  final String departmentName;
  final VoidCallback onFinished;

  const DepartmentSetupWizard({
    super.key,
    required this.departmentId,
    required this.departmentName,
    required this.onFinished,
  });

  @override
  State<DepartmentSetupWizard> createState() => _DepartmentSetupWizardState();
}

enum WizardScreen {
  mainChoice,
  hodSubChoice,
  hodCreateNew,
  hodAssignExisting,
  coursesSubChoice,
  coursesCreateNew,
  coursesAssignExisting,
}

class _DepartmentSetupWizardState extends State<DepartmentSetupWizard> {
  bool get isAr => AppSettings.language.value == 'ar';

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  WizardScreen _currentScreen = WizardScreen.mainChoice;
  bool _isLoading = false;

  bool _hodCompleted = false;
  bool _coursesCompleted = false;

  // Existing Teachers Data
  List<dynamic> _teachers = [];
  int? _selectedTeacherId;

  // Existing Programs Data
  List<dynamic> _programs = [];
  final List<int> _selectedProgramIds = [];

  // Controllers for New HOD Form
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // Controllers for New Course Form
  final _courseTitleCtrl = TextEditingController();
  final _courseDescCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    _loadInitialData();
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _courseTitleCtrl.dispose();
    _courseDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final hodData = await AdminServices().getAssignHodData();
      if (hodData != null) {
        _teachers = hodData['teachers'] ?? [];
      }

      final subjectsData = await AdminServices().getSemestersSubjects();
      if (subjectsData != null) {
        _programs = subjectsData['programs'] ?? [];
      }
    } catch (e) {
      debugPrint("Error loading wizard data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onHodStepDone() {
    _hodCompleted = true;
    if (!_coursesCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم تعيين رئيس القسم بنجاح! الانتقال إجباري لتخصيص الدورات...' : 'Head of Department assigned successfully! Redirecting to allocate courses...'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() => _currentScreen = WizardScreen.coursesSubChoice);
    } else {
      _finishWizard();
    }
  }

  void _onCoursesStepDone() {
    _coursesCompleted = true;
    if (!_hodCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم إعداد الدورات بنجاح! الانتقال إجباري لتعيين رئيس القسم...' : 'Courses setup successfully! Redirecting to assign Head of Department...'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() => _currentScreen = WizardScreen.hodSubChoice);
    } else {
      _finishWizard();
    }
  }

  void _finishWizard() {
    widget.onFinished();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isAr ? 'تهانينا! تم إكمال جميع خطوات تأسيس قسم "${widget.departmentName}" بنجاح! 🎉' : 'Congratulations! All setup steps for department "${widget.departmentName}" completed successfully! 🎉'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  // Submit Actions
  Future<void> _submitNewHod() async {
    if (_firstNameCtrl.text.trim().isEmpty ||
        _lastNameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _usernameCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'يرجى تعبئة جميع الحقول المطلوبة' : 'Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await AdminServices().assignHodNew({
        'department_id': widget.departmentId,
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? '0000000' : _phoneCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'password': _passwordCtrl.text.trim(),
        'password_confirmation': _passwordCtrl.text.trim(),
      });

      if (success) {
        _onHodStepDone();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isAr ? 'فشل إنشاء حساب رئيس القسم' : 'Failed to create Head of Department account'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'خطأ: $e' : 'Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitExistingHod() async {
    if (_selectedTeacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'يرجى اختيار أستاذ من القائمة' : 'Please select a teacher from the list')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await AdminServices().assignHodExisting(
        widget.departmentId,
        _selectedTeacherId!,
      );

      if (success) {
        _onHodStepDone();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isAr ? 'فشل تخصيص رئيس القسم' : 'Failed to assign Head of Department'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'خطأ: $e' : 'Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitNewCourse() async {
    if (_courseTitleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'يرجى إدخال اسم الدورة' : 'Please enter course title')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await AdminServices().createCourse({
        'title': _courseTitleCtrl.text.trim(),
        'description': _courseDescCtrl.text.trim(),
        'department_id': widget.departmentId,
      });

      if (success) {
        _onCoursesStepDone();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isAr ? 'فشل إضافة الدورة الجديدة' : 'Failed to add new course'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'خطأ: $e' : 'Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitAssignCourses() async {
    if (_selectedProgramIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'يرجى اختيار دورة واحدة على الأقل' : 'Please select at least one course')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await AdminServices().assignProgramsToDepartment(
        widget.departmentId,
        _selectedProgramIds,
      );

      if (success) {
        _onCoursesStepDone();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isAr ? 'فشل تخصيص الدورات للقسم' : 'Failed to allocate courses to department'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'خطأ: $e' : 'Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onCourseToggled(bool? checked, dynamic program) async {
    final programId = program['id'] as int;
    final currentDept = program['department_name'] as String?;
    final currentDeptClean = currentDept?.trim();
    final hasRealDept = currentDeptClean != null &&
        currentDeptClean.isNotEmpty &&
        currentDeptClean != 'غير مخصصة (دورة مستقلة)' &&
        currentDeptClean != 'غير مخصص' &&
        currentDeptClean != 'عام';

    if (checked == true) {
      if (hasRealDept && currentDeptClean != widget.departmentName.trim()) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? 'تنبيه نقل دورة' : 'Course Transfer Warning',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              content: Text(
                isAr
                    ? 'الدورة "${program['name']}" مخصصة حالياً لقسم "$currentDept".\n\nهل تريد إلغاء تخصيصها ونقلها بالكامل لقسمك الجديد "${widget.departmentName}"؟'
                    : 'Course "${program['name']}" is currently assigned to "$currentDept".\n\nDo you want to transfer it completely to your new department "${widget.departmentName}"?',
                style: const TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(isAr ? 'تأكيد النقل' : 'Confirm Transfer'),
                ),
              ],
            ),
          ),
        );

        if (confirm != true) return;
      }

      setState(() => _selectedProgramIds.add(programId));
    } else {
      setState(() => _selectedProgramIds.remove(programId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryYellow = const Color(0xFFFFCC00);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: isDark ? const Color(0xFF181B20) : Colors.white,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(22.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Icon
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 38),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isAr ? "تم إنشاء القسم بنجاح! 🎉" : "Department Created Successfully! 🎉",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAr ? "القسم: ${widget.departmentName}" : "Department: ${widget.departmentName}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),

                      // Build Active Screen
                      _buildActiveScreenBody(isDark, primaryYellow),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildActiveScreenBody(bool isDark, Color primaryYellow) {
    switch (_currentScreen) {
      case WizardScreen.mainChoice:
        return _buildMainChoiceScreen(isDark, primaryYellow);
      case WizardScreen.hodSubChoice:
        return _buildHodSubChoiceScreen(isDark, primaryYellow);
      case WizardScreen.hodCreateNew:
        return _buildHodCreateNewScreen(isDark, primaryYellow);
      case WizardScreen.hodAssignExisting:
        return _buildHodAssignExistingScreen(isDark, primaryYellow);
      case WizardScreen.coursesSubChoice:
        return _buildCoursesSubChoiceScreen(isDark, primaryYellow);
      case WizardScreen.coursesCreateNew:
        return _buildCoursesCreateNewScreen(isDark, primaryYellow);
      case WizardScreen.coursesAssignExisting:
        return _buildCoursesAssignExistingScreen(isDark, primaryYellow);
    }
  }

  // 1. MAIN CHOICE SCREEN
  Widget _buildMainChoiceScreen(bool isDark, Color primaryYellow) {
    return Column(
      children: [
        Text(
          isAr ? "ماذا تريد أن تفعل الآن للقسم الجديد؟" : "What would you like to do next for the new department?",
          style: const TextStyle(fontSize: 13, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // HOD Option
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _currentScreen = WizardScreen.hodSubChoice),
            icon: Icon(
              _hodCompleted ? Icons.check_circle : Icons.person_add_alt_1,
              color: Colors.black,
              size: 20,
            ),
            label: Text(
              _hodCompleted
                  ? (isAr ? "تعديل رئيس القسم (مكتمل)" : "Edit Department Head (Done)")
                  : (isAr ? "تخصيص رئيس للقسم" : "Assign Head of Department"),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _hodCompleted ? const Color(0xFF10B981) : primaryYellow,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Courses Option
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _currentScreen = WizardScreen.coursesSubChoice),
            icon: Icon(
              _coursesCompleted ? Icons.check_circle : Icons.add_circle_outline,
              color: Colors.black,
              size: 20,
            ),
            label: Text(
              _coursesCompleted
                  ? (isAr ? "إدارة دورات القسم (مكتمل)" : "Manage Department Courses (Done)")
                  : (isAr ? "إضافة/تخصيص دورات للقسم" : "Add/Assign Courses to Department"),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _coursesCompleted ? const Color(0xFF10B981) : primaryYellow,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        TextButton(
          onPressed: () {
            widget.onFinished();
            Navigator.pop(context);
          },
          child: Text(isAr ? "إلغاء / تخطي" : "Cancel / Skip", style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
      ],
    );
  }

  // 2. HOD SUB-CHOICE SCREEN
  Widget _buildHodSubChoiceScreen(bool isDark, Color primaryYellow) {
    return Column(
      children: [
        Text(
          isAr ? "إشراف رئيس القسم: اختر الآلية المناسبة" : "Department Head Supervision: Choose method",
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Create New HOD
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _currentScreen = WizardScreen.hodCreateNew),
            icon: const Icon(Icons.person_add, color: Colors.black, size: 18),
            label: Text(
              isAr ? "إنشاء حساب رئيس قسم جديد (إضافة)" : "Create New Department Head Account",
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryYellow,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Assign Existing Teacher
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _currentScreen = WizardScreen.hodAssignExisting),
            icon: const Icon(Icons.group, size: 18),
            label: Text(
              isAr ? "تخصيص شخص موجود في النظام" : "Assign an Existing Teacher",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        TextButton(
          onPressed: () => setState(() => _currentScreen = WizardScreen.mainChoice),
          child: Text(isAr ? "رجوع للخيارات" : "Back to Options", style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ),
      ],
    );
  }

  // 3. HOD CREATE NEW FORM
  Widget _buildHodCreateNewScreen(bool isDark, Color primaryYellow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? "إضافة رئيس قسم جديد وتخصيصه فوراً:" : "Add new Department Head and assign immediately:",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildTextField(_firstNameCtrl, isAr ? "الاسم الأول" : "First Name", isDark)),
            const SizedBox(width: 8),
            Expanded(child: _buildTextField(_lastNameCtrl, isAr ? "اسم العائلة" : "Last Name", isDark)),
          ],
        ),
        const SizedBox(height: 8),
        _buildTextField(_emailCtrl, isAr ? "البريد الإلكتروني" : "Email", isDark, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 8),
        _buildTextField(_phoneCtrl, isAr ? "رقم الهاتف" : "Phone Number", isDark, keyboardType: TextInputType.phone),
        const SizedBox(height: 8),
        _buildTextField(_usernameCtrl, isAr ? "اسم المستخدم" : "Username", isDark),
        const SizedBox(height: 8),
        _buildTextField(_passwordCtrl, isAr ? "كلمة المرور" : "Password", isDark, isPassword: true),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _currentScreen = WizardScreen.hodSubChoice),
              child: Text(isAr ? "رجوع" : "Back", style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _submitNewHod,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryYellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isAr ? "إنهاء وتعيين" : "Finish & Assign", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  // 4. HOD ASSIGN EXISTING FORM
  Widget _buildHodAssignExistingScreen(bool isDark, Color primaryYellow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? "اختر أستاذ من النظام ليكون رئيساً للقسم:" : "Select teacher from system as Department Head:",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: _teachers.isEmpty
              ? Center(child: Text(isAr ? "لا يوجد أساتذة متاحيين" : "No available teachers"))
              : ListView.builder(
                  itemCount: _teachers.length,
                  itemBuilder: (context, index) {
                    final teacher = _teachers[index];
                    final isSelected = _selectedTeacherId == teacher['user_id'];
                    final deptName = teacher['department'] ?? (isAr ? 'غير مخصص' : 'Unassigned');
                    return ListTile(
                      dense: true,
                      onTap: () => setState(() => _selectedTeacherId = teacher['user_id']),
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: isSelected ? const Color(0xFF10B981) : Colors.grey.shade400,
                        child: Icon(Icons.person, size: 16, color: isSelected ? Colors.white : Colors.black),
                      ),
                      title: Text(teacher['full_name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        isAr ? 'القسم الحالي: $deptName' : 'Current Dept: $deptName',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF10B981)) : null,
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _currentScreen = WizardScreen.hodSubChoice),
              child: Text(isAr ? "رجوع" : "Back", style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _submitExistingHod,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryYellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isAr ? "تأكيد التخصيص" : "Confirm Assignment", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  // 5. COURSES SUB-CHOICE SCREEN
  Widget _buildCoursesSubChoiceScreen(bool isDark, Color primaryYellow) {
    return Column(
      children: [
        Text(
          isAr ? "إعداد الدورات والبرامج: اختر الإجراء المناسب" : "Courses & Programs Setup: Choose Action",
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Create New Course
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _currentScreen = WizardScreen.coursesCreateNew),
            icon: const Icon(Icons.add_circle, color: Colors.black, size: 18),
            label: Text(
              isAr ? "إنشاء دورة جديدة للقسم" : "Create New Course for Department",
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryYellow,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Assign Existing Courses
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _currentScreen = WizardScreen.coursesAssignExisting),
            icon: const Icon(Icons.category, size: 18),
            label: Text(
              isAr ? "تخصيص دورات موجودة في النظام" : "Assign Existing Courses from System",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        TextButton(
          onPressed: () => setState(() => _currentScreen = WizardScreen.mainChoice),
          child: Text(isAr ? "رجوع للخيارات" : "Back to Options", style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ),
      ],
    );
  }

  // 6. COURSES CREATE NEW FORM
  Widget _buildCoursesCreateNewScreen(bool isDark, Color primaryYellow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? "إضافة دورة جديدة مخصصة لهذا القسم:" : "Add new course dedicated to this department:",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildTextField(_courseTitleCtrl, isAr ? "اسم الدورة" : "Course Title", isDark),
        const SizedBox(height: 8),
        _buildTextField(_courseDescCtrl, isAr ? "وصف الدورة" : "Course Description", isDark, maxLines: 2),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _currentScreen = WizardScreen.coursesSubChoice),
              child: Text(isAr ? "رجوع" : "Back", style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _submitNewCourse,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryYellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isAr ? "حفظ الدورة" : "Save Course", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  // 7. COURSES ASSIGN EXISTING FORM
  Widget _buildCoursesAssignExistingScreen(bool isDark, Color primaryYellow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? "اختر الدورات من النظام لنقلها/تخصيصها لهذا القسم:" : "Select courses from system to transfer/assign to this department:",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: _programs.isEmpty
              ? Center(child: Text(isAr ? "لا توجد دورات مضافة للنظام" : "No courses added in system"))
              : ListView.builder(
                  itemCount: _programs.length,
                  itemBuilder: (context, index) {
                    final program = _programs[index];
                    final programId = program['id'] as int;
                    final isChecked = _selectedProgramIds.contains(programId);
                    final currentDept = program['department_name'] as String? ?? (isAr ? 'غير مخصص' : 'Unassigned');

                    return CheckboxListTile(
                      dense: true,
                      value: isChecked,
                      onChanged: (val) => _onCourseToggled(val, program),
                      activeColor: const Color(0xFF10B981),
                      title: Text(program['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        isAr ? 'القسم الحالي: $currentDept' : 'Current Dept: $currentDept',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _currentScreen = WizardScreen.coursesSubChoice),
              child: Text(isAr ? "رجوع" : "Back", style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _submitAssignCourses,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryYellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isAr ? "تأكيد النقل والتخصيص" : "Confirm Transfer & Assignment", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool isDark, {
    int maxLines = 1,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
      ),
    );
  }
}
