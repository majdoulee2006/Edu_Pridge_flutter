import 'package:flutter/material.dart';

class StudentAffairsManagementScreen extends StatefulWidget {
  final String mode;
  const StudentAffairsManagementScreen({super.key, required this.mode});

  @override
  State<StudentAffairsManagementScreen> createState() => _StudentAffairsManagementScreenState();
}

class _StudentAffairsManagementScreenState extends State<StudentAffairsManagementScreen> {
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
      initialDate: DateTime(1995),
      firstDate: DateTime(1960),
      lastDate: DateTime(2008),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFEFFF00), onPrimary: Colors.black),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedBirthDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryYellow = const Color(0xFFEFFF00);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.mode == 'create' ? 'إضافة موظف شؤون' : widget.mode == 'delete' ? 'إزالة موظف' : 'طلبات موظفي الشؤون'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.mode == 'create') _buildCreateForm(isDark, primaryYellow),
              if (widget.mode == 'delete') const Center(child: Padding(padding: EdgeInsets.only(top: 50), child: Text("إدارة حسابات الشؤون الطلابية"))),
              if (widget.mode == 'request') const Center(child: Padding(padding: EdgeInsets.only(top: 50), child: Text("طلبات التوظيف"))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateForm(bool isDark, Color yellow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- القسم الأول: البيانات الشخصية ---
        _buildSectionTitle("البيانات الشخصية"),
        _buildTextField("الاسم الكامل للموظف", Icons.admin_panel_settings_outlined, _nameController, isDark),
        const SizedBox(height: 15),
        _buildTextField("رقم التواصل", Icons.phone_android_outlined, _phoneController, isDark),
        const SizedBox(height: 15),
        _buildTextField("البريد الرسمي", Icons.email_outlined, _emailController, isDark),

        const SizedBox(height: 20),

        // --- القسم الثاني: التفاصيل الإضافية ---
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
        _buildDropdown("القسم التابع له", departments, selectedDept, (val) => setState(() => selectedDept = val), isDark),

        const SizedBox(height: 20),

        // --- القسم الثالث: الأمان ---
        _buildSectionTitle("أمان الحساب"),
        _buildTextField("كلمة المرور", Icons.lock_outline, _passController, isDark, isPassword: true),
        const SizedBox(height: 15),
        _buildTextField("تأكيد كلمة المرور", Icons.lock_reset_outlined, _confirmPassController, isDark, isPassword: true),

        const SizedBox(height: 30),

        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: yellow,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text("إنشاء حساب الموظف", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // دالة مخصصة لعناوين الأقسام للفصل بين البيانات
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