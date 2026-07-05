import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ChatInputWidget extends StatefulWidget {
  final Function(String text, {String? filePath, List<int>? fileBytes, String? fileName}) onSend;
  final TextEditingController? controller;
  final bool isEditing;
  final VoidCallback? onCancelEdit;

  const ChatInputWidget({
    Key? key,
    required this.onSend,
    this.controller,
    this.isEditing = false,
    this.onCancelEdit,
  }) : super(key: key);

  @override
  _ChatInputWidgetState createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void didUpdateWidget(ChatInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && widget.controller != _controller) {
      _controller = widget.controller!;
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'mp4', 'mov', 'avi'],
      withData: true,
    );
    if (result != null) {
      final file = result.files.single;
      widget.onSend(
        "[Attachment]",
        filePath: file.path,
        fileBytes: file.bytes,
        fileName: file.name,
      );
    }
  }

  Future<void> _pickVoiceNote() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg', 'aac'],
      withData: true,
    );
    if (result != null) {
      final file = result.files.single;
      widget.onSend(
        "[Voice Note]",
        filePath: file.path,
        fileBytes: file.bytes,
        fileName: file.name,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final inputBgColor = isDark ? Colors.grey.shade800 : const Color(0xFFF2F2F2);
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      color: bgColor,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: inputBgColor,
                borderRadius: BorderRadius.circular(30), // Oval-shaped (rounded)
              ),
              child: TextField(
                controller: _controller,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  hintStyle: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade500 : Colors.grey),
                  border: InputBorder.none,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isEditing)
                        IconButton(
                          icon: Icon(Icons.cancel, color: Colors.red.shade400, size: 22),
                          onPressed: widget.onCancelEdit,
                        )
                      else ...[
                        IconButton(
                          icon: Icon(Icons.mic, color: isDark ? Colors.grey.shade400 : Colors.grey, size: 22),
                          onPressed: _pickVoiceNote,
                        ),
                        IconButton(
                          icon: Icon(Icons.attach_file, color: isDark ? Colors.grey.shade400 : Colors.grey, size: 22),
                          onPressed: _pickFile,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              if (_controller.text.trim().isNotEmpty) {
                widget.onSend(_controller.text);
                _controller.clear();
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.isEditing ? Colors.blue : const Color(0xFFFFCC00),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.isEditing ? Icons.check : Icons.arrow_upward,
                color: widget.isEditing ? Colors.white : Colors.black,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
