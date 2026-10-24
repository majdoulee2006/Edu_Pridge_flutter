import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/qr_scanner/face_capture_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isProcessing = false;
  String _processingMessage = '';

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    _cameraController.dispose();
    super.dispose();
  }

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  /// فحص هل الرمز يتطلب التحقق بالوجه بناءً على حمولة QR
  bool _doesRequireFace(String raw) {
    try {
      final trimmed = raw.trim();
      if (trimmed.startsWith('edu-bridge://attendance') || trimmed.contains('?')) {
        final uri = Uri.tryParse(trimmed);
        if (uri != null && uri.queryParameters.containsKey('rf')) {
          return uri.queryParameters['rf'] != '0';
        }
      }
    } catch (_) {}
    return true; // الافتراضي هو التفعيل لأقصى درجات الأمان
  }

  Future<void> _onQrDetected(String qrToken) async {
    if (_isProcessing) return;

    final isAr = AppSettings.language.value == 'ar';
    final requiresFace = _doesRequireFace(qrToken);

    setState(() {
      _isProcessing = true;
      _processingMessage = requiresFace
          ? (isAr ? 'جارِ الانتقال لكاميرا الوجه... 📸' : 'Proceeding to face camera... 📸')
          : (isAr ? 'تم قراءة الرمز! جارِ تسجيل الحضور مباشرة... ⚡' : 'QR scanned! Recording attendance directly... ⚡');
    });

    await _cameraController.stop();
    if (!mounted) return;

    if (requiresFace) {
      // ─── الحالة 1: المعلم فعّل التحقق بالوجه ───
      // نقل الطالب لشاشة التحقق من الوجه وتقليب الكاميرا للأمامية
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FaceCaptureScreen(qrToken: qrToken),
        ),
      );

      if (mounted) Navigator.pop(context);
    } else {
      // ─── الحالة 2: المعلم ألغى التحقق بالوجه ───
      // لا يتم تقليب الكاميرا ولا فتح شاشة الوجه، بل يسجل الحضور فوراً برمز الـ QR فقط
      await _submitDirectAttendance(qrToken);
    }
  }

  /// تسجيل الحضور المباشر بدون صورة أو بصمة وجه
  Future<void> _submitDirectAttendance(String qrToken) async {
    final isAr = AppSettings.language.value == 'ar';

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final res = await Dio().post(
        "${ApiService().baseUrl}/student/attendance/scan",
        data: {
          "qr_token":    qrToken,
          "scanned_at":  DateTime.now().toUtc().toIso8601String(),
          "device_time": DateTime.now().toUtc().toIso8601String(),
        },
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );

      if (!mounted) return;

      final success = res.data['success'] == true;
      final serverMsg = res.data['message'];
      final message = serverMsg ?? (isAr ? 'تم تسجيل حضورك بنجاح ✅' : 'Attendance recorded successfully ✅');

      await _showResultDialog(
        success: success,
        title: success ? (isAr ? 'تم تسجيل الحضور بنجاح' : 'Attendance Recorded') : (isAr ? 'تنبيه' : 'Notice'),
        message: success
            ? '$message\n${isAr ? "(رمز QR فقط - التحقق بالوجه غير مطلوب)" : "(QR only - Face verification not required)"}'
            : message,
      );

      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      if (!mounted) return;

      bool isOffline = false;
      if (e.response == null) {
        isOffline = true;
      } else {
        final status = e.response?.statusCode ?? 0;
        if (status >= 502 && status <= 504) isOffline = true;
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        isOffline = true;
      }

      if (isOffline) {
        // حفظ المسح محلياً للمزامنة لاحقاً عند توفر الشبكة
        await _saveOfflineDirectScan(qrToken);
        if (!mounted) return;
        await _showResultDialog(
          success: true,
          title: isAr ? 'حفظ الحضور أوفلاين' : 'Attendance Saved Offline',
          message: isAr
              ? 'تم حفظ حضورك في ذاكرة الجهاز بنجاح، وسيتم رفعه تلقائياً للسيرفر فور عودة الاتصال 📱'
              : 'Attendance saved offline, it will be uploaded automatically when connection resumes 📱',
        );
        if (mounted) Navigator.pop(context);
      } else {
        final errorMsg = e.response?.data?['message'] ?? (isAr ? 'تعذر تسجيل الحضور، تأكد من صلاحية الرمز' : 'Failed to record attendance, verify QR token');
        await _showResultDialog(
          success: false,
          title: isAr ? 'فشل تسجيل الحضور' : 'Attendance Failed',
          message: errorMsg.toString(),
        );
        if (mounted) {
          setState(() => _isProcessing = false);
          _cameraController.start();
        }
      }
    } catch (_) {
      if (!mounted) return;
      await _showResultDialog(
        success: false,
        title: isAr ? 'خطأ' : 'Error',
        message: isAr ? 'حدث خطأ غير متوقع أثناء المعالجة' : 'An unexpected error occurred during processing',
      );
      if (mounted) {
        setState(() => _isProcessing = false);
        _cameraController.start();
      }
    }
  }

  Future<void> _saveOfflineDirectScan(String qrToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> offlineScans = prefs.getStringList('offline_attendance_scans') ?? [];

      bool alreadyExists = offlineScans.any((scan) {
        try {
          final data = jsonDecode(scan);
          return data['qr_token'] == qrToken;
        } catch (_) {
          return false;
        }
      });

      if (!alreadyExists) {
        final clientScanId = "scan_${DateTime.now().millisecondsSinceEpoch}_${qrToken.hashCode.abs()}";
        String scanData = jsonEncode({
          'client_scan_id': clientScanId,
          'qr_token': qrToken,
          'scanned_at': DateTime.now().toUtc().toIso8601String(),
          'face_embedding': <double>[], // لا توجد بصمة وجه مطلوبة
          'status': 'pending',
        });
        offlineScans.add(scanData);
        await prefs.setStringList('offline_attendance_scans', offlineScans);
      }
    } catch (_) {}
  }

  Future<void> _showResultDialog({
    required bool success,
    required String title,
    required String message,
  }) async {
    final isAr = AppSettings.language.value == 'ar';
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Icon(
                success ? Icons.check_circle_rounded : Icons.error_rounded,
                color: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 68,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13.5, height: 1.5),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    isAr ? 'حسناً' : 'OK',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
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
            isAr ? 'مسح رمز الحضور' : 'Scan Attendance QR',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white),
              onPressed: () => _cameraController.switchCamera(),
            ),
            IconButton(
              icon: const Icon(Icons.flash_on_outlined, color: Colors.white),
              onPressed: () => _cameraController.toggleTorch(),
            ),
          ],
        ),
        body: Stack(
          children: [
            MobileScanner(
              controller: _cameraController,
              onDetect: (capture) {
                final barcode = capture.barcodes.firstOrNull;
                if (barcode?.rawValue != null) {
                  _onQrDetected(barcode!.rawValue!);
                }
              },
            ),

            Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFFCC00), width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    _buildCorner(top: 0, right: 0, rotate: 0),
                    _buildCorner(top: 0, left: 0, rotate: 90),
                    _buildCorner(bottom: 0, left: 0, rotate: 180),
                    _buildCorner(bottom: 0, right: 0, rotate: 270),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 60,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  if (_isProcessing)
                    const CircularProgressIndicator(color: Color(0xFFFFCC00))
                  else
                    const Icon(Icons.qr_code_scanner, color: Colors.white54, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    _isProcessing
                        ? _processingMessage
                        : (isAr ? 'وجّه الكاميرا نحو رمز QR' : 'Point camera at QR code'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double rotate,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: rotate * 3.14159 / 180,
        child: Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFFFCC00), width: 4),
              right: BorderSide(color: Color(0xFFFFCC00), width: 4),
            ),
            borderRadius: BorderRadius.only(topRight: Radius.circular(6)),
          ),
        ),
      ),
    );
  }
}
