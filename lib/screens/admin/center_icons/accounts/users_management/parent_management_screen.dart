import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:edu_pridge_flutter/services/admin_services.dart';

class ParentManagementScreen extends StatefulWidget {
  final String mode; // 'create', 'delete', 'request'
  const ParentManagementScreen({super.key, required this.mode});

  @override
  State<ParentManagementScreen> createState() => _ParentManagementScreenState();
}

class _ParentManagementScreenState extends State<ParentManagementScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _telegramController = TextEditingController();
  final _passwordController = TextEditingController();

  int _selectedChildrenCount = 1;
  final List<TextEditingController> _childIdControllers = [TextEditingController()];

  String selectedGender = "ذكر";

  List<dynamic> users = [];
  List<dynamic> allStudents = [];
  String? filterDept;
  String? filterBranch;

  final Map<String, List<String>> _departmentData = {
    'نظم معلومات': ['ذكاء صنعي', 'الكترون', 'معلوماتية', 'اتصالات'],
    'طبي': ['مساعد صيدلي', 'مساعد مخبري'],
    'تجاري': ['محاسبة', 'مصارف', 'إدارة اعمال', 'تجارة الكترونية'],
    'هندسي': ['مساعد مهندس ديكور', 'مساعد مهندس مدني', 'ديكور واعلان'],
  };

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
        final all = await AdminServices().getUsers(roleId: 4, status: 'active', all: true);
        final students = await AdminServices().getUsers(roleId: 3, status: 'active', all: true);
        if (all != null) {
          setState(() {
            users = all;
            allStudents = students ?? [];
          });
        }
      } else if (widget.mode == 'request') {
        final pending = await AdminServices().getPendingAccounts();
        if (pending != null) {
          setState(() {
            users = pending.where((u) => u['role_id'] == 4 || u['role']?['name'] == 'parent').toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading parents: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _onCreateParent() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final name = "$firstName $lastName".trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final telegram = _telegramController.text.trim();
    final password = _passwordController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || phone.isEmpty || password.isEmpty) {
      _showSnackBar("يرجى ملء الحقول الإجبارية (الاسم الأول، الكنية، الهاتف، كلمة المرور)");
      return;
    }

    final childrenList = _childIdControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (childrenList.isEmpty) {
      _showSnackBar("يرجى إدخال الرقم الجامعي لطفل واحد على الأقل");
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final success = await AdminServices().createUser({
        'full_name': name,
        'first_name': firstName,
        'last_name': lastName,
        'username': phone,
        'email': email.isEmpty ? null : email,
        'phone': phone,
        'telegram_id': telegram.isEmpty ? null : telegram,
        'password': password,
        'role': 'parent',
        'gender': selectedGender,
        'children_ids': jsonEncode(childrenList),
      });

      if (success) {
        _showSnackBar("تم تسجيل ولي الأمر بنجاح", isError: false);
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _telegramController.clear();
        _passwordController.clear();
        for (var c in _childIdControllers) {
          c.clear();
        }
      } else {
        _showSnackBar("فشل إضافة ولي الأمر");
      }
    } catch (e) {
      debugPrint("Error creating parent: $e");
      _showSnackBar("حدث خطأ، قد يكون رقم الهاتف أو البريد مسجلاً مسبقاً");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _onDeleteParent(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: const Text("هل تريد حذف حساب ولي الأمر هذا نهائياً؟"),
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
        _showSnackBar("تم حذف ولي الأمر بنجاح", isError: false);
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
        _showSnackBar("تم قبول وتفعيل حساب ولي الأمر بنجاح", isError: false);
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
        _showSnackBar("تم رفض الطلب وحذفه بنجاح", isError: false);
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
    _emailController.dispose();
    _phoneController.dispose();
    _telegramController.dispose();
    _passwordController.dispose();
    for (var c in _childIdControllers) {
      c.dispose();
    }
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
          title: Text(widget.mode == 'create' ? 'إضافة ولي أمر' : widget.mode == 'delete' ? 'إزالة حساب' : 'طلبات الانضمام (أولياء الأمور)'),
          centerTitle: true,
        ),
        body: isSubmitting
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (widget.mode == 'create') _buildCreateForm(isDark, primaryYellow, cardColor, textColor),
                    if (widget.mode == 'delete') _buildDeleteView(isDark),
                    if (widget.mode == 'request') _buildRequestsList(isDark, cardColor),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCreateForm(bool isDark, Color yellow, Color cardColor, Color textColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTextField("الاسم الأول (إجباري)", Icons.person_outline, _firstNameController, isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField("الاسم الثاني / الكنية (إجباري)", Icons.person_outline, _lastNameController, isDark)),
          ],
        ),
        const SizedBox(height: 15),
        _buildTextField("رقم الهاتف الشخصي (إجباري)", Icons.phone_enabled_outlined, _phoneController, isDark),
        const SizedBox(height: 15),
        _buildTextField("البريد الإلكتروني", Icons.email_outlined, _emailController, isDark),
        const SizedBox(height: 15),
        _buildTextField("معرف التليجرام (Telegram ID)", Icons.send_outlined, _telegramController, isDark),
        const SizedBox(height: 15),

        _buildSectionTitle("تفاصيل إضافية"),
        Row(
          children: [
            Expanded(child: _buildGenderCard("ذكر", Icons.male, selectedGender == "ذكر", yellow, isDark)),
            const SizedBox(width: 15),
            Expanded(child: _buildGenderCard("أنثى", Icons.female, selectedGender == "أنثى", yellow, isDark)),
          ],
        ),
        const SizedBox(height: 15),

        _buildDropdown("عدد الأبناء المرتبطين", ['1', '2', '3', '4'], _selectedChildrenCount.toString(), (val) {
          if (val != null) {
            setState(() {
              int newCount = int.parse(val);
              if (newCount > _childIdControllers.length) {
                for (int i = _childIdControllers.length; i < newCount; i++) {
                  _childIdControllers.add(TextEditingController());
                }
              } else {
                for (int i = _childIdControllers.length - 1; i >= newCount; i--) {
                  _childIdControllers.removeAt(i);
                }
              }
              _selectedChildrenCount = newCount;
            });
          }
        }, isDark),

        const SizedBox(height: 15),

        ...List.generate(_selectedChildrenCount, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildTextField("الرقم الجامعي للابن ${index + 1} (إجباري)", Icons.badge_outlined, _childIdControllers[index], isDark),
        )),

        const SizedBox(height: 15),
        _buildTextField("كلمة مرور الحساب (إجباري)", Icons.lock_outline, _passwordController, isDark, isPassword: true),

        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _onCreateParent,
          style: ElevatedButton.styleFrom(backgroundColor: yellow, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          child: const Text("إنشاء حساب ولي الأمر", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
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

    final filteredUsers = users.where((parent) {
      List<String> childCodes = [];
      try {
        if (parent['children_ids'] != null) {
          final decoded = parent['children_ids'] is String
              ? jsonDecode(parent['children_ids'])
              : parent['children_ids'];
          if (decoded is List) {
            childCodes = decoded.map((c) => c.toString()).toList();
          }
        }
      } catch (_) {}

      if (filterDept == null && filterBranch == null) return true;
      if (childCodes.isEmpty) return false;

      bool matches = false;
      for (var code in childCodes) {
        final studentObj = allStudents.firstWhere(
          (s) => s['username'].toString().trim() == code.trim(),
          orElse: () => null,
        );
        if (studentObj != null) {
          bool deptMatch = (filterDept == null || studentObj['department'] == filterDept);
          bool branchMatch = (filterBranch == null || studentObj['branch'] == filterBranch);
          if (deptMatch && branchMatch) {
            matches = true;
            break;
          }
        }
      }
      return matches;
    }).toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                "تصفية بالقسم للابن",
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
                "تصفية بالدورة للابن",
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
          const Center(child: Padding(padding: EdgeInsets.only(top: 50), child: Text("لا يوجد أولياء أمور مطابقين للتصفية")))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final parent = filteredUsers[index];
              final name = parent['full_name'] ?? parent['name'] ?? '';
              final phone = parent['phone'] ?? '';
              final id = parent['user_id'] ?? parent['id'] ?? 0;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.family_restroom)),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("الهاتف: $phone"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _onDeleteParent(id),
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
    if (users.isEmpty) return const Center(child: Padding(padding: EdgeInsets.only(top: 50), child: Text("لا توجد طلبات معلقة من أولياء الأمور")));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final parent = users[index];
        final name = parent['full_name'] ?? parent['name'] ?? '';
        final phone = parent['phone'] ?? '';
        final id = parent['user_id'] ?? parent['id'] ?? 0;

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
                  subtitle: Text("هاتف: $phone"),
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
      padding: const EdgeInsets.only(bottom: 10, top: 15, right: 5),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ),
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

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, bool isDark, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20),
        hintText: hint,
        filled: true,
        fillColor: isDark ? Colors.white.withAlpha(12) : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
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