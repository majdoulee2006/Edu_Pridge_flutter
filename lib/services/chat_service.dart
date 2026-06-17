import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'dart:convert';
import '../models/chat_message_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Configuration Constants ---
// You can easily update these constants for your production environment
const String BASE_URL = 'http://192.168.9.116:8000/api';
const String PUSHER_APP_KEY = '7ddc52d35c1e7beb4c83';
const String PUSHER_CLUSTER = 'eu';

class ChatService extends ChangeNotifier {
  final Dio _dio = Dio(BaseOptions(baseUrl: BASE_URL));
  late PusherChannelsFlutter _pusher;
  
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
        '/contacts', // Note: Endpoint missing in Laravel, assuming /contacts
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
    } catch (e) {
      debugPrint("Fetch Messages Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send a message to a specific chat
  Future<void> sendMessage(String contactId, String text) async {
    // Optimistic UI Update for instant feedback
    final tempMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isMe: true,
      timestamp: DateTime.now(),
    );
    _messages.insert(0, tempMsg);
    notifyListeners();

    try {
      final token = await _getToken();

      await _dio.post(
        '/send-message',
        data: {
          'sender_id': _currentUserId, // Required by Laravel ChatController
          'receiver_id': contactId,
          'message': text,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      debugPrint("Send Message Error: $e");
      // Revert optimistic update on failure
      _messages.remove(tempMsg);
      notifyListeners();
    }
  }

  // --- Real-time Pusher Integration ---

  /// Initialize Pusher and subscribe to the user's private channel
  Future<void> initPusher(String userId) async {
    _currentUserId = userId;
    _pusher = PusherChannelsFlutter.getInstance();
    
    try {
      await _pusher.init(
        apiKey: PUSHER_APP_KEY,
        cluster: PUSHER_CLUSTER,
        onEvent: _onEvent,
        authEndpoint: "$BASE_URL/broadcasting/auth", // Laravel standard auth endpoint
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
    // Check for standard Laravel Echo event name or simple new-message
    if (event.eventName == 'App\\Events\\MessageSent' || 
        event.eventName == 'MessageSent' || 
        event.eventName == 'new-message') {
      try {
        final data = jsonDecode(event.data);
        // Extract payload (Laravel broadcasts often nest data inside 'message')
        final payload = data['message'] ?? data;
        
        final newMessage = ChatMessage.fromJson(payload, _currentUserId ?? '');
        
        // Dynamically append the new message
        _messages.insert(0, newMessage); // Insert at 0 because ListView is reversed
        
        // Notify listeners so UI updates instantly
        notifyListeners();
      } catch (e) {
        debugPrint("Error parsing pusher event: $e");
      }
    }
  }
}
