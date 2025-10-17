import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

enum RelationshipType { none, monogamous, nonMonogamous, openToEither } // YAHAN 'none' ADD KIYA
enum NonMonogamousStatus { single, partnered, married } // YAHAN 'married' ADD KIYA

class UserProfileModel {
  String uid;
  String phoneNumber;
  
  String currentName;
  String currentAge;
  GeoPoint? currentLocation;      // <-- BADLAAV 1
  String currentLocationName;      // <-- BADLAAV 2
  
  List<File?> profileImages;
  List<String> profileImageUrls;

  String aboutMe;

  List<String> basicGender;
  List<String> basicOrientation;
  List<String> basicIdentity;
  bool basicIdentityPreferNotToSay;
  Map<String, dynamic>? basicRelationshipData;

  String heightFeet;
  String heightInches;
  String weightKg;

  List<String> selectedInterests;

  String jobTitle;
  String jobCompany;
  List<String> selectedLanguages;

  String drinkingHabit;
  String smokingHabit;
  String marijuanaHabit;

  Timestamp? createdAt;

  // === STEP 1: YEH DO NAYI PROPERTIES CLASS ME ADD KAREIN ===
  int profanityWarningCount;
  bool isBlocked;
  // ==========================================================

  // === MONETIZATION FIELDS ===
  int diamonds;
  Map<String, dynamic> activeSubscriptions;
  // ===========================

  List<String> blockedUsers; // New field for user blocking

  List<String> unlockedLikedProfiles; // <--- YEH NAYI LINE ADD KAREIN
  List<String> unlockedCrushProfiles; // <--- YEH NAYI LINE ADD KAREIN

  // === BOOST FEATURE FIELDS ===
  final int boostCount;
  final bool isBoosted;
  final Timestamp? boostExpiresAt;
  final GeoPoint? boostLocation;
  // ============================



  UserProfileModel({
    this.uid = '',
    this.phoneNumber = '',
    this.currentName = 'Your Name', // Default values
    this.currentAge = '25',
    this.currentLocation,             // <-- BADLAAV
    this.currentLocationName = '',    // <-- NAYI LINE
    List<File?>? profileImages,
    this.profileImageUrls = const [],
    this.aboutMe = '',
    this.basicGender = const ['Man'], // Default gender
    this.basicOrientation = const [],
    this.basicIdentity = const [],
    this.basicIdentityPreferNotToSay = false,
    this.basicRelationshipData,
    this.heightFeet = '',
    this.heightInches = '',
    this.weightKg = '',
    this.selectedInterests = const [],
    this.jobTitle = '',
    this.jobCompany = '',
    this.selectedLanguages = const [],
    this.drinkingHabit = '',
    this.smokingHabit = '',
    this.marijuanaHabit = '',
    this.createdAt,
    // === STEP 2: INHE CONSTRUCTOR ME BHI ADD KAREIN ===
    this.profanityWarningCount = 0, // Default value 0
    this.isBlocked = false,        // Default value false
    this.blockedUsers = const [],

    this.unlockedLikedProfiles = const [], // <--- YEH NAYI LINE ADD KAREIN
    this.unlockedCrushProfiles = const [], // <--- YEH NAYI LINE ADD KAREIN

    // =================================================
    // === MONETIZATION DEFAULTS ===
    this.diamonds = 0,
    this.activeSubscriptions = const {},
    // =============================

    // === BOOST FEATURE DEFAULTS ===
    this.boostCount = 0,
    this.isBoosted = false,
    this.boostExpiresAt,
    this.boostLocation,
    // ==============================

  }) : this.profileImages = profileImages ?? List.filled(5, null);

  // === Firestore se data padhne ke liye ===
  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    // Relationship data ko alag se handle karte hain
    Map<String, dynamic>? relationshipDataFromFirestore;
    final rawRelationshipData = map['myBasics']?['relationship'];
    
    if (rawRelationshipData is Map) {
      final typeString = rawRelationshipData['type'] as String?;
      final statusString = rawRelationshipData['status'] as String?;
      
      relationshipDataFromFirestore = {
        // String se enum wapas banana
        'type': typeString != null 
          ? RelationshipType.values.firstWhere((e) => e.name == typeString, orElse: () => RelationshipType.none) 
          : RelationshipType.none,
        
        'status': statusString != null && NonMonogamousStatus.values.any((e) => e.name == statusString)
  ? NonMonogamousStatus.values.firstWhere((e) => e.name == statusString)
  : null,
      };
    }

