import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/chat_service.dart';
import '../../../widgets/chat/chat_bubble_widget.dart';
import '../../../widgets/chat/chat_input_widget.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class StudentChatScreen extends StatelessWidget {
  final String chatId;

  const StudentChatScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isAr = AppSettings.language.value == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(isAr ? "المحادثة مع المعلم" : "Chat with Teacher")),
      body: Consumer<ChatService>(
        builder: (context, chatService, child) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true, // typical for chat
                  itemCount: chatService.messages.length,
                  itemBuilder: (context, index) {
                    final msg = chatService.messages[index];
                    return ChatBubbleWidget(
                      text: msg.text,
                      isSender: msg.isMe,
                    );
                  },
                ),
              ),
              ChatInputWidget(
                onSend: (text, {filePath, fileBytes, fileName}) => chatService.sendMessage(
                  chatId,
                  text,
                  filePath: filePath,
                  fileBytes: fileBytes,
                  fileName: fileName,
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
}
