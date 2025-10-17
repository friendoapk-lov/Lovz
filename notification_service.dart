import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // 1. User se permission maango
    await _firebaseMessaging.requestPermission();

    // 2. Device ka unique FCM token lo
    final fcmToken = await _firebaseMessaging.getToken();
    print("====== FCM TOKEN ======");
    print(fcmToken);
    print("=======================");

    // 3. Is token ko Firestore me save karo
    if (fcmToken != null) {
      await _saveTokenToDatabase(fcmToken);
    }

    // Agar token refresh hota hai (bohot kam hota hai), to use bhi save karo
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'fcmToken': token,
            });
        print("FCM Token saved to Firestore.");
      } catch (e) {
        print("Error saving FCM Token: $e");
      }
    }
  }
}