    return UserProfileModel(
      uid: map['uid'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      currentName: map['name'] ?? '',
      currentAge: (map['age'] ?? 0).toString(),
      currentLocation: map['location'] as GeoPoint?,       // <-- BADLAAV
      currentLocationName: map['locationName'] ?? '', // <-- NAYI LINE
      profileImageUrls: List<String>.from(map['profileImageUrls'] ?? []),
      aboutMe: map['aboutMe'] ?? '',
      selectedInterests: List<String>.from(map['interests'] ?? []),
      selectedLanguages: List<String>.from(map['languages'] ?? []),
      createdAt: map['createdAt'],

      basicGender: List<String>.from(map['myBasics']?['gender'] ?? []),
      basicOrientation: List<String>.from(map['myBasics']?['orientation'] ?? []),
      basicIdentity: List<String>.from(map['myBasics']?['identity'] ?? []),
      basicIdentityPreferNotToSay: map['myBasics']?['identityPreferNotToSay'] ?? false,
      basicRelationshipData: relationshipDataFromFirestore, // YAHAN CONVERTED DATA USE HOGA

      heightFeet: map['heightWeight']?['feet'] ?? '',
      heightInches: map['heightWeight']?['inches'] ?? '',
      weightKg: map['heightWeight']?['weight'] ?? '',

      jobTitle: map['myWork']?['jobTitle'] ?? '',
      jobCompany: map['myWork']?['company'] ?? '',
      
      drinkingHabit: map['habits']?['drinking'] ?? '',
      smokingHabit: map['habits']?['smoking'] ?? '',
      marijuanaHabit: map['habits']?['marijuana'] ?? '',

      // === NAYA FIELD ADD KIYA ===
      blockedUsers: List<String>.from(map['blockedUsers'] ?? []),

      // vvv YEH NAYI LINE ADD KAREIN vvv
      unlockedLikedProfiles: List<String>.from(map['unlockedLikedProfiles'] ?? []), 
      unlockedCrushProfiles: List<String>.from(map['unlockedCrushProfiles'] ?? []),


      profanityWarningCount: map['profanityWarningCount'] ?? 0,
      isBlocked: map['isBlocked'] ?? false,

      // === MONETIZATION FIELDS FROM FIRESTORE ===
      diamonds: map['diamonds'] ?? 0,
      activeSubscriptions: Map<String, dynamic>.from(map['activeSubscriptions'] ?? {}),
      // ==========================================

      // === BOOST FEATURE FIELDS FROM FIRESTORE ===
      boostCount: map['boostCount'] ?? 0,
      isBoosted: map['isBoosted'] ?? false,
      boostExpiresAt: map['boostExpiresAt'] as Timestamp?,
      boostLocation: map['boostLocation'] as GeoPoint?,
      // ==========================================

    );
  }

  // === Firestore me data bhejne ke liye ===
    // lib/models/user_profile_model.dart me is function ko poora replace karein

  Map<String, dynamic> toJson() {
    // Relationship data ko alag se handle karte hain
    Map<String, dynamic>? relationshipDataForFirestore;
    if (basicRelationshipData != null) {
      relationshipDataForFirestore = {
        // .name se enum ki value as a String milti hai (e.g., 'monogamous')
        'type': (basicRelationshipData!['type'] as RelationshipType).name,
        
        // Status null ho sakta hai, isliye check karenge
        'status': (basicRelationshipData!['status'] as NonMonogamousStatus?)?.name,
      };
    }

    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'name': currentName,
      'age': int.tryParse(currentAge) ?? 0,
      'location': currentLocation,
      'locationName': currentLocationName,
      'profileImageUrls': profileImageUrls,
      'aboutMe': aboutMe,
      'interests': selectedInterests,
      'languages': selectedLanguages,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'myBasics': {
        'gender': basicGender,
        'orientation': basicOrientation,
        'identity': basicIdentity,
        'identityPreferNotToSay': basicIdentityPreferNotToSay,
        'relationship': relationshipDataForFirestore, // AB YAHAN CONVERTED DATA JAYEGA
      },
      'heightWeight': {
        'feet': heightFeet,
        'inches': heightInches,
        'weight': weightKg,
      },
      'myWork': {
        'jobTitle': jobTitle,
        'company': jobCompany,
      },
      'habits': {
        'drinking': drinkingHabit,
        'smoking': smokingHabit,
        'marijuana': marijuanaHabit,
      },

      // === STEP 3: YEH DO NAYI LINES 'toJson' FUNCTION ME ADD KAREIN ===
      'profanityWarningCount': profanityWarningCount,
      'isBlocked': isBlocked,
      // ===============================================================
      'blockedUsers': blockedUsers,

      'unlockedLikedProfiles': unlockedLikedProfiles, // <--- YEH NAYI LINE ADD KAREIN
      'unlockedCrushProfiles': unlockedCrushProfiles, // <--- YEH NAYI LINE ADD KAREIN



      // === MONETIZATION FIELDS TO FIRESTORE ===
      'diamonds': diamonds,
      'activeSubscriptions': activeSubscriptions,
      // ======================================

      // === BOOST FEATURE FIELDS TO FIRESTORE ===
      'boostCount': boostCount,
      'isBoosted': isBoosted,
      'boostExpiresAt': boostExpiresAt,
      'boostLocation': boostLocation,
      // =======================================

    };
  }
}