import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class InAppMediaViewer extends StatefulWidget {
  final String imageUrl;
  final String title;

  const InAppMediaViewer({
    super.key,
    required this.imageUrl,
    this.title = 'معاينة الصورة',
  });

  static void show(BuildContext context, String imageUrl, {String title = 'معاينة الصورة'}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => InAppMediaViewer(imageUrl: imageUrl, title: title),
      ),
    );
  }

  @override
  State<InAppMediaViewer> createState() => _InAppMediaViewerState();
}

class _InAppMediaViewerState extends State<InAppMediaViewer> {
  bool _isSaving = false;

  Future<void> _saveToGallery() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = "img_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final filePath = "${tempDir.path}/$fileName";

      final dio = Dio();
      await dio.download(widget.imageUrl, filePath);

      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      await Gal.putImage(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ الصورة في المعرض بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ تعذر حفظ الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareImage() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = "share_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final filePath = "${tempDir.path}/$fileName";

      final dio = Dio();
      await dio.download(widget.imageUrl, filePath);

      await Share.shareXFiles([XFile(filePath)], text: widget.title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ تعذر مشاركة الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withAlpha(200),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'مشاركة',
            onPressed: _shareImage,
          ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_rounded),
            tooltip: 'حفظ في المعرض',
            onPressed: _saveToGallery,
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              final percent = progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null;
              return Center(
                child: CircularProgressIndicator(
                  value: percent,
                  color: const Color(0xFFFFCC00),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 64),
                  const SizedBox(height: 12),
                  const Text(
                    'تعذر تحميل الصورة',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.imageUrl,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
