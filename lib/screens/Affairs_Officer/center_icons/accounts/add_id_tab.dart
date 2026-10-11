import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class AddIdTab extends StatefulWidget {
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final bool isDark;

  const AddIdTab({
    super.key,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.isDark,
  });

  @override
  State<AddIdTab> createState() => _AddIdTabState();
}

class _AddIdTabState extends State<AddIdTab> {
  final TextEditingController _firstNameController  = TextEditingController();
  final TextEditingController _lastNameController   = TextEditingController();
  final TextEditingController _phoneController      = TextEditingController();
  final TextEditingController _telegramController   = TextEditingController(text: '7821980919');
  final TextEditingController _searchController     = TextEditingController();
  final ApiService _api = ApiService();
  final Dio _dio = Dio();

  File? _selectedPhoto;
  bool _isLoading = false;
  bool _isLoadingId = false;
  String _generatedId = '';
  DateTime? _selectedBirth;
  List<Map<String, dynamic>> universityIds = [];

  bool get isAr => AppSettings.language.value == 'ar';

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    _loadNextId();
    _loadUniversityIds();
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _telegramController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNextId() async {
    setState(() => _isLoadingId = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await _dio.get(
        '${_api.baseUrl}/affairs/university-ids/next-id',
        options: Options(headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        setState(() => _generatedId = res.data['university_id'].toString());
      }
    } catch (e) {
      debugPrint('Next ID error: $e');
    } finally {
      setState(() => _isLoadingId = false);
    }
  }

  Future<void> _loadUniversityIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await _dio.get(
        '${_api.baseUrl}/affairs/university-ids',
        options: Options(headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        setState(() {
          universityIds = List<Map<String, dynamic>>.from(res.data['data']);
        });
      }
    } catch (e) {
      debugPrint('Load IDs Error: $e');
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: widget.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(isAr ? 'اختر مصدر الصورة' : 'Select Photo Source',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.textColor, fontFamily: 'Noto Sans Arabic')),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFFFCC00)),
              title: Text(isAr ? 'الكاميرا' : 'Camera', style: TextStyle(color: widget.textColor, fontFamily: 'Noto Sans Arabic')),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFFFCC00)),
              title: Text(isAr ? 'معرض الصور' : 'Gallery', style: TextStyle(color: widget.textColor, fontFamily: 'Noto Sans Arabic')),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ]),
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(source: source, maxWidth: 800, imageQuality: 85);
    if (picked != null) setState(() => _selectedPhoto = File(picked.path));
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(now.year - 22, now.month, now.day),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFFFFCC00),
            onPrimary: Colors.black,
            surface: widget.cardColor,
            onSurface: widget.textColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedBirth = picked);
  }

  Future<void> _addUniversityId() async {
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
      _showError(isAr ? 'الرجاء إدخال الاسم الأول والأخير' : 'Please enter first and last name');
      return;
    }
    if (_selectedPhoto == null) {
      _showError(isAr ? 'الرجاء إرفاق صورة الطالب قبل الإنشاء' : 'Please attach student photo before creating');
      return;
    }
    if (_generatedId.isEmpty) {
      _showError(isAr ? 'لم يتم توليد الرقم الجامعي بعد' : 'University ID has not been generated yet');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final formData = FormData.fromMap({
        'first_name':    _firstNameController.text.trim(),
        'last_name':     _lastNameController.text.trim(),
        'university_id': _generatedId,
        if (_selectedBirth != null)
          'date_of_birth': '${_selectedBirth!.year}-${_selectedBirth!.month.toString().padLeft(2,'0')}-${_selectedBirth!.day.toString().padLeft(2,'0')}',
        if (_phoneController.text.isNotEmpty)
          'phone': _phoneController.text.trim(),
        if (_telegramController.text.isNotEmpty)
          'telegram_chat_id': _telegramController.text.trim(),
        if (_selectedPhoto != null)
          'photo': await MultipartFile.fromFile(_selectedPhoto!.path, filename: 'student_$_generatedId.jpg'),
      });

      final res = await _dio.post(
        '${_api.baseUrl}/affairs/university-ids',
        data: formData,
        options: Options(headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'}),
      );

      if (res.statusCode == 200 && res.data['success'] == true) {
        _firstNameController.clear();
        _lastNameController.clear();
        _phoneController.clear();
        _telegramController.text = '7821980919';
        setState(() { _selectedPhoto = null; _selectedBirth = null; });
        await _loadNextId();
        await _loadUniversityIds();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              isAr ? 'تم إضافة الرقم الجامعي بنجاح ✓' : 'University ID added successfully ✓',
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            ),
            backgroundColor: Colors.green,
          ));
        }
      } else {
        _showError(res.data['message'] ?? (isAr ? 'حدث خطأ' : 'An error occurred'));
      }
    } on DioException catch (e) {
      _showError(e.response?.data?['message'] ?? (isAr ? 'فشل الاتصال بالسيرفر' : 'Failed to connect to server'));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textDirection: isAr ? TextDirection.rtl : TextDirection.ltr),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
        children: [
          // ── بحث ─────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: widget.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(widget.isDark ? 20 : 5), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: TextField(
              controller: _searchController,
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              style: TextStyle(color: widget.textColor, fontFamily: 'Noto Sans Arabic'),
              decoration: InputDecoration(
                hintText: isAr ? 'البحث برقم جامعي أو اسم...' : 'Search by university ID or name...',
                hintStyle: TextStyle(color: widget.subColor, fontFamily: 'Noto Sans Arabic'),
                prefixIcon: Icon(Icons.search, color: widget.subColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            isAr ? 'إضافة رقم جامعي جديد' : 'Add New University ID',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.textColor, fontFamily: 'Noto Sans Arabic'),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(widget.isDark ? 20 : 5), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(children: [
              // صورة الطالب
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: widget.isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFCC00), width: 2),
                    image: _selectedPhoto != null
                        ? DecorationImage(image: FileImage(_selectedPhoto!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _selectedPhoto == null
                      ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.camera_alt, color: widget.subColor, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            isAr ? 'صورة الطالب' : 'Student Photo',
                            style: TextStyle(fontSize: 10, color: widget.subColor, fontFamily: 'Noto Sans Arabic'),
                          ),
                        ])
                      : null,
                ),
              ),
              if (_selectedPhoto != null)
                TextButton.icon(
                  onPressed: () => setState(() => _selectedPhoto = null),
                  icon: const Icon(Icons.close, color: Colors.red, size: 16),
                  label: Text(
                    isAr ? 'إزالة الصورة' : 'Remove Photo',
                    style: const TextStyle(color: Colors.red, fontSize: 12, fontFamily: 'Noto Sans Arabic'),
                  ),
                ),

              const SizedBox(height: 16),

              // الرقم الجامعي التلقائي
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFCC00).withValues(alpha: 0.5)),
                ),
                child: Row(children: [
                  const Icon(Icons.badge_outlined, color: Color(0xFFFFCC00), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _isLoadingId
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFCC00)))
                        : Text(
                            isAr ? 'الرقم الجامعي: $_generatedId' : 'University ID: $_generatedId',
                            style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold, fontFamily: 'Noto Sans Arabic'),
                          ),
                  ),
                  Text(
                    isAr ? 'تلقائي' : 'Auto',
                    style: TextStyle(color: widget.subColor, fontSize: 11, fontFamily: 'Noto Sans Arabic'),
                  ),
                ]),
              ),

              const SizedBox(height: 12),

              // الاسم الأول والأخير
              Row(children: [
                Expanded(child: _buildField(_firstNameController, isAr ? 'الاسم الأول' : 'First Name')),
                const SizedBox(width: 10),
                Expanded(child: _buildField(_lastNameController, isAr ? 'الاسم الأخير' : 'Last Name')),
              ]),

              const SizedBox(height: 12),

              // تاريخ الميلاد
              GestureDetector(
                onTap: _pickBirthDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: widget.isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(Icons.cake_outlined, color: widget.subColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      _selectedBirth != null
                          ? '${_selectedBirth!.year}-${_selectedBirth!.month.toString().padLeft(2,'0')}-${_selectedBirth!.day.toString().padLeft(2,'0')}'
                          : (isAr ? 'تاريخ الميلاد' : 'Date of Birth'),
                      style: TextStyle(
                        color: _selectedBirth != null ? widget.textColor : widget.subColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 12),

              // رقم الهاتف
              _buildField(_phoneController, isAr ? 'رقم الهاتف' : 'Phone Number', icon: Icons.phone_outlined, type: TextInputType.phone),

              const SizedBox(height: 12),

              // Telegram ID
              _buildField(_telegramController, 'Telegram Chat ID', icon: Icons.telegram, type: TextInputType.number),

              const SizedBox(height: 16),

              // زر الإضافة
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _addUniversityId,
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.add, color: Colors.black),
                  label: Text(
                    _isLoading
                        ? (isAr ? 'جاري الإضافة...' : 'Adding...')
                        : (isAr ? 'إضافة وإرسال للتلغرام' : 'Add & Send to Telegram'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Noto Sans Arabic'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          Row(children: [
            Container(width: 4, height: 24, decoration: BoxDecoration(color: const Color(0xFFFFCC00), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Text(
              isAr ? 'الأرقام الجامعية المضافة' : 'Added University IDs',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.textColor, fontFamily: 'Noto Sans Arabic'),
            ),
          ]),

          const SizedBox(height: 16),

          ..._buildIdList(),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint,
      {IconData? icon, TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      keyboardType: type,
      style: TextStyle(color: widget.textColor, fontFamily: 'Noto Sans Arabic'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: widget.subColor, fontFamily: 'Noto Sans Arabic'),
        prefixIcon: icon != null ? Icon(icon, color: widget.subColor, size: 20) : null,
        filled: true,
        fillColor: widget.isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  List<Widget> _buildIdList() {
    final query = _searchController.text.toLowerCase();
    final filtered = query.isEmpty
        ? universityIds
        : universityIds.where((item) =>
            (item['university_id'] ?? '').toString().contains(query) ||
            (item['full_name'] ?? '').toString().toLowerCase().contains(query) ||
            (item['first_name'] ?? '').toString().toLowerCase().contains(query) ||
            (item['last_name'] ?? '').toString().toLowerCase().contains(query)).toList();

    return filtered.map((item) {
      final photoUrl = item['photo_url'] as String?;
      final fixedPhotoUrl = photoUrl != null ? ApiService.fixMediaUrl(photoUrl) : null;
      final name = item['full_name'] ?? '${item['first_name'] ?? ''} ${item['last_name'] ?? ''}'.trim();

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(widget.isDark ? 20 : 5), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 45, height: 45,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                image: fixedPhotoUrl != null
                    ? DecorationImage(image: NetworkImage(fixedPhotoUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: fixedPhotoUrl == null ? const Icon(Icons.school_outlined, color: Colors.blue, size: 22) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: widget.textColor, fontFamily: 'Noto Sans Arabic')),
                const SizedBox(height: 2),
                Text(item['university_id'] ?? '', style: TextStyle(fontSize: 13, color: widget.subColor, fontFamily: 'Noto Sans Arabic')),
                if (item['phone'] != null && item['phone'] != '')
                  Text(item['phone'], style: TextStyle(fontSize: 12, color: widget.subColor, fontFamily: 'Noto Sans Arabic')),
              ]),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _showDeleteDialog(item),
            ),
          ]),
        ),
      );
    }).toList();
  }

  void _showDeleteDialog(Map<String, dynamic> item) {
    final name = item['full_name'] ?? '${item['first_name'] ?? ''} ${item['last_name'] ?? ''}'.trim();
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: widget.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isAr ? 'تأكيد الحذف' : 'Confirm Delete',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.textColor, fontFamily: 'Noto Sans Arabic'),
          ),
          content: Text(
            isAr ? 'هل أنت متأكد من حذف $name؟' : 'Are you sure you want to delete $name?',
            textAlign: TextAlign.center,
            style: TextStyle(color: widget.subColor, fontFamily: 'Noto Sans Arabic'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isAr ? 'إلغاء' : 'Cancel', style: TextStyle(color: widget.subColor, fontFamily: 'Noto Sans Arabic')),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final id = item['id']?.toString() ?? '';
                try {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('token') ?? '';
                  await _dio.delete(
                    '${_api.baseUrl}/affairs/university-ids/$id',
                    options: Options(headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'}),
                  );
                  await _loadUniversityIds();
                } catch (e) {
                  setState(() => universityIds.remove(item));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(isAr ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Noto Sans Arabic')),
            ),
          ],
        ),
      ),
    );
  }
}

