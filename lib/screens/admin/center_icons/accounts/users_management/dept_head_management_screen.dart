import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/admin_services.dart';

class DeptHeadManagementScreen extends StatefulWidget {
  final String mode; // 'create', 'delete', 'request'
  const DeptHeadManagementScreen({super.key, required this.mode});

  @override
  State<DeptHeadManagementScreen> createState() => _DeptHeadManagementScreenState();
}

class _DeptHeadManagementScreenState extends State<DeptHeadManagementScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? selectedDept;
  String selectedGender = "ذكر";
  DateTime? selectedBirthDate;

  final List<String> departments = ['نظم معلومات', 'طبي', 'تجاري', 'هندسي'];

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
        final all = await AdminServices().getUsers(roleId: 5, status: 'active', all: true);
        if (all != null) {
          setState(() {
            users = all;
          });
        }
      } else if (widget.mode == 'request') {
        final pending = await AdminServices().getPendingAccounts();
        if (pending != null) {
          setState(() {
            users = pending.where((u) => u['role_id'] == 5 || u['role']?['name'] == 'head').toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading HODs: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1985),
      firstDate: DateTime(1960),
      lastDate: DateTime(2005),
    );
    if (picked != null) setState(() => selectedBirthDate = picked);
  }

  Future<void> _onCreateHOD() async {
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

    final email = "$emailPrefix@edu-bridge.com";
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
        'role': 'head',
        'gender': selectedGender,
        'birth_date': selectedBirthDate != null ? "${selectedBirthDate!.toLocal()}".split(' ')[0] : null,
        'department': selectedDept,
      });

      if (success) {
        _showSnackBar("تم تسجيل رئيس القسم بنجاح", isError: false);
        _firstNameController.clear();
        _lastNameController.clear();
        _phoneController.clear();
        _emailController.clear();
        _passwordController.clear();
        setState(() {
          selectedDept = null;
          selectedBirthDate = null;
        });
      } else {
        _showSnackBar("فشل إضافة رئيس القسم");
      }
    } catch (e) {
      debugPrint("Error creating HOD: $e");
      _showSnackBar("حدث خطأ أثناء إنشاء الحساب، يرجى التحقق من المدخلات");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _onDeleteHOD(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: const Text("هل تريد حذف حساب رئيس القسم هذا نهائياً؟"),
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
        _showSnackBar("تم حذف رئيس القسم بنجاح", isError: false);
        _loadUsers();
      } else {
        _showSnackBar("فشل الحذف");
      }
    } catch (e) {
      _showSnackBar("حدث خطأ");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _onApproveRequest(int id) async {
    setState(() => isSubmitting = true);
    try {
      final success = await AdminServices().approveAccount(id);
      if (success) {
        _showSnackBar("تم قبول وتفعيل حساب رئيس القسم بنجاح", isError: false);
        _loadUsers();
      } else {
        _showSnackBar("فشل التفعيل");
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
        _showSnackBar("تم رفض طلب الحساب وحذفه بنجاح", isError: false);
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
    _phoneController.dispose();
    _emailController.dispose();
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
              ? 'إضافة رئيس قسم جديد'
              : widget.mode == 'delete'
                  ? 'إزالة رئيس قسم'
                  : 'طلبات الانضمام (رؤساء الأقسام)'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("البيانات الشخصية والإدارية"),
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
        _buildTextField("البريد الإلكتروني المهني (اسم الحساب فقط)", Icons.alternate_email, _emailController, isDark, suffixText: "@edu-bridge.com"),
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
        _buildDropdown("القسم المسؤول عنه", departments, selectedDept, (val) => setState(() => selectedDept = val), isDark),
        const SizedBox(height: 25),

        _buildSectionTitle("أمان الحساب"),
        _buildTextField("كلمة المرور (إجباري)", Icons.lock_outline, _passwordController, isDark, isPassword: true),
        const SizedBox(height: 35),

        ElevatedButton(
          onPressed: _onCreateHOD,
          style: ElevatedButton.styleFrom(
            backgroundColor: yellow,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text("اعتماد رئيس القسم",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildDeleteView(bool isDark) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (users.isEmpty) return const Center(child: Padding(padding: EdgeInsets.only(top: 50), child: Text("لا يوجد رؤساء أقسام مسجلين")));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final hod = users[index];
        final name = hod['full_name'] ?? hod['name'] ?? '';
        final username = hod['username'] ?? '';
        final id = hod['user_id'] ?? hod['id'] ?? 0;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.manage_accounts)),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("اسم المستخدم: $username"),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _onDeleteHOD(id),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestsList(bool isDark, Color cardColor) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (users.isEmpty) return const Center(child: Padding(padding: EdgeInsets.only(top: 50), child: Text("لا توجد طلبات معلقة من رؤساء الأقسام")));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final hod = users[index];
        final name = hod['full_name'] ?? hod['name'] ?? '';
        final email = hod['email'] ?? '';
        final id = hod['user_id'] ?? hod['id'] ?? 0;

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