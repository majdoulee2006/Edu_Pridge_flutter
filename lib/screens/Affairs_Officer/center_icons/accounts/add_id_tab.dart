import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ApiService _api = ApiService();
  final Dio _dio = Dio();

  File? _selectedPhoto;
  bool _isLoading = false;

  List<Map<String, dynamic>> universityIds = [];

  @override
  void initState() {
    super.initState();
    _loadUniversityIds();
  }

  Future<void> _loadUniversityIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await _dio.get(
        '${_api.baseUrl}/affairs/university-ids',
        options: Options(headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        }),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('اختر مصدر الصورة',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.textColor,
                    fontFamily: 'Noto Sans Arabic')),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFFFCC00)),
              title: Text('الكاميرا',
                  style: TextStyle(color: widget.textColor, fontFamily: 'Noto Sans Arabic')),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFFFCC00)),
              title: Text('معرض الصور',
                  style: TextStyle(color: widget.textColor, fontFamily: 'Noto Sans Arabic')),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    final picked = await picker.pickImage(source: source, maxWidth: 800, imageQuality: 85);
    if (picked != null) {
      setState(() => _selectedPhoto = File(picked.path));
    }
  }

  Future<void> _addUniversityId() async {
    if (_nameController.text.isEmpty || _idController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final formData = FormData.fromMap({
        'full_name': _nameController.text,
        'university_id': _idController.text,
        if (_selectedPhoto != null)
          'photo': await MultipartFile.fromFile(_selectedPhoto!.path,
              filename: 'student_${_idController.text}.jpg'),
      });

      final res = await _dio.post(
        '${_api.baseUrl}/affairs/university-ids',
        data: formData,
        options: Options(headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        }),
      );

      if (res.statusCode == 200 && res.data['success'] == true) {
        _nameController.clear();
        _idController.clear();
        setState(() => _selectedPhoto = null);
        _loadUniversityIds();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة الرقم الجامعي بنجاح ✓',
                  textDirection: TextDirection.rtl),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showError(res.data['message'] ?? 'حدث خطأ');
      }
    } on DioException catch (e) {
      _showError(e.response?.data?['message'] ?? 'فشل الاتصال بالسيرفر');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textDirection: TextDirection.rtl),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
      children: [
        // ═══════════════════════════════════════
        // مربع البحث
        // ═══════════════════════════════════════
        Container(
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(widget.isDark ? 20 : 5),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: widget.textColor,
              fontFamily: 'Noto Sans Arabic',
            ),
            decoration: InputDecoration(
              hintText: 'البحث برقم جامعي...',
              hintStyle: TextStyle(
                color: widget.subColor,
                fontFamily: 'Noto Sans Arabic',
              ),
              prefixIcon: Icon(Icons.search, color: widget.subColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),

        const SizedBox(height: 24),

        // ═══════════════════════════════════════
        // عنوان "إضافة رقم جامعي جديد"
        // ═══════════════════════════════════════
        Text(
          'إضافة رقم جامعي جديد',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.textColor,
            fontFamily: 'Noto Sans Arabic',
          ),
        ),

        const SizedBox(height: 16),

        // ═══════════════════════════════════════
        // الفورم
        // ═══════════════════════════════════════
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(widget.isDark ? 20 : 5),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // ═══════════════════════════════════════
              // 📸 اختيار صورة الطالب
              // ═══════════════════════════════════════
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: widget.isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFCC00),
                      width: 2,
                    ),
                    image: _selectedPhoto != null
                        ? DecorationImage(
                            image: FileImage(_selectedPhoto!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedPhoto == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt,
                                color: widget.subColor, size: 28),
                            const SizedBox(height: 4),
                            Text(
                              'صورة الطالب',
                              style: TextStyle(
                                fontSize: 10,
                                color: widget.subColor,
                                fontFamily: 'Noto Sans Arabic',
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),

              // زر إزالة الصورة
              if (_selectedPhoto != null)
                TextButton.icon(
                  onPressed: () => setState(() => _selectedPhoto = null),
                  icon: const Icon(Icons.close, color: Colors.red, size: 16),
                  label: Text(
                    'إزالة الصورة',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // حقل اسم الطالب
              TextField(
                controller: _nameController,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: widget.textColor,
                  fontFamily: 'Noto Sans Arabic',
                ),
                decoration: InputDecoration(
                  hintText: 'اسم الطالب',
                  hintStyle: TextStyle(
                    color: widget.subColor,
                    fontFamily: 'Noto Sans Arabic',
                  ),
                  filled: true,
                  fillColor: widget.isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),

              const SizedBox(height: 12),

              // حقل الرقم الجامعي
              TextField(
                controller: _idController,
                textDirection: TextDirection.rtl,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: widget.textColor,
                  fontFamily: 'Noto Sans Arabic',
                ),
                decoration: InputDecoration(
                  hintText: 'الرقم الجامعي',
                  hintStyle: TextStyle(
                    color: widget.subColor,
                    fontFamily: 'Noto Sans Arabic',
                  ),
                  filled: true,
                  fillColor: widget.isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),

              const SizedBox(height: 16),

              // زر الإضافة
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _addUniversityId,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.add, color: Colors.black),
                  label: Text(
                    _isLoading ? 'جاري الإضافة...' : 'إضافة',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ═══════════════════════════════════════
        // عنوان "الأرقام الجامعية المضافة"
        // ═══════════════════════════════════════
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFFFCC00),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'الأرقام الجامعية المضافة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.textColor,
                fontFamily: 'Noto Sans Arabic',
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ═══════════════════════════════════════
        // قائمة الأرقام
        // ═══════════════════════════════════════
        ..._buildIdList(),
      ],
    );
  }

  // ═══════════════════════════════════════
  // بناء قائمة الأرقام
  // ═══════════════════════════════════════
  List<Widget> _buildIdList() {
    final filteredList = _searchController.text.isEmpty
        ? universityIds
        : universityIds.where((item) =>
            (item['university_id'] ?? item['id'] ?? '').toString().contains(_searchController.text)).toList();

    return filteredList.map((item) {
      final photoUrl = item['photo_url'] as String?;
      final fixedPhotoUrl = photoUrl != null ? ApiService.fixMediaUrl(photoUrl) : null;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(widget.isDark ? 20 : 5),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // صورة الطالب أو أيقونة افتراضية
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                  image: fixedPhotoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(fixedPhotoUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: fixedPhotoUrl == null
                    ? const Icon(
                        Icons.school_outlined,
                        color: Colors.blue,
                        size: 22,
                      )
                    : null,
              ),

              const SizedBox(width: 12),

              // الاسم + الرقم
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['full_name'] ?? item['name'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.textColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['university_id'] ?? item['id'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.subColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                  ],
                ),
              ),

              // أزرار التعديل والحذف
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.amber, size: 20),
                    onPressed: () => _showEditDialog(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => _showDeleteDialog(item),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ═══════════════════════════════════════
  // نافذة التعديل
  // ═══════════════════════════════════════
  void _showEditDialog(Map<String, dynamic> item) {
    final nameEditController = TextEditingController(text: item['full_name'] ?? item['name'] ?? '');
    final idEditController = TextEditingController(text: item['university_id'] ?? item['id'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'تعديل الرقم الجامعي',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.textColor,
              fontFamily: 'Noto Sans Arabic',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameEditController,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: widget.textColor, fontFamily: 'Noto Sans Arabic'),
                decoration: InputDecoration(
                  labelText: 'اسم الطالب',
                  labelStyle: TextStyle(color: widget.subColor, fontFamily: 'Noto Sans Arabic'),
                  filled: true,
                  fillColor: widget.isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: idEditController,
                textDirection: TextDirection.rtl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: widget.textColor, fontFamily: 'Noto Sans Arabic'),
                decoration: InputDecoration(
                  labelText: 'الرقم الجامعي',
                  labelStyle: TextStyle(color: widget.subColor, fontFamily: 'Noto Sans Arabic'),
                  filled: true,
                  fillColor: widget.isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  color: widget.subColor,
                  fontFamily: 'Noto Sans Arabic',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  item['full_name'] = nameEditController.text;
                  item['name'] = nameEditController.text;
                  item['university_id'] = idEditController.text;
                  item['id'] = idEditController.text;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCC00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'حفظ',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Noto Sans Arabic',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════
  // نافذة تأكيد الحذف
  // ═══════════════════════════════════════
  void _showDeleteDialog(Map<String, dynamic> item) {
    final name = item['full_name'] ?? item['name'] ?? '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'تأكيد الحذف',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.textColor,
              fontFamily: 'Noto Sans Arabic',
            ),
          ),
          content: Text(
            'هل أنت متأكد من حذف $name؟',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.subColor,
              fontFamily: 'Noto Sans Arabic',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  color: widget.subColor,
                  fontFamily: 'Noto Sans Arabic',
                ),
              ),
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
                    options: Options(headers: {
                      'Accept': 'application/json',
                      'Authorization': 'Bearer $token',
                    }),
                  );
                  _loadUniversityIds();
                } catch (e) {
                  setState(() {
                    universityIds.remove(item);
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'حذف',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Noto Sans Arabic',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}