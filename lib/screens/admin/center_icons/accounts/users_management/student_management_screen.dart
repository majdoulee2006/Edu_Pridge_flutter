import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/admin_services.dart';

class StudentManagementScreen extends StatefulWidget {
  final String mode; // 'create', 'delete', 'request'
  const StudentManagementScreen({super.key, required this.mode});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _telegramIdController = TextEditingController(text: '7821980919');

  String? selectedDept;
  String? selectedBranch;
  String selectedGender = "ذكر";
  String? selectedYear;
  DateTime? selectedBirthDate;

  String? filterDept;
  String? filterBranch;

  final Map<String, List<String>> _departmentData = {
    'نظم معلومات': ['ذكاء صنعي', 'الكترون', 'معلوماتية', 'اتصالات'],
    'طبي': ['مساعد صيدلي', 'مساعد مخبري'],
    'تجاري': ['محاسبة', 'مصارف', 'إدارة اعمال', 'تجارة الكترونية'],
    'هندسي': ['مساعد مهندس ديكور', 'مساعد مهندس مدني', 'ديكور واعلان'],
  };

  final List<String> academicYears = ['سنة اولى', 'سنة تانية'];

  List<dynamic> users = [];
  bool isLoading = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.mode == 'delete' || widget.mode == 'request') {
      _loadUsers();
    }
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      if (widget.mode == 'delete') {
        final all = await AdminServices().getUsers(roleId: 3, status: 'active', all: true);
        if (all != null) {
          setState(() {
            users = all;
          });
        }
      } else if (widget.mode == 'request') {
        final pending = await AdminServices().getPendingAccounts();
        if (pending != null) {
          setState(() {
            users = pending.where((u) => u['role_id'] == 3 || u['role']?['name'] == 'student').toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading students: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(today.year - 20),
      firstDate: DateTime(today.year - 22),
      lastDate: DateTime(today.year - 18),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFFFCC00), onPrimary: Colors.black),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedBirthDate = picked);
  }

  Future<void> _onCreateStudent() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final name = "$firstName $lastName".trim();
    final username = _usernameController.text.trim();
    final emailPrefix = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final telegramId = _telegramIdController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty || emailPrefix.isEmpty) {
      _showSnackBar("الرجاء تعبئة الحقول الإجبارية (الاسم الأول، الكنية، الرقم الجامعي، البريد الإلكتروني، كلمة المرور وتأكيدها)");
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar("كلمتا المرور غير متطابقتين");
      return;
    }

    if (selectedBirthDate == null) {
      _showSnackBar("الرجاء تحديد تاريخ الميلاد");
      return;
    }

    final today = DateTime.now();
    int age = today.year - selectedBirthDate!.year;
    if (today.month < selectedBirthDate!.month || (today.month == selectedBirthDate!.month && today.day < selectedBirthDate!.day)) {
      age--;
    }
    if (age < 18 || age > 22) {
      _showSnackBar("عمر الطالب يجب أن يكون بين 18 و 22 سنة");
      return;
    }

    final email = "$emailPrefix@gmail.com";

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
        'password_confirmation': confirmPassword,
        'telegram_chat_id': telegramId.isEmpty ? null : telegramId,
        'role': 'student',
        'academic_year': selectedYear ?? 'سنة اولى',
        'gender': selectedGender,
        'department': selectedDept,
        'branch': selectedBranch,
        'birth_date': "${selectedBirthDate!.toLocal()}".split(' ')[0],
      });

      if (success) {
        _showSnackBar("تم إضافة الطالب بنجاح", isError: false);
        _firstNameController.clear();
        _lastNameController.clear();
        _usernameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _telegramIdController.text = '7821980919';
        setState(() {
          selectedDept = null;
          selectedBranch = null;
          selectedYear = null;
          selectedBirthDate = null;
        });
      } else {
        _showSnackBar("حدث خطأ أثناء إضافة الطالب");
      }
    } catch (e) {
      _showSnackBar("فشل إضافة الطالب: $e");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _onDeleteStudent(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: const Text("هل أنت متأكد من رغبتك في حذف هذا الطالب نهائياً؟"),
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
        _showSnackBar("تم حذف الطالب بنجاح", isError: false);
        _loadUsers();
      } else {
        _showSnackBar("فشل حذف الطالب");
      }
    } catch (e) {
      debugPrint("Error deleting student: $e");
      _showSnackBar("حدث خطأ أثناء الاتصال بالسيرفر");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _onApproveRequest(int id) async {
    setState(() => isSubmitting = true);
    try {
      final success = await AdminServices().approveAccount(id);
      if (success) {
        _showSnackBar("تم قبول وتفعيل حساب الطالب بنجاح", isError: false);
        _loadUsers();
      } else {
        _showSnackBar("فشل قبول الحساب");
      }
    } catch (e) {
      _showSnackBar("حدث خطأ أثناء قبول الحساب");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _onRejectRequest(int id) async {
    setState(() => isSubmitting = true);
    try {
      final success = await AdminServices().rejectAccount(id);
      if (success) {
        _showSnackBar("تم رفض وحذف الطلب بنجاح", isError: false);
        _loadUsers();
      } else {
        _showSnackBar("فشل رفض الطلب");
      }
    } catch (e) {
      _showSnackBar("حدث خطأ أثناء رفض الطلب");
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
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _telegramIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryYellow = const Color(0xFFFFCC00);
    final cardColor = isDark ? Colors.white10 : Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.mode == 'create' ? 'إضافة طالب جديد' : widget.mode == 'delete' ? 'إزالة طالب' : 'طلبات الانضمام (الطلاب)'),
          centerTitle: true,
        ),
        body: isSubmitting
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (widget.mode == 'create') _buildCreateForm(isDark, primaryYellow, cardColor),
                    if (widget.mode == 'delete') _buildDeleteView(isDark),
                    if (widget.mode == 'request') _buildRequestsList(isDark, cardColor),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCreateForm(bool isDark, Color yellow, Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("البيانات الشخصية الأساسية"),
        Row(
          children: [
            Expanded(child: _buildTextField("الاسم الأول (إجباري)", Icons.person_outline, _firstNameController, isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField("الاسم الثاني / الكنية (إجباري)", Icons.person_outline, _lastNameController, isDark)),
          ],
        ),
        const SizedBox(height: 15),
        _buildTextField("الرقم الجامعي / اسم المستخدم (إجباري)", Icons.badge_outlined, _usernameController, isDark),
        const SizedBox(height: 15),
        _buildTextField("البريد الإلكتروني (اسم الحساب فقط)", Icons.email_outlined, _emailController, isDark, suffixText: "@gmail.com"),
        const SizedBox(height: 15),
        _buildTextField("رقم الهاتف", Icons.phone_android_outlined, _phoneController, isDark),
        const SizedBox(height: 15),
        _buildTextField("كلمة المرور (إجباري)", Icons.lock_outline, _passwordController, isDark, isPassword: true),
        const SizedBox(height: 15),
        _buildTextField("تأكيد كلمة المرور (إجباري)", Icons.lock_outline, _confirmPasswordController, isDark, isPassword: true),
        const SizedBox(height: 15),
        _buildTextField("معرف التليجرام (Telegram Chat ID)", Icons.send_rounded, _telegramIdController, isDark),
        const SizedBox(height: 25),

        _buildSectionTitle("تفاصيل أكاديمية وإضافية"),
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
            selectedBirthDate == null ? "تاريخ الميلاد (العمر بين 18 و 22)" : "${selectedBirthDate!.toLocal()}".split(' ')[0],
            Icons.calendar_month,
            isDark,
          ),
        ),
        const SizedBox(height: 15),

        _buildDropdown("السنة الدراسية", academicYears, selectedYear, (val) => setState(() => selectedYear = val), isDark),
        const SizedBox(height: 15),

        Row(
          children: [
            Expanded(
              child: _buildDropdown("القسم", _departmentData.keys.toList(), selectedDept, (val) {
                setState(() { selectedDept = val; selectedBranch = null; });
              }, isDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDropdown(
                  "الدورة",
                  selectedDept == null ? [] : _departmentData[selectedDept!]!,
                  selectedBranch,
                  (val) => setState(() => selectedBranch = val),
                  isDark
              ),
            ),
          ],
        ),

        const SizedBox(height: 35),
        ElevatedButton(
          onPressed: _onCreateStudent,
          style: ElevatedButton.styleFrom(backgroundColor: yellow, minimumSize: const Size(double.infinity, 55)),
          child: const Text("إضافة الطالب للقاعدة", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        )
      ],
    );
  }

  Widget _buildDeleteView(bool isDark) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    List<String> branches = [];
    if (filterDept != null && _departmentData.containsKey(filterDept)) {
      branches = _departmentData[filterDept!]!;
    }

    final filteredUsers = users.where((u) {
      if (filterDept != null && u['department'] != filterDept) {
        return false;
      }
      if (filterBranch != null && u['branch'] != filterBranch) {
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
                ["الكل", ..._departmentData.keys],
                filterDept ?? "الكل",
                (val) {
                  setState(() {
                    filterDept = (val == "الكل") ? null : val;
                    filterBranch = null;
                  });
                },
                isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDropdown(
                "تصفية بالدورة",
                ["الكل", ...branches],
                filterBranch ?? "الكل",
                (val) {
                  setState(() {
                    filterBranch = (val == "الكل") ? null : val;
                  });
                },
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (filteredUsers.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.only(top: 50), child: Text("لا يوجد طلاب مسجلين مطابقين للتصفية")))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final student = filteredUsers[index];
              final name = student['full_name'] ?? student['name'] ?? '';
              final username = student['username'] ?? '';
              final id = student['user_id'] ?? student['id'] ?? 0;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.school)),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("الرقم الجامعي: $username\nالقسم: ${student['department'] ?? 'غير محدد'} | الدورة: ${student['branch'] ?? 'غير محدد'}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _onDeleteStudent(id),
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
    if (users.isEmpty) return const Center(child: Padding(padding: EdgeInsets.only(top: 50), child: Text("لا توجد طلبات انضمام معلقة")));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final student = users[index];
        final name = student['full_name'] ?? student['name'] ?? '';
        final email = student['email'] ?? '';
        final id = student['user_id'] ?? student['id'] ?? 0;

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
          hint: Text(hint, style: const TextStyle(fontSize: 13)),
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}