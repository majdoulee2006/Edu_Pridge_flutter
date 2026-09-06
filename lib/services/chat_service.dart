import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'dart:convert';
import '../models/chat_message_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

const String PUSHER_APP_KEY = '7ddc52d35c1e7beb4c83';
const String PUSHER_CLUSTER = 'eu';

class ChatService extends ChangeNotifier {
  late final Dio _dio;
  late PusherChannelsFlutter _pusher;

  ChatService() {
    _dio = Dio(BaseOptions(baseUrl: ApiService().baseUrl));
  }
  
  // Cache messages per contact ID
  final Map<String, List<ChatMessage>> _messagesCache = {};
  
  String? _activeContactId;
  List<ChatMessage> get messages => _activeContactId != null && _messagesCache.containsKey(_activeContactId)
      ? _messagesCache[_activeContactId]!
      : [];

  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> get contacts => _contacts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingContacts = false;
  bool get isLoadingContacts => _isLoadingContacts;
  
  String? _currentUserId;

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _ensureUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString('user_id') ?? '';
    if (storedId.isNotEmpty) {
      _currentUserId = storedId;
    }
  }

  Future<void> fetchContacts() async {
    _isLoadingContacts = true;
    notifyListeners();

    try {
      final token = await _getToken();
      final response = await _dio.get(
        '/contacts',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        _contacts = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint("Fetch Contacts Error: $e");
    } finally {
      _isLoadingContacts = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(String contactId) async {
    _activeContactId = contactId.toString();
    
    // Check if we already have messages cached for this contact
    if (!_messagesCache.containsKey(_activeContactId)) {
      // Pre-fill initial conversation history for known mock contacts
      if (_activeContactId == '1') {
        _messagesCache[_activeContactId!] = [
          ChatMessage(id: 'm1', message: 'تم اعتماد جدول الامتحانات الجديد', isMe: false, timestamp: DateTime.now().subtract(const Duration(minutes: 40)), isRead: true),
        ];
      } else if (_activeContactId == '2') {
        _messagesCache[_activeContactId!] = [
          ChatMessage(id: 'm2', message: 'يرجى مراجعة طلبات التسجيل المتأخرة', isMe: false, timestamp: DateTime.now().subtract(const Duration(minutes: 55)), isRead: true),
        ];
      } else if (_activeContactId == '3') {
        _messagesCache[_activeContactId!] = [
          ChatMessage(id: 'm3', message: 'هل انتهيت من تقييم مشاريع فلاتر؟', isMe: false, timestamp: DateTime.now().subtract(const Duration(hours: 1)), isRead: true),
        ];
      } else if (_activeContactId == '4') {
        _messagesCache[_activeContactId!] = [
          ChatMessage(id: 'm4', message: 'أستاذ، متى موعد تسليم الوظيفة؟', isMe: false, timestamp: DateTime.now().subtract(const Duration(hours: 2)), isRead: true),
        ];
      } else if (_activeContactId == '5') {
        _messagesCache[_activeContactId!] = [
          ChatMessage(id: 'm5', message: 'شكراً جزيلاً لك أستاذ على الشرح', isMe: false, timestamp: DateTime.now().subtract(const Duration(days: 1)), isRead: true),
        ];
      } else {
        _messagesCache[_activeContactId!] = [];
      }
    }

    _isLoading = true;
    notifyListeners();
    
    try {
      await _ensureUserId();
      final token = await _getToken();
      
      final response = await _dio.get(
        '/messages/$_activeContactId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final fetched = data.map((e) => ChatMessage.fromJson(e, _currentUserId ?? '')).toList();
        if (fetched.isNotEmpty) {
          _messagesCache[_activeContactId!] = fetched;
        }
      }

      try {
        await _dio.put(
          '/messages/$_activeContactId/mark-read',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } catch (e) {
        debugPrint("Mark Read API Error: $e");
      }
    } catch (e) {
      debugPrint("Fetch Messages Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(
    String contactId,
    String text, {
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    await _ensureUserId();
    final targetId = contactId.toString();
    
    final tempMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: text,
      isMe: true,
      timestamp: DateTime.now(),
      attachment: filePath ?? fileName,
      isRead: false, // 🌟 Sent messages start with single gray checkmark
    );

    if (!_messagesCache.containsKey(targetId)) {
      _messagesCache[targetId] = [];
    }
    
    // Insert new message locally
    _messagesCache[targetId]!.insert(0, tempMsg);
    _activeContactId = targetId;
    
    // Update contact's last_message in local contacts list
    final idx = _contacts.indexWhere((c) => c['id'].toString() == targetId);
    if (idx != -1) {
      _contacts[idx]['last_message'] = text;
      _contacts[idx]['message'] = text;
      _contacts[idx]['time'] = 'الآن';
      _contacts[idx]['is_read'] = true;
    }

    _isLoading = false; // 🌟 Force loading to false so sent message displays immediately!
    notifyListeners();

    try {
      final token = await _getToken();

      dynamic postData;
      if (fileBytes != null || filePath != null) {
        MultipartFile multipartFile;
        if (kIsWeb) {
          final resolvedFileName = fileName ?? filePath?.split('/').last ?? 'attachment';
          multipartFile = MultipartFile.fromBytes(
            fileBytes ?? [],
            filename: resolvedFileName,
          );
        } else {
          multipartFile = await MultipartFile.fromFile(
            filePath!,
            filename: fileName ?? filePath.split('/').last,
          );
        }

        postData = FormData.fromMap({
          'receiver_id': contactId,
          'message': text,
          'attachment': multipartFile,
        });
      } else {
        postData = {
          'receiver_id': contactId,
          'message': text,
        };
      }

      final response = await _dio.post(
        '/send-message',
        data: postData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        onSendProgress: (count, total) {
          if (total > 0) {
            debugPrint("📤 File Upload Progress: ${(count / total * 100).toStringAsFixed(0)}%");
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final serverData = response.data['data'];
        if (serverData != null && serverData['id'] != null) {
          final realId = serverData['id'].toString();
          final realAttachment = serverData['attachment']?.toString();
          
          final list = _messagesCache[targetId];
          if (list != null && list.isNotEmpty) {
            final idx = list.indexWhere((m) => m.id == tempMsg.id);
            if (idx != -1) {
              list[idx] = ChatMessage(
                id: realId,
                message: list[idx].text,
                isMe: true,
                timestamp: list[idx].timestamp,
                attachment: realAttachment ?? list[idx].attachment,
                isRead: false,
                isDelivered: true,
              );
              notifyListeners();
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Send Message API Warning (kept locally): $e");
    }
  }

  Future<void> editMessage(String messageId, String newText) async {
    if (_activeContactId != null && _messagesCache.containsKey(_activeContactId)) {
      final list = _messagesCache[_activeContactId]!;
      final index = list.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        list[index].message = newText;
        notifyListeners();
      }
    }
    
    try {
      final token = await _getToken();
      await _dio.put(
        '/messages/$messageId/edit',
        data: {'message': newText},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      debugPrint("Edit Message Error: $e");
    }
  }

  Future<void> deleteMessage(String messageId, {bool deleteForEveryone = false}) async {
    if (_activeContactId != null && _messagesCache.containsKey(_activeContactId)) {
      _messagesCache[_activeContactId]!.removeWhere((m) => m.id == messageId);
      notifyListeners();
    }

    try {
      final token = await _getToken();
      await _dio.delete(
        '/messages/$messageId',
        data: {'type': deleteForEveryone ? 'everyone' : 'me'},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      debugPrint("Delete Message Error: $e");
    }
  }

  Future<void> searchMessages(String contactId, String query) async {
    if (query.isEmpty) {
      fetchMessages(contactId);
      return;
    }
    if (_messagesCache.containsKey(contactId)) {
      _messagesCache[contactId] = _messagesCache[contactId]!
          .where((m) => m.message.toLowerCase().contains(query.toLowerCase()))
          .toList();
      notifyListeners();
    }
  }

  void initPusher(String userId) async {
    try {
      _pusher = PusherChannelsFlutter.getInstance();
      await _pusher.init(
        apiKey: PUSHER_APP_KEY,
        cluster: PUSHER_CLUSTER,
        onEvent: (event) {
          if (event.eventName == 'MessageSent') {
            final data = jsonDecode(event.data);
            final senderId = data['message']['sender_id'].toString();
            
            _ensureUserId().then((_) {
              final newMsg = ChatMessage.fromJson(data['message'], _currentUserId ?? '');
              
              if (!_messagesCache.containsKey(senderId)) {
                _messagesCache[senderId] = [];
              }
              _messagesCache[senderId]!.insert(0, newMsg);
              
              final idx = _contacts.indexWhere((c) => c['id'].toString() == senderId);
              if (idx != -1) {
                _contacts[idx]['last_message'] = newMsg.message;
                _contacts[idx]['message'] = newMsg.message;
                _contacts[idx]['time'] = 'الآن';
                _contacts[idx]['is_read'] = false;
                final currentUnread = _contacts[idx]['unread'] ?? 0;
                _contacts[idx]['unread'] = currentUnread + 1;
              } else {
                fetchContacts();
              }
              notifyListeners();
            });
          }
        },
      );
      await _pusher.subscribe(channelName: 'private-chat.$userId');
      await _pusher.connect();
    } catch (e) {
      debugPrint("Pusher Error: $e");
    }
  }
}