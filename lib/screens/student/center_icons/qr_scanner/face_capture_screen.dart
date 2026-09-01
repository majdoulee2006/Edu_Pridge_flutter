import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/services/arc_face_service.dart';

class FaceCaptureScreen extends StatefulWidget {
  final String qrToken;

  const FaceCaptureScreen({super.key, required this.qrToken});

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;

  bool _isFaceDetected = false;
  bool _isCapturing    = false;
  bool _isSubmitting   = false;
  bool _isInitializingReference = false;
  String _hint         = 'وجّه كاميرتك الأمامية نحو وجهك';

  Timer? _captureTimer;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    _checkAndInitializeFace();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      front,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );
    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() {});
    _startFaceDetectionLoop();
  }

  Future<void> _checkAndInitializeFace() async {
    setState(() => _isInitializingReference = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // 1. جلب بيانات الملف الشخصي لمعرفة حالة البصمة ورابط صورة الشؤون
      final resProfile = await Dio().get(
        "${ApiService().baseUrl}/student/profile",
        options: Options(headers: {"Authorization": "Bearer $token", "Accept": "application/json"}),
      );

      final profileData = resProfile.data['data'];
      final bool hasFace = profileData['has_face_embedding'] == true;
      final String? photoUrl = profileData['reference_photo_url'];

      if (!hasFace) {
        if (photoUrl == null || photoUrl.isEmpty) {
          _showErrorDialog("صورة الشؤون غير متوفرة. يرجى مراجعة إدارة شؤون الطلاب لتسجيل صورتك الرسمية.");
          return;
        }

        setState(() => _hint = "جاري تهيئة بصمة وجهك من صورة الشؤون المرجعية...");

        // 2. تحميل صورة الشؤون مؤقتاً
        final tempDir = await getTemporaryDirectory();
        final tempPath = "${tempDir.path}/ref_photo.jpg";
        await Dio().download(photoUrl, tempPath);

        // 3. معالجة الصورة واستخراج البصمة
        final inputImage = InputImage.fromFilePath(tempPath);
        final faces = await _faceDetector!.processImage(inputImage);

        if (faces.isEmpty) {
          _showErrorDialog("فشل العثور على وجه في صورتك الرسمية المرفوعة من الشؤون. يرجى مراجعة شؤون الطلاب لتحديثها.");
          return;
        }

        final embedding = await ArcFaceService.extractArcFaceEmbedding(faces.first, tempPath);

        if (embedding.isEmpty) {
          _showErrorDialog("فشل استخراج بصمة وجهك من الصورة. يرجى التواصل مع الدعم الفني.");
          return;
        }

        // 4. رفع البصمة لتثبيتها في قاعدة البيانات
        await Dio().post(
          "${ApiService().baseUrl}/student/profile/initialize-face",
          data: {"face_embedding": embedding},
          options: Options(headers: {"Authorization": "Bearer $token", "Accept": "application/json"}),
        );
      }

      // بعد انتهاء التهيئة بنجاح، يتم تشغيل الكاميرا
      await _initCamera();
    } catch (e) {
      _showErrorDialog("حدث خطأ أثناء الاتصال بالخادم لتهيئة الوجه: $e");
    } finally {
      setState(() => _isInitializingReference = false);
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("تنبيه أمني", textDirection: TextDirection.rtl),
        content: Text(message, textDirection: TextDirection.rtl),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // الخروج من شاشة الحضور
            },
            child: const Text("موافق"),
          )
        ],
      ),
    );
  }

  void _startFaceDetectionLoop() {
    Timer.periodic(const Duration(milliseconds: 800), (timer) async {
      if (!mounted || _isCapturing || _isSubmitting) {
        timer.cancel();
        return;
      }
      await _detectFace();
    });
  }

  Future<void> _detectFace() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isCapturing || _isSubmitting) return;

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFile(File(image.path));
      final faces = await _faceDetector!.processImage(inputImage);

      if (!mounted) return;

      if (faces.isNotEmpty) {
        final face = faces.first;

        // التأكد من أن الطالب ينظر مباشرة للكاميرا بشكل مستقيم لضمان دقة المطابقة
        final double yaw = face.headEulerAngleY ?? 0;
        final double pitch = face.headEulerAngleX ?? 0;

        if (yaw.abs() > 12 || pitch.abs() > 12) {
          setState(() {
            _isFaceDetected = false;
            _hint = 'انظر مباشرة إلى الكاميرا بشكل مستقيم ⚠️';
            _isCapturing = false;
          });
          _captureTimer?.cancel();
          return;
        }

        if (!_isFaceDetected) {
          setState(() {
            _isFaceDetected = true;
            _hint = 'تم كشف وجهك ✅ — ابقَ ثابتاً...';
          });
        }

        if (!_isCapturing) {
          _isCapturing = true;
          _captureTimer = Timer(const Duration(seconds: 1), () {
            _captureAndSubmit(face, image.path);
          });
        }
      } else {
        if (_isFaceDetected) {
          setState(() {
            _isFaceDetected = false;
            _hint = 'لم يتم كشف وجهك، حاول مجدداً';
            _isCapturing = false;
          });
          _captureTimer?.cancel();
        }
      }
    } catch (_) {}
  }

  // مقارنة pixels الوجه بدقة 64×64 وتعديل الدوران لزيادة الدقة
  Future<List<double>> _extractPixelEmbedding(Face face, String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return [];

      // تصحيح اتجاه الصورة من الـ EXIF
      image = img.bakeOrientation(image);

      final box = face.boundingBox;
      final padX = (box.width * 0.2).toInt();
      final padY = (box.height * 0.2).toInt();

      final x = max(0, box.left.toInt() - padX);
      final y = max(0, box.top.toInt() - padY);
      final w = min(image.width - x, box.width.toInt() + padX * 2);
      final h = min(image.height - y, box.height.toInt() + padY * 2);

      if (w <= 0 || h <= 0) return [];

      // قص منطقة الوجه
      var cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);

      // تعديل زاوية دوران الوجه (Alignment/Roll Correction) لرفع الدقة
      if (face.headEulerAngleZ != null && face.headEulerAngleZ != 0) {
        cropped = img.copyRotate(cropped, angle: -face.headEulerAngleZ!);
      }

      // تصغير لـ 64×64 لزيادة ميزات التعرف
      final resized = img.copyResize(cropped, width: 64, height: 64);
      final gray    = img.grayscale(resized);

      // استخراج قيم البكسلات (سيكون الطول الإجمالي 4096 قيمة)
      final pixels = <double>[];
      double sum = 0;
      for (int py = 0; py < 64; py++) {
        for (int px = 0; px < 64; px++) {
          final val = gray.getPixel(px, py).r.toDouble();
          pixels.add(val);
          sum += val;
        }
      }

      // تطبيع البيانات لإزالة أثر الإضاءة
      final mean = sum / pixels.length;
      double variance = 0;
      for (final v in pixels) variance += (v - mean) * (v - mean);
      final std = sqrt(variance / pixels.length).clamp(1.0, double.infinity);

      return pixels.map((v) => (v - mean) / std).toList();
    } catch (e) {
      debugPrint('Pixel embedding error: $e');
      return [];
    }
  }

  Future<void> _captureAndSubmit(Face face, String imagePath) async {
    if (!mounted) return;
    setState(() {
      _isSubmitting = true;
      _hint = 'جارِ التحقق من وجهك...';
    });

    List<double> embedding = [];
    try {
      embedding = await ArcFaceService.extractArcFaceEmbedding(face, imagePath);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final res = await Dio().post(
        "${ApiService().baseUrl}/student/attendance/scan",
        data: {
          "qr_token":       widget.qrToken,
          "face_embedding": embedding,
          "scanned_at":     DateTime.now().toUtc().toIso8601String(),
        },
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (!mounted) return;
      _showResult(
        success: res.data['success'] == true,
        message: res.data['message'] ?? 'تم التسجيل',
        faceStatus: res.data['face_status'],
        score: (res.data['face_score'] as num?)?.toDouble(),
      );
    } on DioException catch (e) {
      if (!mounted) return;

      bool isOffline = false;
      if (e.response == null) {
        isOffline = true;
      } else {
        final status = e.response?.statusCode ?? 0;
        if (status >= 502 && status <= 504) {
          isOffline = true;
        }
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        isOffline = true;
      }

      if (isOffline) {
        await _saveAttendanceLocally(widget.qrToken, embedding);
      } else {
        final msg = e.response?.data?['message'] ?? 'تعذر الاتصال بالسيرفر';
        _showResult(success: false, message: msg);
      }
    } catch (_) {
      if (!mounted) return;
      _showResult(success: false, message: 'حدث خطأ غير متوقع');
    }
  }

  Future<void> _saveAttendanceLocally(String qrToken, List<double> embedding) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> offlineScans = prefs.getStringList('offline_attendance_scans') ?? [];

      bool alreadyExists = offlineScans.any((scan) {
        try {
          final data = jsonDecode(scan);
          return data['qr_token'] == qrToken;
        } catch (e) {
          return false;
        }
      });

      if (!alreadyExists) {
        String scanData = jsonEncode({
          'qr_token': qrToken,
          'scanned_at': DateTime.now().toUtc().toIso8601String(),
          'face_embedding': embedding,
        });
        offlineScans.add(scanData);
        await prefs.setStringList('offline_attendance_scans', offlineScans);
      }

      if (!mounted) return;
      _showResult(
        success: true,
        message: 'لا يوجد اتصال بالإنترنت. تم حفظ رمز حضورك محلياً بنجاح وسيرسل تلقائياً فور توفر الشبكة! 📡✅',
      );
    } catch (e) {
      if (!mounted) return;
      _showResult(success: false, message: 'حدث خطأ أثناء حفظ الحضور محلياً');
    }
  }

  void _showResult({
    required bool success,
    required String message,
    String? faceStatus,
    double? score,
  }) {
    Color iconColor = success ? Colors.green : Colors.red;
    IconData icon   = success ? Icons.check_circle_rounded : Icons.error_rounded;

    if (faceStatus == 'suspicious') {
      iconColor = Colors.orange;
      icon      = Icons.warning_amber_rounded;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Icon(icon, color: iconColor, size: 70),
              const SizedBox(height: 16),
              Text(
                success ? 'تم التسجيل' : 'فشل التسجيل',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
              ),
              if (score != null) ...[
                const SizedBox(height: 8),
                Text(
                  'نسبة التطابق: ${score.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: score >= 75 ? Colors.green : (score >= 50 ? Colors.orange : Colors.red),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context); // يغلق الـ dialog
                    Navigator.pop(context); // يغلق FaceCaptureScreen
                  },
                  child: const Text(
                    'حسناً',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'التحقق من الوجه',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isInitializingReference
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFFFFCC00)),
                      SizedBox(height: 20),
                      Text(
                        'جاري تهيئة بصمة وجهك من صورتك الرسمية بالجامعة...\nالرجاء الانتظار.',
                        style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5, fontFamily: 'Noto Sans Arabic'),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : Stack(
                children: [
                  // معاينة الكاميرا
            if (_cameraController != null && _cameraController!.value.isInitialized)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _cameraController!.value.previewSize?.height ?? 1,
                    height: _cameraController!.value.previewSize?.width ?? 1,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              )
            else
              const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00))),

            // إطار الوجه
            Center(
              child: Container(
                width: 220,
                height: 280,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isSubmitting
                        ? Colors.blue
                        : (_isFaceDetected ? Colors.green : const Color(0xFFFFCC00)),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(140),
                ),
              ),
            ),

            // تعليمات أسفل الشاشة
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  if (_isSubmitting)
                    const CircularProgressIndicator(color: Color(0xFFFFCC00))
                  else
                    Icon(
                      _isFaceDetected ? Icons.face_retouching_natural : Icons.face,
                      color: _isFaceDetected ? Colors.green : Colors.white54,
                      size: 32,
                    ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _hint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
