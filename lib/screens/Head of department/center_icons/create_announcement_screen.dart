import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:dio/dio.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  String _selectedAudience = 'all';
  final Map<String, String> _audiences = {
    'all': 'كل المعهد (عام)',
    'students': 'الطلاب في قسم/دورة',
    'teachers': 'المعلمين في قسم/دورة',
    'heads': 'رؤساء الأقسام',
    'department': 'قسم معين',
  };

  List<dynamic> _departments = [];
  List<dynamic> _courses = [];
  String? _selectedDepartment;
  String? _selectedCourse;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? selectedImagePath;

  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchMetadata();
  }

  Future<void> _fetchMetadata() async {
    try {
      await ApiService.init();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await Dio().get(
        "${ApiService().baseUrl}/department-head/metadata",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (res.statusCode == 200 && res.data['success'] == true && mounted) {
        final List fetchedDepts = res.data['data']['departments'] ?? [];
        setState(() {
          if (fetchedDepts.isNotEmpty) {
            _departments = fetchedDepts;
          } else {
            _departments = [
              {'department_id': 1, 'name': 'قسم نظم المعلومات'},
              {'department_id': 2, 'name': 'قسم تجاري'},
              {'department_id': 3, 'name': 'قسم طبي'},
              {'department_id': 4, 'name': 'قسم هندسي'},
            ];
          }
          _courses = res.data['data']['courses'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("❌ fetch metadata error: $e");
    } finally {
      if (mounted && _departments.isEmpty) {
        setState(() {
          _departments = [
            {'department_id': 1, 'name': 'قسم نظم المعلومات'},
            {'department_id': 2, 'name': 'قسم تجاري'},
            {'department_id': 3, 'name': 'قسم طبي'},
            {'department_id': 4, 'name': 'قسم هندسي'},
          ];
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCropImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'تعديل الصورة',
            toolbarColor: const Color(0xFFFFCC00),
            toolbarWidgetColor: Colors.black,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'تعديل الصورة'),
        ],
      );
      if (croppedFile != null) {
        setState(() {
          selectedImagePath = croppedFile.path;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFFCC00),
              onPrimary: Colors.black,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFFCC00),
              onPrimary: Colors.black,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _submitAnnouncement() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      _showSnackBar("يرجى إدخال عنوان الإعلان");
      return;
    }
    if (content.isEmpty) {
      _showSnackBar("يرجى إدخال تفاصيل الإعلان");
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      Map<String, dynamic> mapData = {
        'title': title,
        'content': content,
        'category': _categoryController.text.trim().isNotEmpty ? _categoryController.text.trim() : 'عام',
        'target_audience': _selectedAudience,
        if (_selectedDate != null) 'event_date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        if (_selectedTime != null) 'event_time': "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00",
        if (_locationController.text.trim().isNotEmpty) 'location': _locationController.text.trim(),
        if (_linkController.text.trim().isNotEmpty) 'link_url': _linkController.text.trim(),
        if (_selectedDepartment != null) 'department_id': _selectedDepartment,
        if (_selectedCourse != null) 'course_id': _selectedCourse,
      };

      FormData formData = FormData.fromMap(mapData);

      if (selectedImagePath != null) {
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(selectedImagePath!),
        ));
      }

      final response = await Dio().post(
        '${ApiService().baseUrl}/department-head/announcements',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (mounted) {
        setState(() => isSubmitting = false);
        if (response.statusCode == 200 && response.data['success'] == true) {
          _showSnackBar("تم نشر الإعلان بنجاح", isError: false);
          Navigator.pop(context, true);
        } else {
          _showSnackBar("فشل نشر الإعلان، يرجى المحاولة لاحقاً");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSubmitting = false);
        _showSnackBar("حدث خطأ أثناء الاتصال بالخادم");
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Noto Sans Arabic')),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryYellow = const Color(0xFFFFCC00);
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF1E2633) : Colors.white;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8),
          elevation: 0,
          title: const Text(
            "نشر إعلان جديد",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Noto Sans Arabic'),
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: textColor),
          ),
        ),
        body: isSubmitting
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عنوان الإعلان
                    TextField(
                      controller: _titleController,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Noto Sans Arabic'),
                      decoration: const InputDecoration(
                        hintText: "عنوان الإعلان (مثال: تنبيه هامي للمؤهلات)",
                        hintStyle: TextStyle(fontSize: 18, color: Colors.grey, fontFamily: 'Noto Sans Arabic'),
                        border: UnderlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // اختيار الجمهور المستهدف والتصنيف
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "الجمهور المستهدف:",
                                style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Noto Sans Arabic'),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedAudience,
                                decoration: InputDecoration(
                                  fillColor: cardColor,
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                ),
                                dropdownColor: cardColor,
                                style: TextStyle(color: textColor, fontFamily: 'Noto Sans Arabic', fontSize: 13),
                                items: _audiences.entries.map((entry) {
                                  return DropdownMenuItem<String>(
                                    value: entry.key,
                                    child: Text(entry.value, overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedAudience = val ?? "all";
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "تصنيف الإعلان:",
                                style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Noto Sans Arabic'),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _categoryController,
                                style: TextStyle(color: textColor, fontFamily: 'Noto Sans Arabic', fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: "مثال: إداري، تنبيه...",
                                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey, fontFamily: 'Noto Sans Arabic'),
                                  fillColor: cardColor,
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "القسم (اختياري):",
                                style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Noto Sans Arabic'),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedDepartment,
                                decoration: InputDecoration(
                                  fillColor: cardColor,
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                ),
                                dropdownColor: cardColor,
                                style: TextStyle(color: textColor, fontFamily: 'Noto Sans Arabic', fontSize: 13),
                                items: [
                                  const DropdownMenuItem<String>(value: null, child: Text("كل الأقسام", overflow: TextOverflow.ellipsis)),
                                  ..._departments.map((dept) {
                                    return DropdownMenuItem<String>(
                                      value: dept['department_id'].toString(),
                                      child: Text(dept['name'].toString(), overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    _selectedDepartment = val;
                                    _selectedCourse = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "الدورة (اختياري):",
                                style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Noto Sans Arabic'),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedCourse,
                                decoration: InputDecoration(
                                  fillColor: cardColor,
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                ),
                                dropdownColor: cardColor,
                                style: TextStyle(color: textColor, fontFamily: 'Noto Sans Arabic', fontSize: 13),
                                items: [
                                  const DropdownMenuItem<String>(value: null, child: Text("كل الدورات", overflow: TextOverflow.ellipsis)),
                                  ..._courses.map((c) {
                                    return DropdownMenuItem<String>(
                                      value: (c['course_id'] ?? c['id']).toString(),
                                      child: Text((c['title'] ?? c['name'] ?? '').toString(), overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (val) {
                                  setState(() => _selectedCourse = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // التاريخ والوقت (اختياري)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "التاريخ (اختياري):",
                                style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Noto Sans Arabic'),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _pickDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedDate == null ? 'اختر التاريخ' : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                                        style: TextStyle(color: _selectedDate == null ? Colors.grey : textColor, fontSize: 13, fontFamily: 'Noto Sans Arabic'),
                                      ),
                                      Icon(Icons.calendar_today, color: Colors.grey.shade400, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "الوقت (اختياري):",
                                style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Noto Sans Arabic'),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _pickTime,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedTime == null ? 'اختر الوقت' : _selectedTime!.format(context),
                                        style: TextStyle(color: _selectedTime == null ? Colors.grey : textColor, fontSize: 13, fontFamily: 'Noto Sans Arabic'),
                                      ),
                                      Icon(Icons.access_time, color: Colors.grey.shade400, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // تفاصيل الإعلان
                    Text(
                      "تفاصيل الإعلان:",
                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Noto Sans Arabic'),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.withAlpha(30)),
                      ),
                      child: TextField(
                        controller: _contentController,
                        maxLines: 5,
                        style: TextStyle(fontSize: 16, color: textColor, fontFamily: 'Noto Sans Arabic'),
                        decoration: const InputDecoration(
                          hintText: "اكتب تفاصيل الإعلان هنا...",
                          hintStyle: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Noto Sans Arabic'),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // الموقع (اختياري)
                    Text(
                      "الموقع (اختياري):",
                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Noto Sans Arabic'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationController,
                      style: TextStyle(fontSize: 16, color: textColor, fontFamily: 'Noto Sans Arabic'),
                      decoration: InputDecoration(
                        hintText: "مثال: المسرح الجامعي",
                        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Noto Sans Arabic'),
                        fillColor: cardColor,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // رابط خارجي (اختياري)
                    Text(
                      "رابط خارجي (اختياري):",
                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Noto Sans Arabic'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _linkController,
                      keyboardType: TextInputType.url,
                      style: TextStyle(fontSize: 16, color: textColor, fontFamily: 'Noto Sans Arabic'),
                      decoration: InputDecoration(
                        hintText: "https://...",
                        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Noto Sans Arabic'),
                        fillColor: cardColor,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // إرفاق صورة للإعلان
                    Text(
                      "إرفاق صورة للإعلان (اختياري):",
                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Noto Sans Arabic'),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickAndCropImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.withAlpha(50)),
                        ),
                        child: selectedImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.file(
                                  File(selectedImagePath!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text("اضغط لإضافة صورة", style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Noto Sans Arabic')),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: isSubmitting
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _submitAnnouncement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryYellow,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 58),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "نشر الإعلان",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Noto Sans Arabic'),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.campaign, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
