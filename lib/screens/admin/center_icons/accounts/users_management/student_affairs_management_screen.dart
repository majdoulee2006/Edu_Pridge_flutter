import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/admin_services.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class StudentAffairsManagementScreen extends StatefulWidget {
  final String mode;
  const StudentAffairsManagementScreen({super.key, required this.mode});

  @override
  State<StudentAffairsManagementScreen> createState() =>
      _StudentAffairsManagementScreenState();
}

class _StudentAffairsManagementScreenState
    extends State<StudentAffairsManagementScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? selectedDept;
  String selectedGender = "ذكر";
  DateTime? selectedBirthDate;

  final List<String> departments = ['نظم المعلومات', 'طبي', 'تجاري', 'هندسي'];

  List<dynamic> users = [];
  bool isLoading = false;
  bool isSubmitting = false;

  bool get isAr => AppSettings.language.value == 'ar';

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    if (widget.mode == 'delete' || widget.mode == 'request') {
      _loadUsers();
    }
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      if (widget.mode == 'delete') {
        final all = await AdminServices()
            .getUsers(roleId: 6, status: 'active', all: true);
        if (all != null) {
          setState(() {
            users = all;
          });
        }
      } else if (widget.mode == 'request') {
        final pending = await AdminServices().getPendingAccounts();
        if (pending != null) {
          setState(() {
            users = pending
                .where((u) =>
                    u['role_id'] == 6 || u['role']?['name'] == 'affairs')
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading affairs: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1960),
      lastDate: DateTime(2008),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFFCC00),
            onPrimary: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedBirthDate = picked);
  }

  Future<void> _onCreateAffairs() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final name = "$firstName $lastName".trim();
    final phone = _phoneController.text.trim();
    final emailPrefix = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        emailPrefix.isEmpty ||
        password.isEmpty) {
      _showSnackBar(
        isAr
            ? "يرجى ملء الحقول الإجبارية (الاسم الأول، الكنية، البريد الإلكتروني، كلمة المرور)"
            : "Please fill in required fields (first name, last name, email, password)",
      );
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
        'role': 'affairs',
        'gender': selectedGender,
        'birth_date': selectedBirthDate != null
            ? "${selectedBirthDate!.toLocal()}".split(' ')[0]
            : null,
      });

      if (success) {
        _showSnackBar(
          isAr
              ? "تم تسجيل موظف الشؤون بنجاح"
              : "Affairs staff registered successfully",
          isError: false,
        );
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
        _showSnackBar(
          isAr ? "فشل إضافة موظف الشؤون" : "Failed to add affairs staff",
        );
      }
    } catch (e) {
      debugPrint("Error creating affairs: $e");
      _showSnackBar(
        isAr
            ? "حدث خطأ أثناء إنشاء الحساب، يرجى التحقق من المدخلات"
            : "Error creating account, please check inputs",
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _onDeleteAffairs(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(isAr ? "تأكيد الحذف" : "Confirm Deletion"),
          content: Text(
            isAr
                ? "هل تريد حذف حساب الموظف هذا نهائياً؟"
                : "Do you want to permanently delete this staff account?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(isAr ? "إلغاء" : "Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                isAr ? "نعم، احذف" : "Yes, Delete",
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => isSubmitting = true);
    try {
      final success = await AdminServices().deleteUser(id);
      if (success) {
        _showSnackBar(
          isAr ? "تم حذف حساب الموظف بنجاح" : "Staff account deleted successfully",
          isError: false,
        );
        _loadUsers();
      } else {
        _showSnackBar(isAr ? "فشل الحذف" : "Deletion failed");
      }
    } catch (e) {
      _showSnackBar(isAr ? "حدث خطأ" : "An error occurred");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _onApproveRequest(int id) async {
    setState(() => isSubmitting = true);
    try {
      final success = await AdminServices().approveAccount(id);
      if (success) {
        _showSnackBar(
          isAr
              ? "تم قبول وتفعيل حساب موظف الشؤون بنجاح"
              : "Account approved and activated successfully",
          isError: false,
        );
        _loadUsers();
      } else {
        _showSnackBar(isAr ? "فشل التفعيل" : "Activation failed");
      }
    } catch (e) {
      _showSnackBar(isAr ? "حدث خطأ" : "An error occurred");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _onRejectRequest(int id) async {
    setState(() => isSubmitting = true);
    try {
      final success = await AdminServices().rejectAccount(id);
      if (success) {
        _showSnackBar(
          isAr
              ? "تم رفض طلب الحساب وحذفه بنجاح"
              : "Request rejected and deleted successfully",
          isError: false,
        );
        _loadUsers();
      } else {
        _showSnackBar(isAr ? "فشل الرفض" : "Rejection failed");
      }
    } catch (e) {
      _showSnackBar(isAr ? "حدث خطأ" : "An error occurred");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryYellow = Color(0xFFFFCC00);
    final cardColor = isDark ? Colors.white10 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    final title = widget.mode == 'create'
        ? (isAr ? 'إضافة موظف شؤون جديد' : 'Add New Affairs Staff')
        : widget.mode == 'delete'
            ? (isAr ? 'إزالة موظف شؤون' : 'Remove Affairs Staff')
            : (isAr
                ? 'طلبات الانضمام (موظفو الشؤون)'
                : 'Join Requests (Affairs Staff)');

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              isAr ? Icons.arrow_back : Icons.arrow_back_ios_new,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: isSubmitting
            ? const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (widget.mode == 'create')
                      _buildCreateForm(
                        isDark,
                        primaryYellow,
                        cardColor,
                        textColor,
                      ),
                    if (widget.mode == 'delete') _buildDeleteView(isDark),
                    if (widget.mode == 'request')
                      _buildRequestsList(isDark, cardColor),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCreateForm(
    bool isDark,
    Color yellow,
    Color cardColor,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          isAr
              ? "البيانات الشخصية والمهنية"
              : "Personal & Professional Information",
        ),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                isAr ? "الاسم الأول (إجباري)" : "First Name (Required)",
                Icons.person_outline,
                _firstNameController,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                isAr
                    ? "الاسم الثاني / الكنية (إجباري)"
                    : "Last Name (Required)",
                Icons.person_outline,
                _lastNameController,
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildTextField(
          isAr ? "رقم الهاتف" : "Phone Number",
          Icons.phone_android_outlined,
          _phoneController,
          isDark,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          isAr
              ? "البريد الإلكتروني المهني (اسم الحساب فقط)"
              : "Email (Account prefix only)",
          Icons.alternate_email,
          _emailController,
          isDark,
          suffixText: "@edu-bridge.com",
        ),
        const SizedBox(height: 25),

        _buildSectionTitle(isAr ? "تفاصيل إضافية" : "Additional Details"),
        Row(
          children: [
            Expanded(
              child: _buildGenderCard(
                isAr ? "ذكر" : "Male",
                Icons.male,
                selectedGender == "ذكر",
                yellow,
                isDark,
                onSelect: () => setState(() => selectedGender = "ذكر"),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildGenderCard(
                isAr ? "أنثى" : "Female",
                Icons.female,
                selectedGender == "أنثى",
                yellow,
                isDark,
                onSelect: () => setState(() => selectedGender = "أنثى"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: _pickDate,
          child: _buildFakeInput(
            selectedBirthDate == null
                ? (isAr ? "تاريخ الميلاد" : "Date of Birth")
                : "${selectedBirthDate!.toLocal()}".split(' ')[0],
            Icons.calendar_month,
            isDark,
          ),
        ),
        const SizedBox(height: 25),

        _buildSectionTitle(isAr ? "أمان الحساب" : "Account Security"),
        _buildTextField(
          isAr ? "كلمة المرور (إجباري)" : "Password (Required)",
          Icons.lock_outline,
          _passwordController,
          isDark,
          isPassword: true,
        ),
        const SizedBox(height: 35),

        ElevatedButton(
          onPressed: _onCreateAffairs,
          style: ElevatedButton.styleFrom(
            backgroundColor: yellow,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Text(
            isAr ? "إنشاء حساب الموظف" : "Create Staff Account",
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteView(bool isDark) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Text(
            isAr
                ? "لا يوجد موظفو شؤون مسجلين"
                : "No registered affairs staff",
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final affairs = users[index];
        final name = affairs['full_name'] ?? affairs['name'] ?? '';
        final username = affairs['username'] ?? '';
        final id = affairs['user_id'] ?? affairs['id'] ?? 0;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.badge)),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              isAr ? "اسم المستخدم: $username" : "Username: $username",
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _onDeleteAffairs(id),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestsList(bool isDark, Color cardColor) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Text(
            isAr
                ? "لا توجد طلبات معلقة من موظفي الشؤون"
                : "No pending requests from affairs staff",
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final affairs = users[index];
        final name = affairs['full_name'] ?? affairs['name'] ?? '';
        final email = affairs['email'] ?? '';
        final id = affairs['user_id'] ?? affairs['id'] ?? 0;

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
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(email),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => _onApproveRequest(id),
                      child: Text(
                        isAr ? "قبول وتفعيل" : "Approve",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: () => _onRejectRequest(id),
                      child: Text(
                        isAr ? "رفض وحذف" : "Reject",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 10,
        right: isAr ? 5 : 0,
        left: isAr ? 0 : 5,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildGenderCard(
    String label,
    IconData icon,
    bool isSelected,
    Color yellow,
    bool isDark, {
    required VoidCallback onSelect,
  }) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? yellow
              : (isDark ? Colors.white.withAlpha(12) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    IconData icon,
    TextEditingController controller,
    bool isDark, {
    bool isPassword = false,
    String? suffixText,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20),
        hintText: hint,
        suffixText: suffixText,
        suffixStyle: suffixText != null
            ? const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              )
            : null,
        filled: true,
        fillColor: isDark ? Colors.white.withAlpha(12) : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
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
}