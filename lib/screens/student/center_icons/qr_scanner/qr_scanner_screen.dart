import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/qr_scanner/face_capture_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _onQrDetected(String qrToken) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    await _cameraController.stop();

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FaceCaptureScreen(qrToken: qrToken),
      ),
    );

    if (mounted) Navigator.pop(context);
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
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
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
                    _isProcessing ? 'جارِ الانتقال لكاميرا الوجه...' : 'وجّه الكاميرا نحو رمز QR',
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
