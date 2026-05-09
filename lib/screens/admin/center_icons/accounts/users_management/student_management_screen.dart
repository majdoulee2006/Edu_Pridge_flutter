import 'package:flutter/material.dart';

class StudentManagementScreen extends StatefulWidget {
  final String mode; // 'create', 'delete', 'request'
  const StudentManagementScreen({super.key, required this.mode});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();

  String? selectedDept;
  String? selectedBranch;
  String selectedGender = "ذكر";        // ← أضفت هذا
  String? selectedYear;
  DateTime? selectedBirthDate;

  final Map<String, List<String>> _departmentData = {
    'نظم المعلومات': ['ذكاء صنعي', 'الكترون', 'معلوماتية', 'اتصالات'],
    'طبي': ['مساعد صيدلي', 'مساعد مخبري'],
    'تجاري': ['محاسبة', 'مصارف', 'إدارة اعمال', 'تجارة الكترونية'],
    'هندسي': ['مساعد مهندس ديكور', 'مساعد مهندس مدني', 'ديكور واعلان'],
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryYellow = const Color(0xFFEFFF00);
    final cardColor = isDark ? Colors.white10 : Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.mode == 'create' ? 'إضافة طالب جديد' : widget.mode == 'delete' ? 'إزالة طالب' : 'طلبات الانضمام'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
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
      children: [
        _buildTextField("الاسم الكامل", Icons.person_outline, _nameController, isDark),
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

        _buildTextField("الرقم الجامعي", Icons.badge_outlined, _idController, isDark),
        const SizedBox(height: 15),
        _buildTextField("البريد الإلكتروني", Icons.email_outlined, _emailController, isDark),
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
                  "الفرع",
                  selectedDept == null ? [] : _departmentData[selectedDept!]!,
                  selectedBranch,
                      (val) => setState(() => selectedBranch = val),
                  isDark
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: yellow, minimumSize: const Size(double.infinity, 55)),
          child: const Text("إضافة الطالب للقاعدة", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

  // باقي الدوال كما هي بدون أي تغيير
  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, bool isDark) {
    return TextField(
      controller: controller,
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
          hint: Text(hint, style: const TextStyle(fontSize: 13)),
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDeleteView(bool isDark) { /* كود الحذف */ return Container(); }
  Widget _buildRequestsList(bool isDark, Color card) { /* كود الطلبات */ return Container(); }
}