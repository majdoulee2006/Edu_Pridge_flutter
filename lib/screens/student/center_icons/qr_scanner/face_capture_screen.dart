import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

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
  String _hint         = 'وجّه كاميرتك الأمامية نحو وجهك';

  Timer? _captureTimer;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() {});
    _startFaceDetectionLoop();
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
        if (!_isFaceDetected) {
          setState(() {
            _isFaceDetected = true;
            _hint = 'تم كشف وجهك ✅ — ابقَ ثابتاً...';
          });
        }

        if (!_isCapturing) {
          _isCapturing = true;
          _captureTimer = Timer(const Duration(seconds: 1), () {
            _captureAndSubmit(faces.first, image.path);
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

  // مقارنة pixels الوجه — أدق بكثير من landmark distances
  Future<List<double>> _extractPixelEmbedding(Face face, String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return [];

      // تصحيح اتجاه الصورة (EXIF)
      image = img.bakeOrientation(image);

      final box = face.boundingBox;
      final padX = (box.width * 0.2).toInt();
      final padY = (box.height * 0.2).toInt();

      final x = max(0, box.left.toInt() - padX);
      final y = max(0, box.top.toInt() - padY);
      final w = min(image.width - x, box.width.toInt() + padX * 2);
      final h = min(image.height - y, box.height.toInt() + padY * 2);

      if (w <= 0 || h <= 0) return [];

      // قص منطقة الوجه، تصغير لـ 32×32، تحويل لرمادي
      final cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);
      final resized = img.copyResize(cropped, width: 32, height: 32);
      final gray    = img.grayscale(resized);

      // استخراج قيم البكسلات
      final pixels = <double>[];
      double sum = 0;
      for (int py = 0; py < 32; py++) {
        for (int px = 0; px < 32; px++) {
          final val = gray.getPixel(px, py).r.toDouble();
          pixels.add(val);
          sum += val;
        }
      }

      // تطبيع: mean=0, std=1 (يزيل أثر الإضاءة)
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

    try {
      final embedding = await _extractPixelEmbedding(face, imagePath);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final res = await Dio().post(
        "${ApiService().baseUrl}/student/attendance/scan",
        data: {
          "qr_token":       widget.qrToken,
          "face_embedding": embedding,
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
      final msg = e.response?.data?['message'] ?? 'تعذر الاتصال بالسيرفر';
      _showResult(success: false, message: msg);
    } catch (_) {
      if (!mounted) return;
      _showResult(success: false, message: 'حدث خطأ غير متوقع');
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
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
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
