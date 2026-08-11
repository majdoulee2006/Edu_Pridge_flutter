import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:edu_pridge_flutter/services/affairs_services.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:dio/dio.dart';

class EditActivityScreen extends StatefulWidget {
  final Map<String, dynamic> activity;
  const EditActivityScreen({super.key, required this.activity});

  @override
  State<EditActivityScreen> createState() => _EditActivityScreenState();
}

class _EditActivityScreenState extends State<EditActivityScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _fetchMetadata();
    _titleController.text = (widget.activity["title"] ?? widget.activity["name"] ?? "").toString();
    _contentController.text = (widget.activity["content"] ?? widget.activity["body"] ?? widget.activity["details"] ?? "").toString();
    _locationController.text = (widget.activity["location"] ?? "").toString();
    _categoryController.text = (widget.activity["category"] ?? "").toString();

    final aud = widget.activity["target_audience"]?.toString();
    if (aud != null && _audiences.containsKey(aud)) {
      _selectedAudience = aud;
    } else {
      _selectedAudience = "all";
    }

    if (widget.activity["department_id"] != null) {
      _selectedDepartment = widget.activity["department_id"].toString();
    }
    if (widget.activity["course_id"] != null) {
      _selectedCourse = widget.activity["course_id"].toString();
    }

    if (widget.activity["event_date"] != null) {
      try {
        _selectedDate = DateTime.parse(widget.activity["event_date"].toString());
      } catch (e) {}
    }
    if (widget.activity["event_time"] != null) {
      try {
        final timeStr = widget.activity["event_time"].toString();
        final parts = timeStr.split(":");
        if (parts.length >= 2) {
          _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      } catch (e) {}
    }
  }

  Future<void> _fetchMetadata() async {
    await ApiService.init();
    final meta = await AffairsServices().getMetadata();
    if (mounted) {
      final List fetchedDepts = (meta != null && meta['departments'] is List) ? meta['departments'] : [];
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
        _courses = (meta != null && meta['courses'] is List) ? meta['courses'] : [];
        if (widget.activity["department_id"] != null) {
          _selectedDepartment = widget.activity["department_id"].toString();
        }
        if (widget.activity["course_id"] != null) {
          _selectedCourse = widget.activity["course_id"].toString();
        }
      });
    }
  }

  List<dynamic> _getFilteredCourses() {
    if (_selectedDepartment == null) return [];
    final selDeptStr = _selectedDepartment.toString();
    final selDeptInt = int.tryParse(selDeptStr);

    return _courses.where((c) {
      final deptIds = c['department_ids'];
      if (deptIds is List) {
        if (deptIds.contains(selDeptInt) ||
            deptIds.contains(selDeptStr) ||
            deptIds.map((e) => e.toString()).contains(selDeptStr)) {
          return true;
        }
      }
      final singleDeptId = c['department_id'] ?? c['dept_id'];
      if (singleDeptId != null && singleDeptId.toString() == selDeptStr) {
        return true;
      }
      return false;
    }).toList();
  }

  final TextEditingController _categoryController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? selectedImagePath;

  bool isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
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

  Future<void> _submitActivity() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      _showSnackBar("يرجى إدخال عنوان النشاط");
      return;
    }
    if (content.isEmpty) {
      _showSnackBar("يرجى إدخال تفاصيل النشاط");
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      _showSnackBar("يرجى تحديد تاريخ ووقت النشاط");
      return;
    }



    setState(() => isSubmitting = true);

    try {
      FormData formData = FormData.fromMap({
        'title': title,
        'content': content,
        'category': _categoryController.text.trim().isNotEmpty ? _categoryController.text.trim() : 'عام',
        'target_audience': _selectedAudience,
        'event_date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'event_time': "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00",
        if (_locationController.text.trim().isNotEmpty) 'location': _locationController.text.trim(),
        if (_selectedDepartment != null) 'department_id': _selectedDepartment,
        if (_selectedCourse != null) 'course_id': _selectedCourse,
      });

      if (selectedImagePath != null) {
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(selectedImagePath!),
        ));
      }

      final result = await AffairsServices().updateActivity(widget.activity["id"] ?? widget.activity["announcement_id"], formData);

      if (mounted) {
        setState(() => isSubmitting = false);
        if (result != null) {
          _showSnackBar("تم تعديل النشاط بنجاح", isError: false);
          Navigator.pop(context, true);
        } else {
          _showSnackBar("فشل نشر النشاط، يرجى المحاولة لاحقاً");
        }
      }
    } catch (e) {
      setState(() => isSubmitting = false);
      _showSnackBar("حدث خطأ أثناء الاتصال بالخادم");
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
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          title: const Text(
            "تعديل النشاط",
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
                    // عنوان النشاط
                    TextField(
                      controller: _titleController,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Noto Sans Arabic'),
                      decoration: const InputDecoration(
                        hintText: "عنوان النشاط (مثال: رحلة علمية)",
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
                                "تصنيف النشاط:",
                                style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Noto Sans Arabic'),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _categoryController,
                                style: TextStyle(color: textColor, fontFamily: 'Noto Sans Arabic', fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: "مثال: رحلة، اجتماع...",
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
                    Builder(
                      builder: (context) {
                        final filteredCourses = _getFilteredCourses();
                        final isDeptSelected = _selectedDepartment != null;

                        return Row(
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
                                    value: _departments.any((d) => (d['department_id'] ?? d['id']).toString() == _selectedDepartment)
                                        ? _selectedDepartment
                                        : null,
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
                                        final deptId = (dept['department_id'] ?? dept['id']).toString();
                                        final deptName = (dept['name'] ?? dept['title'] ?? '').toString();
                                        return DropdownMenuItem<String>(
                                          value: deptId,
                                          child: Text(deptName, overflow: TextOverflow.ellipsis),
                                        );
                                      }),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedDepartment = val;
                                        _selectedCourse = null; // إعادة تعيين الدورة إلى كل الدورات عند تغيير القسم
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDeptSelected ? textColor : Colors.grey,
                                      fontFamily: 'Noto Sans Arabic',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: (isDeptSelected && filteredCourses.any((c) => (c['course_id'] ?? c['id']).toString() == _selectedCourse))
                                        ? _selectedCourse
                                        : null,
                                    decoration: InputDecoration(
                                      fillColor: isDeptSelected ? cardColor : cardColor.withAlpha(128),
                                      filled: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                    ),
                                    dropdownColor: cardColor,
                                    style: TextStyle(color: isDeptSelected ? textColor : Colors.grey, fontFamily: 'Noto Sans Arabic', fontSize: 13),
                                    items: [
                                      DropdownMenuItem<String>(
                                        value: null,
                                        child: Text(
                                          isDeptSelected ? "كل الدورات في هذا القسم" : "كل الدورات (إجباري عند اختيار كل الأقسام)",
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isDeptSelected)
                                        ...filteredCourses.map((c) {
                                          final courseId = (c['course_id'] ?? c['id']).toString();
                                          final courseTitle = (c['title'] ?? c['name'] ?? '').toString();
                                          return DropdownMenuItem<String>(
                                            value: courseId,
                                            child: Text(courseTitle, overflow: TextOverflow.ellipsis),
                                          );
                                        }),
                                    ],
                                    onChanged: isDeptSelected
                                        ? (val) {
                                            setState(() => _selectedCourse = val);
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // التاريخ والوقت
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "التاريخ:",
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
                                "الوقت:",
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

                    // محتوى النشاط / التفاصيل
                    Text(
                      "تفاصيل النشاط:",
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
                          hintText: "اكتب تفاصيل النشاط هنا...",
                          hintStyle: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Noto Sans Arabic'),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // موقع النشاط
                    Text(
                      "الموقع (اختياري):",
                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Noto Sans Arabic'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationController,
                      style: TextStyle(fontSize: 16, color: textColor, fontFamily: 'Noto Sans Arabic'),
                      decoration: InputDecoration(
                        hintText: "مثال: المسرح المدرسي",
                        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Noto Sans Arabic'),
                        fillColor: cardColor,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // إرفاق صورة للنشاط
                    Text(
                      "إرفاق صورة للنشاط (اختياري):",
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
                            : (widget.activity["image_url"] != null && widget.activity["image_url"].toString().isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.network(
                                      widget.activity["image_url"].toString(),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey.shade400),
                                          const SizedBox(height: 8),
                                          Text("تغيير الصورة الحالية", style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Noto Sans Arabic')),
                                        ],
                                      ),
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
                    onPressed: _submitActivity,
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
                          "حفظ التعديلات",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Noto Sans Arabic'),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.event_available, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
