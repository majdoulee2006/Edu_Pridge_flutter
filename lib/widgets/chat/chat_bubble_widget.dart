import 'package:flutter/material.dart';

class ChatBubbleWidget extends StatelessWidget {
  final String text;
  final bool isSender;
  final VoidCallback? onLongPress;

  const ChatBubbleWidget({
    Key? key,
    required this.text,
    required this.isSender,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSender ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(color: isSender ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}
