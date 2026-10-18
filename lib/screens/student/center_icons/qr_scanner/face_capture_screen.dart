import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/services/arc_face_service.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

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
  bool _isMirrored     = false;
  late String _hint;

  // ── فحص الحيوية (Liveness): نطلب رمشة عين حقيقية قبل قبول الصورة
  // لمنع خداع النظام بصورة مطبوعة أو معروضة على شاشة أخرى
  bool _sawEyesOpen   = false;
  bool _sawEyesClosed = false;
  bool _blinkConfirmed = false;

  Timer? _captureTimer;

  @override
  void initState() {
    super.initState();
    final isAr = AppSettings.language.value == 'ar';
    _hint = isAr ? 'وجّه كاميرتك الأمامية نحو وجهك' : 'Point your front camera at your face';
    AppSettings.language.addListener(_onLangChange);
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    _checkAndInitializeFace();
  }

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  void _resetBlinkState() {
    _sawEyesOpen = false;
    _sawEyesClosed = false;
    _blinkConfirmed = false;
  }

  // يتحقق أن هناك رمشة عين فعلية (مفتوحة ثم مغلقة ثم مفتوحة) خلال الالتقاط
  void _trackBlink(Face face) {
    final double? left = face.leftEyeOpenProbability;
    final double? right = face.rightEyeOpenProbability;
    if (left == null || right == null) return; // الجهاز لا يدعم قياس العين، نتجاوز فحص الرمشة

    final double avgOpen = (left + right) / 2;

    if (!_sawEyesOpen && avgOpen > 0.6) {
      _sawEyesOpen = true;
    } else if (_sawEyesOpen && !_sawEyesClosed && avgOpen < 0.3) {
      _sawEyesClosed = true;
    } else if (_sawEyesOpen && _sawEyesClosed && avgOpen > 0.6) {
      _blinkConfirmed = true;
    }
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
      imageFormatGroup: !kIsWeb && Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
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
      if (hasFace) {
        await prefs.setBool('has_face_embedding', true);
      }
      final String? photoUrl = profileData['reference_photo_url'];

      if (!hasFace) {
        // 1. فحص هل البصمة مخزنة محلياً في ذاكرة الجوال
        final localEmbeddingStr = prefs.getString('local_face_embedding');
        if (localEmbeddingStr != null && localEmbeddingStr.isNotEmpty) {
          try {
            final List<dynamic> raw = jsonDecode(localEmbeddingStr);
            final List<double> localEmbedding = raw.map((e) => (e as num).toDouble()).toList();
            if (localEmbedding.isNotEmpty) {
              final isAr = AppSettings.language.value == 'ar';
              setState(() => _hint = isAr ? "جاري مزامنة بصمة وجهك المحفوظة محلياً..." : "Syncing locally saved face embedding...");
              await Dio().post(
                "${ApiService().baseUrl}/student/profile/initialize-face",
                data: {"face_embedding": localEmbedding},
                options: Options(headers: {"Authorization": "Bearer $token", "Accept": "application/json"}),
              );
              await _initCamera();
              return;
            }
          } catch (e) {
            debugPrint("Local embedding sync error: $e");
          }
        }

        final isAr = AppSettings.language.value == 'ar';
        if (photoUrl == null || photoUrl.isEmpty) {
          _showErrorDialog(isAr ? "صورة الوجه المرجعية غير متوفرة في حسابك. يرجى التقاط صورتك الشخصية أولاً." : "Reference photo is not available in your account. Please capture your personal photo first.");
          return;
        }

        setState(() => _hint = isAr ? "جاري تهيئة بصمة وجهك من صورتك المرجعية..." : "Initializing face embedding from your reference photo...");
        // 2. تحميل صورة الشؤون مؤقتاً
        final tempDir = await getTemporaryDirectory();
        final tempPath = "${tempDir.path}/ref_photo.jpg";
        await Dio().download(photoUrl, tempPath);

        // 3. معالجة الصورة واستخراج البصمة
        final inputImage = InputImage.fromFilePath(tempPath);
        final faces = await _faceDetector!.processImage(inputImage);

        if (faces.isEmpty) {
          _showErrorDialog(isAr ? "فشل العثور على وجه في صورتك الرسمية المرفوعة من الشؤون. يرجى مراجعة شؤون الطلاب لتحديثها." : "No face found in your official university photo. Please consult student affairs.");
          return;
        }

        final embedding = await ArcFaceService.extractArcFaceEmbedding(faces.first, tempPath);

        if (embedding.isEmpty) {
          _showErrorDialog(isAr ? "فشل استخراج بصمة وجهك من الصورة. يرجى التواصل مع الدعم الفني." : "Failed to extract face embedding. Please contact technical support.");
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
      final isAr = AppSettings.language.value == 'ar';
      bool isNetworkError = false;
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.error is SocketException) {
          isNetworkError = true;
        }
      } else if (e is SocketException) {
        isNetworkError = true;
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Network is unreachable') ||
          e.toString().contains('Connection failed')) {
        isNetworkError = true;
      }

      if (isNetworkError) {
        debugPrint("📡 Offline mode detected during face check, proceeding to camera directly: $e");
        await _initCamera();
        return;
      }

      _showErrorDialog(isAr ? "حدث خطأ أثناء الاتصال بالخادم لتهيئة الوجه: $e" : "Error connecting to server for face setup: $e");
    } finally {
      if (mounted) {
        setState(() => _isInitializingReference = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    final isAr = AppSettings.language.value == 'ar';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? "تنبيه أمني" : "Security Notice", textDirection: isAr ? TextDirection.rtl : TextDirection.ltr),
        content: Text(message, textDirection: isAr ? TextDirection.rtl : TextDirection.ltr),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // الخروج من شاشة الحضور
            },
            child: Text(isAr ? "موافق" : "OK"),
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
          final isAr = AppSettings.language.value == 'ar';
          setState(() {
            _isFaceDetected = false;
            _hint = isAr ? 'انظر مباشرة إلى الكاميرا بشكل مستقيم ⚠️' : 'Look straight into the camera ⚠️';
            _isCapturing = false;
          });
          _captureTimer?.cancel();
          _resetBlinkState();
          return;
        }

        if (!_isFaceDetected) {
          setState(() {
            _isFaceDetected = true;
          });
        }

        // فحص الحيوية: نطلب رمشة عين حقيقية قبل قبول الالتقاط لمنع خداع
        // النظام بصورة مطبوعة أو معروضة على شاشة أخرى
        _trackBlink(face);

        final isAr = AppSettings.language.value == 'ar';
        if (!_blinkConfirmed) {
          setState(() {
            _hint = isAr 
                ? (_sawEyesClosed ? 'تم رصد الرمشة، افتح عينيك... ✅' : 'ارمش بعينيك لإثبات أنك موجود فعلياً 👁️')
                : (_sawEyesClosed ? 'Blink detected, open your eyes... ✅' : 'Blink your eyes to verify liveness 👁️');
          });
          return;
        }

        setState(() => _hint = isAr ? 'تم التحقق من حيويتك ✅ — ابقَ ثابتاً...' : 'Liveness verified ✅ — Stay still...');

        if (!_isCapturing) {
          _isCapturing = true;
          _captureTimer = Timer(const Duration(seconds: 1), () {
            _captureAndSubmit(face, image.path);
          });
        }
      } else {
        if (_isFaceDetected) {
          final isAr = AppSettings.language.value == 'ar';
          setState(() {
            _isFaceDetected = false;
            _hint = isAr ? 'لم يتم كشف وجهك، حاول مجدداً' : 'Face not detected, try again';
            _isCapturing = false;
          });
          _resetBlinkState();
          _captureTimer?.cancel();
        }
      }
    } catch (_) {}
  }

  Future<void> _captureAndSubmit(Face face, String imagePath) async {
    if (!mounted) return;
    final isAr = AppSettings.language.value == 'ar';
    setState(() {
      _isSubmitting = true;
      _hint = isAr ? 'جارِ التحقق من وجهك...' : 'Verifying your face...';
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
          // ساعة الهاتف لحظة الإرسال: يقارنها السيرفر بساعته لكشف الانحراف/التلاعب
          "device_time":    DateTime.now().toUtc().toIso8601String(),
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
        message: res.data['message'] ?? (isAr ? 'تم التسجيل' : 'Registered successfully'),
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
        final msg = e.response?.data?['message'] ?? (isAr ? 'تعذر الاتصال بالسيرفر' : 'Could not connect to server');
        _showResult(success: false, message: msg);
      }
    } catch (_) {
      if (!mounted) return;
      _showResult(success: false, message: isAr ? 'حدث خطأ غير متوقع' : 'An unexpected error occurred');
    }
  }

  Future<void> _saveAttendanceLocally(String qrToken, List<double> embedding) async {
    final isAr = AppSettings.language.value == 'ar';
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
        final clientScanId = "scan_${DateTime.now().millisecondsSinceEpoch}_${qrToken.hashCode.abs()}";
        String scanData = jsonEncode({
          'client_scan_id': clientScanId,
          'qr_token': qrToken,
          'scanned_at': DateTime.now().toUtc().toIso8601String(),
          'face_embedding': embedding,
          'status': 'pending',
        });
        offlineScans.add(scanData);
        await prefs.setStringList('offline_attendance_scans', offlineScans);
      }

      if (!mounted) return;
      _showResult(
        success: true,
        message: isAr
            ? 'لا يوجد اتصال بالإنترنت. تم حفظ رمز حضورك محلياً بنجاح وسيرسل تلقائياً فور توفر الشبكة! 📡✅'
            : 'No internet connection. Attendance token saved locally and will sync once online! 📡✅',
      );
    } catch (e) {
      if (!mounted) return;
      _showResult(success: false, message: isAr ? 'حدث خطأ أثناء حفظ الحضور محلياً' : 'Error saving attendance locally');
    }
  }

  void _showResult({
    required bool success,
    required String message,
    String? faceStatus,
    double? score,
  }) {
    final isAr = AppSettings.language.value == 'ar';
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
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Icon(icon, color: iconColor, size: 70),
              const SizedBox(height: 16),
              Text(
                success ? (isAr ? 'تم التسجيل' : 'Registered') : (isAr ? 'فشل التسجيل' : 'Registration Failed'),
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
                  isAr ? 'نسبة التطابق: ${score.toStringAsFixed(1)}%' : 'Match Score: ${score.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: score >= 85 ? Colors.green : (score >= 70 ? Colors.orange : Colors.red),
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
                  child: Text(
                    isAr ? 'حسناً' : 'OK',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
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
    AppSettings.language.removeListener(_onLangChange);
    _captureTimer?.cancel();
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppSettings.language.value == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          title: Text(
            isAr ? 'التحقق من الوجه' : 'Face Verification',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isInitializingReference
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFFFFCC00)),
                      const SizedBox(height: 20),
                      Text(
                        isAr
                            ? 'جاري تهيئة بصمة وجهك من صورتك الرسمية بالجامعة...\nالرجاء الانتظار.'
                            : 'Initializing face embedding from your official university photo...\nPlease wait.',
                        style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5, fontFamily: 'Noto Sans Arabic'),
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
                    child: _isMirrored
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
                            child: CameraPreview(_cameraController!),
                          )
                        : CameraPreview(_cameraController!),
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

            // زر عكس الكاميرا للمستخدم على الشاشة
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isMirrored = !_isMirrored;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFCC00).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flip_camera_android, color: Color(0xFFFFCC00), size: 20),
                        const SizedBox(width: 6),
                        Text(
                          isAr ? "عكس الكاميرا" : "Flip Camera",
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
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
