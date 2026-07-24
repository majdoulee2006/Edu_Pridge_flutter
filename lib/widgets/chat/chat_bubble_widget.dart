import 'package:flutter/material.dart';

class ChatBubbleWidget extends StatelessWidget {
  final String text;
  final bool isSender;
  final bool isRead;
  final bool isDelivered;
  final VoidCallback? onLongPress;

  const ChatBubbleWidget({
    Key? key,
    required this.text,
    required this.isSender,
    this.isRead = false,
    this.isDelivered = false,
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
            color: isSender ? const Color(0xFFE7FFDB) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  text,
                  style: const TextStyle(color: Colors.black87, fontSize: 15),
                ),
              ),
              if (isSender) ...[
                const SizedBox(width: 8),
                Icon(
                  isRead ? Icons.done_all : (isDelivered ? Icons.done_all : Icons.check),
                  size: 16,
                  color: isRead ? Colors.blue : Colors.grey,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
