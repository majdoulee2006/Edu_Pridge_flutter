import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'dart:convert';
import '../models/chat_message_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

// --- Configuration Constants ---
// You can easily update these constants for your production environment
const String PUSHER_APP_KEY = '7ddc52d35c1e7beb4c83';
const String PUSHER_CLUSTER = 'eu';

class ChatService extends ChangeNotifier {
  late final Dio _dio;
  late PusherChannelsFlutter _pusher;

  ChatService() {
    _dio = Dio(BaseOptions(baseUrl: ApiService().baseUrl));
  }
  
  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> get contacts => _contacts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingContacts = false;
  bool get isLoadingContacts => _isLoadingContacts;
  
  String? _currentUserId;

  // --- Auth Helper ---
  
  /// Retrieve the user's authentication token from shared_preferences
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  // --- Real API HTTP Requests ---

  /// Retrieve the allowed roles/contacts based on the logged-in user
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

  /// Load the conversation history for a specific chat
  Future<void> fetchMessages(String contactId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final token = await _getToken();
      
      final response = await _dio.get(
        '/messages/$contactId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        _messages = data.map((e) => ChatMessage.fromJson(e, _currentUserId ?? '')).toList();
      }

      // Mark messages from this contact as read
      try {
        await _dio.put(
          '/messages/$contactId/mark-read',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        // Refresh contacts to clear the unread badge
        fetchContacts();
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

  /// Send a message to a specific chat
  Future<void> sendMessage(
    String contactId,
    String text, {
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    // Optimistic UI Update for instant feedback
    final tempMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: text,
      isMe: true,
      timestamp: DateTime.now(),
      attachment: filePath ?? fileName,
    );
    _messages.insert(0, tempMsg);
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

      await _dio.post(
        '/send-message',
        data: postData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // Refresh contacts to update the last message and timestamp in the contact list
      fetchContacts();
    } catch (e) {
      debugPrint("Send Message Error: $e");
      // Revert optimistic update on failure
      _messages.remove(tempMsg);
      notifyListeners();
    }
  }

  /// Edit a specific message
  Future<void> editMessage(String messageId, String newText) async {
    try {
      final token = await _getToken();
      await _dio.put(
        '/messages/$messageId/edit',
        data: {'message': newText},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      // Update locally
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index].message = newText;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Edit Message Error: $e");
      throw Exception("فشل تعديل الرسالة");
    }
  }

  /// Delete a specific message
  Future<void> deleteMessage(String messageId) async {
    try {
      final token = await _getToken();
      await _dio.delete(
        '/messages/$messageId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      // Update locally
      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();
    } catch (e) {
      debugPrint("Delete Message Error: $e");
      throw Exception("فشل حذف الرسالة");
    }
  }

  /// Search messages within a specific chat
  Future<void> searchMessages(String contactId, String query) async {
    if (query.trim().isEmpty) {
      return fetchMessages(contactId);
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final token = await _getToken();
      final response = await _dio.get(
        '/messages/$contactId/search',
        queryParameters: {'q': query},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        _messages = data.map((e) => ChatMessage.fromJson(e, _currentUserId ?? '')).toList();
      }
    } catch (e) {
      debugPrint("Search Messages Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Real-time Pusher Integration ---

  /// Initialize Pusher and subscribe to the user's private channel
  Future<void> initPusher(String userId) async {
    if (_currentUserId == userId) return; // Prevent multiple connections for the same user
    _currentUserId = userId;
    _pusher = PusherChannelsFlutter.getInstance();
    
    try {
      await _pusher.init(
        apiKey: PUSHER_APP_KEY,
        cluster: PUSHER_CLUSTER,
        onEvent: _onEvent,
        authEndpoint: ApiService().baseUrl.replaceAll('/api', '/broadcasting/auth'), // Fix: remove /api
        onAuthorizer: _onAuthorizer,
      );
      
      // Subscribing to a private channel because Laravel uses new PrivateChannel('chat.{id}')
      await _pusher.subscribe(channelName: "private-chat.$userId");
      await _pusher.connect();
    } catch (e) {
      debugPrint("Pusher Init Error: $e");
    }
  }

  /// Custom Authorizer to authenticate private channels using Dio
  dynamic _onAuthorizer(String channelName, String socketId, dynamic options) async {
    try {
      final token = await _getToken();
      final response = await _dio.post(
        '/broadcasting/auth',
        data: {
          'socket_id': socketId,
          'channel_name': channelName,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (e) {
      debugPrint("Pusher Auth Error: $e");
      return null;
    }
  }

  /// Handle incoming Pusher events
  void _onEvent(dynamic event) {
    if (event.eventName == 'App\\Events\\MessagesMarkedAsRead' || 
        event.eventName == 'MessagesMarkedAsRead') {
      bool updated = false;
      for (var msg in _messages) {
        if (!msg.isRead) {
          msg.isRead = true;
          updated = true;
        }
      }
      if (updated) notifyListeners();
      return;
    }

    if (event.eventName == 'App\\Events\\MessageSent' || 
        event.eventName == 'MessageSent' || 
        event.eventName == 'new-message') {
      try {
        final data = jsonDecode(event.data);
        Map<String, dynamic> payload;
        if (data is Map) {
          final nested = data['message'];
          if (nested is Map) {
            payload = Map<String, dynamic>.from(nested);
          } else {
            payload = Map<String, dynamic>.from(data);
          }
        } else {
          return;
        }
        
        final newMessage = ChatMessage.fromJson(payload, _currentUserId ?? '');
        
        // Dynamically append the new message
        _messages.insert(0, newMessage); // Insert at 0 because ListView is reversed
        
        // Refresh contacts to update the unread count/last message in the UI list
        fetchContacts();
        
        // Notify listeners so UI updates instantly
        notifyListeners();
      } catch (e) {
        debugPrint("Error parsing pusher event: $e");
      }
    }
  }
}