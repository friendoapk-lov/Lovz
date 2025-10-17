class ChatThread {
  final int chatId;
  final String user1Id;
  final String user2Id;
  final String lastMessage;
  final String lastMessageTimestamp;

  ChatThread({
    required this.chatId,
    required this.user1Id,
    required this.user2Id,
    required this.lastMessage,
    required this.lastMessageTimestamp,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      chatId: json['chat_id'],
      user1Id: json['user1_id'],
      user2Id: json['user2_id'],
      lastMessage: json['last_message'] ?? 'No messages yet',
      lastMessageTimestamp: json['last_message_timestamp'] ?? '',
    );
  }
}