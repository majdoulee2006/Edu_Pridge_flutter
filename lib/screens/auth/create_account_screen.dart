import 'package:edu_pridge_flutter/services/arc_face_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'pending_approval_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  bool isStudent = true;
  bool isLoading = false;

  String? selectedDept;
  String? selectedBranch;
  String? selectedGender;
  final String selectedYear = 'أولى';
  DateTime? selectedBirthDate;
  Uint8List? _profileImageBytes;

  List<double>? _extractedFaceEmbedding;
  static const Color primaryYellow = Color(0xFFF6E300);

  bool get isAr => AppSettings.language.value == 'ar';

  final Map<String, List<String>> _departmentData = {
    'نظم معلومات': ['معلوماتية', 'اتصالات'],
    'طبي':         ['صيدلة', 'مخابر'],
    'تجاري':       ['ادارة اعمال', 'محاسبة'],
    'هندسي':       ['هندسة عمارة', 'ديكور'],
  };

  final _studentFirstNameController = TextEditingController();
  final _studentLastNameController  = TextEditingController();
  final _studentTelegramIdController = TextEditingController(text: '7821980919');
  final _studentEmailController     = TextEditingController();
  final _studentPhoneController     = TextEditingController();
  final _studentPasswordController  = TextEditingController();
  final _studentConfirmPasswordController = TextEditingController();

  final _parentFirstNameController = TextEditingController();
  final _parentLastNameController  = TextEditingController();
  final _parentTelegramIdController = TextEditingController(text: '7821980919');
  final _parentEmailController     = TextEditingController();
  final _parentPhoneController     = TextEditingController();
  final _parentPasswordController  = TextEditingController();
  final _parentConfirmPasswordController = TextEditingController();

  int _selectedChildrenCount = 1;
  final List<TextEditingController> _parentChildIdControllers = [TextEditingController()];

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    _studentFirstNameController.dispose();
    _studentLastNameController.dispose();
    _studentTelegramIdController.dispose();
    _studentEmailController.dispose();
    _studentPhoneController.dispose();
    _studentPasswordController.dispose();
    _studentConfirmPasswordController.dispose();
    _parentFirstNameController.dispose();
    _parentLastNameController.dispose();
    _parentTelegramIdController.dispose();
    _parentEmailController.dispose();
    _parentPhoneController.dispose();
    _parentPasswordController.dispose();
    _parentConfirmPasswordController.dispose();
    for (var c in _parentChildIdControllers) { c.dispose(); }
    super.dispose();
  }

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  String _getDeptName(String deptKey) {
    if (isAr) return deptKey;
    switch (deptKey) {
      case 'نظم معلومات': return 'Information Systems';
      case 'طبي': return 'Medical';
      case 'تجاري': return 'Commercial';
      case 'هندسي': return 'Engineering';
      default: return deptKey;
    }
  }

  String _getBranchName(String branchKey) {
    if (isAr) return branchKey;
    switch (branchKey) {
      case 'معلوماتية': return 'Informatics';
      case 'اتصالات': return 'Communications';
      case 'صيدلة': return 'Pharmacy';
      case 'مخابر': return 'Laboratories';
      case 'ادارة اعمال': return 'Business Administration';
      case 'محاسبة': return 'Accounting';
      case 'هندسة عمارة': return 'Architecture';
      case 'ديكور': return 'Interior Design';
      default: return branchKey;
    }
  }

  Future<void> _pickProfilePhoto() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAr ? 'التقاط صورة الوجه (سيلفي الحضور)' : 'Take Face Photo (Attendance Selfie)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr
                      ? 'يرجى التقاط سيلفي واضح ومواجه للكاميرا لاعتماد بصمة الحضور'
                      : 'Please take a clear selfie facing the camera for attendance recognition',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontFamily: 'Cairo'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: primaryYellow.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.black),
                  ),
                  title: Text(
                    isAr ? 'التقاط سيلفي بالكاميرا' : 'Take selfie with camera',
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isAr ? 'موصى به لاعتماد بصمة الوجه بدقة' : 'Recommended for accurate face recognition',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
                  ),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                    child: const Icon(Icons.photo_library, color: Colors.black87),
                  ),
                  title: Text(
                    isAr ? 'اختيار صورة من المعرض' : 'Choose photo from gallery',
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 90,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (photo != null && mounted) {
      final bytes = await photo.readAsBytes();
      setState(() => _profileImageBytes = bytes);

      try {
        final inputImage = InputImage.fromFilePath(photo.path);
        final faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.accurate,
            enableLandmarks: true,
          ),
        );

        final faces = await faceDetector.processImage(inputImage);
        await faceDetector.close();

        if (faces.isNotEmpty) {
          final embedding = await ArcFaceService.extractArcFaceEmbedding(faces.first, photo.path);
          if (embedding.isNotEmpty) {
            _extractedFaceEmbedding = embedding;

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('local_face_embedding', jsonEncode(embedding));

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAr
                        ? 'تم رصد ملامح وجهك وحفظ بصمة الحضور محلياً بنجاح ✅'
                        : 'Face features detected and attendance biometric saved successfully ✅',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isAr
                      ? 'تنبيه: لم يتم كشف وجه واضح. يرجى التأكد من وضوح السيلفي لاعتماد الحضور.'
                      : 'Warning: No clear face detected. Ensure selfie is clear for attendance.',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Face embedding extraction error: $e');
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final maxDate = DateTime(now.year - 14, now.month, now.day);
    final minDate = DateTime(now.year - 60, now.month, now.day);

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: minDate,
      lastDate: maxDate,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: primaryYellow,
            onPrimary: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedBirthDate = picked);
  }

  Future<void> _handleRegister() async {
    String p1 = isStudent ? _studentPasswordController.text : _parentPasswordController.text;
    String p2 = isStudent ? _studentConfirmPasswordController.text : _parentConfirmPasswordController.text;

    if (p1 != p2) {
      _showSnackBar(isAr ? 'كلمات المرور غير متطابقة!' : 'Passwords do not match!');
      return;
    }

    String phone = isStudent ? _studentPhoneController.text.trim() : _parentPhoneController.text.trim();

    if (isStudent) {
      final firstName = _studentFirstNameController.text.trim();
      final lastName  = _studentLastNameController.text.trim();
      if (firstName.isEmpty || lastName.isEmpty) {
        _showSnackBar(isAr ? 'يرجى إدخال الاسم الكامل' : 'Please enter full name');
        return;
      }

      final email = _studentEmailController.text.trim();
      if (email.isEmpty) {
        _showSnackBar(isAr ? 'يرجى إدخال البريد الإلكتروني' : 'Please enter email address');
        return;
      }

      if (phone.isEmpty) {
        _showSnackBar(isAr ? 'يرجى إدخال رقم الهاتف' : 'Please enter phone number');
        return;
      }

      if (selectedGender == null || selectedBirthDate == null) {
        _showSnackBar(isAr ? 'يرجى إكمال كافة البيانات المطلوبة' : 'Please complete all required fields');
        return;
      }

      final fullName = '$firstName $lastName';
      final telegramId = _studentTelegramIdController.text.trim();

      setState(() => isLoading = true);
      try {
        FormData formData = FormData.fromMap({
          "full_name":         fullName,
          "first_name":        firstName,
          "last_name":         lastName,
          "telegram_username": telegramId,
          "telegram_chat_id":  telegramId,
          "email":             email,
          "phone":             phone,
          "gender":            selectedGender,
          "birth_date":        selectedBirthDate.toString().split(' ')[0],
          "academic_year":     selectedYear,
          "department":        selectedDept ?? '',
          "branch":            selectedBranch ?? '',
          "password":          _studentPasswordController.text,
          "role":              "student",
          if (_profileImageBytes != null)
            "avatar": MultipartFile.fromBytes(
              _profileImageBytes!,
              filename: 'avatar.jpg',
            ),
          if (_extractedFaceEmbedding != null && _extractedFaceEmbedding!.isNotEmpty)
            "face_embedding": jsonEncode(_extractedFaceEmbedding),
        });

        final response = await Dio().post(
          "${ApiService().baseUrl}/register",
          data: formData,
          options: Options(headers: {'Accept': 'application/json'}),
        );
        if ((response.statusCode == 201 || response.statusCode == 200) && mounted) {
          Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
            (route) => false);
        }
      } on DioException catch (e) {
        _showSnackBar(e.response?.data['message'] ?? (isAr ? "خطأ في تسجيل البيانات" : "Registration failed"));
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
      return;
    }

    // ولي أمر
    final firstName = _parentFirstNameController.text.trim();
    final lastName  = _parentLastNameController.text.trim();
    if (firstName.isEmpty || lastName.isEmpty) {
      _showSnackBar(isAr ? 'يرجى إدخال الاسم الأول والأخير' : 'Please enter first and last name');
      return;
    }

    final email = _parentEmailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar(isAr ? 'يرجى إدخال البريد الإلكتروني' : 'Please enter email address');
      return;
    }
    if (phone.isEmpty) {
      _showSnackBar(isAr ? 'يرجى إدخال رقم الهاتف' : 'Please enter phone number');
      return;
    }

    final childrenIds = _parentChildIdControllers.map((c) => c.text.trim()).toList();
    if (childrenIds.any((id) => id.isEmpty)) {
      _showSnackBar(isAr ? 'يرجى إدخال الرقم الجامعي لجميع الأبناء' : 'Please enter student ID for all children');
      return;
    }

    final parentTelegramId = _parentTelegramIdController.text.trim();

    setState(() => isLoading = true);
    try {
      final response = await Dio().post(
        "${ApiService().baseUrl}/register",
        data: {
          "full_name":         '$firstName $lastName',
          "first_name":        firstName,
          "last_name":         lastName,
          "email":             email,
          "phone":             phone,
          "telegram_username": parentTelegramId,
          "telegram_chat_id":  parentTelegramId,
          "children_ids":      childrenIds,
          "password":          _parentPasswordController.text,
          "role":              "parent",
        },
      );
      if ((response.statusCode == 201 || response.statusCode == 200) && mounted) {
        Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
          (route) => false);
      }
    } on DioException catch (e) {
      _showSnackBar(e.response?.data['message'] ?? (isAr ? "خطأ في تسجيل البيانات" : "Registration failed"));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [Colors.black, theme.scaffoldBackgroundColor]
                  : [const Color(0xFFFCFAEE), Colors.white],
              stops: const [0.0, 0.2],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                children: [
                  // Top Navigation & Language switcher
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(isAr ? Icons.arrow_back : Icons.arrow_forward, color: textColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            AppSettings.setLanguage(isAr ? 'en' : 'ar');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? Colors.white24 : Colors.black12,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.language_rounded, size: 16, color: primaryYellow),
                                const SizedBox(width: 6),
                                Text(
                                  isAr ? "English" : "العربية",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Role toggle (طالب / ولي أمر)
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        _toggleItem(isAr ? 'طالب' : 'Student', isStudent, () => setState(() => isStudent = true)),
                        _toggleItem(isAr ? 'ولي أمر' : 'Parent', !isStudent, () => setState(() => isStudent = false)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // صورة البروفايل بالكاميرا (للطالب فقط)
                  if (isStudent) ...[
                    GestureDetector(
                      onTap: _pickProfilePhoto,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? Colors.white12 : const Color(0xFFF0F0F0),
                              border: Border.all(color: primaryYellow, width: 3),
                              image: _profileImageBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(_profileImageBytes!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _profileImageBytes == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person, size: 50, color: Colors.grey.shade400),
                                    ],
                                  )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: primaryYellow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAr ? 'اضغط لالتقاط صورتك' : 'Tap to take your photo',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    const Icon(Icons.family_restroom, size: 60, color: primaryYellow),
                    const SizedBox(height: 15),
                  ],

                  Text(
                    isStudent
                        ? (isAr ? 'بيانات الطالب' : 'Student Information')
                        : (isAr ? 'بيانات ولي الأمر' : 'Parent Information'),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 25),
                  isStudent
                      ? _buildStudentForm(textColor, cardColor, isDark)
                      : _buildParentForm(textColor, cardColor, isDark),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryYellow,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(
                              isAr ? 'إنشاء حساب' : 'Create Account',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Cairo'),
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text.rich(TextSpan(
                      text: isAr ? 'لديك حساب بالفعل؟ ' : 'Already have an account? ',
                      style: TextStyle(color: textColor.withValues(alpha: 0.6), fontFamily: 'Cairo', fontSize: 14),
                      children: [
                        TextSpan(
                          text: isAr ? 'تسجيل الدخول' : 'Sign In',
                          style: const TextStyle(color: primaryYellow, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                        ),
                      ],
                    )),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleItem(String title, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? primaryYellow : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(color: isActive ? Colors.black : Colors.grey, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        ),
      ),
    );
  }

  Widget _buildStudentForm(Color textColor, Color cardColor, bool isDark) {
    return Column(
      children: [
        // الاسم الأول والأخير
        Row(
          children: [
            Expanded(child: _buildInputField(
              label: isAr ? 'الاسم الأول' : 'First Name',
              hint: isAr ? 'مثال: أحمد' : 'e.g. John',
              icon: Icons.person_outline,
              controller: _studentFirstNameController,
              textColor: textColor, cardColor: cardColor, isDark: isDark,
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildInputField(
              label: isAr ? 'الاسم الأخير' : 'Last Name',
              hint: isAr ? 'مثال: محمد' : 'e.g. Doe',
              icon: Icons.person_outline,
              controller: _studentLastNameController,
              textColor: textColor, cardColor: cardColor, isDark: isDark,
            )),
          ],
        ),

        // معرّف تيليجرام
        _buildInputField(
          label: isAr ? 'معرّف تيليجرام (Telegram ID)' : 'Telegram ID',
          hint: '7821980919',
          icon: Icons.send_outlined,
          controller: _studentTelegramIdController,
          keyboardType: TextInputType.number,
          textColor: textColor, cardColor: cardColor, isDark: isDark,
        ),

        // الجنس
        _buildInputField(
          label: isAr ? 'الجنس' : 'Gender',
          hint: isAr ? 'اختر' : 'Select',
          isDropdown: true,
          dropdownItems: ['ذكر', 'أنثى'],
          dropdownItemLabels: {'ذكر': isAr ? 'ذكر' : 'Male', 'أنثى': isAr ? 'أنثى' : 'Female'},
          value: selectedGender,
          onChanged: (val) => setState(() => selectedGender = val),
          textColor: textColor, cardColor: cardColor, isDark: isDark,
        ),

        // تاريخ الميلاد
        GestureDetector(
          onTap: _pickDate,
          child: AbsorbPointer(
            child: _buildInputField(
              label: isAr ? 'تاريخ الميلاد' : 'Birth Date',
              hint: selectedBirthDate == null
                  ? (isAr ? 'حدد التاريخ' : 'Select Date')
                  : "${selectedBirthDate!.toLocal()}".split(' ')[0],
              icon: Icons.calendar_today_outlined,
              textColor: textColor, cardColor: cardColor, isDark: isDark,
            ),
          ),
        ),

        // رقم الهاتف
        _buildInputField(
          label: isAr ? 'رقم الهاتف' : 'Phone Number',
          hint: '09xxxxxxxx',
          icon: Icons.phone_enabled_outlined,
          controller: _studentPhoneController,
          keyboardType: TextInputType.phone,
          textColor: textColor, cardColor: cardColor, isDark: isDark,
        ),

        // البريد الإلكتروني
        _buildInputField(
          label: isAr ? 'البريد الإلكتروني' : 'Email Address',
          hint: 'student@example.com',
          icon: Icons.email_outlined,
          controller: _studentEmailController,
          keyboardType: TextInputType.emailAddress,
          textColor: textColor, cardColor: cardColor, isDark: isDark,
        ),

        // القسم والفرع
        Row(
          children: [
            Expanded(child: _buildInputField(
              label: isAr ? 'القسم' : 'Department',
              hint: isAr ? 'اختر القسم' : 'Select Dept',
              isDropdown: true,
              dropdownItems: _departmentData.keys.toList(),
              dropdownItemLabels: { for (var k in _departmentData.keys) k : _getDeptName(k) },
              value: selectedDept,
              onChanged: (val) {
                setState(() {
                  selectedDept = val;
                  selectedBranch = null;
                });
              },
              textColor: textColor, cardColor: cardColor, isDark: isDark,
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildInputField(
              label: isAr ? 'الفرع' : 'Branch',
              hint: isAr ? 'اختر الفرع' : 'Select Branch',
              isDropdown: true,
              dropdownItems: selectedDept == null ? [] : _departmentData[selectedDept!],
              dropdownItemLabels: selectedDept == null
                  ? {}
                  : { for (var b in _departmentData[selectedDept!]!) b : _getBranchName(b) },
              value: selectedBranch,
              onChanged: (val) => setState(() => selectedBranch = val),
              textColor: textColor, cardColor: cardColor, isDark: isDark,
            )),
          ],
        ),

        _buildInputField(
          label: isAr ? 'كلمة المرور' : 'Password',
          hint: '........',
          icon: Icons.lock_outline,
          controller: _studentPasswordController,
          isPassword: true,
          textColor: textColor, cardColor: cardColor, isDark: isDark,
        ),
        _buildInputField(
          label: isAr ? 'تأكيد كلمة المرور' : 'Confirm Password',
          hint: '........',
          icon: Icons.check_circle_outline,
          controller: _studentConfirmPasswordController,
          isPassword: true,
          textColor: textColor, cardColor: cardColor, isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildParentForm(Color textColor, Color cardColor, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildInputField(
              label: isAr ? 'الاسم الأول' : 'First Name',
              hint: isAr ? 'مثال: أحمد' : 'e.g. John',
              icon: Icons.person_outline,
              controller: _parentFirstNameController,
              textColor: textColor, cardColor: cardColor, isDark: isDark,
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildInputField(
              label: isAr ? 'الاسم الأخير' : 'Last Name',
              hint: isAr ? 'مثال: محمد' : 'e.g. Doe',
              icon: Icons.person_outline,
              controller: _parentLastNameController,
              textColor: textColor, cardColor: cardColor, isDark: isDark,
            )),
          ],
        ),
        _buildInputField(
          label: isAr ? 'معرّف تيليجرام (Telegram ID)' : 'Telegram ID',
          hint: '7821980919',
          icon: Icons.send_outlined,
          controller: _parentTelegramIdController,
          keyboardType: TextInputType.number,
          textColor: textColor, cardColor: cardColor, isDark: isDark,
        ),
        _buildInputField(
          label: isAr ? 'البريد الإلكتروني' : 'Email Address',
          hint: 'parent@example.com',
          icon: Icons.email_outlined,
          controller: _parentEmailController,
          textColor: textColor, cardColor: cardColor, isDark: isDark,
        ),
        _buildInputField(
          label: isAr ? 'رقم الهاتف' : 'Phone Number',
          hint: isAr ? 'رقم الموبايل الشخصي' : 'Personal mobile number',
          icon: Icons.phone_enabled_outlined,
          controller: _parentPhoneController,
          textColor: textColor, cardColor: cardColor, isDark: isDark,
        ),
        _buildInputField(
          label: isAr ? 'عدد الأبناء' : 'Number of Children',
          hint: isAr ? 'العدد' : 'Count',
          isDropdown: true,
          dropdownItems: ['1', '2', '3', '4'],
          value: _selectedChildrenCount.toString(),
          textColor: textColor, cardColor: cardColor, isDark: isDark,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                int newCount = int.parse(val);
                while (_parentChildIdControllers.length < newCount) {
                  _parentChildIdControllers.add(TextEditingController());
                }
                while (_parentChildIdControllers.length > newCount) {
                  _parentChildIdControllers.removeLast();
                }
                _selectedChildrenCount = newCount;
              });
            }
          },
        ),
        ...List.generate(_selectedChildrenCount, (i) => _buildInputField(
          label: _selectedChildrenCount == 1
              ? (isAr ? 'الرقم الجامعي لابنك/ابنتك' : 'Student ID of your child')
              : (isAr ? 'الرقم الجامعي للابن ${i + 1}' : 'Student ID for child ${i + 1}'),
          hint: isAr ? 'الرقم الذي أعطاه موظف الشؤون' : 'ID provided by student affairs',
          icon: Icons.badge_outlined,
          controller: _parentChildIdControllers[i],
          textColor: textColor, cardColor: cardColor, isDark: isDark,
        )),
        _buildInputField(
          label: isAr ? 'كلمة المرور' : 'Password',
          hint: '........',
          icon: Icons.lock_outline,
          controller: _parentPasswordController,
          isPassword: true,
          textColor: textColor, cardColor: cardColor, isDark: isDark,
        ),
        _buildInputField(
          label: isAr ? 'تأكيد كلمة المرور' : 'Confirm Password',
          hint: '........',
          icon: Icons.check_circle_outline,
          controller: _parentConfirmPasswordController,
          isPassword: true,
          textColor: textColor, cardColor: cardColor, isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    IconData? icon,
    TextEditingController? controller,
    bool isPassword = false,
    bool isDropdown = false,
    List<String>? dropdownItems,
    Map<String, String>? dropdownItemLabels,
    String? value,
    Function(String?)? onChanged,
    TextInputType? keyboardType,
    required Color textColor,
    required Color cardColor,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: textColor.withValues(alpha: 0.7),
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: textColor.withValues(alpha: 0.1)),
            ),
            child: isDropdown
                ? DropdownButtonFormField<String>(
                    initialValue: value,
                    items: (dropdownItems ?? []).map((e) {
                      final display = dropdownItemLabels != null && dropdownItemLabels.containsKey(e)
                          ? dropdownItemLabels[e]!
                          : e;
                      return DropdownMenuItem(
                        value: e,
                        child: Text(display, style: const TextStyle(fontSize: 13, fontFamily: 'Cairo')),
                      );
                    }).toList(),
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      prefixIcon: Icon(icon, size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                    style: TextStyle(color: textColor, fontSize: 13),
                  )
                : TextField(
                    controller: controller,
                    obscureText: isPassword,
                    keyboardType: keyboardType,
                    textAlign: isAr ? TextAlign.right : TextAlign.left,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontFamily: 'Cairo'),
                      prefixIcon: Icon(icon, size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: TextStyle(color: textColor, fontSize: 13),
                  ),
          ),
        ],
      ),
    );
  }
}
