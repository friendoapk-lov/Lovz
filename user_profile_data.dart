import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileData {
  final String uid;
  final String name;
  final int age;
  final List<String> profileImageUrls;
  final String aboutMe;
  final List<String> interests;
  final String jobTitle;
  final GeoPoint? location;
  final String locationName;
  final List<String> basicGender;
  final List<String> basicOrientation;
  final List<String> basicIdentity;
  final String drinkingHabit;
  final String smokingHabit;
  final List<String> blockedUsers;
  final int diamonds;
  final Map<String, dynamic> activeSubscriptions;
  final String? premiumExpiry;

  // === NAYE CRUSH FIELDS ===
  final List<String> crushesSent; // Jisko maine crush bheja
  // === NAYE LIKE FIELDS ===
  final List<String> likesSent; // Jisko maine like kiya
  // =========================
  final int crushesSentToday; // Aaj kitne crush bheje
  final String lastCrushDate; // Last crush bhejne ki date (YYYY-MM-DD)
  // =========================

  UserProfileData({
    required this.uid,
    required this.name,
    required this.age,
    required this.profileImageUrls,
    required this.aboutMe,
    required this.interests,
    required this.jobTitle,
    required this.location,
    required this.locationName,
    required this.basicGender,
    required this.basicOrientation,
    required this.basicIdentity,
    required this.drinkingHabit,
    required this.smokingHabit,
    required this.blockedUsers,
    required this.diamonds,
    required this.activeSubscriptions,
    this.premiumExpiry,
    // === NAYE CRUSH FIELDS KO CONSTRUCTOR MEIN ADD KIYA ===
    this.crushesSent = const [],
    this.crushesSentToday = 0,
    this.lastCrushDate = '',
    // ====================================================
    // === NAYE LIKE FIELDS KO CONSTRUCTOR MEIN ADD KIYA ===
    this.likesSent = const [],
    // ====================================================
  });

  factory UserProfileData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final myWork = data['myWork'] as Map<String, dynamic>?;
    final habits = data['habits'] as Map<String, dynamic>?;

    return UserProfileData(
      uid: data['uid'] ?? '',
      name: data['name'] ?? 'No Name',
      age: data['age'] ?? 18,
      profileImageUrls: List<String>.from(data['profileImageUrls'] ?? []),
      aboutMe: data['aboutMe'] ?? '',
      interests: List<String>.from(data['interests'] ?? []),
      jobTitle: myWork?['jobTitle'] ?? '',
      location: data['location'] as GeoPoint?,
      locationName: data['locationName'] ?? '',
      basicGender: List<String>.from(data['myBasics']?['gender'] ?? []),
      basicOrientation: List<String>.from(data['myBasics']?['orientation'] ?? []),
      basicIdentity: List<String>.from(data['myBasics']?['identity'] ?? []),
      drinkingHabit: habits?['drinking'] ?? '',
      smokingHabit: habits?['smoking'] ?? '',
      blockedUsers: List<String>.from(data['blockedUsers'] ?? []),
      diamonds: data['diamonds'] ?? 0,
      activeSubscriptions: Map<String, dynamic>.from(data['activeSubscriptions'] ?? {}),
      premiumExpiry: data['premiumExpiry'] as String?,
      // === NAYE CRUSH FIELDS KO FIRESTORE SE PARSE KIYA ===
      crushesSent: List<String>.from(data['crushes_sent'] ?? []),
      crushesSentToday: data['crushes_sent_today'] ?? 0,
      lastCrushDate: data['last_crush_date'] ?? '',
      // ===================================================
      // === NAYE LIKE FIELDS KO FIRESTORE SE PARSE KIYA ===
      likesSent: List<String>.from(data['likes_sent'] ?? []),
      // ==================================================
    );
  }

  // === SUBSCRIPTION CHECKER FUNCTION ===
  bool isSubscriptionActive(String packId) {
    final expiryKey = '${packId}_expiry';
    if (!activeSubscriptions.containsKey(expiryKey)) {
      return false;
    }
    try {
      final expiryDateString = activeSubscriptions[expiryKey] as String;
      final expiryDate = DateTime.parse(expiryDateString);
      return expiryDate.isAfter(DateTime.now());
    } catch (e) {
      print('Error parsing subscription date: $e');
      return false;
    }
  }
  
  // === PREMIUM CHECKER FUNCTION ===
  bool isPremiumActive() {
    if (premiumExpiry == null) return false;
    try {
      final expiryDate = DateTime.parse(premiumExpiry!);
      return expiryDate.isAfter(DateTime.now());
    } catch (e) {
      print('Error parsing premium expiry date: $e');
      return false;
    }
  }

  // === COPY WITH METHOD ===
  UserProfileData copyWith({
    String? uid,
    String? name,
    int? age,
    List<String>? profileImageUrls,
    String? aboutMe,
    List<String>? interests,
    String? jobTitle,
    GeoPoint? location,
    String? locationName,
    List<String>? basicGender,
    List<String>? basicOrientation,
    List<String>? basicIdentity,
    String? drinkingHabit,
    String? smokingHabit,
    List<String>? blockedUsers,
    int? diamonds,
    Map<String, dynamic>? activeSubscriptions,
    String? premiumExpiry,
    List<String>? crushesSent,
    int? crushesSentToday,
    String? lastCrushDate,
    List<String>? likesSent,
  }) {
    return UserProfileData(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      age: age ?? this.age,
      profileImageUrls: profileImageUrls ?? this.profileImageUrls,
      aboutMe: aboutMe ?? this.aboutMe,
      interests: interests ?? this.interests,
      jobTitle: jobTitle ?? this.jobTitle,
      location: location ?? this.location,
      locationName: locationName ?? this.locationName,
      basicGender: basicGender ?? this.basicGender,
      basicOrientation: basicOrientation ?? this.basicOrientation,
      basicIdentity: basicIdentity ?? this.basicIdentity,
      drinkingHabit: drinkingHabit ?? this.drinkingHabit,
      smokingHabit: smokingHabit ?? this.smokingHabit,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      diamonds: diamonds ?? this.diamonds,
      activeSubscriptions: activeSubscriptions ?? this.activeSubscriptions,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
      crushesSent: crushesSent ?? this.crushesSent,
      crushesSentToday: crushesSentToday ?? this.crushesSentToday,
      lastCrushDate: lastCrushDate ?? this.lastCrushDate,
      likesSent: likesSent ?? this.likesSent,
    );
  }
}