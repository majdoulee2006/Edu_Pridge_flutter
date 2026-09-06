import 'dart:io';
import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:dio/dio.dart';

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
    this.status = 'read',
    this.isRead = true,
    this.isDelivered = false,
    this.onLongPress,
  });

  @override
  State<ChatBubbleWidget> createState() => _ChatBubbleWidgetState();
}

class _ChatBubbleWidgetState extends State<ChatBubbleWidget> {
  bool _isPlayingAudio = false;

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
        lower.contains('voice_notes') ||
        lower.contains('voice-note') ||
        widget.text.startsWith('[Voice Note');
  }

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('.webm') ||
        lower.contains('.avi');
  }

  bool _isDownloading = false;

  Future<void> _openAttachment(String rawUrl) async {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
    });

    String finalUrl = rawUrl;
    if (widget.messageId.isNotEmpty && widget.messageId != '0') {
      finalUrl = "${ApiService.serverIp}/public-download/message/${widget.messageId}";
    }

    try {
      final tempDir = await getTemporaryDirectory();
      String fileName = "attachment_${widget.messageId}";
      
      String ext = "";
      if (rawUrl.contains('.')) {
        ext = rawUrl.split('.').last.split('?').first;
      }
      
      if (ext.isEmpty || ext.length > 5) {
        if (widget.text.startsWith('[Voice Note') || _isAudio(rawUrl)) {
          ext = "m4a";
        } else {
          ext = "pdf";
        }
      }

      fileName = "$fileName.$ext";
      final savePath = "${tempDir.path}/$fileName";
      final file = File(savePath);

      final dio = Dio();
      await dio.download(finalUrl, savePath);

      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        debugPrint("OpenFilex result error: ${result.message}");
      }
    } catch (e) {
      debugPrint("Native File Open Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Widget _buildTickIcon() {
    if (!widget.isSender) return const SizedBox.shrink();

    // WhatsApp style ticks:
    // read -> double blue ticks
    // delivered -> double gray ticks
    // sent -> single gray tick
    if (widget.status == 'read' || widget.isRead) {
      return const Icon(
        Icons.done_all,
        size: 16,
        color: Color(0xFF34B7F1), // WhatsApp Blue Tick
      );
    } else if (widget.status == 'delivered') {
      return const Icon(
        Icons.done_all,
        size: 16,
        color: Colors.grey,
      );
    } else {
      return const Icon(
        Icons.check,
        size: 16,
        color: Colors.grey,
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
        mediaContent = GestureDetector(
          onTap: () => _openAttachment(fixedUrl),
          child: Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 250),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 5)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
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
            ),
          ),
        );
      } else if ((fixedUrl != null && _isAudio(fixedUrl)) || widget.text.startsWith('[Voice Note')) {
        // 🎙️ مشغل التسجيل الصوتي بتصميم الواتس اب المميز
        mediaContent = Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSender ? Colors.black.withAlpha(25) : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  setState(() {
                    _isPlayingAudio = !_isPlayingAudio;
                  });
                  if (fixedUrl != null && fixedUrl.isNotEmpty) {
                    await _openAttachment(fixedUrl);
                  }
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: widget.isSender ? Colors.black : const Color(0xFFFFCC00),
                  child: Icon(
                    _isPlayingAudio ? Icons.pause : Icons.play_arrow_rounded,
                    color: widget.isSender ? Colors.white : Colors.black,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Waveform representation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        14,
                        (i) => Container(
                          width: 3,
                          height: (i % 3 == 0 ? 18.0 : (i % 2 == 0 ? 12.0 : 8.0)),
                          decoration: BoxDecoration(
                            color: _isPlayingAudio
                                ? (widget.isSender ? Colors.black : const Color(0xFF00A884))
                                : (widget.isSender ? Colors.black45 : Colors.grey.shade600),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Builder(
                      builder: (context) {
                        String durationDisplay = "0:15";
                        if (widget.text.contains('[Voice Note|')) {
                          final parts = widget.text.split('|');
                          if (parts.length > 1) {
                            durationDisplay = parts[1].replaceAll(']', '');
                          }
                        }
                        return Text(
                          _isPlayingAudio ? "جاري التشغيل..." : "تسجيل صوتي ($durationDisplay)",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: widget.isSender ? Colors.black87 : Colors.black54,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.mic, color: widget.isSender ? Colors.black54 : Colors.grey.shade700, size: 20),
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
        // Document/File with Download & Eye buttons for receiver
        final String fileName = fixedUrl.split('/').last;
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
                  _isDownloading ? "جاري التنزيل..." : (fileName.length > 16 ? "...${fileName.substring(fileName.length - 14)}" : fileName),
                  style: TextStyle(
                    color: widget.isSender ? Colors.black : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // 📥 زر تنزيل الملف
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
              // 👁️ زر العين لمعاينة الملف بداخل التطبيق
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
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
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
