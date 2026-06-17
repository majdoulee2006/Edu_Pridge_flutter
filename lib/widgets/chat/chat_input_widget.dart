import 'package:flutter/material.dart';

class ChatInputWidget extends StatefulWidget {
  final Function(String text) onSend;
  final VoidCallback onAttachmentPressed;
  final VoidCallback onVoiceRecordPressed;

  const ChatInputWidget({
    Key? key,
    required this.onSend,
    required this.onAttachmentPressed,
    required this.onVoiceRecordPressed,
  }) : super(key: key);

  @override
  _ChatInputWidgetState createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: widget.onAttachmentPressed,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Type a message...",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: widget.onVoiceRecordPressed,
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blueAccent),
            onPressed: () {
              if (_controller.text.trim().isNotEmpty) {
                widget.onSend(_controller.text);
                _controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
