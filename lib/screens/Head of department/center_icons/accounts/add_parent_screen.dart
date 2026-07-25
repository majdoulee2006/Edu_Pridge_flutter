import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

class AddParentScreen extends StatefulWidget {
  const AddParentScreen({super.key});

  @override
  State<AddParentScreen> createState() => _AddParentScreenState();
}

class _AddParentScreenState extends State<AddParentScreen> {
  final _nameController     = TextEditingController();
  final _phoneController    = TextEditingController();
  final _relationController = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  int _childrenCount = 1;
  List<TextEditingController> _childIdControllers = [TextEditingController()];

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    for (final c in _childIdControllers) c.dispose();
    super.dispose();
  }

  void _updateChildrenCount(int count) {
    setState(() {
      _childrenCount = count;
      while (_childIdControllers.length < count) {
        _childIdControllers.add(TextEditingController());
      }
      while (_childIdControllers.length > count) {
        _childIdControllers.removeLast().dispose();
      }
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة جميع الحقول المطلوبة')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final studentIds = _childIdControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await Dio().post(
        "${ApiService().baseUrl}/department-head/users/parent",
        data: {
          'full_name':   _nameController.text.trim(),
          'phone':       _phoneController.text.trim(),
          'relation':    _relationController.text.trim(),
          'email':       _emailController.text.trim(),
          'password':    _passwordController.text.trim(),
          'student_ids': studentIds,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم إنشاء حساب ولي الأمر بنجاح'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('⛔ Add Parent Error: $e');
      String msg = 'حدث خطأ، حاول مجدداً';
      if (e is DioException && e.response?.data is Map) {
        msg = e.response!.data['message'] ?? msg;
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    const primaryYellow = Color(0xFFFFCC00);

    return Scaffold(
      appBar: AppBar(
        title: const Text("إنشاء حساب ولي أمر", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("معلومات ولي الأمر", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 16),
              _buildInput(label: "اسم ولي الأمر الكامل",     icon: Icons.family_restroom_outlined, controller: _nameController,     isDark: isDark),
              _buildInput(label: "رقم الهاتف المحمول",        icon: Icons.phone_android_outlined,   controller: _phoneController,    isDark: isDark, inputType: TextInputType.phone),
              _buildInput(label: "صلة القرابة (أب/أم...)",   icon: Icons.link,                      controller: _relationController, isDark: isDark),
              _buildInput(label: "البريد الإلكتروني",         icon: Icons.email_outlined,            controller: _emailController,    isDark: isDark, inputType: TextInputType.emailAddress),
              _buildInput(label: "كلمة المرور",               icon: Icons.lock_outline,              controller: _passwordController, isDark: isDark, isPass: true),

              const SizedBox(height: 24),
              const Text("معلومات الأبناء", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 16),

              // عدد الأبناء
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.child_care, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text("عدد الأبناء", style: TextStyle(color: textColor, fontSize: 14)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFFFCC00)),
                      onPressed: _childrenCount > 1 ? () => _updateChildrenCount(_childrenCount - 1) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryYellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$_childrenCount',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFFFCC00))),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFFCC00)),
                      onPressed: _childrenCount < 6 ? () => _updateChildrenCount(_childrenCount + 1) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // حقول الأرقام الجامعية
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, color: Color(0xFFFFCC00), size: 20),
                        const SizedBox(width: 8),
                        Text("الأرقام الجامعية للأبناء",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_childrenCount, (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: _childIdControllers[i],
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: "الرقم الجامعي للابن ${i + 1}",
                          prefixIcon: const Icon(Icons.numbers, color: Colors.grey),
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text("إنشاء الحساب وربط الأبناء", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool isDark,
    bool isPass = false,
    TextInputType inputType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        keyboardType: inputType,
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: Icon(icon, color: Colors.grey),
          filled: true,
          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
