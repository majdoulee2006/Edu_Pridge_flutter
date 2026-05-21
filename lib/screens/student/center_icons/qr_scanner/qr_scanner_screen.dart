import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isProcessing = false; // منع التكرار عند المسح

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  // إرسال التوكن للـ API وتسجيل الحضور
  Future<void> _submitAttendance(String qrToken) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    await _cameraController.stop(); // إيقاف الكاميرا

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final res = await Dio().post(
        "${ApiService().baseUrl}/student/attendance/scan",
        data: {"qr_token": qrToken},
        options: Options(headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        _showResultDialog(
          success: true,
          message: res.data['message'] ?? 'تم تسجيل حضورك بنجاح ✅',
        );
      } else {
        _showResultDialog(success: false, message: 'فشل التسجيل، حاول مجدداً');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data?['message'] ?? 'تعذر الاتصال بالسيرفر';
      _showResultDialog(success: false, message: msg);
    } catch (e) {
      if (!mounted) return;
      _showResultDialog(success: false, message: 'حدث خطأ غير متوقع');
    }
  }

  void _showResultDialog({required bool success, required String message}) {
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
              Icon(
                success ? Icons.check_circle_rounded : Icons.error_rounded,
                color: success ? Colors.green : Colors.red,
                size: 70,
              ),
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
                    Navigator.pop(context); // أغلق الـ dialog
                    Navigator.pop(context); // ارجع لصفحة الطالب
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
            'مسح رمز الحضور',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // زر التبديل بين الكاميرا الأمامية والخلفية
            IconButton(
              icon: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white),
              onPressed: () => _cameraController.switchCamera(),
            ),
            // زر الفلاش
            IconButton(
              icon: const Icon(Icons.flash_on_outlined, color: Colors.white),
              onPressed: () => _cameraController.toggleTorch(),
            ),
          ],
        ),
        body: Stack(
          children: [
            // كاميرا المسح
            MobileScanner(
              controller: _cameraController,
              onDetect: (capture) {
                final barcode = capture.barcodes.firstOrNull;
                if (barcode?.rawValue != null) {
                  _submitAttendance(barcode!.rawValue!);
                }
              },
            ),

            // إطار التوجيه (مستطيل الاستهداف)
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
                    // زوايا مميزة
                    _buildCorner(top: 0, right: 0, rotate: 0),
                    _buildCorner(top: 0, left: 0, rotate: 90),
                    _buildCorner(bottom: 0, left: 0, rotate: 180),
                    _buildCorner(bottom: 0, right: 0, rotate: 270),
                  ],
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
                  if (_isProcessing)
                    const CircularProgressIndicator(color: Color(0xFFFFCC00))
                  else
                    const Icon(Icons.qr_code_scanner, color: Colors.white54, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    _isProcessing ? 'جارِ التسجيل...' : 'وجّه الكاميرا نحو رمز QR',
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء زوايا الإطار المميز
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
