import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class AffairsPdfViewerScreen extends StatefulWidget {
  final String title;
  final Uint8List pdfBytes;
  final String fileName;
  final String? bannerNotice;
  final bool allowPrinting;
  final bool allowSharing;
  final bool preventScreenshot;

  const AffairsPdfViewerScreen({
    super.key,
    required this.title,
    required this.pdfBytes,
    required this.fileName,
    this.bannerNotice,
    this.allowPrinting = false,
    this.allowSharing = false,
    this.preventScreenshot = true,
  });

  @override
  State<AffairsPdfViewerScreen> createState() => _AffairsPdfViewerScreenState();
}

class _AffairsPdfViewerScreenState extends State<AffairsPdfViewerScreen> {
  static const _securityChannel = MethodChannel('com.example.edu_pridge_flutter/security');

  @override
  void initState() {
    super.initState();
    if (widget.preventScreenshot) {
      _setSecureMode(true);
    }
  }

  @override
  void dispose() {
    if (widget.preventScreenshot) {
      _setSecureMode(false);
    }
    super.dispose();
  }

  Future<void> _setSecureMode(bool enable) async {
    try {
      await _securityChannel.invokeMethod(enable ? 'enableSecure' : 'disableSecure');
    } catch (e) {
      debugPrint('Security channel error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'عودة للصفحة',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.bannerNotice != null && widget.bannerNotice!.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2205) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF785408) : const Color(0xFFFCD34D),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.bannerNotice!,
                        style: TextStyle(
                          color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: PdfPreview(
                build: (PdfPageFormat format) async => widget.pdfBytes,
                pdfFileName: widget.fileName,
                allowPrinting: widget.allowPrinting,
                allowSharing: widget.allowSharing,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                actions: (widget.allowPrinting || widget.allowSharing) ? null : const [],
                loadingWidget: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFFFFCC00)),
                      SizedBox(height: 12),
                      Text('جاري تجهيز مستند التقرير...', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
