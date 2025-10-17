// lib/screens/chat_screen.dart - THEME REFACTORED

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lovz/models/message.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:provider/provider.dart';
import 'package:lovz/providers/online_status_provider.dart';
import 'package:lovz/services/profanity_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lovz/screens/blocked_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovz/utils/theme.dart'; // THEME: Custom theme file import kiya gaya

class ChatScreen extends StatefulWidget {
  final int chatId;
  final String otherUserName;
  final String? otherUserImageUrl;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    this.otherUserImageUrl,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ========================================
  // STATE VARIABLES - KOI CHANGE NAHI
  // ========================================
  List<Message> _messages = [];
  bool _isLoading = true;
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _isOtherUserOnline = false;
  bool _isLocallyBlocked = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  WebSocketChannel? _channel;
  bool _isConnected = false;

  // ========================================
  // INIT STATE - KOI CHANGE NAHI
  // ========================================
  @override
  void initState() {
    super.initState();
    _fetchChatHistory();
    _connectWebSocket();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OnlineStatusProvider>(context, listen: false)
          .markChatAsRead(widget.chatId.toString());
    });
  }

  // ========================================
  // WEBSOCKET CONNECTION - KOI LOGIC CHANGE NAHI
  // ========================================
  void _connectWebSocket() {
    final wsUrl = Uri.parse(
        'wss://lovz-image-uploader.friendo-apk.workers.dev/api/websocket/${widget.chatId}?senderId=$_currentUserId');

    try {
      _channel = WebSocketChannel.connect(wsUrl);
      setState(() => _isConnected = true);

      _channel?.sink.add(json.encode({"type": "MESSAGES_READ", "chatId": widget.chatId}));

      _channel!.stream.listen(
        (message) {
          if (!mounted) return;
          final data = json.decode(message);
          final type = data['type'];

          if (type == 'NEW_MESSAGE') {
            final newMessage = Message.fromJson(data['payload']);

            if (newMessage.senderId == _currentUserId) {
              final tempMessageIndex = _messages.lastIndexWhere(
                  (m) => m.id > 1000000000 && m.content == newMessage.content);

              if (tempMessageIndex != -1) {
                setState(() {
                  _messages[tempMessageIndex] = newMessage;
                });
              }
            } else {
              setState(() => _messages.insert(0, newMessage));

              _scrollToBottom();
              _channel?.sink.add(json.encode({"type": "MESSAGES_READ", "chatId": widget.chatId}));
            }
          } else if (type == 'STATUS_UPDATE') {
            final messageId = data['messageId'];
            final newStatus = data['status'];

            for (var i = 0; i < _messages.length; i++) {
              if (_messages[i].id == messageId) {
                setState(() {
                  if (mounted) {
                    _messages[i].status = newStatus;
                  }
                });
              }
            }
          } else if (type == 'PRESENCE_UPDATE') {
            if (data['senderId'] == widget.otherUserId) {
              setState(() => _isOtherUserOnline = (data['status'] == 'online'));
            }
          }
        },
        onDone: () {
          if (mounted) setState(() => _isConnected = false);
          print('WebSocket disconnected');
        },
        onError: (error) {
          if (mounted) setState(() => _isConnected = false);
          print('WebSocket error: $error');
        },
      );
    } catch (e) {
      print("Error connecting to WebSocket: $e");
    }
  }

  // ========================================
  // DISPOSE - KOI CHANGE NAHI
  // ========================================
  @override
  void dispose() {
    _channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ========================================
  // FETCH CHAT HISTORY - KOI LOGIC CHANGE NAHI
  // ========================================
  Future<void> _fetchChatHistory() async {
    final url = Uri.parse(
        'https://lovz-image-uploader.friendo-apk.workers.dev/api/history?chatId=${widget.chatId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _messages = data.map((json) => Message.fromJson(json)).toList().reversed.toList();
            _isLoading = false;
          });
          _scrollToBottom();
        }
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ========================================
  // SCROLL TO BOTTOM - KOI LOGIC CHANGE NAHI
  // ========================================
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ========================================
  // SEND MESSAGE - KOI LOGIC CHANGE NAHI
  // ========================================
  void _sendMessage() {
    if (_isLocallyBlocked) return;

    final content = _messageController.text.trim();

    debugPrint("-----------------------------------------");
    debugPrint("🚀 [ChatScreen] Send button pressed.");
    debugPrint("   Message content: '$content'");

    final bool isAbusive = ProfanityService.instance.isProfane(content);

    debugPrint("   Decision from ProfanityService: isAbusive = $isAbusive");
    debugPrint("-----------------------------------------");

    if (isAbusive) {
      _handleProfanityViolation();
      return;
    }

    if (content.isEmpty || !_isConnected) return;

    final payload = {
      "chatId": widget.chatId,
      "receiverId": widget.otherUserId,
      "content": content,
    };

    final tempId = DateTime.now().millisecondsSinceEpoch;
    final tempMessage = Message(
      id: tempId,
      chatId: widget.chatId,
      senderId: _currentUserId,
      content: content,
      createdAt: DateTime.now().toIso8601String(),
      status: 'sent',
    );
    if (mounted) {
      setState(() {
        _messages.insert(0, tempMessage);
        _messageController.clear();
      });
      _scrollToBottom();
    }

    _channel?.sink.add(json.encode({"type": "NEW_MESSAGE", "payload": payload}));
  }

  // ========================================
  // HANDLE PROFANITY - KOI LOGIC CHANGE NAHI
  // ========================================
  Future<void> _handleProfanityViolation() async {
    _messageController.clear();
    final userRef = FirebaseFirestore.instance.collection('users').doc(_currentUserId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);

        if (!snapshot.exists) {
          throw Exception("User does not exist!");
        }

        int previousCount = snapshot.data()?['profanityWarningCount'] ?? 0;
        int newCount = previousCount + 1;

        if (newCount >= 3) {
          transaction.update(userRef, {
            'profanityWarningCount': newCount,
            'isBlocked': true,
          });
        } else {
          transaction.update(userRef, {
            'profanityWarningCount': newCount,
          });
        }
      });

      final updatedSnapshot = await userRef.get();
      final finalCount = updatedSnapshot.data()?['profanityWarningCount'] ?? 1;

      if (!mounted) return;

      String message;
      if (finalCount >= 3) {
        setState(() {
          _isLocallyBlocked = true;
        });
        message = "You have been blocked for violating community guidelines.";
      } else {
        message = "Inappropriate language. This is your warning ($finalCount/3).";
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ));

      if (finalCount >= 3) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const BlockedScreen()),
              (Route<dynamic> route) => false,
            );
          }
        });
      }
    } catch (e) {
      debugPrint("Error handling profanity violation: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Message bhejte samay ek samasya aayi."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ========================================
  // BLOCK/REPORT DIALOGS - KOI LOGIC CHANGE NAHI
  // ========================================
  void _showBlockDialog() {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // UPDATED: Dialog colors ab theme se
          backgroundColor: customColors.surface_2,
          title: Text(
            'Block User',
            style: theme.textTheme.titleLarge,
          ),
          content: Text(
            'Are you sure you want to block ${widget.otherUserName}? You will no longer see their profile or receive messages from them.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: theme.textTheme.labelLarge),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Block',
                style: theme.textTheme.labelLarge?.copyWith(color: customColors.love),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _blockUser();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _blockUser() async {
    try {
      final currentUserRef = FirebaseFirestore.instance.collection('users').doc(_currentUserId);

      await currentUserRef.update({
        'blockedUsers': FieldValue.arrayUnion([widget.otherUserId])
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.otherUserName} has been blocked.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint("Error blocking user: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to block user. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReportDialog() {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;

    String? selectedReason;
    final reportReasons = [
      "Inappropriate Photos",
      "Harassment or Bullying",
      "Spam / Fake Profile",
      "Scamming or Fraud"
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              // UPDATED: Dialog colors ab theme se
              backgroundColor: customColors.surface_2,
              title: Text(
                'Report ${widget.otherUserName}',
                style: theme.textTheme.titleLarge,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: reportReasons.map((reason) {
                    return RadioListTile<String>(
                      title: Text(reason, style: theme.textTheme.bodyMedium),
                      value: reason,
                      groupValue: selectedReason,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel', style: theme.textTheme.labelLarge),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  onPressed: selectedReason == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          _reportUser(selectedReason!);
                        },
                  child: Text('Submit Report', style: theme.textTheme.labelLarge),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _reportUser(String reason) async {
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'reporterId': _currentUserId,
        'reportedUserId': widget.otherUserId,
        'reason': reason,
        'chatId': widget.chatId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully. Thank you for your help.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error submitting report: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit report. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ========================================
  // BUILD METHOD - UI REFACTORED FOR THEME
  // ========================================
  @override
  Widget build(BuildContext context) {
    // THEME: Theme data aur custom colors ko access karna
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;

    return Scaffold(
      // UPDATED: Background color ab theme se aa raha hai
      backgroundColor: theme.scaffoldBackgroundColor,

      // UPDATED: AppBar ab theme-based hai
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 22.sp),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20.r,
              backgroundColor: customColors.surface_2,
              backgroundImage: widget.otherUserImageUrl != null
                  ? CachedNetworkImageProvider(
                      'https://pub-20b75325021441f58867571ca62aa1aa.r2.dev/${widget.otherUserImageUrl}_thumb.webp')
                  : null,
              child: widget.otherUserImageUrl == null
                  ? Icon(
                      Icons.person,
                      size: 20.r,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    )
                  : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName.toUpperCase(),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontSize: 18.sp,
                      letterSpacing: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_isOtherUserOnline)
                    Text(
                      'Online',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: customColors.onlineGreen,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'block') _showBlockDialog();
              else if (value == 'report') _showReportDialog();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'block',
                child: Text(
                  'Block ${widget.otherUserName}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              PopupMenuItem<String>(
                value: 'report',
                child: Text(
                  'Report ${widget.otherUserName}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
            icon: Icon(Icons.more_vert, size: 24.sp),
          ),
        ],
      ),
      body: Column(
        children: [
          // UPDATED: Divider color ab theme se aa raha hai
          Container(height: 1.h, color: theme.dividerColor),

          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final bool isMe = message.senderId == _currentUserId;
                      return _buildMessageBubble(
                        theme,
                        customColors,
                        message.content,
                        isMe,
                        message.status,
                        message.createdAt,
                      );
                    },
                  ),
          ),

          _buildMessageInputField(theme, customColors),
        ],
      ),
    );
  }

  // ========================================
  // MESSAGE BUBBLE - UI REFACTORED
  // ========================================
  Widget _buildMessageBubble(
    ThemeData theme,
    CustomColors customColors,
    String text,
    bool isMe,
    String status,
    String timestamp,
  ) {
    String utcTimestamp = timestamp.endsWith('Z') ? timestamp : '${timestamp}Z';
    final DateTime messageTime = DateTime.parse(utcTimestamp).toLocal();
    final String formattedTime = DateFormat('HH:mm').format(messageTime);

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          margin: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            // UPDATED: Bubble colors ab theme se aa rahe hain
            color: isMe ? customColors.love : customColors.surface_2,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                text,
                // UPDATED: Text color ab theme se aa raha hai
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 5.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formattedTime,
                    // UPDATED: Timestamp color ab theme se aa raha hai
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12.sp,
                    ),
                  ),
                  if (isMe) ...[
                    SizedBox(width: 5.w),
                    Icon(
                      Icons.done_all,
                      // UPDATED: Tick colors ab theme se aa rahe hain
                      color: status == 'read'
                          ? const Color(0xFF1170FF) // Blue for read
                          : theme.colorScheme.onSurface.withOpacity(0.7),
                      size: 16.sp,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========================================
  // MESSAGE INPUT FIELD - UI REFACTORED
  // ========================================
  Widget _buildMessageInputField(ThemeData theme, CustomColors customColors) {
    return Container(
      // UPDATED: Background color ab theme se aa raha hai
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                // UPDATED: Text style ab theme se aa raha hai
                style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16.sp),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  // UPDATED: Field colors ab theme se aa rahe hain
                  fillColor: customColors.surface_2,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Material(
              // UPDATED: Send button color ab theme se aa raha hai
              color: customColors.love,
              borderRadius: BorderRadius.circular(50.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(50.r),
                onTap: _sendMessage,
                child: Padding(
                  padding: EdgeInsets.all(12.r),
                  child: Icon(
                    Icons.send,
                    color: theme.colorScheme.onPrimary,
                    size: 24.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}