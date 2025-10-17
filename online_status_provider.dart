// lib/providers/online_status_provider.dart (MISSION 2 - NAYA, UPGRADED CODE)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

// Ek helper class jo har chat ki state ko saaf-suthre tareeke se store karegi
class ChatState {
  final String chatId;
  String lastMessage;
  String lastMessageSenderId;
  DateTime lastMessageTimestamp;
  int unreadCount;

  ChatState({
    required this.chatId,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageTimestamp,
    required this.unreadCount,
  });
}

class OnlineStatusProvider with ChangeNotifier {
  final Set<String> _onlineUsers = {};
  final Map<String, ChatState> _chatStates = {};
  WebSocketChannel? _channel;
  final String _currentUserId;

  OnlineStatusProvider(this._currentUserId) {
    if (_currentUserId.isNotEmpty) {
      // 2. Ab hum pehle purana hisaab lenge, fir live updates sunenge
      fetchInitialChatStates();
      connect();
    }
  }
  // UI ke liye Getters
  Set<String> get onlineUsers => _onlineUsers;
  bool isUserOnline(String userId) => _onlineUsers.contains(userId);
  
  // Naya Getter: Kisi ek chat ki state haasil karne ke liye
  ChatState? getChatState(String chatId) => _chatStates[chatId];
  
  // Naya Getter: Poori app ke total unread messages ka hisaab
  int get totalUnreadCount {
    int total = 0;
    _chatStates.values.forEach((state) {
      total += state.unreadCount;
    });
    return total;
  }

  // Naya Function: Jab user chat screen khole, to unread count ko 0 kar do
  void markChatAsRead(String chatId) {
    if (_chatStates.containsKey(chatId)) {
      _chatStates[chatId]!.unreadCount = 0;
      // UI ko turant update karo (taaki bottom bar ka count kam ho jaaye)
      notifyListeners();
    }
  }

  // 3. YEH POORA NAYA FUNCTION ADD KIYA GAYA HAI
  Future<void> fetchInitialChatStates() async {
    debugPrint("🚀 Fetching initial unread counts for user: $_currentUserId");
    final url = Uri.parse('https://lovz-image-uploader.friendo-apk.workers.dev/api/chat-summaries?userId=$_currentUserId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> summaries = json.decode(response.body);
        for (var summary in summaries) {
          final String chatId = summary['chatId'].toString();
          // Server se aa rahe null values ko handle karne ke liye checks daale hain
          final newChatState = ChatState(
            chatId: chatId,
            lastMessage: summary['lastMessage'] ?? '',
            lastMessageSenderId: summary['lastMessageSenderId'] ?? '',
            lastMessageTimestamp: summary['lastMessageTimestamp'] != null
                ? DateTime.parse(summary['lastMessageTimestamp'])
                : DateTime.now(), // Fallback
            unreadCount: summary['unreadCount'] ?? 0,
          );
          _chatStates[chatId] = newChatState;
        }
        debugPrint("✅ Fetched and updated ${_chatStates.length} chat summaries.");
        notifyListeners(); // UI ko update karo
      } else {
        debugPrint("Error fetching summaries. Status code: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      debugPrint("Exception caught while fetching initial chat states: $e");
    }
  }

  void connect() {
    final wsUrl = Uri.parse(
      'wss://lovz-image-uploader.friendo-apk.workers.dev/api/presence?userId=$_currentUserId'
    );
    try {
      _channel = WebSocketChannel.connect(wsUrl);

      // Ab hamara listener do tarah ke events ko sunega
      _channel!.stream.listen((message) {
        final data = json.decode(message);
        final type = data['type'];

        switch (type) {
          case 'PRESENCE_UPDATE':
            final userId = data['userId'];
            final status = data['status'];
            if (status == 'online') {
              _onlineUsers.add(userId);
            } else {
              _onlineUsers.remove(userId);
            }
            break;

          // === YEH HAI MISSION 2 KA ASLI JAADU ===
          case 'NEW_MESSAGE_NOTIFICATION':
            final payload = data['payload'];
            final String chatId = payload['chatId'].toString();

            final newChatState = ChatState(
              chatId: chatId,
              lastMessage: payload['lastMessage'],
              lastMessageSenderId: payload['lastMessageSenderId'],
              lastMessageTimestamp: DateTime.parse(payload['lastMessageTimestamp']),
              unreadCount: payload['unreadCount'],
            );
            
            // Apni diary (_chatStates) me is chat ki nayi entry update kar do
            _chatStates[chatId] = newChatState;
            break;
        }

        // State me koi bhi badlaav ho, UI ko hamesha khabar do
        notifyListeners();
      });
    } catch (e) {
      print("Error connecting to Presence Lobby: $e");
    }
  }

  void disconnect() {
    _channel?.sink.close();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}