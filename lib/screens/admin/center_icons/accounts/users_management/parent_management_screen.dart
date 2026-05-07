import 'package:flutter/material.dart';

class ParentManagementScreen extends StatefulWidget {
  final String mode; // 'create', 'delete', 'request'
  const ParentManagementScreen({super.key, required this.mode});

  @override
  State<ParentManagementScreen> createState() => _ParentManagementScreenState();
}

class _ParentManagementScreenState extends State<ParentManagementScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  int _selectedChildrenCount = 1;
  final List<TextEditingController> _childIdControllers = [TextEditingController()];

  String selectedGender = "ذكر";   // ← أضفت هذا

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryYellow = const Color(0xFFEFFF00);
    final cardColor = isDark ? Colors.white10 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.mode == 'create' ? 'إضافة ولي أمر' : widget.mode == 'delete' ? 'إزالة حساب' : 'طلبات الأهل'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
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
        _buildTextField("الاسم الكامل لولي الأمر", Icons.person_outline, _nameController, isDark),
        const SizedBox(height: 15),
        _buildTextField("البريد الإلكتروني", Icons.email_outlined, _emailController, isDark),
        const SizedBox(height: 15),
        _buildTextField("رقم الهاتف الشخصي", Icons.phone_enabled_outlined, _phoneController, isDark),
        const SizedBox(height: 15),

        // === قسم تفاصيل اضافية (نفس طريقة المعلم) ===
        _buildSectionTitle("تفاصيل اضافية"),
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
          child: _buildTextField("الرقم الجامعي للابن ${index + 1}", Icons.badge_outlined, _childIdControllers[index], isDark),
        )),

        const SizedBox(height: 15),
        _buildTextField("كلمة مرور الحساب", Icons.lock_outline, _passwordController, isDark, isPassword: true),

        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: yellow, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          child: const Text("إنشاء حساب ولي الأمر", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  // ==================== دوال المعلم المضافة ====================
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
          color: isSelected ? yellow : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
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

  // باقي الدوال كما هي بدون تغيير
  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, bool isDark, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20),
        hintText: hint,
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdown(String hint, List<String> items, String? value, Function(String?) onChanged, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
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

  Widget _buildDeleteView(bool isDark) => const Center(child: Text("واجهة حذف حسابات الأهل"));
  Widget _buildRequestsList(bool isDark, Color card) => const Center(child: Text("قائمة طلبات انضمام الأهل"));
}