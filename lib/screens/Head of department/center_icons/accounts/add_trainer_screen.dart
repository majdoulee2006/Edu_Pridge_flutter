import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

class AddTrainerScreen extends StatefulWidget {
  const AddTrainerScreen({super.key});

  @override
  State<AddTrainerScreen> createState() => _AddTrainerScreenState();
}

class _AddTrainerScreenState extends State<AddTrainerScreen> {
  final _nameController     = TextEditingController();
  final _phoneController    = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading   = false;
  bool _isLoadingCourses = false;

  String? _selectedSpecialization;
  final List<String> _specializations = ['نظم المعلومات', 'طبي', 'تجاري', 'هندسي'];

  List<Map<String, dynamic>> _allCourses = [];
  final Set<int> _selectedCourseIds = {};

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoadingCourses = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await Dio().get(
        "${ApiService().baseUrl}/department-head/courses",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final data = res.data['data'] as List<dynamic>? ?? [];
        setState(() {
          _allCourses = data
              .map<Map<String, dynamic>>((c) => {
                    'id': (c['id'] as num).toInt(),
                    'title': c['title'].toString(),
                  })
              .toList();
        });
      }
    } catch (e) {
      debugPrint('⛔ Fetch Courses Error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingCourses = false);
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _selectedSpecialization == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة جميع الحقول المطلوبة')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      await Dio().post(
        "${ApiService().baseUrl}/department-head/users/trainer",
        data: {
          'full_name':      _nameController.text.trim(),
          'phone':          _phoneController.text.trim(),
          'email':          _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          'specialization': _selectedSpecialization,
          'password':       _passwordController.text.trim(),
          'course_ids':     _selectedCourseIds.toList(),
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إنشاء حساب المدرب بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('⛔ Add Trainer Error: $e');
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
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final cardColor   = Theme.of(context).cardColor;
    final textColor   = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    const yellow      = Color(0xFFFFCC00);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("إنشاء حساب مدرب"), centerTitle: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── الاسم ──
              _customField("اسم المدرب الكامل", Icons.person, _nameController, isDark),

              // ── رقم الهاتف (يستخدمه للدخول) ──
              _customField("رقم الهاتف (للدخول)", Icons.phone, _phoneController, isDark,
                  inputType: TextInputType.phone),

              // ── الاختصاص ──
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: InputDecorator(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.school),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSpecialization,
                      hint: const Text('القسم الذي يدرس فيه'),
                      isExpanded: true,
                      items: _specializations
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedSpecialization = val),
                    ),
                  ),
                ),
              ),

              // ── البريد (اختياري) وكلمة المرور ──
              _customField("البريد الإلكتروني (اختياري)", Icons.email, _emailController, isDark,
                  inputType: TextInputType.emailAddress),
              _customField("كلمة المرور", Icons.lock, _passwordController, isDark, isPass: true),

              const SizedBox(height: 10),

              // ── المواد الدراسية ──
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Row(
                        children: [
                          const Icon(Icons.menu_book, color: yellow, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'المواد الدراسية التي يدرّسها',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                          const Spacer(),
                          if (_selectedCourseIds.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: yellow.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_selectedCourseIds.length} مختار',
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (_isLoadingCourses)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator(color: yellow)),
                      )
                    else if (_allCourses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('لا توجد مواد متاحة', style: TextStyle(color: Colors.grey)),
                      )
                    else
                      ...(_allCourses.map((course) {
                        final id = course['id'] as int;
                        final isSelected = _selectedCourseIds.contains(id);
                        return InkWell(
                          onTap: () => setState(() {
                            if (isSelected) {
                              _selectedCourseIds.remove(id);
                            } else {
                              _selectedCourseIds.add(id);
                            }
                          }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  activeColor: yellow,
                                  checkColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4)),
                                  onChanged: (_) => setState(() {
                                    if (isSelected) {
                                      _selectedCourseIds.remove(id);
                                    } else {
                                      _selectedCourseIds.add(id);
                                    }
                                  }),
                                ),
                                Expanded(
                                  child: Text(
                                    course['title'] as String,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      })),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ── زر الحفظ ──
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2))
                      : const Text(
                          "حفظ البيانات",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customField(
    String hint,
    IconData icon,
    TextEditingController controller,
    bool isDark, {
    bool isPass = false,
    TextInputType inputType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        keyboardType: inputType,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}
