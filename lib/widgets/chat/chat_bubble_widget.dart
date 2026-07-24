import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBubbleWidget extends StatelessWidget {
  final String text;
  final bool isSender;
  final String? attachment;
  final VoidCallback? onLongPress;

  const ChatBubbleWidget({
    super.key,
    required this.text,
    required this.isSender,
    this.attachment,
    this.onLongPress,
  });

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
        lower.contains('voice-note');
  }

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('.webm') ||
        lower.contains('.avi');
  }

  Future<void> _openAttachment(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String? fixedUrl = ApiService.fixMediaUrl(attachment);

    Widget mediaContent = const SizedBox.shrink();

    if (fixedUrl != null && fixedUrl.isNotEmpty) {
      if (_isImage(fixedUrl)) {
        mediaContent = GestureDetector(
          onTap: () => _openAttachment(fixedUrl),
          child: Container(
            margin: const EdgeInsets.only(top: 8),
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
      } else if (_isAudio(fixedUrl)) {
        mediaContent = Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSender ? Colors.black.withAlpha(38) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.play_arrow, color: isSender ? Colors.white : Colors.black87),
                onPressed: () => _openAttachment(fixedUrl),
              ),
              const SizedBox(width: 5),
              Text(
                "رسالة صوتية",
                style: TextStyle(
                  color: isSender ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.mic, color: isSender ? Colors.white70 : Colors.grey),
            ],
          ),
        );
      } else if (_isVideo(fixedUrl)) {
        mediaContent = GestureDetector(
          onTap: () => _openAttachment(fixedUrl),
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            height: 150,
            width: 250,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
            ),
          ),
        );
      } else {
        // Document/File
        final String fileName = fixedUrl.split('/').last;
        mediaContent = GestureDetector(
          onTap: () => _openAttachment(fixedUrl),
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSender ? Colors.black.withAlpha(25) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withAlpha(51)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insert_drive_file, color: isSender ? Colors.white : Colors.blue),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    fileName.length > 20 ? "...${fileName.substring(fileName.length - 17)}" : fileName,
                    style: TextStyle(
                      color: isSender ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    final showText = text != "[Attachment]" && text != "[Voice Note]";

    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isSender ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSender
                ? const Color(0xFFFFCC00)
                : (isDark ? Colors.white.withAlpha(12) : Colors.grey.shade200),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isSender ? const Radius.circular(20) : const Radius.circular(0),
              bottomRight: isSender ? const Radius.circular(0) : const Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showText)
                Text(
                  text,
                  style: TextStyle(
                    color: isSender ? Colors.black : (isDark ? Colors.white : Colors.black87),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              mediaContent,
            ],
          ),
        ),
      ),
    );
  }
}
