import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/chat/chat_bubble_widget.dart';
import '../../widgets/chat/chat_input_widget.dart';

class ChatRoomScreen extends StatefulWidget {
  final Map<String, dynamic> contact;

  const ChatRoomScreen({super.key, required this.contact});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String? _editingMessageId;

  @override
  void initState() {
    super.initState();
    // Fetch messages when entering the chat room
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatService>().fetchMessages(widget.contact['id']);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Theme.of(context).cardColor,
        elevation: 1,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'البحث في المحادثة...',
                  hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  border: InputBorder.none,
                ),
                onSubmitted: (val) {
                  context.read<ChatService>().searchMessages(widget.contact['id'].toString(), val);
                },
              )
            : Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: widget.contact['image'] != null ? NetworkImage(widget.contact['image']) : null,
                      child: widget.contact['image'] == null ? Text(widget.contact['name'][0]) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.contact['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(widget.contact['role'], style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  context.read<ChatService>().searchMessages(widget.contact['id'].toString(), '');
                }
              });
            },
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Consumer<ChatService>(
            builder: (context, chatService, child) {
              return Column(
                children: [
                  Expanded(
                    child: chatService.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.all(16),
                            itemCount: chatService.messages.length,
                            itemBuilder: (context, index) {
                              final msg = chatService.messages[index];
                              return ChatBubbleWidget(
                                text: msg.text,
                                isSender: msg.isMe,
                                onLongPress: msg.isMe && msg.attachment == null && msg.text != '[Voice Note]'
                                    ? () {
                                        showModalBottomSheet(
                                          context: context,
                                          builder: (ctx) => SafeArea(
                                            child: Wrap(
                                              children: [
                                                ListTile(
                                                  leading: const Icon(Icons.edit, color: Colors.blue),
                                                  title: const Text('تعديل الرسالة'),
                                                  onTap: () {
                                                    Navigator.pop(ctx);
                                                    setState(() {
                                                      _editingMessageId = msg.id;
                                                      _inputController.text = msg.text;
                                                    });
                                                  },
                                                ),
                                                ListTile(
                                                  leading: const Icon(Icons.delete, color: Colors.red),
                                                  title: const Text('حذف الرسالة'),
                                                  onTap: () {
                                                    Navigator.pop(ctx);
                                                    chatService.deleteMessage(msg.id);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                              );
                            },
                          ),
                  ),
                  ChatInputWidget(
                    controller: _inputController,
                    isEditing: _editingMessageId != null,
                    onCancelEdit: () {
                      setState(() {
                        _editingMessageId = null;
                        _inputController.clear();
                      });
                    },
                    onSend: (text, {filePath, fileBytes, fileName}) {
                      if (_editingMessageId != null) {
                        chatService.editMessage(_editingMessageId!, text);
                        setState(() {
                          _editingMessageId = null;
                        });
                      } else {
                        chatService.sendMessage(
                          widget.contact['id'].toString(),
                          text,
                          filePath: filePath,
                          fileBytes: fileBytes,
                          fileName: fileName,
                        );
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
