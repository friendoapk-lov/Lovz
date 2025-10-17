class Message {
  int id;
  final int chatId;
  final String senderId;
  final String content;
  final String createdAt;
  String status;

 Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.status, // <-- YEH NAYI LINE ADD HUI HAI
  });

  // Yeh factory constructor JSON data ko Message object me badalta hai
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? -1, // Agar ID null aaye to -1 maan lo
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      content: json['content'],
      createdAt: json['created_at'],
      // status ko bhi JSON se parse karo, agar na mile to 'sent' maan lo
      status: json['status'] ?? 'sent', // <-- YEH NAYI LINE ADD HUI HAI
    );
  }
}