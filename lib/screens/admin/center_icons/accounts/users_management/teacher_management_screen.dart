import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/admin_services.dart';

class TeacherManagementScreen extends StatefulWidget {
  final String mode; // 'create', 'delete', 'request'
  const TeacherManagementScreen({super.key, required this.mode});

  @override
  State<TeacherManagementScreen> createState() => _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends State<TeacherManagementScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String? selectedDept;
  String selectedGender = "ذكر";
  DateTime? selectedBirthDate;

  String? filterDept;
  dynamic filterProgramObj;

  List<dynamic> allPrograms = [];
  List<dynamic> allDepts = [];
  List<dynamic> programCourses = [];
  List<int> selectedCourseIds = [];
  bool isLoadingCourses = false;

  final List<String> departments = ['نظم معلومات', 'طبي', 'تجاري', 'هندسي'];

  List<dynamic> users = [];
  dynamic selectedProgramObj;
  bool isLoading = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.mode == 'delete' || widget.mode == 'request') {
      _loadUsers();
    } else {
      _loadMetadata();
    }
  }

  Future<void> _loadMetadata() async {
    setState(() => isLoading = true);
    try {
      final data = await AdminServices().getSemestersSubjects();
      if (data != null) {
        setState(() {
          allPrograms = data['programs'] ?? [];
          allDepts = data['departments'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error loading metadata: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadProgramCourses(int programId) async {
    setState(() => isLoadingCourses = true);
    try {
      int? deptId;
      if (selectedDept != null) {
        final deptObj = allDepts.firstWhere(
          (d) => d['name'].toString().trim().contains(selectedDept!) || selectedDept!.contains(d['name'].toString().trim()),
          orElse: () => null,
        );
        if (deptObj != null) {
          deptId = deptObj['department_id'];
        }
      }
      final data = await AdminServices().getSemestersSubjects(departmentId: deptId, programId: programId);
      if (data != null) {
        setState(() {
          programCourses = data['courses'] ?? [];
          selectedCourseIds.clear();
        });
      }
    } catch (e) {
      debugPrint("Error loading program courses: $e");
    } finally {
      setState(() => isLoadingCourses = false);
    }
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      if (widget.mode == 'delete') {
        final all = await AdminServices().getUsers(roleId: 2, status: 'active', all: true);
        if (all != null) {
          setState(() {
            users = all;
          });
        }
      } else if (widget.mode == 'request') {
        final pending = await AdminServices().getPendingAccounts();
        if (pending != null) {
          setState(() {
            users = pending.where((u) => u['role_id'] == 2 || u['role']?['name'] == 'teacher').toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading teachers: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1960),
      lastDate: DateTime(2010),
    );
    if (picked != null) setState(() => selectedBirthDate = picked);
  }

  Future<void> _onCreateTeacher() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final name = "$firstName $lastName".trim();
    final phone = _phoneController.text.trim();
    final emailPrefix = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || emailPrefix.isEmpty || password.isEmpty) {
      _showSnackBar("يرجى ملء الحقول الإجبارية (الاسم الأول، الكنية، البريد الإلكتروني، كلمة المرور)");
      return;
    }

    final email = "$emailPrefix@edu.com";
    final username = emailPrefix;

    setState(() => isSubmitting = true);
    try {
      final success = await AdminServices().createUser({
        'full_name': name,
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'email': email,
        'phone': phone.isEmpty ? null : phone,
        'password': password,
        'role': 'teacher',
        'department': selectedDept,
        'specialization': selectedProgramObj != null ? selectedProgramObj['name'] : (selectedDept ?? 'عام'),
        'gender': selectedGender,
        'birth_date': selectedBirthDate != null ? "${selectedBirthDate!.toLocal()}".split(' ')[0] : null,
        'course_ids': selectedCourseIds,
      });

      if (success) {
        _showSnackBar("تم تسجيل المعلم بنجاح", isError: false);
        _firstNameController.clear();
        _lastNameController.clear();
        _phoneController.clear();
        _emailController.clear();
        _passwordController.clear();
        setState(() {
          selectedDept = null;
          selectedProgramObj = null;
          selectedBirthDate = null;
          programCourses.clear();
          selectedCourseIds.clear();
        });
      } else {
        _showSnackBar("فشل إضافة المعلم");
      }
    } catch (e) {
      debugPrint("Error creating teacher: $e");
      _showSnackBar("فشل إنشاء الحساب، يرجى التحقق من المدخلات");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _onDeleteTeacher(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: const Text("هل أنت متأكد من حذف هذا المعلم؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("إلغاء")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("نعم، احذف", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isSubmitting = true);
    try {
      final success = await AdminServices().deleteUser(id);
      if (success) {
        _showSnackBar("تم حذف المعلم بنجاح", isError: false);
        _loadUsers();
      } else {
        _showSnackBar("فشل حذف المعلم");
      }
    } catch (e) {
      _showSnackBar("حدث خطأ أثناء الحذف");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _onApproveRequest(int id) async {
    setState(() => isSubmitting = true);
    try {
      final success = await AdminServices().approveAccount(id);
      if (success) {
        _showSnackBar("تم تفعيل حساب المعلم بنجاح", isError: false);
        _loadUsers();
      } else {
        _showSnackBar("فشل تفعيل الحساب");
      }
    } catch (e) {
      _showSnackBar("حدث خطأ");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _onRejectRequest(int id) async {
    setState(() => isSubmitting = true);
    try {
      final success = await AdminServices().rejectAccount(id);
      if (success) {
        _showSnackBar("تم رفض طلب المعلم وحذفه بنجاح", isError: false);
        _loadUsers();
      } else {
        _showSnackBar("فشل الرفض");
      }
    } catch (e) {
      _showSnackBar("حدث خطأ");
    } finally {
      setState(() => isSubmitting = false);
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
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _specializationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryYellow = const Color(0xFFFFCC00);
    final cardColor = isDark ? Colors.white10 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.mode == 'create'
              ? 'إضافة معلم جديد'
              : widget.mode == 'delete'
                  ? 'إزالة معلم'
                  : 'طلبات الانضمام (المعلمون)'),
          centerTitle: true,
        ),
        body: isSubmitting
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (widget.mode == 'create')
                      _buildCreateForm(isDark, primaryYellow, cardColor, textColor),
                    if (widget.mode == 'delete')
                      _buildDeleteView(isDark),
                    if (widget.mode == 'request')
                      _buildRequestsList(isDark, cardColor),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCreateForm(bool isDark, Color yellow, Color cardColor, Color textColor) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Find the current department ID based on selectedDept name
    int? currentDeptId;
    if (selectedDept != null && allDepts.isNotEmpty) {
      final deptObj = allDepts.firstWhere(
        (d) => d['name'].toString().trim().contains(selectedDept!) || selectedDept!.contains(d['name'].toString().trim()),
        orElse: () => null,
      );
      if (deptObj != null) {
        currentDeptId = deptObj['department_id'];
      }
    }

    // Filter programs list by current department ID
    final filteredProgs = allPrograms.where((p) {
      if (currentDeptId == null) return false;
      return p['department_id'] == currentDeptId;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("البيانات الشخصية والمهنية"),
        Row(
          children: [
            Expanded(child: _buildTextField("الاسم الأول (إجباري)", Icons.person_outline, _firstNameController, isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField("الاسم الثاني / الكنية (إجباري)", Icons.person_outline, _lastNameController, isDark)),
          ],
        ),
        const SizedBox(height: 15),
        _buildTextField("رقم الهاتف", Icons.phone_android_outlined, _phoneController, isDark),
        const SizedBox(height: 15),
        _buildTextField("البريد الإلكتروني (اسم الحساب فقط)", Icons.email_outlined, _emailController, isDark, suffixText: "@edu.com"),
        const SizedBox(height: 25),

        _buildSectionTitle("تفاصيل إضافية"),
        Row(
          children: [
            Expanded(child: _buildGenderCard("ذكر", Icons.male, selectedGender == "ذكر", yellow, isDark)),
            const SizedBox(width: 15),
            Expanded(child: _buildGenderCard("أنثى", Icons.female, selectedGender == "أنثى", yellow, isDark)),
          ],
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: _pickDate,
          child: _buildFakeInput(
            selectedBirthDate == null ? "تاريخ الميلاد" : "${selectedBirthDate!.toLocal()}".split(' ')[0],
            Icons.calendar_month,
            isDark,
          ),
        ),
        const SizedBox(height: 15),

        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                "القسم الأكاديمي",
                allDepts.map((d) => d['name'].toString()).toList(),
                selectedDept,
                (val) {
                  setState(() {
                    selectedDept = val;
                    selectedProgramObj = null;
                    programCourses.clear();
                    selectedCourseIds.clear();
                  });
                },
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(12) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<dynamic>(
                    value: selectedProgramObj,
                    hint: const Text("الدورة / التخصص", style: TextStyle(fontSize: 14)),
                    isExpanded: true,
                    dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                    items: filteredProgs.map((p) {
                      return DropdownMenuItem<dynamic>(
                        value: p,
                        child: Text(p['name'].toString(), style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedProgramObj = val;
                      });
                      if (val != null) {
                        _loadProgramCourses(val['id'] ?? val['program_id']);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),

        _buildSectionTitle("المواد المخصصة للمعلم في هذه الدورة"),
        if (isLoadingCourses)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (programCourses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              "الرجاء تحديد القسم والدورة لعرض المواد المتاحة",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: programCourses.length,
              itemBuilder: (context, index) {
                final course = programCourses[index];
                final courseId = course['course_id'] ?? course['id'];
                final isSelected = selectedCourseIds.contains(courseId);
                return CheckboxListTile(
                  title: Text(course['title'] ?? 'بدون عنوان', style: TextStyle(color: textColor, fontSize: 14)),
                  activeColor: yellow,
                  checkColor: Colors.black,
                  value: isSelected,
                  onChanged: (bool? val) {
                    setState(() {
                      if (val == true) {
                        selectedCourseIds.add(courseId);
                      } else {
                        selectedCourseIds.remove(courseId);
                      }
                    });
                  },
                );
              },
            ),
          ),
        const SizedBox(height: 25),

        _buildSectionTitle("أمان الحساب"),
        _buildTextField("كلمة المرور (إجباري)", Icons.lock_outline, _passwordController, isDark, isPassword: true),
        const SizedBox(height: 35),

        ElevatedButton(
          onPressed: _onCreateTeacher,
          style: ElevatedButton.styleFrom(
            backgroundColor: yellow,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text("حفظ بيانات المعلم",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildDeleteView(bool isDark) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    // Find the current department ID based on filterDept name
    int? currentDeptId;
    if (filterDept != null && allDepts.isNotEmpty) {
      final deptObj = allDepts.firstWhere(
        (d) => d['name'].toString().trim().contains(filterDept!) || filterDept!.contains(d['name'].toString().trim()),
        orElse: () => null,
      );
      if (deptObj != null) {
        currentDeptId = deptObj['department_id'];
      }
    }

    // Filter programs list by current department ID
    final filteredProgs = allPrograms.where((p) {
      if (currentDeptId == null) return false;
      return p['department_id'] == currentDeptId;
    }).toList();

    final filteredUsers = users.where((u) {
      if (filterDept != null && u['department'] != filterDept) {
        return false;
      }
      if (filterProgramObj != null && u['specialization'] != filterProgramObj['name']) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                "تصفية بالقسم",
                ["الكل", ...allDepts.map((d) => d['name'].toString()).toList()],
                filterDept ?? "الكل",
                (val) {
                  setState(() {
                    filterDept = (val == "الكل") ? null : val;
                    filterProgramObj = null;
                  });
                },
                isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(12) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<dynamic>(
                    value: filterProgramObj,
                    hint: const Text("تصفية بالدورة", style: TextStyle(fontSize: 14)),
                    isExpanded: true,
                    dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                    items: [
                      const DropdownMenuItem<dynamic>(
                        value: null,
                        child: Text("الكل", style: TextStyle(fontSize: 13)),
                      ),
                      ...filteredProgs.map((p) {
                        return DropdownMenuItem<dynamic>(
                          value: p,
                          child: Text(p['name'].toString(), style: const TextStyle(fontSize: 13)),
                        );
                      })
                    ],
                    onChanged: (val) {
                      setState(() {
                        filterProgramObj = val;
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (filteredUsers.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.only(top: 50), child: Text("لا يوجد معلمون مسجلون مطابقين للتصفية")))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final teacher = filteredUsers[index];
              final name = teacher['full_name'] ?? teacher['name'] ?? '';
              final username = teacher['username'] ?? '';
              final id = teacher['user_id'] ?? teacher['id'] ?? 0;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.co_present)),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("اسم المستخدم: $username\nالقسم: ${teacher['department'] ?? 'غير محدد'} | التخصص: ${teacher['specialization'] ?? 'غير محدد'}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _onDeleteTeacher(id),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildRequestsList(bool isDark, Color cardColor) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (users.isEmpty) return const Center(child: Padding(padding: EdgeInsets.only(top: 50), child: Text("لا توجد طلبات معلقة من معلمين")));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final teacher = users[index];
        final name = teacher['full_name'] ?? teacher['name'] ?? '';
        final email = teacher['email'] ?? '';
        final id = teacher['user_id'] ?? teacher['id'] ?? 0;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person_pin)),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(email),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () => _onApproveRequest(id),
                      child: const Text("قبول وتفعيل", style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () => _onRejectRequest(id),
                      child: const Text("رفض وحذف", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 5),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  Widget _buildGenderCard(String label, IconData icon, bool isSelected, Color yellow, bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => selectedGender = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? yellow : (isDark ? Colors.white.withAlpha(12) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, bool isDark, {bool isPassword = false, String? suffixText}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20),
        hintText: hint,
        suffixText: suffixText,
        suffixStyle: suffixText != null ? const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13) : null,
        filled: true,
        fillColor: isDark ? Colors.white.withAlpha(12) : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildFakeInput(String text, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(12) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDropdown(String hint, List<String> items, String? value, Function(String?) onChanged, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(12) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}