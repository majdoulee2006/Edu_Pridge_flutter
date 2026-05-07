import 'package:flutter/material.dart';

class DeptHeadManagementScreen extends StatefulWidget {
  final String mode; // 'create', 'delete', 'request'
  const DeptHeadManagementScreen({super.key, required this.mode});

  @override
  State<DeptHeadManagementScreen> createState() => _DeptHeadManagementScreenState();
}

class _DeptHeadManagementScreenState extends State<DeptHeadManagementScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  String? selectedDept;
  String selectedGender = "ذكر";
  DateTime? selectedBirthDate;

  final List<String> departments = ['نظم المعلومات', 'طبي', 'تجاري', 'هندسي'];

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1985),
      firstDate: DateTime(1960),
      lastDate: DateTime(2005),
    );
    if (picked != null) setState(() => selectedBirthDate = picked);
  }

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
          title: Text(widget.mode == 'create'
              ? 'إضافة رئيس قسم'
              : widget.mode == 'delete'
              ? 'إزالة رئيس قسم'
              : 'طلبات رؤساء الأقسام'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (widget.mode == 'create')
                _buildCreateForm(isDark, primaryYellow, cardColor, textColor),
              if (widget.mode == 'delete')
                const Center(child: Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Text("واجهة إدارة وحذف رؤساء الأقسام"),
                )),
              if (widget.mode == 'request')
                const Center(child: Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Text("قائمة طلبات رؤساء الأقسام"),
                )),
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
        // البيانات الشخصية
        _buildSectionTitle("البيانات الشخصية"),
        _buildTextField("الاسم الكامل لرئيس القسم", Icons.person_add_alt_1_outlined, _nameController, isDark),
        const SizedBox(height: 15),
        _buildTextField("رقم الهاتف", Icons.phone_android_outlined, _phoneController, isDark),
        const SizedBox(height: 15),
        _buildTextField("البريد الإلكتروني المهني", Icons.alternate_email, _emailController, isDark),

        const SizedBox(height: 25),

        // تفاصيل إضافية (نفس التصميم)
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

        // أمان الحساب
        _buildSectionTitle("أمان الحساب"),
        _buildTextField("كلمة المرور", Icons.lock_outline, _passController, isDark, isPassword: true),
        const SizedBox(height: 15),
        _buildTextField("تأكيد كلمة المرور", Icons.lock_reset_outlined, _confirmPassController, isDark, isPassword: true),

        const SizedBox(height: 35),

        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: yellow,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text("اعتماد رئيس القسم",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ====================== الدوال المشتركة ======================
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

  Widget _buildFakeInput(String text, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
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
}