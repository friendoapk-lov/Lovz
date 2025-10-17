import 'package:cloud_firestore/cloud_firestore.dart';

// Yeh class Boost se jude saare database operations ko handle karegi.
class BoostService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _usersCollection = _firestore.collection('users');

  // === STEP 5 ka Logic: Diamonds se Boosts Khareedna ===
  // Yeh function diamonds kaatkar user ko boosts deta hai.
  // Return karega 'true' agar safal, 'false' agar koi error aayi.
  static Future<bool> purchaseBoosts({
    required String userId,
    required int diamondCost,
    required int boostAmount,
  }) async {
    try {
      final userDocRef = _usersCollection.doc(userId);

      // Hum Firestore Transaction ka istemaal karenge.
      // Yeh is baat ki guarantee deta hai ki ya toh dono kaam (diamonds kaatna aur boosts dena) honge,
      // ya fir dono mein se koi bhi nahi hoga. Isse data hamesha a consistent rehta hai.
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDocRef);

        if (!snapshot.exists) {
          throw Exception("User does not exist!");
        }

                final data = snapshot.data() as Map<String, dynamic>?;
        final currentDiamonds = data?['diamonds'] ?? 0;

        // Check karo ki user ke paas paryapt diamonds hain ya nahi.
        if (currentDiamonds < diamondCost) {
          throw Exception("Insufficient diamonds."); // Yeh aage catch block mein handle hoga.
        }

        // Update logic:
        // 1. Diamonds ko kam karo.
        // 2. Boosts ko badhao.
        transaction.update(userDocRef, {
          'diamonds': FieldValue.increment(-diamondCost),
          'boostCount': FieldValue.increment(boostAmount),
        });
      });

      print('$boostAmount boosts purchased successfully for $diamondCost diamonds.');
      return true; // Safal

    } catch (e) {
      // Yahan koi bhi error (jaise diamonds kam hona ya internet na hona) catch ho jaayegi.
      print('Error purchasing boosts: $e');
      return false; // Asafal
    }
  }

  // === STEP 6 ka Logic: Boost ko Activate Karna ===
  // Yeh function user ka ek boost istemaal karke uski profile ko "boosted" mark karta hai.
  // Return karega 'true' agar safal, 'false' agar koi error aayi.
  static Future<bool> activateBoost({
    required String userId,
    required GeoPoint location,
  }) async {
    try {
      final userDocRef = _usersCollection.doc(userId);
      final expiryTime = DateTime.now().add(const Duration(minutes: 30));

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDocRef);

        if (!snapshot.exists) {
          throw Exception("User does not exist!");
        }

                final data = snapshot.data() as Map<String, dynamic>?;
        final currentBoosts = data?['boostCount'] ?? 0;

        // Check karo ki user ke paas kam se kam 1 boost hai ya nahi.
        if (currentBoosts < 1) {
          throw Exception("No boosts available to activate.");
        }

        // Update logic:
        // 1. Boost count ko 1 se kam karo.
        // 2. Profile ko boosted mark karo aur expiry time set karo.
        transaction.update(userDocRef, {
          'boostCount': FieldValue.increment(-1),
          'isBoosted': true,
          'boostExpiresAt': Timestamp.fromDate(expiryTime), // Expiry time
          'boostLocation': location, // Chuni hui location
        });
      });
      
      print('Boost activated successfully for location: ${location.latitude}, ${location.longitude}');
      return true; // Safal

    } catch (e) {
      print('Error activating boost: $e');
      return false; // Asafal
    }
  }
}