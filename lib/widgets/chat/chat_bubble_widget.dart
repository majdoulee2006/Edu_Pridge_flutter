import 'dart:io';
import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:dio/dio.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'in_app_media_viewer.dart';

class ChatBubbleWidget extends StatefulWidget {
  final String messageId;
  final String text;
  final bool isSender;
  final String? attachment;
  final String? time;
  final String status; // 'sent', 'delivered', 'read'
  final bool isRead;
  final bool isDelivered;
  final VoidCallback? onLongPress;

  const ChatBubbleWidget({
    super.key,
    this.messageId = '',
    required this.text,
    required this.isSender,
    this.attachment,
    this.time,
    this.status = 'sent',
    this.isRead = false,
    this.isDelivered = false,
    this.onLongPress,
  });

  @override
  State<ChatBubbleWidget> createState() => _ChatBubbleWidgetState();
}

class _ChatBubbleWidgetState extends State<ChatBubbleWidget> {
  // ── Audio Player State ──
  AudioPlayer? _audioPlayer;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  bool _isPlayingAudio = false;
  bool _isAudioBuffering = false;

  bool _isImage(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.png') ||
        lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.webp') ||
        lower.contains('.gif');
  }

  bool _isAudio(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.mp3') ||
        lower.contains('.wav') ||
        lower.contains('.m4a') ||
        lower.contains('.ogg') ||
        lower.contains('.aac') ||
        lower.contains('.webm') ||
        lower.contains('voice_notes') ||
        lower.contains('voice-note') ||
        widget.text.startsWith('[Voice Note');
  }

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('voice_notes') || lower.contains('voice-note') || widget.text.startsWith('[Voice Note')) {
      return false;
    }
    return lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('.avi') ||
        lower.contains('.mkv');
  }

  bool _isDownloading = false;

  @override
  void dispose() {
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _audioPlayer = null;
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Future<void> _toggleAudio(String? fixedUrl) async {
    if (_isPlayingAudio) {
      await _audioPlayer?.pause();
      if (mounted) setState(() => _isPlayingAudio = false);
      return;
    }

    if (_audioPlayer != null && _audioPosition > Duration.zero && _audioPosition < _audioDuration) {
      await _audioPlayer?.resume();
      if (mounted) setState(() => _isPlayingAudio = true);
      return;
    }

    String? playSource = fixedUrl;
    bool isLocal = false;

    // Check if attachment is a valid local file path (recorded on this device)
    if (widget.attachment != null && File(widget.attachment!).existsSync()) {
      playSource = widget.attachment!;
      isLocal = true;
    } else if (playSource == null || playSource.isEmpty) {
      if (widget.messageId.isNotEmpty && widget.messageId != '0') {
        playSource = "${ApiService.baseHttpUrl}/public-download/message/${widget.messageId}";
      }
    }

    if (playSource == null || playSource.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ ملف التسجيل الصوتي غير متوفر على السيرفر'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isAudioBuffering = true;
        _isPlayingAudio = true;
      });
    }

    try {
      _audioPlayer ??= AudioPlayer();

      _audioPlayer!.onPlayerStateChanged.listen((state) {
        if (!mounted) return;
        setState(() {
          _isPlayingAudio = (state == PlayerState.playing);
          if (state == PlayerState.playing || state == PlayerState.stopped || state == PlayerState.paused) {
            _isAudioBuffering = false;
          }
        });
      });

      _audioPlayer!.onDurationChanged.listen((d) {
        if (!mounted) return;
        setState(() => _audioDuration = d);
      });

      _audioPlayer!.onPositionChanged.listen((p) {
        if (!mounted) return;
        setState(() {
          _audioPosition = p;
          _isAudioBuffering = false;
        });
      });

      _audioPlayer!.onPlayerComplete.listen((_) {
        if (!mounted) return;
        setState(() {
          _isPlayingAudio = false;
          _audioPosition = Duration.zero;
        });
      });

      if (isLocal) {
        await _audioPlayer!.play(DeviceFileSource(playSource));
      } else {
        // Download audio locally to temp before playing to guarantee cross-platform support
        final tempDir = await getTemporaryDirectory();
        final ext = playSource.contains('.') ? ".${playSource.split('.').last.split('?').first}" : ".m4a";
        final tempAudioPath = "${tempDir.path}/voice_${widget.messageId}$ext";
        final tempFile = File(tempAudioPath);

        if (!tempFile.existsSync() || tempFile.lengthSync() < 100) {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token') ?? '';
          final dio = Dio();
          await dio.download(
            playSource,
            tempAudioPath,
            options: Options(
              headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null,
              validateStatus: (status) => status != null && status < 500,
            ),
          );
        }

        if (tempFile.existsSync() && tempFile.lengthSync() > 100) {
          // Binary Header Validation: ensure file is valid audio and not an HTML error response (e.g. 404 page)
          final firstBytes = await tempFile.openRead(0, 100).first;
          final headerContent = String.fromCharCodes(firstBytes).toLowerCase();
          if (headerContent.contains('<!doctype') || headerContent.contains('<html') || headerContent.contains('404 not found')) {
            await tempFile.delete();
            throw Exception("ملف التسجيل الصوتي غير متوفر على السيرفر");
          }
          await _audioPlayer!.play(DeviceFileSource(tempAudioPath));
        } else {
          await _audioPlayer!.play(UrlSource(playSource));
        }
      }
    } catch (e) {
      debugPrint("❌ In-App Audio Play Error: $e");
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
          _isAudioBuffering = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ تعذر تشغيل التسجيل الصوتي، الملف غير متوفر أو تالف'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _openAttachment(String rawUrl) async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      // 1. Check if attachment is a local file on this device (e.g. sent by current user)
      if (rawUrl.isNotEmpty && File(rawUrl).existsSync()) {
        await OpenFilex.open(rawUrl);
        return;
      }
      if (widget.attachment != null && File(widget.attachment!).existsSync()) {
        await OpenFilex.open(widget.attachment!);
        return;
      }

      // 2. Prepare save path in temporary directory
      final tempDir = await getTemporaryDirectory();
      String originalName = rawUrl.split('/').last.split('?').first;
      if (originalName.isEmpty || !originalName.contains('.')) {
        originalName = "file_${widget.messageId}.pdf";
      }

      final savePath = "${tempDir.path}/$originalName";
      final cachedFile = File(savePath);

      // 3. If file was already downloaded and exists locally with valid size, open directly
      if (cachedFile.existsSync() && cachedFile.lengthSync() > 100) {
        await OpenFilex.open(savePath);
        return;
      }

      // 4. Resolve download URL using ApiService.fixMediaUrl
      String? downloadUrl = ApiService.fixMediaUrl(rawUrl);
      if ((downloadUrl == null || downloadUrl.isEmpty) && widget.messageId.isNotEmpty && widget.messageId != '0') {
        downloadUrl = "${ApiService.baseHttpUrl}/public-download/message/${widget.messageId}";
      }

      if (downloadUrl == null || downloadUrl.isEmpty) {
        throw Exception("رابط الملف غير صالح");
      }

      // 5. Get auth token for protected routes
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final dio = Dio();
      await dio.download(
        downloadUrl,
        savePath,
        options: Options(
          headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final downloadedFile = File(savePath);
      if (downloadedFile.existsSync() && downloadedFile.lengthSync() > 100) {
        // Validate file content is not an HTML error response (e.g. 404/403 page)
        final firstBytes = await downloadedFile.openRead(0, 100).first;
        final headerContent = String.fromCharCodes(firstBytes).toLowerCase();
        if (headerContent.contains('<!doctype') || headerContent.contains('<html') || headerContent.contains('404 not found')) {
          await downloadedFile.delete();
          throw Exception("الملف المرفق غير موجود على السيرفر أو لم يتم رفعه بنجاح");
        }
        await OpenFilex.open(savePath);
      } else {
        throw Exception("فشل تنزيل الملف من السيرفر");
      }
    } catch (e) {
      debugPrint("Native File Open Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تحميل أو فتح الملف: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Widget _buildTickIcon() {
    if (!widget.isSender) return const SizedBox.shrink();

    if (widget.isRead || widget.status == 'read') {
      return const Icon(
        Icons.done_all,
        size: 16,
        color: Color(0xFF34B7F1), // Double Blue Ticks (Read)
      );
    } else if (widget.isDelivered || widget.status == 'delivered') {
      return const Icon(
        Icons.done_all,
        size: 16,
        color: Colors.grey, // Double Grey Ticks (Delivered)
      );
    } else {
      return const Icon(
        Icons.check,
        size: 16,
        color: Colors.grey, // Single Grey Tick (Sent)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String? fixedUrl = ApiService.fixMediaUrl(widget.attachment);
    final String timeStr = widget.time ?? 'الآن';

    Widget mediaContent = const SizedBox.shrink();

    if ((fixedUrl != null && fixedUrl.isNotEmpty) || widget.text.startsWith('[Voice Note')) {
      if (fixedUrl != null && _isImage(fixedUrl)) {
        // 🖼️ صورة تفاعلية تفتح بداخل التطبيق
        mediaContent = GestureDetector(
          onTap: () => InAppMediaViewer.show(context, fixedUrl, title: 'صورة مرفقة'),
          child: Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 250),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 5)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    fixedUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        color: Colors.grey,
                        child: const Icon(Icons.broken_image, color: Colors.white),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(120),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.fullscreen, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else if ((fixedUrl != null && _isAudio(fixedUrl)) || widget.text.startsWith('[Voice Note')) {
        // 🎙️ مشغل صوت احترافي داخل الفقاعة (In-App Voice Note Player)
        String durationHint = "0:15";
        if (widget.text.contains('[Voice Note|')) {
          final parts = widget.text.split('|');
          if (parts.length > 1) {
            durationHint = parts[1].replaceAll(']', '');
          }
        }

        final displayCurrentTime = _formatDuration(_audioPosition);
        final displayTotalTime = _audioDuration > Duration.zero
            ? _formatDuration(_audioDuration)
            : durationHint;

        mediaContent = Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSender ? Colors.black.withAlpha(25) : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // زر التشغيل / الإيقاف المؤقت
              GestureDetector(
                onTap: () => _toggleAudio(fixedUrl),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: widget.isSender ? Colors.black : const Color(0xFFFFCC00),
                  child: _isAudioBuffering
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: widget.isSender ? Colors.white : Colors.black,
                          ),
                        )
                      : Icon(
                          _isPlayingAudio ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: widget.isSender ? Colors.white : Colors.black,
                          size: 26,
                        ),
                ),
              ),
              const SizedBox(width: 8),
              // شريط التقدم والوقت
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                        activeTrackColor: widget.isSender ? Colors.black : const Color(0xFF00A884),
                        inactiveTrackColor: widget.isSender ? Colors.black26 : Colors.grey.shade500,
                        thumbColor: widget.isSender ? Colors.black : const Color(0xFF00A884),
                      ),
                      child: Slider(
                        value: _audioPosition.inMilliseconds
                            .clamp(0, (_audioDuration.inMilliseconds > 0 ? _audioDuration.inMilliseconds : 1))
                            .toDouble(),
                        max: (_audioDuration.inMilliseconds > 0 ? _audioDuration.inMilliseconds : 1).toDouble(),
                        onChanged: (val) {
                          if (_audioPlayer != null && _audioDuration > Duration.zero) {
                            _audioPlayer!.seek(Duration(milliseconds: val.toInt()));
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isPlayingAudio ? displayCurrentTime : "تسجيل صوتي",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: widget.isSender ? Colors.black87 : Colors.black54,
                            ),
                          ),
                          Text(
                            displayTotalTime,
                            style: TextStyle(
                              fontSize: 10,
                              color: widget.isSender ? Colors.black87 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.mic_rounded, color: widget.isSender ? Colors.black54 : Colors.grey.shade700, size: 20),
            ],
          ),
        );
      } else if (fixedUrl != null && _isVideo(fixedUrl)) {
        mediaContent = GestureDetector(
          onTap: () => _openAttachment(fixedUrl),
          child: Container(
            margin: const EdgeInsets.only(top: 6),
            height: 150,
            width: 230,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
            ),
          ),
        );
      } else if (fixedUrl != null) {
        // 📄 مستند أو ملف
        final String fileName = fixedUrl.split('/').last.split('?').first;
        mediaContent = Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.isSender ? Colors.black.withAlpha(25) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withAlpha(51)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _isDownloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                    )
                  : Icon(Icons.insert_drive_file, color: widget.isSender ? Colors.black : Colors.blue),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _isDownloading ? "جاري التنزيل..." : (fileName.length > 18 ? "...${fileName.substring(fileName.length - 16)}" : fileName),
                  style: TextStyle(
                    color: widget.isSender ? Colors.black : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // 📥 زر تنزيل وفتح الملف
              InkWell(
                onTap: () => _openAttachment(fixedUrl),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.file_download_rounded, size: 18, color: Colors.blue),
                ),
              ),
              const SizedBox(width: 6),
              // 👁️ زر المعاينة
              InkWell(
                onTap: () => _openAttachment(fixedUrl),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove_red_eye_rounded, size: 18, color: Colors.green),
                ),
              ),
            ],
          ),
        );
      }
    }

    final showText = widget.text != "[Attachment]" && !widget.text.startsWith("[Voice Note");

    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: Align(
        alignment: widget.isSender ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
          decoration: BoxDecoration(
            color: widget.isSender
                ? const Color(0xFFFFCC00)
                : (isDark ? Colors.white.withAlpha(15) : Colors.grey.shade200),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: widget.isSender ? const Radius.circular(18) : const Radius.circular(2),
              bottomRight: widget.isSender ? const Radius.circular(2) : const Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: widget.isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showText)
                Text(
                  widget.text,
                  style: TextStyle(
                    color: widget.isSender ? Colors.black : (isDark ? Colors.white : Colors.black87),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              mediaContent,
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.isSender ? Colors.black54 : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                    ),
                  ),
                  if (widget.isSender) ...[
                    const SizedBox(width: 4),
                    _buildTickIcon(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

