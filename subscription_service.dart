import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Yeh function kisi bhi subscription pack ke purchase logic ko handle karega.
  // Success par 'true' aur failure par 'false' return karega.
  static Future<bool> purchaseSubscription({
    required String userId,
    required String packId, // jaise 'unlimited_messages' ya 'unlimited_undos'
    required int cost,
  }) async {
    try {
      final userDocRef = _firestore.collection('users').doc(userId);

      // Diamonds check karne ke liye latest user data fetch karo
      final userDoc = await userDocRef.get();
      if (!userDoc.exists) {
        print('Error: User does not exist.');
        return false;
      }

      int currentDiamonds = userDoc.data()?['diamonds'] ?? 0;

      // Check karo ki user ke paas पर्याप्त diamonds hain ya nahi
      if (currentDiamonds < cost) {
        print('Error: Not enough diamonds to purchase.');
        return false; // Kam paise hone par failure indicate karo
      }

      // Expiry date calculate karo (aaj se 30 din baad)
      final expiryDate = DateTime.now().add(const Duration(days: 30));

      // Update kiya jaane wala data taiyaar karo
      // Hum map ke andar ek specific field ko update karne ke liye dot notation ka istemaal kar rahe hain
      final String expiryFieldKey = 'activeSubscriptions.${packId}_expiry';

      await userDocRef.update({
        'diamonds': FieldValue.increment(-cost), // Keemat kaato
        expiryFieldKey: expiryDate.toIso8601String(), // Expiry date set karo
      });

      print('Subscription purchased successfully for pack: $packId');
      return true; // Success indicate karo
    } catch (e) {
      print('An error occurred during subscription purchase: $e');
      return false; // Failure indicate karo
    }
  }

  // === NAYA FUNCTION: PREMIUM SUBSCRIPTION KE LIYE ===
  static Future<bool> purchasePremiumSubscription({
    required String userId,
    required int cost,
    required int durationInDays, // Hum din yahan se lenge (e.g., 30, 90, 365)
  }) async {
    try {
      final userDocRef = _firestore.collection('users').doc(userId);

      // Diamonds check karne ke liye latest user data fetch karo
      final userDoc = await userDocRef.get();
      if (!userDoc.exists) {
        print('Error: User does not exist.');
        return false;
      }

      int currentDiamonds = userDoc.data()?['diamonds'] ?? 0;

      // Check karo ki user ke paas पर्याप्त diamonds hain ya nahi
      if (currentDiamonds < cost) {
        print('Error: Not enough diamonds to purchase premium.');
        return false;
      }

      // Expiry date calculate karo (durationInDays ke hisaab se)
      final expiryDate = DateTime.now().add(Duration(days: durationInDays));

      // Update kiya jaane wala data taiyaar karo
      // Hum seedha ek 'premiumExpiry' field ko update karenge
      await userDocRef.update({
        'diamonds': FieldValue.increment(-cost), // Keemat kaato
        'premiumExpiry': expiryDate.toIso8601String(), // Premium expiry date set karo
      });

      print('Premium subscription purchased successfully for $durationInDays days.');
      return true; // Success indicate karo
    } catch (e) {
      print('An error occurred during premium subscription purchase: $e');
      return false;
    }
  }

}