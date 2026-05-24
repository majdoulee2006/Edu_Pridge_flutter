import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController   = TextEditingController();
  final _contentController = TextEditingController();
  final _linkController    = TextEditingController();

  String _targetAudience = 'all';
  bool _isLoading = false;
  File? _pickedImage;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFFCCAA00)),
              title: const Text('التقاط صورة'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFFCCAA00)),
              title: const Text('اختيار من المعرض'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final formData = FormData.fromMap({
        'title':           _titleController.text.trim(),
        'content':         _contentController.text.trim(),
        'target_audience': _targetAudience,
        'link_url':        _linkController.text.trim(),
        'allow_comments':  '0',
        if (_pickedImage != null)
          'image': await MultipartFile.fromFile(
            _pickedImage!.path,
            filename: _pickedImage!.path.split('/').last,
          ),
      });

      await Dio().post(
        '${ApiService().baseUrl}/department-head/announcements',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم نشر الإعلان بنجاح')),
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ?? 'حدث خطأ، حاول مجدداً';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text('نشر إعلان جديد',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: Icon(Icons.arrow_forward,
                color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // عنوان الإعلان
                _sectionLabel('عنوان الإعلان', textColor),
                const SizedBox(height: 8),
                _buildField(
                  controller: _titleController,
                  hint: 'أدخل عنوان الإعلان',
                  cardColor: cardColor,
                  textColor: textColor,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null,
                ),
                const SizedBox(height: 20),

                // محتوى الإعلان
                _sectionLabel('محتوى الإعلان', textColor),
                const SizedBox(height: 8),
                _buildField(
                  controller: _contentController,
                  hint: 'اكتب تفاصيل الإعلان هنا...',
                  cardColor: cardColor,
                  textColor: textColor,
                  maxLines: 6,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'المحتوى مطلوب' : null,
                ),
                const SizedBox(height: 20),

                // صورة مرفقة (اختياري)
                _sectionLabel('صورة مرفقة (اختياري)', textColor),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showImageSourceSheet,
                  child: Container(
                    width: double.infinity,
                    height: _pickedImage != null ? null : 110,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFCCAA00).withValues(alpha: 0.4),
                          style: BorderStyle.solid),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _pickedImage != null
                        ? Stack(
                            children: [
                              Image.file(_pickedImage!,
                                  width: double.infinity,
                                  fit: BoxFit.cover),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() => _pickedImage = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_photo_alternate_outlined,
                                  color: Color(0xFFCCAA00), size: 36),
                              SizedBox(height: 6),
                              Text('اضغط لإضافة صورة',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // رابط خارجي (اختياري)
                _sectionLabel('رابط خارجي (اختياري)', textColor),
                const SizedBox(height: 8),
                _buildField(
                  controller: _linkController,
                  hint: 'https://...',
                  cardColor: cardColor,
                  textColor: textColor,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 20),

                // الجمهور المستهدف
                _sectionLabel('الجمهور المستهدف', textColor),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      _targetChip('طلاب فقط',  'students', textColor),
                      _targetChip('معلمون فقط', 'teachers', textColor),
                      _targetChip('الجميع',     'all',      textColor),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // زر النشر
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCCAA00),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : const Text('نشر الإعلان',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color textColor) {
    return Text(text,
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor));
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required Color cardColor,
    required Color textColor,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _targetChip(String label, String value, Color textColor) {
    final isSelected = _targetAudience == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _targetAudience = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFCCAA00) : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isSelected ? Colors.black : Colors.grey)),
          ),
        ),
      ),
    );
  }
}
