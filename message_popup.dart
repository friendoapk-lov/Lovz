import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:lovz/models/user_profile_data.dart';

Future<bool?> showSendMessagePopup({
  required BuildContext context,
  required UserProfileData receiverUser,
}) async {
  final TextEditingController messageController = TextEditingController();
  final String senderId = FirebaseAuth.instance.currentUser!.uid;
  final String receiverId = receiverUser.uid;

  // State variable ko builder ke bahar declare kiya gaya hai (YAHI ASLI FIX HAI)
  bool isSending = false; 

  final bool? result = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // Loading ke dauraan bahar click na ho
    builder: (context) {
      // StatefulBuilder ka istemaal taaki sirf dialog ka UI update ho
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Message to ${receiverUser.name}'),
            content: TextField(
              controller: messageController,
              decoration: const InputDecoration(
                hintText: "Type your first message...",
              ),
              autofocus: true,
              enabled: !isSending, // Loading ke dauraan disable
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: isSending ? null : () => Navigator.of(context).pop(null),
              ),
              isSending
                  // Agar 'isSending' true hai, toh spinner dikhao
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    )
                  // Warna, 'Send' button dikhao
                  : TextButton(
                      child: const Text('Send'),
                      onPressed: () async {
                        final content = messageController.text.trim();
                        if (content.isEmpty) return;

                        // Ab yeh state builder ke bahar waale variable ko update karega
                        setState(() => isSending = true); 

                        bool isSuccess = false;
                        try {
                          final response = await http.post(
                            Uri.parse('https://lovz-image-uploader.friendo-apk.workers.dev/api/message'),
                            headers: {'Content-Type': 'application/json'},
                            body: json.encode({
                              'senderId': senderId,
                              'receiverId': receiverId,
                              'content': content,
                            }),
                          );
                          isSuccess = (response.statusCode == 200);
                        } catch (e) {
                          isSuccess = false;
                          print("Error sending message: $e");
                        }

                        if (context.mounted) {
                          Navigator.of(context).pop(isSuccess);
                        }
                      },
                    ),
            ],
          );
        },
      );
    },
  );

  return result;
}