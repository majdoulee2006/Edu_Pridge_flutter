import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'api_service.dart';

/// فحص وتنزيل تحديثات التطبيق من السيرفر (توزيع APK خارج Google Play).
/// التثبيت فوق النسخة القديمة يحافظ على البيانات لأن التوقيع و applicationId ثابتان.
class AppUpdateService {
  AppUpdateService._();

  static bool _checked = false;

  /// يُستدعى مرة واحدة عند فتح التطبيق. أي فشل (لا إنترنت…) يُتجاهل بصمت.
  static Future<void> checkOnStartup(BuildContext context) async {
    if (kIsWeb || !Platform.isAndroid || _checked) return;
    _checked = true;

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
      ));
      // هواتف 32-بت (قديمة) تحتاج نسخة armeabi-v7a، والباقي arm64
      final abis = (await DeviceInfoPlugin().androidInfo).supported64BitAbis;
      final abi = abis.isEmpty ? 'v7a' : 'arm64';
      final res = await dio.get('${ApiService().baseUrl}/app-version', queryParameters: {'abi': abi});
      final data = res.data;
      if (data is! Map || data['available'] != true) return;

      // flutter build --split-per-abi يضيف إزاحة (1000 لـ v7a، 2000 لـ arm64) على versionCode،
      // فنأخذ الرقم الأساسي (الذي بعد + في pubspec) بباقي القسمة على 1000.
      final current = (int.tryParse((await PackageInfo.fromPlatform()).buildNumber) ?? 0) % 1000;
      final latest = (data['version_code'] as num).toInt();
      final minSupported = (data['min_version_code'] as num?)?.toInt() ?? 1;
      if (current >= latest) return;

      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _UpdateDialog(
          info: data,
          force: current < minSupported,
        ),
      );
    } catch (e) {
      debugPrint('Update check skipped: $e');
    }
  }
}

class _UpdateDialog extends StatefulWidget {
  final Map info;
  final bool force;
  const _UpdateDialog({required this.info, required this.force});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double? _progress; // null = لم يبدأ
  String? _error;

  Future<void> _download() async {
    setState(() {
      _progress = 0;
      _error = null;
    });
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/EduBridge-update.apk');
      if (file.existsSync()) file.deleteSync();

      await Dio().download(
        widget.info['apk_url'] as String,
        file.path,
        onReceiveProgress: (got, total) {
          if (total > 0 && mounted) setState(() => _progress = got / total);
        },
      );

      final expected = widget.info['sha256'] as String?;
      if (expected != null && expected.isNotEmpty) {
        final actual = (await sha256.bind(file.openRead()).first).toString();
        if (actual != expected) {
          file.deleteSync();
          throw 'الملف تالف، أعد المحاولة';
        }
      }

      // يفتح نافذة تثبيت أندرويد (تحديث فوق النسخة الحالية)
      final r = await OpenFilex.open(file.path, type: 'application/vnd.android.package-archive');
      if (r.type != ResultType.done && mounted) {
        throw 'تعذّر فتح المثبّت: ${r.message}';
      }
      if (mounted) setState(() => _progress = null);
    } catch (e) {
      if (mounted) {
        setState(() {
          _progress = null;
          _error = e is DioException ? 'تحقق من اتصال الإنترنت وأعد المحاولة' : '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final changelog = (widget.info['changelog'] as String?) ?? '';
    final downloading = _progress != null;

    return PopScope(
      canPop: false,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(widget.force ? 'تحديث إجباري' : 'يتوفر تحديث جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الإصدار ${widget.info['version_name']}'),
              if (changelog.isNotEmpty) ...[const SizedBox(height: 8), Text(changelog)],
              const SizedBox(height: 8),
              const Text('سيتم التحديث فوق النسخة الحالية بدون حذف بياناتك.'),
              if (downloading) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _progress),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            if (!widget.force && !downloading)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('لاحقاً'),
              ),
            FilledButton(
              onPressed: downloading ? null : _download,
              child: Text(downloading ? 'جاري التحميل…' : 'تحديث الآن'),
            ),
          ],
        ),
      ),
    );
  }
}
