// lib/screens/chat_list_screen.dart - THEME REFACTORED

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lovz/models/chat_thread.dart';
import 'package:lovz/widgets/chat_list_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

// ================== HELPER FUNCTION - KOI CHANGE NAHI ==================
String formatChatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  final dateToFormat = DateTime(timestamp.year, timestamp.month, timestamp.day);

  if (dateToFormat == today) {
    // Agar message aaj ka hai, to sirf time dikhayein (jaise 10:45 AM)
    return DateFormat('h:mm a').format(timestamp);
  } else if (dateToFormat == yesterday) {
    // Agar message kal ka hai, to "Yesterday" dikhayein
    return 'Yesterday';
  } else {
    // Agar message purana hai, to date dikhayein (jaise 09/10/2025)
    return DateFormat('dd/MM/yyyy').format(timestamp);
  }
}
// ================== HELPER FUNCTION KHATAM ==================

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  // ========================================
  // STATE VARIABLES - KOI CHANGE NAHI
  // ========================================
  List<ChatThread> _chatThreads = [];
  bool _isLoading = true;

  // ========================================
  // INIT STATE - KOI CHANGE NAHI
  // ========================================
  @override
  void initState() {
    super.initState();
    _fetchChatThreads();
  }

  // ========================================
  // FETCH CHAT THREADS FUNCTION - KOI LOGIC CHANGE NAHI
  // ========================================
  Future<void> _fetchChatThreads() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // Step 1: Current user ki blocked list laao Firestore se
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final List<String> blockedUsers = userDoc.exists && userDoc.data()!.containsKey('blockedUsers')
          ? List<String>.from(userDoc.data()!['blockedUsers'])
          : [];

      // Step 2: Hamesha ki tarah, saare chats laao API se
      final url = Uri.parse('https://lovz-image-uploader.friendo-apk.workers.dev/api/chats?userId=$userId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<ChatThread> allThreads = data.map((json) => ChatThread.fromJson(json)).toList();

        // Step 3: Sabse ZAROORI - List ko filter karo
        // Hum sirf woh threads rakhenge jinka otherUserId hamari blockedUsers list me NAHI hai.
        final List<ChatThread> filteredThreads = allThreads.where((thread) {
          // Yahan hum sahi logic laga rahe hain
          final otherUserId = thread.user1Id == userId ? thread.user2Id : thread.user1Id;
          return !blockedUsers.contains(otherUserId);
        }).toList();

        if (mounted) {
          setState(() {
            _chatThreads = filteredThreads; // Ab yahan filtered list show hogi
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load chats');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching chats: ${e.toString()}')),
        );
      }
    }
  }

  // ========================================
  // BUILD METHOD - UI REFACTORED FOR THEME
  // ========================================
  @override
  Widget build(BuildContext context) {
    // THEME: Theme data ko ek baar build method me access karna
    final theme = Theme.of(context);

    return Scaffold(
      // UPDATED: Background color ab theme se aa raha hai
      backgroundColor: theme.scaffoldBackgroundColor,
      
      // UPDATED: AppBar ab standard theme-based hai
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('MESSAGES'),
        centerTitle: true,
        // NOTE: backgroundColor, titleTextStyle ab theme se automatically aa rahe hain
      ),

      body: Column(
        children: [
          // UPDATED: Divider color ab theme se aa raha hai
          Container(height: 1.h, color: theme.dividerColor),
          
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      // UPDATED: Loader color ab theme se aa raha hai
                      color: theme.colorScheme.primary,
                    ),
                  )
                : _chatThreads.isEmpty
                    ? Center(
                        child: Text(
                          'You have no messages yet.',
                          // UPDATED: Text style ab theme se aa raha hai
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 16.sp,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.zero, // Default padding hatayi gayi
                        itemCount: _chatThreads.length,
                        itemBuilder: (context, index) {
                          final thread = _chatThreads[index];
                          return ChatListItem(
                            thread: thread,
                            onReturn: _fetchChatThreads,
                          );
                        },
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          thickness: 1,
                          // UPDATED: Divider color ab theme se aa raha hai
                          color: theme.dividerColor,
                          indent: 85.w,  // Responsive indent (profile pic ke baad se)
                          endIndent: 16.w, // Responsive end indent
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}