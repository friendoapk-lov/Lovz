// lib/widgets/chat_list_item.dart - THEME REFACTORED

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lovz/models/chat_thread.dart';
import 'package:lovz/screens/chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:lovz/providers/online_status_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovz/screens/chat_list_screen.dart' show formatChatTimestamp;
import 'package:lovz/utils/theme.dart'; // THEME: Custom theme file import kiya gaya

class ChatListItem extends StatefulWidget {
  final ChatThread thread;
  final VoidCallback onReturn;

  const ChatListItem({
    super.key, 
    required this.thread,
    required this.onReturn,
  });

  @override
  State<ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<ChatListItem> {
  // ========================================
  // STATE VARIABLES - KOI CHANGE NAHI
  // ========================================
  Map<String, dynamic>? _otherUserData;
  bool _isLoading = true;

  // ========================================
  // INIT STATE - KOI CHANGE NAHI
  // ========================================
  @override
  void initState() {
    super.initState();
    _fetchOtherUserData();
  }

  // ========================================
  // FETCH OTHER USER DATA - KOI LOGIC CHANGE NAHI
  // ========================================
  Future<void> _fetchOtherUserData() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      // Saamne waale user ki ID nikalo
      final otherUserId = widget.thread.user1Id == currentUserId
          ? widget.thread.user2Id
          : widget.thread.user1Id;

      // Firestore se uss user ka data fetch karo
      final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();

      if (mounted) {
        setState(() {
          _otherUserData = docSnapshot.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error fetching other user's data: $e");
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

    if (_isLoading || _otherUserData == null) {
      return ListTile(
        leading: CircleAvatar(
          radius: 28.r,
          // UPDATED: Loading state color ab theme se aa raha hai
          backgroundColor: customColors.surface_2,
        ),
        title: Text(
          'Loading...',
          // UPDATED: Text style ab theme se aa raha hai
          style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16.sp),
        ),
      );
    }

    final String name = _otherUserData!['name'] ?? 'Unknown User';
    final List<String> imageUrls = List<String>.from(_otherUserData!['profileImageUrls'] ?? []);
    final String? firstImage = imageUrls.isNotEmpty ? imageUrls[0] : null;
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final otherUserId = widget.thread.user1Id == currentUserId
        ? widget.thread.user2Id
        : widget.thread.user1Id;

    // ========================================
    // CONSUMER & ONLINE STATUS LOGIC - KOI CHANGE NAHI
    // ========================================
    return Consumer<OnlineStatusProvider>(
      builder: (context, provider, child) {
        
        // Timestamp formatting - KOI LOGIC CHANGE NAHI
        String formattedTimestamp = '';
        if (widget.thread.lastMessageTimestamp.isNotEmpty) {
          try {
            final timestamp = DateTime.parse(widget.thread.lastMessageTimestamp).toLocal();
            formattedTimestamp = formatChatTimestamp(timestamp);
          } catch (e) {
            formattedTimestamp = ''; 
          }
        }

        // Online status check logic - KOI CHANGE NAHI
        bool isOnline = provider.isUserOnline(otherUserId);

        if (!isOnline && _otherUserData != null) {
          try {
            if (_otherUserData!['isOnline'] == true) isOnline = true;
          } catch (e) { /* ignore absent field */ }
        }

        if (!isOnline && _otherUserData != null && _otherUserData!['lastActive'] != null) {
          try {
            final ts = _otherUserData!['lastActive'];
            if (ts is Timestamp) {
              final last = ts.toDate();
              if (DateTime.now().difference(last).inSeconds <= 30) {
                isOnline = true;
              }
            }
          } catch (e) { /* ignore parse issues */ }
        }
        
        // Live chat state logic - KOI CHANGE NAHI
        final liveChatState = provider.getChatState(widget.thread.chatId.toString());
        final String lastMessageToShow = liveChatState?.lastMessage ?? widget.thread.lastMessage;
        final int unreadCount = liveChatState?.unreadCount ?? 0;

        // ========================================
        // UI BUILD - REFACTORED FOR THEME
        // ========================================
        return InkWell(
          onTap: () async {
            // Navigation logic - KOI CHANGE NAHI
            final onlineStatusProvider = Provider.of<OnlineStatusProvider>(context, listen: false);
            await Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: false,
                builder: (newContext) {
                  return ChangeNotifierProvider.value(
                    value: onlineStatusProvider,
                    child: ChatScreen(
                      chatId: widget.thread.chatId,
                      otherUserName: name,
                      otherUserImageUrl: firstImage,
                      otherUserId: otherUserId,
                    ),
                  );
                },
              ),
            );
            widget.onReturn();
          },
          child: Container(
            // UPDATED: Background color ab theme se aa raha hai
            color: theme.scaffoldBackgroundColor,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                // ========================================
                // PROFILE PICTURE WITH ONLINE INDICATOR
                // ========================================
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 30.r,
                      // UPDATED: Placeholder color ab theme se aa raha hai
                      backgroundColor: customColors.surface_2,
                      backgroundImage: firstImage != null
                          ? CachedNetworkImageProvider('https://pub-20b75325021441f58867571ca62aa1aa.r2.dev/${firstImage}_thumb.webp')
                          : null,
                      child: firstImage == null 
                          ? Icon(
                              Icons.person, 
                              size: 30.r, 
                              // UPDATED: Icon color ab theme se aa raha hai
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                            ) 
                          : null,
                    ),
                    // Online indicator - logic same, color updated
                    if (isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          height: 14.r,
                          width: 14.r,
                          decoration: BoxDecoration(
                            // UPDATED: Online color ab CustomColors se aa raha hai
                            color: customColors.onlineGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.scaffoldBackgroundColor, 
                              width: 2.w,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 12.w),

                // ========================================
                // NAME AND LAST MESSAGE
                // ========================================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // UPDATED: Name text ab theme se style ho raha hai
                      Text(
                        name.toUpperCase(),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontSize: 18.sp,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      // UPDATED: Last message text ab theme se style ho raha hai
                      Text(
                        lastMessageToShow,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: unreadCount > 0 
                              ? theme.colorScheme.onSurface 
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 14.sp,
                          fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),

                // ========================================
                // TIMESTAMP AND UNREAD COUNT
                // ========================================
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // UPDATED: Timestamp text ab theme se style ho raha hai
                    Text(
                      formattedTimestamp,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),

                    // Unread count badge - logic same, colors updated
                    if (unreadCount > 0)
                      Container(
                        padding: EdgeInsets.all(7.r),
                        decoration: BoxDecoration(
                          // UPDATED: Badge color ab CustomColors se aa raha hai
                          color: customColors.love,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      // Spacing balance ke liye
                      SizedBox(width: 28.r),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}