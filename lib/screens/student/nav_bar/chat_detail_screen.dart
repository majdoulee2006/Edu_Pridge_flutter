import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:edu_pridge_flutter/services/chat_service.dart';
import 'package:edu_pridge_flutter/models/chat_message_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class ChatDetailScreen extends StatefulWidget {
  final int receiverId;
  final String name;
  final String imageUrl;
  final bool isGroup;

  const ChatDetailScreen({
    super.key,
    required this.receiverId,
    required this.name,
    required this.imageUrl,
    this.isGroup = false,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatService>().fetchMessages(widget.receiverId.toString());
    });
  }

  String _formatTime(DateTime dt) {
    final localDt = dt.toLocal();
    final hour = localDt.hour > 12 ? localDt.hour - 12 : (localDt.hour == 0 ? 12 : localDt.hour);
    final amPm = localDt.hour >= 12 ? 'م' : 'ص';
    final minute = localDt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final String text = _messageController.text;

    setState(() {
      _messageController.clear();
    });

    try {
      await context.read<ChatService>().sendMessage(widget.receiverId.toString(), text);
    } catch (e) {
      debugPrint("❌ خطأ في إرسال الرسالة: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('إرفاق ملف', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(Icons.image, 'صورة', Colors.purple, isDark, textColor, 'image'),
                  _buildAttachmentOption(Icons.videocam, 'فيديو', Colors.pink, isDark, textColor, 'video'),
                  _buildAttachmentOption(Icons.insert_drive_file, 'مستند', Colors.blue, isDark, textColor, 'file'),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(IconData icon, String title, Color color, bool isDark, Color textColor, String type) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        String? filePath;
        List<int>? fileBytes;
        String? fileName;
        try {
          if (type == 'image') {
            final picker = ImagePicker();
            final image = await picker.pickImage(source: ImageSource.gallery);
            if (image != null) {
              filePath = image.path;
              fileName = image.name;
              fileBytes = await image.readAsBytes();
            }
          } else if (type == 'video') {
            final picker = ImagePicker();
            final video = await picker.pickVideo(source: ImageSource.gallery);
            if (video != null) {
              filePath = video.path;
              fileName = video.name;
              fileBytes = await video.readAsBytes();
            }
          } else {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'zip'],
              withData: true,
            );
            if (result != null) {
              filePath = result.files.single.path;
              fileName = result.files.single.name;
              fileBytes = result.files.single.bytes;
            }
          }

          if (fileBytes != null || filePath != null) {
            await context.read<ChatService>().sendMessage(
              widget.receiverId.toString(),
              "[Attachment]",
              filePath: filePath,
              fileBytes: fileBytes,
              fileName: fileName,
            );
          }
        } catch (e) {
          debugPrint("Picking attachment error: $e");
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: color.withAlpha(isDark ? 50 : 25), shape: BoxShape.circle),
            child: Icon(icon, color: isDark ? color.withAlpha(200) : color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF7F9FC);
    final appBarColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    final chatService = context.watch<ChatService>();
    final messages = chatService.messages;
    final isLoading = chatService.isLoading;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: appBarColor,
          elevation: isDark ? 0 : 1,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                backgroundImage: NetworkImage(widget.imageUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.isGroup ? 'مجموعة دراسية' : 'متصل الآن',
                      style: TextStyle(color: widget.isGroup ? Colors.grey : Colors.green, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(20),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        bool isMe = widget.isGroup ? false : msg.isMe;
                        return _buildMessageBubble(msg.text, isMe, _formatTime(msg.timestamp), isDark);
                      },
                    ),
            ),
            if (widget.isGroup)
              _buildReadOnlyBanner(isDark)
            else
              _buildMessageInput(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String time, bool isDark) {
    Color bubbleColor = isMe ? const Color(0xFFFFCC00) : (isDark ? Theme.of(context).cardColor : Colors.white);
    Color messageTextColor = isMe ? Colors.black87 : (isDark ? Colors.white : Colors.black87);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(color: isDark ? Colors.black.withAlpha(50) : Colors.black.withAlpha(12), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(text, style: TextStyle(fontSize: 14, color: messageTextColor, height: 1.4)),
            const SizedBox(height: 1),
            Text(time, style: TextStyle(fontSize: 10, color: isMe ? Colors.black54 : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        boxShadow: [BoxShadow(color: isDark ? Colors.black45 : Colors.black12, blurRadius: 10)],
      ),
      child: const Center(
        child: Text(
          'هذه المجموعة مغلقة ولا يمكنك إرسال رسائل فيها',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Future<void> _showVoiceNotePicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg', 'aac'],
        withData: true,
      );
      if (result != null) {
        final path = result.files.single.path;
        final bytes = result.files.single.bytes;
        final name = result.files.single.name;
        
        if (bytes != null || path != null) {
          await context.read<ChatService>().sendMessage(
            widget.receiverId.toString(),
            "[Voice Note]",
            filePath: path,
            fileBytes: bytes,
            fileName: name,
          );
        }
      }
    } catch (e) {
      debugPrint("Error sending voice note: $e");
    }
  }

  Widget _buildMessageInput(bool isDark) {
    final bgColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final inputBgColor = isDark ? Colors.grey.shade800 : const Color(0xFFF2F2F2);
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      // 🌟 الإصلاح هنا: وضعنا الـ color والـ boxShadow بداخل BoxDecoration
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [BoxShadow(color: isDark ? Colors.black45 : Colors.black12, blurRadius: 10)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: inputBgColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالتك...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade500 : Colors.grey,
                    ),
                    border: InputBorder.none,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.mic, color: isDark ? Colors.grey.shade400 : Colors.grey, size: 22),
                          onPressed: _showVoiceNotePicker,
                        ),
                        IconButton(
                          icon: Icon(Icons.attach_file, color: isDark ? Colors.grey.shade400 : Colors.grey, size: 22),
                          onPressed: () => _showAttachmentOptions(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFCC00),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}