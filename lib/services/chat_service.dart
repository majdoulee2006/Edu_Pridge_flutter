import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message_model.dart';
import 'api_service.dart';

const String PUSHER_APP_KEY = '7ddc52d35c1e7beb4c83';
const String PUSHER_CLUSTER = 'eu';

class ChatService extends ChangeNotifier {
  PusherChannelsFlutter? _pusher;
  Timer? _messagesPollingTimer;
  Timer? _contactsPollingTimer;

  // Cache messages per contact ID
  final Map<String, List<ChatMessage>> _messagesCache = {};
  
  String? _activeContactId;
  String? get activeContactId => _activeContactId;

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

  // 🌟 Dynamic Dio instance getter matching ApiService.baseUrl
  Dio get _dio => Dio(BaseOptions(
        baseUrl: ApiService().baseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
      ));

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

  // ==========================================
  // 1. جلب قائمة جهات الاتصال (Contacts)
  // ==========================================
  Future<void> fetchContacts({bool silent = false}) async {
    if (!silent) {
      _isLoadingContacts = true;
      notifyListeners();
    }

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
      debugPrint("📡 Fetch Contacts API Warning: $e");
    } finally {
      if (!silent) {
        _isLoadingContacts = false;
      }
      notifyListeners();
    }
  }

  // ==========================================
  // 2. جلب المحادثة مع شخص محدد (Messages)
  // ==========================================
  Future<void> fetchMessages(String contactId, {bool silent = false}) async {
    _activeContactId = contactId.toString();

    if (!_messagesCache.containsKey(_activeContactId)) {
      _messagesCache[_activeContactId!] = [];
    }

    if (!silent && _messagesCache[_activeContactId!]!.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      await _ensureUserId();
      final token = await _getToken();
      
      final response = await _dio.get(
        '/messages/$_activeContactId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final fetched = data.map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map), _currentUserId ?? '')).toList();
        
        // Merge or replace safely
        _messagesCache[_activeContactId!] = fetched;
      }

      // Mark conversation as read on server
      try {
        await _dio.put(
          '/messages/$_activeContactId/mark-read',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } catch (_) {}

    } catch (e) {
      debugPrint("📡 Fetch Messages API Warning: $e");
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  // ==========================================
  // 3. المحرك الهجين الذكي (Smart Polling Engine)
  // ==========================================
  void startSmartPolling(String contactId) {
    _activeContactId = contactId;
    _messagesPollingTimer?.cancel();

    // Fetch immediately
    fetchMessages(contactId, silent: true);

    // هذا الاستطلاع (polling) هو المسار الوحيد الفعّال حالياً لاستقبال الرسائل،
    // لأن BROADCAST_CONNECTION على السيرفر لسا مضبوطة على "log" وليس "pusher"
    // (Pusher نفسه موصول بشكل صحيح من جهة التوثيق ويشتغل تلقائياً فور ضبط
    // بيانات اعتماد Pusher حقيقية بالسيرفر — دون أي تعديل إضافي بهذا الملف)
    _messagesPollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_activeContactId != null && _activeContactId == contactId) {
        fetchMessages(contactId, silent: true);
      }
    });
  }

  void stopSmartPolling() {
    _messagesPollingTimer?.cancel();
    _messagesPollingTimer = null;
  }

  void startContactsPolling() {
    _contactsPollingTimer?.cancel();
    fetchContacts(silent: true);
    _contactsPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchContacts(silent: true);
    });
  }

  void stopContactsPolling() {
    _contactsPollingTimer?.cancel();
    _contactsPollingTimer = null;
  }

  // ==========================================
  // 4. إرسال رسالة (Send Message)
  // ==========================================
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
      isRead: false,
      isDelivered: false,
    );

    if (!_messagesCache.containsKey(targetId)) {
      _messagesCache[targetId] = [];
    }
    
    // Insert new message locally for immediate UI feedback
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

    _isLoading = false;
    notifyListeners();

    try {
      final token = await _getToken();

      dynamic postData;
      if (fileBytes != null || (filePath != null && filePath.isNotEmpty)) {
        MultipartFile multipartFile;
        if (kIsWeb || fileBytes != null) {
          final resolvedFileName = fileName ?? (filePath != null ? filePath.split('/').last : 'attachment.bin');
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
                attachment: ApiService.fixMediaUrl(realAttachment ?? list[idx].attachment),
                isRead: false,
                isDelivered: true,
              );
              notifyListeners();
            }
          }
        }
      }
    } catch (e) {
      debugPrint(" Send Message API Warning (kept locally): $e");
    }
  }

  // ==========================================
  // 5. تعديل وحذف الرسائل (Edit & Delete)
  // ==========================================
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
      final typeStr = deleteForEveryone ? 'everyone' : 'me';
      await _dio.delete(
        '/messages/$messageId?type=$typeStr',
        data: {'type': typeStr},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      debugPrint("Delete Message Error: $e");
    }
  }

  Future<void> searchMessages(String contactId, String query) async {
    if (query.isEmpty) {
      fetchMessages(contactId, silent: true);
      return;
    }
    if (_messagesCache.containsKey(contactId)) {
      _messagesCache[contactId] = _messagesCache[contactId]!
          .where((m) => m.message.toLowerCase().contains(query.toLowerCase()))
          .toList();
      notifyListeners();
    }
  }

  // ==========================================
  // 6. تهيئة Pusher للشبكات الأونلاين (Pusher Realtime)
  // ==========================================
  void initPusher(String userId) async {
    try {
      _pusher = PusherChannelsFlutter.getInstance();
      await _pusher!.init(
        apiKey: PUSHER_APP_KEY,
        cluster: PUSHER_CLUSTER,
        // نوثّق قنوات البث الخاصة (private-) بأنفسنا عبر توكن الدخول (Bearer)
        // بدل الاعتماد على جلسة متصفح، لأن التطبيق موبايل وليس ويب
        onAuthorizer: (channelName, socketId, options) async {
          // مهم جداً: هالكولباك بيوقف خيط تنفيذ كامل بمكتبة Pusher الأصلية
          // لحد ما يرجع نتيجة، فلازم نحدد سقف زمني قصير — غير هيك أي بطء
          // أو انقطاع بالشبكة (متل السيرفر المحلي لما نكون برّا الجامعة)
          // بيجمّد الشاشة بدل ما يفشل بسرعة ويرجع لـ polling العادي
          try {
            final token = await _getToken();
            // نفس مسار /api لأن /api/broadcasting/auth هو المسجّل فعلياً
            // ضمن مجموعة auth:sanctum بـ routes/api.php
            final response = await Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 5),
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            )).post(
              '${ApiService().baseUrl}/broadcasting/auth',
              data: {'socket_id': socketId, 'channel_name': channelName},
              options: Options(headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              }),
            );
            return response.data;
          } catch (e) {
            debugPrint("📡 Pusher channel auth failed (falling back to polling): $e");
            return {};
          }
        },
        onEvent: (event) {
          if (event.eventName == 'MessageSent' || event.eventName.contains('MessageSent')) {
            try {
              final rawData = jsonDecode(event.data);
              Map<String, dynamic> data;
              if (rawData is Map<String, dynamic>) {
                data = rawData;
              } else {
                data = Map<String, dynamic>.from(rawData);
              }

              // Extract sender_id safely from top-level or nested message
              final senderId = (data['sender_id'] ?? data['message_data']?['sender_id'] ?? data['message']?['sender_id'])?.toString() ?? '';
              
              if (senderId.isNotEmpty) {
                _ensureUserId().then((_) {
                  final newMsg = ChatMessage.fromJson(data, _currentUserId ?? '');
                  
                  if (!_messagesCache.containsKey(senderId)) {
                    _messagesCache[senderId] = [];
                  }

                  // Prevent duplicates
                  if (!_messagesCache[senderId]!.any((m) => m.id == newMsg.id)) {
                    _messagesCache[senderId]!.insert(0, newMsg);
                  }
                  
                  final idx = _contacts.indexWhere((c) => c['id'].toString() == senderId);
                  if (idx != -1) {
                    _contacts[idx]['last_message'] = newMsg.message;
                    _contacts[idx]['message'] = newMsg.message;
                    _contacts[idx]['time'] = 'الآن';
                    _contacts[idx]['is_read'] = false;
                    final currentUnread = _contacts[idx]['unread'] ?? 0;
                    _contacts[idx]['unread'] = currentUnread + 1;
                  } else {
                    fetchContacts(silent: true);
                  }
                  notifyListeners();
                });
              }
            } catch (e) {
              debugPrint("Pusher Event Parse Warning: $e");
            }
          }
        },
        onSubscriptionError: (message, error) {
          debugPrint("📡 Pusher Subscription Error: $message | $error");
        },
        onError: (message, code, error) {
          debugPrint("📡 Pusher Error [$code]: $message");
        },
      );

      await _pusher!.subscribe(channelName: 'private-chat.$userId');
      await _pusher!.connect();
    } catch (e) {
      debugPrint("📡 Pusher Init Warning (System will use Smart Polling Fallback): $e");
    }
  }

  @override
  void dispose() {
    stopSmartPolling();
    stopContactsPolling();
    _pusher?.disconnect();
    super.dispose();
  }
}