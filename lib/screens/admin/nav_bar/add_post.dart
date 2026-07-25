import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/services/admin_services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';

class AddPostScreen extends StatefulWidget {
  final Map<String, dynamic>? announcement;
  const AddPostScreen({super.key, this.announcement});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  
  String? selectedImagePath;
  
  String selectedAudience = "all"; // all, students, teachers, department
  int? selectedDepartmentId;
  List<dynamic> departments = [];
  bool isLoadingDepts = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.announcement != null) {
      _titleController.text = widget.announcement!['title'] ?? '';
      _contentController.text = widget.announcement!['content'] ?? '';
      _linkController.text = widget.announcement!['link_url'] ?? widget.announcement!['link'] ?? '';
      selectedAudience = widget.announcement!['target_audience'] ?? 'all';
    }
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() => isLoadingDepts = true);
    try {
      final depts = await AdminServices().getDepartments();
      if (depts != null && depts.isNotEmpty) {
        setState(() {
          departments = depts.where((d) {
            String name = d['name']?.toString().trim() ?? '';
            return ['نظم معلومات', 'تجاري', 'طبي', 'هندسي'].contains(name);
          }).toList();
          isLoadingDepts = false;
        });
      } else {
        setState(() => isLoadingDepts = false);
      }
    } catch (e) {
      debugPrint("Error loading departments: $e");
    } finally {
      if (departments.isEmpty) {
        // Fallback static list
        departments = [
          {'department_id': 1, 'name': 'نظم معلومات'},
          {'department_id': 2, 'name': 'تجاري'},
          {'department_id': 3, 'name': 'طبي'},
          {'department_id': 4, 'name': 'هندسي'},
        ];
      }
      if (mounted) setState(() => isLoadingDepts = false);
    }
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

  Future<void> _submitPost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final link = _linkController.text.trim();

    if (title.isEmpty) {
      _showSnackBar("يرجى إدخال عنوان المنشور/الإعلان");
      return;
    }
    if (content.isEmpty) {
      _showSnackBar("يرجى إدخال محتوى المنشور/الإعلان");
      return;
    }

    setState(() => isSubmitting = true);
    try {
      bool success = false;
      if (widget.announcement != null) {
        final annId = widget.announcement!['announcement_id'] ?? widget.announcement!['id'];
        success = await AdminServices().updateAnnouncement(
          id: annId,
          title: title,
          content: content,
          targetAudience: selectedAudience,
          departmentId: selectedAudience == 'department' ? selectedDepartmentId : null,
          imagePath: selectedImagePath,
          link: link,
        );
      } else {
        success = await AdminServices().createAnnouncement(
          title: title,
          content: content,
          targetAudience: selectedAudience,
          departmentId: selectedAudience == 'department' ? selectedDepartmentId : null,
          imagePath: selectedImagePath,
          link: link,
        );
      }

      if (success) {
        _showSnackBar(widget.announcement != null ? "تم تعديل الإعلان بنجاح" : "تم نشر الإعلان بنجاح", isError: false);
        Navigator.pop(context);
      } else {
        _showSnackBar("فشل حفظ الإعلان، يرجى المحاولة لاحقاً");
      }
    } on DioException catch (e) {
      debugPrint("Dio Error submitting post: ${e.response?.data}");
      String msg = "حدث خطأ بالاتصال بالسيرفر";
      if (e.response?.data != null && e.response?.data['errors'] != null) {
        msg = e.response!.data['errors'].values.first.first;
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        msg = e.response!.data['message'];
      }
      _showSnackBar(msg);
    } catch (e) {
      debugPrint("Error submitting post: $e");
      _showSnackBar("حدث خطأ بالاتصال بالسيرفر");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Cairo')),
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
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8),
          elevation: 0,
          title: Text(
            widget.announcement != null ? "تعديل المنشور / الإعلان" : "إنشاء منشور جديد",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عنوان المنشور
                    TextField(
                      controller: _titleController,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      decoration: const InputDecoration(
                        hintText: "عنوان الإعلان / المنشور",
                        hintStyle: TextStyle(fontSize: 18, color: Colors.grey),
                        border: UnderlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // اختيار الجمهور المستهدف
                    Text(
                      "الجمهور المستهدف:",
                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedAudience,
                      decoration: InputDecoration(
                        fillColor: cardColor,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      dropdownColor: cardColor,
                      items: const [
                        DropdownMenuItem(value: "all", child: Text("الجميع (عام)")),
                        DropdownMenuItem(value: "students", child: Text("الطلاب فقط")),
                        DropdownMenuItem(value: "teachers", child: Text("المعلمين فقط")),
                        DropdownMenuItem(value: "department", child: Text("قسم معين")),
                      ],
                      onChanged: (val) {
                        setState(() {
                          selectedAudience = val ?? "all";
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // اختيار القسم إذا كان الجمهور قسم معين
                    if (selectedAudience == "department") ...[
                      Text(
                        "اختر القسم الموجه له:",
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      isLoadingDepts
                          ? const CircularProgressIndicator()
                          : DropdownButtonFormField<int>(
                              value: selectedDepartmentId,
                              decoration: InputDecoration(
                                fillColor: cardColor,
                                filled: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              dropdownColor: cardColor,
                              items: departments.map((dept) {
                                return DropdownMenuItem<int>(
                                  value: dept['department_id'],
                                  child: Text(dept['name'] ?? ''),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedDepartmentId = val;
                                });
                              },
                            ),
                      const SizedBox(height: 20),
                    ],

                    // محتوى المنشور
                    Text(
                      "محتوى المنشور:",
                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.withAlpha(50)),
                      ),
                      child: TextField(
                        controller: _contentController,
                        maxLines: 8,
                        style: TextStyle(fontSize: 16, color: textColor),
                        decoration: const InputDecoration(
                          hintText: "اكتب تفاصيل الإعلان هنا...",
                          hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // إرفاق رابط (اختياري)
                    Text(
                      "رابط إضافي (اختياري):",
                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _linkController,
                      style: TextStyle(fontSize: 16, color: textColor),
                      decoration: InputDecoration(
                        hintText: "https://example.com",
                        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                        fillColor: cardColor,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 20),

                    // إرفاق صورة (اختياري)
                    Text(
                      "إرفاق صورة (اختياري):",
                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
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
                                  Text("اضغط لإضافة صورة", style: TextStyle(color: Colors.grey.shade500)),
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
                    onPressed: _submitPost,
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
                          "نشر الآن",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.send, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}