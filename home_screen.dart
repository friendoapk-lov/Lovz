import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovz/screens/profile_screen.dart';
import 'package:lovz/screens/chat_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lovz/models/user_profile_data.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:lovz/screens/profile_card.dart';
import 'package:provider/provider.dart';
import 'package:lovz/providers/online_status_provider.dart';
import 'package:lovz/screens/crush_screen.dart';
import 'package:lovz/screens/filter_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lovz/screens/likes_you_screen.dart';
import 'package:lovz/screens/match_notification_screen.dart';
import 'package:lovz/widgets/message_popup.dart';
import 'package:lovz/providers/new_counts_provider.dart';
import 'package:lovz/screens/diamond_store_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lovz/helpers/monetization_helper.dart';
import 'package:lovz/widgets/monetization_popup.dart';
import 'package:lovz/services/subscription_service.dart';
import 'package:lovz/screens/premium_plans_screen.dart';
import 'package:lovz/screens/online_users_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lovz/utils/theme.dart';
import 'package:lottie/lottie.dart';
import 'package:lovz/services/diamond_service.dart';
import 'package:lovz/services/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<UserProfileData> _users = [];
  bool _isLoading = true;
  int _currentCardIndex = 0;
  final CardSwiperController _swiperController = CardSwiperController();
  bool _areFiltersActive = false;
  UserProfileData? _currentUserProfile;
  int _diamondBalance = 0;
  bool _isProcessingSwipe = false; // ✅ NEW: Swipe lock
  // ✅ NEW: Animation state management
  DateTime _lastCrushTime = DateTime.now();
  final Duration _minCrushInterval = const Duration(milliseconds: 800);
  bool _isShowingAnimation = false;

  // Rate limiting state (per-minute tracking)
  int _crushesRemainingToday = 5; // Daily crush limit tracker

  // AdMob state
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  final String _adUnitId = "ca-app-pub-3940256099942544/5224354917";

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRealtimeCountListeners();
      _setupDiamondListener();
      _loadRewardedAd();
    });
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserUid == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .get();
      if (!currentUserDoc.exists) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      _currentUserProfile = UserProfileData.fromFirestore(currentUserDoc);
      // Calculate remaining crushes for today
      _updateCrushCountDisplay();

      // User ki blocked list
      final List<String> myBlockedList =
          List<String>.from(currentUserDoc.data()?['blockedUsers'] ?? []);

      // Jinko maine crush/like kiya unki list
      final List<String> myCrushesSent =
          List<String>.from(currentUserDoc.data()?['crushes_sent'] ?? []);
      final List<String> myLikesSent =
          List<String>.from(currentUserDoc.data()?['likes_sent'] ?? []);

// Jinone mujhe like kiya aur jinse main match ho gaya unki list
      final matchesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .collection('matches')
          .get();
      final List<String> matchedUserIds =
          matchesSnapshot.docs.map((doc) => doc.id).toList();

      // Filter preferences
      final minAge = prefs.getDouble('filter_min_age') ?? 18.0;
      final maxAge = prefs.getDouble('filter_max_age') ?? 80.0;
      final maxDistance = prefs.getDouble('filter_distance') ?? 100.0;
      final List<String> genders = prefs.getStringList('filter_genders') ?? [];
      final List<String> orientations =
          prefs.getStringList('filter_orientations') ?? [];
      final List<String> identities =
          prefs.getStringList('filter_identities') ?? [];
      final filterLat = prefs.getDouble('filter_location_lat');
      final filterLng = prefs.getDouble('filter_location_lng');
      final bool isLocationFilterActive =
          filterLat != null && filterLng != null;

      final bool filtersAreSet = (minAge != 18.0 ||
          maxAge != 80.0 ||
          maxDistance != 100.0 ||
          genders.isNotEmpty ||
          orientations.isNotEmpty ||
          identities.isNotEmpty ||
          isLocationFilterActive);

      GeoPoint? sourceLocation;
      if (isLocationFilterActive) {
        sourceLocation = GeoPoint(filterLat, filterLng);
      } else {
        sourceLocation = _currentUserProfile?.location;
      }

      if (sourceLocation == null) {
        if (mounted)
          setState(() {
            _users = [];
            _areFiltersActive = filtersAreSet;
            _isLoading = false;
          });
        return;
      }

      // Boosted users fetch karein
      List<UserProfileData> boostedUsers = [];
      final boostedUsersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isBoosted', isEqualTo: true)
          .where('boostExpiresAt', isGreaterThan: Timestamp.now())
          .get();

      List<UserProfileData> filteredBoostedUsers = [];
      if (boostedUsersSnapshot.docs.isNotEmpty) {
        for (var doc in boostedUsersSnapshot.docs) {
          final user = UserProfileData.fromFirestore(doc);
          final boostLocation = doc.data().containsKey('boostLocation')
              ? doc.data()['boostLocation'] as GeoPoint?
              : null;

          // Exclusion logic: sirf jinko maine crush/like kiya ya jo match/likedBy me hain unko exclude karo
          final basicConditionsMet = user.uid != currentUserUid &&
              !myBlockedList.contains(user.uid) &&
              !user.blockedUsers.contains(currentUserUid) &&
              !myCrushesSent.contains(user.uid) && // Jinko maine crush kiya
              !myLikesSent.contains(user.uid) && // Jinko maine like kiya
              !matchedUserIds.contains(user.uid); // Jinse match ho gaya

          if (!basicConditionsMet) continue;

          if (boostLocation != null) {
            final distanceToBoostLocation = Geolocator.distanceBetween(
                  sourceLocation.latitude,
                  sourceLocation.longitude,
                  boostLocation.latitude,
                  boostLocation.longitude,
                ) /
                1000;

            if (distanceToBoostLocation <= 100) {
              boostedUsers.add(user);
            }
          }
        }

        filteredBoostedUsers = boostedUsers.where((user) {
          final ageMatch = user.age >= minAge && user.age <= maxAge;
          final genderMatch = genders.isEmpty ||
              user.basicGender.any((g) => genders.contains(g));
          final orientationMatch = orientations.isEmpty ||
              user.basicOrientation.any((o) => orientations.contains(o));
          final identityMatch = identities.isEmpty ||
              user.basicIdentity.any((i) => identities.contains(i));
          return ageMatch && genderMatch && orientationMatch && identityMatch;
        }).toList();
      }

      Query query = FirebaseFirestore.instance
          .collection('users')
          .where('isBoosted', isEqualTo: false);

      if (genders.isNotEmpty)
        query = query.where('myBasics.gender', arrayContainsAny: genders);
      if (orientations.isNotEmpty)
        query =
            query.where('myBasics.orientation', arrayContainsAny: orientations);
      if (identities.isNotEmpty)
        query = query.where('myBasics.identity', arrayContainsAny: identities);

      final normalUsersSnapshot = await query.get();

      List<UserProfileData> normalUsers = [];
      final Set<String> boostedUserIds =
          filteredBoostedUsers.map((u) => u.uid).toSet();

      for (var doc in normalUsersSnapshot.docs) {
        final user = UserProfileData.fromFirestore(doc);

        if (boostedUserIds.contains(user.uid)) continue;

        // Exclusion logic: sirf jinko maine crush/like kiya ya jo match/likedBy me hain unko exclude karo
        final basicConditionsMet = user.uid != currentUserUid &&
            !myBlockedList.contains(user.uid) &&
            !user.blockedUsers.contains(currentUserUid) &&
            !myCrushesSent.contains(user.uid) && // Jinko maine crush kiya
            !myLikesSent.contains(user.uid) && // Jinko maine like kiya
            !matchedUserIds.contains(user.uid); // Jinse match ho gaya

        if (!basicConditionsMet) continue;

        final ageMatch = user.age >= minAge && user.age <= maxAge;

        double distanceInKm = double.maxFinite;
        if (user.location != null) {
          distanceInKm = Geolocator.distanceBetween(
                sourceLocation.latitude,
                sourceLocation.longitude,
                user.location!.latitude,
                user.location!.longitude,
              ) /
              1000;
        }
        final distanceMatch = distanceInKm <= maxDistance;

        if (ageMatch && distanceMatch) {
          normalUsers.add(user);
        }
      }

      final finalUserList = [...filteredBoostedUsers, ...normalUsers];

      if (mounted) {
        setState(() {
          _users = finalUserList;
          _areFiltersActive = filtersAreSet;
          _isLoading = false;

          // ✅ CRITICAL FIX: Clamp index to valid range
          if (_currentCardIndex >= _users.length) {
            _currentCardIndex = _users.length > 0 ? _users.length - 1 : 0;
            debugPrint(
                '⚠️ [FIX] Index clamped to $_currentCardIndex (list length: ${_users.length})');
          }
        });

        // ✅ CRITICAL FIX: Move swiper to valid index
        if (_users.isNotEmpty && _currentCardIndex < _users.length) {
          try {
            _swiperController.moveTo(_currentCardIndex);
            debugPrint('✅ [FIX] Swiper moved to index $_currentCardIndex');
          } catch (e) {
            debugPrint('⚠️ [FIX] Swiper move failed: $e');
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (kDebugMode) print("Error fetching users: $e");
      if (e is FirebaseException && e.code == 'failed-precondition') {
        debugPrint("FIRESTORE INDEX REQUIRED: ${e.message}");
      }
    }
  }

  void _setupRealtimeCountListeners() {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null || !mounted) return;

    final countsProvider =
        Provider.of<NewCountsProvider>(context, listen: false);

    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .collection('likedBy')
        .snapshots()
        .listen((snapshot) {
      countsProvider.updateTotalLikes(snapshot.size);
    });

    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .collection('matches')
        .snapshots()
        .listen((snapshot) {
      countsProvider.updateTotalMatches(snapshot.size);
    });

    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .collection('crushesMe')
        .snapshots()
        .listen((snapshot) {
      countsProvider.updateTotalCrushes(snapshot.size);
    });
  }

  void _setupDiamondListener() {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null || !mounted) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        if (mounted) {
          setState(() {
            _diamondBalance = snapshot.data()!['diamonds'] ?? 0;
          });
        }
      }
    });
  }

  void _updateCrushCountDisplay() {
    if (_currentUserProfile == null) return;

    final isPremium = _currentUserProfile!.isPremiumActive();
    if (isPremium) {
      setState(() => _crushesRemainingToday = 999); // Unlimited for premium
      return;
    }

    final String todayDate = DateTime.now().toIso8601String().split('T')[0];
    final String lastCrushDate = _currentUserProfile!.lastCrushDate;
    final int crushesSentToday = _currentUserProfile!.crushesSentToday;

    if (lastCrushDate != todayDate) {
      // New day - reset to 5
      setState(() => _crushesRemainingToday = 5);
    } else {
      // Same day - calculate remaining
      setState(() => _crushesRemainingToday = 5 - crushesSentToday);
    }
  }

  void _showCrushSentAnimation() {
    // ✅ Prevent concurrent animations
    if (_isShowingAnimation) {
      debugPrint('⏸️ [ANIMATION] Already showing - skipping');
      return;
    }

    _isShowingAnimation = true;

    // ✅ Use overlay (non-blocking)
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: Container(
          width: 200.w,
          height: 200.h,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Lottie.asset(
            'assets/crush_sent.json',
            repeat: false,
            animate: true,
            onLoaded: (composition) {
              Future.delayed(composition.duration, () {
                try {
                  overlayEntry.remove();
                  _isShowingAnimation = false;
                } catch (e) {
                  debugPrint('⚠️ Overlay remove error: $e');
                }
              });
            },
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Fallback timeout
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (_isShowingAnimation) {
        try {
          overlayEntry.remove();
        } catch (e) {}
        _isShowingAnimation = false;
      }
    });
  }

  Future<void> _showCrushLimitPopup() async {
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.purpleAccent.shade200, size: 28.sp),
            SizedBox(width: 8.w),
            Text(
              'Daily Crush Limit Reached',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          "You've used all 5 free crushes today! ✨\n\nUpgrade to Premium for unlimited crushes and unlock all premium features.",
          style: TextStyle(fontSize: 15.sp, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe Later',
                style: TextStyle(
                    color:
                        theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PremiumPlansScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            ),
            child: Text('Upgrade to Premium',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          setState(() {
            _rewardedAd = ad;
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isAdLoaded = false;
        },
      ),
    );
  }

  void _showAdForAction(VoidCallback onSuccess) {
    if (_rewardedAd != null && _isAdLoaded) {
      _rewardedAd!.fullScreenContentCallback =
          FullScreenContentCallback(onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd();
      }, onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd();
      });
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) => onSuccess());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ad not ready yet. Please try again.'),
            backgroundColor: Colors.orange.shade800),
      );
      _loadRewardedAd();
    }
  }

  Future<void> _payWithDiamondsForAction(
      int cost, VoidCallback onSuccess) async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) return;

    if (_diamondBalance < cost) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You don't have enough diamonds!"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final result = await DiamondService.spendDiamonds(
      userId: currentUserUid,
      cost: cost,
      reason: 'home_action', // Can be 'undo' or 'message' based on context
      metadata: {
        'action': 'generic',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (!mounted) return;

    if (result['success'] == true) {
      onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Transaction failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleSubscriptionPurchase(String packId, int cost) async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final bool success = await SubscriptionService.purchaseSubscription(
      userId: currentUserUid,
      packId: packId,
      cost: cost,
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (success) {
      // Refresh user data from Firestore to get updated values
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .get();

        if (userDoc.exists) {
          final userData = UserProfileData.fromFirestore(userDoc);
          setState(() {
            _currentUserProfile = userData;
          });
        }
      } catch (e) {
        print('Error refreshing user data: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Pack Activated Successfully!'),
            backgroundColor: Colors.green.shade700),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Purchase failed. You may not have enough diamonds.'),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  void _actuallySendMessage(UserProfileData receiverUser) async {
    final result = await showSendMessagePopup(
      context: context,
      receiverUser: receiverUser,
    );

    if (!mounted) return;

    if (result != null && result['success'] == true) {
      // ✅ Instant feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message sent successfully! 📨'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // ✅ Navigate immediately
      _onItemTapped(1);

      // ✅ Background cleanup
      Future.microtask(() async {
        print('🔄 [BACKGROUND] Cleaning cache...');

        final dbHelper = DatabaseHelper.instance;
        final onlineStatusProvider =
            Provider.of<OnlineStatusProvider>(context, listen: false);

        await Future.wait([
          dbHelper.clearChat(result['chatId'] ?? 0),
          dbHelper.clearAllChatThreads(),
          onlineStatusProvider.fetchInitialChatStates(),
        ]);

        print('✅ [BACKGROUND] Cache cleaned');
      });
    } else if (result != null && result['success'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send message. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _handleMessageButtonTap(UserProfileData tappedUser) async {
    if (_currentUserProfile != null &&
        (_currentUserProfile!.isPremiumActive() ||
            _currentUserProfile!.isSubscriptionActive('unlimited_messages'))) {
      _actuallySendMessage(tappedUser);
      return;
    }

    List<MonetizationOption> options = [
      MonetizationOption(
        title: 'Send a Free Message',
        subtitle: 'Watch a short video ad to send',
        icon: Icons.smart_display_rounded,
        action: MonetizationAction.watchAd,
        color: Colors.green,
      ),
      MonetizationOption(
        title: 'Send Instantly',
        subtitle: 'Use 7 diamonds to send a message',
        icon: Icons.send_rounded,
        action: MonetizationAction.payWithDiamonds,
        diamondCost: 7,
        color: Colors.blueAccent,
      ),
      MonetizationOption(
        title: 'Unlimited Messages',
        subtitle: 'Get a monthly pack for unlimited chats',
        icon: Icons.all_inclusive_rounded,
        action: MonetizationAction.buySubscriptionMessage,
        diamondCost: 149,
        color: Colors.purple,
      ),
      MonetizationOption(
        title: 'Get Premium',
        subtitle: 'Unlock all features & remove ads',
        icon: Icons.workspace_premium_rounded,
        action: MonetizationAction.buyPremium,
        color: Colors.orange.shade700,
        diamondCost: 499,
      ),
    ];

    final selectedAction = await showMonetizationPopup(
      context: context,
      title: 'Send First Message?',
      options: options,
      currentUserDiamondBalance: _diamondBalance,
    );

    if (selectedAction == null || !mounted) return;

    switch (selectedAction) {
      case MonetizationAction.watchAd:
        _showAdForAction(() => _actuallySendMessage(tappedUser));
        break;
      case MonetizationAction.payWithDiamonds:
        _payWithDiamondsForAction(7, () => _actuallySendMessage(tappedUser));
        break;
      case MonetizationAction.buySubscriptionMessage:
        _handleSubscriptionPurchase('unlimited_messages', 149);
        break;
      case MonetizationAction.buyPremium:
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => const PremiumPlansScreen()),
        );
        if (result == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Premium Activated Successfully!'),
                backgroundColor: Colors.green.shade700),
          );
          setState(() {
            if (_currentUserProfile != null) {
              final expiryDate = DateTime.now().add(const Duration(days: 30));
              _currentUserProfile = _currentUserProfile!.copyWith(
                premiumExpiry: expiryDate.toIso8601String(),
              );
            }
          });
        }
        break;
      default:
        break;
    }
  }

  void _handleUndoButtonTap() async {
    if (_currentUserProfile != null &&
        (_currentUserProfile!.isPremiumActive() ||
            _currentUserProfile!.isSubscriptionActive('unlimited_undos'))) {
      _swiperController.undo();
      return;
    }

    List<MonetizationOption> options = [
      MonetizationOption(
        title: 'Free Undo',
        subtitle: 'Watch a short video ad',
        icon: Icons.smart_display_rounded,
        action: MonetizationAction.watchAd,
        color: Colors.green,
      ),
      MonetizationOption(
        title: 'Undo Instantly',
        subtitle: 'Use 5 diamonds for one undo',
        icon: Icons.replay_rounded,
        action: MonetizationAction.payWithDiamonds,
        diamondCost: 5,
        color: Colors.amber,
      ),
      MonetizationOption(
        title: 'Unlimited Undos',
        subtitle: 'Get a monthly pack for unlimited reverses',
        icon: Icons.all_inclusive_rounded,
        action: MonetizationAction.buySubscriptionUndo,
        diamondCost: 89,
        color: Colors.purple,
      ),
      MonetizationOption(
        title: 'Get Premium',
        subtitle: 'Unlock all features & remove ads',
        icon: Icons.workspace_premium_rounded,
        action: MonetizationAction.buyPremium,
        color: Colors.orange.shade700,
        diamondCost: 499,
      ),
    ];

    final selectedAction = await showMonetizationPopup(
      context: context,
      title: 'Undo Last Swipe?',
      options: options,
      currentUserDiamondBalance: _diamondBalance,
    );

    if (selectedAction == null || !mounted) return;

    switch (selectedAction) {
      case MonetizationAction.watchAd:
        _showAdForAction(() => _swiperController.undo());
        break;
      case MonetizationAction.payWithDiamonds:
        _payWithDiamondsForAction(5, () => _swiperController.undo());
        break;
      case MonetizationAction.buySubscriptionUndo:
        _handleSubscriptionPurchase('unlimited_undos', 89);
        break;
      case MonetizationAction.buyPremium:
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => const PremiumPlansScreen()),
        );
        if (result == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Premium Activated Successfully!'),
                backgroundColor: Colors.green.shade700),
          );
          setState(() {
            if (_currentUserProfile != null) {
              final expiryDate = DateTime.now().add(const Duration(days: 30));
              _currentUserProfile = _currentUserProfile!.copyWith(
                premiumExpiry: expiryDate.toIso8601String(),
              );
            }
          });
        }
        break;
      default:
        break;
    }
  }

  void _onItemTapped(int index) {
    if (index == 0 && _selectedIndex != 0) {
      setState(() {
        _isLoading = true;
      });
      _fetchUsers();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      _buildDiscoverPageBody(),
      const ChatListScreen(),
      LikesYouScreen(
        currentUserDiamondBalance: _diamondBalance,
        onMessageSent: () => _onItemTapped(1),
      ),
      CrushScreen(
        currentUserDiamondBalance: _diamondBalance,
        onMessageSent: () => _onItemTapped(1),
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _selectedIndex == 0 ? _buildCustomAppBar() : null,
      body: Column(
        children: [
          if (_selectedIndex == 0)
            Container(
                height: 1.h,
                color: Theme.of(context).dividerColor.withOpacity(0.2)),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              height: 1.h,
              color: Theme.of(context).dividerColor.withOpacity(0.2)),
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildDiscoverPageBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_users.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            "No new people around you right now.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 18.sp,
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color
                    ?.withOpacity(0.6)),
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: CardSwiper(
            controller: _swiperController,
            cardsCount: _users.length,
            numberOfCardsDisplayed: 1,
            onSwipe: _onSwipe,
            onUndo: _onUndo,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            cardBuilder:
                (context, index, percentThresholdX, percentThresholdY) {
              debugPrint(
                  'JAASOOS_SWIPE: 🎨 CARD BUILDER called | index: $index | list: ${_users.length}');

              // ✅ CRITICAL SAFETY: Return placeholder if index invalid
              if (index < 0 || index >= _users.length) {
                debugPrint(
                    'JAASOOS_SWIPE: ⚠️ [BUILDER] Invalid index $index - showing placeholder');

                // Show a loading placeholder instead of empty
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              }

              debugPrint(
                  'JAASOOS_SWIPE: ✅ [BUILDER] Building card for: ${_users[index].name}');

              return ProfileCard(
                key: ValueKey(_users[index].uid),
                user: _users[index],
                percentThresholdX: percentThresholdX.toDouble(),
                percentThresholdY: percentThresholdY.toDouble(),
                currentUserProfile: _currentUserProfile,
              );
            },
          ),
        ),
        _buildStickyActionButtons(),
        SizedBox(height: 20.h),
      ],
    );
  }

  // NAYA AUR BEHTAR _onSwipe FUNCTION
  // NAYA, FINAL, AUR 100% SAFE _onSwipe FUNCTION

  // NAYA, FINAL, ROCK-SOLID _onSwipe FUNCTION

  // NAYA, FINAL, GUARANTEED FIX _onSwipe FUNCTION

  // NAYA, FINAL, GUARANTEED INSTANT-RECOVERY _onSwipe FUNCTION

// NAYA, FINAL, GUARANTEED RACE-CONDITION-PROOF _onSwipe FUNCTION

  bool _onSwipe(
      int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    debugPrint(
        'JAASOOS_SWIPE: 👆 SWIPE | prevIdx: $previousIndex | currIdx: $currentIndex | List: ${_users.length}');

    // 🛡️ SAFETY CHECK #1: Stale previous index
    if (previousIndex >= _users.length) {
      debugPrint(
          'JAASOOS_SWIPE: ⚠️ STALE prevIndex ($previousIndex) - list only has ${_users.length}');

      // Force CardSwiper back to valid index in next frame
      if (_users.isNotEmpty) {
        final safeIndex = (_users.length - 1).clamp(0, _users.length - 1);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            try {
              _swiperController.moveTo(safeIndex);
              setState(() => _currentCardIndex = safeIndex);
              debugPrint(
                  'JAASOOS_SWIPE: ✅ Forced swiper to safe index: $safeIndex');
            } catch (e) {
              debugPrint('JAASOOS_SWIPE: ⚠️ Recovery failed: $e');
            }
          }
        });
      }

      return true; // Tell CardSwiper swipe was handled
    }

    // 🔒 Prevent concurrent swipes
    if (_isProcessingSwipe) {
      debugPrint('JAASOOS_SWIPE: ⏸️ Already processing');
      return false;
    }
    _isProcessingSwipe = true;

    final swipedUser = _users[previousIndex];

    // DB operations in background
    Future.microtask(() {
      if (direction == CardSwiperDirection.top) {
        _handleCrush(swipedUser.uid);
      } else if (direction == CardSwiperDirection.right) {
        _recordLike(swipedUser);
      }
    });

    // 🛡️ SAFETY CHECK #2: Clamp currentIndex to valid range
    int safeCurrent = currentIndex ?? 0;

    // Calculate what the index SHOULD be after removal
    final int expectedIndex;
    if (previousIndex == _users.length - 1) {
      // Last card removed - go to new last card
      expectedIndex = (_users.length - 2).clamp(0, _users.length - 1);
    } else {
      // Middle/first card removed - stay at same position
      expectedIndex = previousIndex.clamp(
          0, (_users.length - 2).clamp(0, _users.length - 1));
    }

    debugPrint(
        'JAASOOS_SWIPE: 🧮 CardSwiper wants idx: $safeCurrent | We calculate: $expectedIndex');

    // Remove the card
    setState(() {
      _users.removeAt(previousIndex);

      // Use our calculated index (more reliable than CardSwiper's)
      _currentCardIndex = _users.isEmpty ? 0 : expectedIndex;

      debugPrint(
          'JAASOOS_SWIPE: ✅ Removed | Remaining: ${_users.length} | Set index: $_currentCardIndex');
    });

    // 🛡️ SAFETY CHECK #3: Force CardSwiper to correct position if needed
    if (_users.isNotEmpty && expectedIndex != safeCurrent) {
      debugPrint('JAASOOS_SWIPE: ⚙️ Correcting CardSwiper position...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _users.isNotEmpty) {
          try {
            _swiperController.moveTo(_currentCardIndex);
            debugPrint(
                'JAASOOS_SWIPE: ✅ Swiper corrected to $_currentCardIndex');
          } catch (e) {
            debugPrint('JAASOOS_SWIPE: ⚠️ moveTo failed: $e');
          }
        }
      });
    }

    // Release lock
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _isProcessingSwipe = false;
        debugPrint('JAASOOS_SWIPE: 🟢 Lock released');
      }
    });

    return true;
  }

  // NAYA _onUndo FUNCTION
  bool _onUndo(
      int? previousIndex, int currentIndex, CardSwiperDirection direction) {
    setState(() {
      _currentCardIndex = currentIndex;
      debugPrint(
          'JAASOOS_SWIPE: 🔄 UNDO successful. New _currentCardIndex is: $currentIndex');
    });
    if (previousIndex != null) {
      if (kDebugMode) print('Undo on user ${_users[previousIndex].name}');
    }
    return true;
  }

  Future<void> _recordLike(UserProfileData likedUser) async {
    // === INSTANT RATE LIMIT CHECK ===

    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) return;

    final likedUserId = likedUser.uid;

    try {
      // Check if mutual like exists
      final potentialMatchDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .collection('likedBy')
          .doc(likedUserId)
          .get();

      if (potentialMatchDoc.exists) {
        // IT'S A MATCH! - Create likedBy and let Cloud Function handle it
        if (kDebugMode) print('MUTUAL LIKE DETECTED with ${likedUser.name}');

        // Create likedBy document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(likedUserId)
            .collection('likedBy')
            .doc(currentUserUid)
            .set({'timestamp': FieldValue.serverTimestamp()});

        // Update likes_sent
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .update({
          'likes_sent': FieldValue.arrayUnion([likedUserId])
        });

        // Listen for match creation
        final matchRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .collection('matches')
            .doc(likedUserId);

        StreamSubscription? matchListener;
        final completer = Completer<bool>();

        matchListener = matchRef.snapshots().listen((snapshot) {
          if (snapshot.exists && !completer.isCompleted) {
            completer.complete(true);
            matchListener?.cancel();
          }
        });

        final isMatch = await completer.future.timeout(
          Duration(seconds: 5),
          onTimeout: () {
            matchListener?.cancel();
            return false;
          },
        );

        if (isMatch && mounted && _currentUserProfile != null) {
          // Show match notification
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value:
                    Provider.of<OnlineStatusProvider>(context, listen: false),
                child: MatchNotificationScreen(
                  currentUserProfile: _currentUserProfile!,
                  matchedUser: likedUser,
                ),
              ),
            ),
          );

          if (result == true) {
            _onItemTapped(1);
          }
        }
      } else {
        // No match - save like
        await FirebaseFirestore.instance
            .collection('users')
            .doc(likedUserId)
            .collection('likedBy')
            .doc(currentUserUid)
            .set({'timestamp': FieldValue.serverTimestamp()});

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .update({
          'likes_sent': FieldValue.arrayUnion([likedUserId])
        });

        if (kDebugMode) print('Like recorded for ${likedUser.name}');
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠ Action blocked by security rules.'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    } catch (e) {
      // ✅ Rollback on failure
      setState(() {
        // Re-insert the user if operation failed
        if (!_users.any((u) => u.uid == likedUser.uid)) {
          _users.insert(_currentCardIndex, likedUser);
        }
      });

      if (kDebugMode) print('Error: $e');
    }
  }

  Future<void> _handleCrush(String receiverUserId) async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) return;

    // ✅ NEW: Rate limit with cooldown
    final now = DateTime.now();
    if (now.difference(_lastCrushTime) < _minCrushInterval) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.timer, color: Colors.white, size: 20.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text('Please wait before sending another crush!'),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            duration: Duration(milliseconds: 500),
          ),
        );
      }
      return;
    }

    _lastCrushTime = now;

    try {
      // === DAILY CRUSH LIMIT CHECK ===
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .get();

      if (!currentUserDoc.exists) return;

      final userData = currentUserDoc.data()!;
      final int crushesToday = userData['crushes_sent_today'] ?? 0;
      final String lastCrushDate = userData['last_crush_date'] ?? '';
      final bool isPremium = _currentUserProfile?.isPremiumActive() ?? false;

      final String todayDate = DateTime.now().toIso8601String().split('T')[0];

      int newCrushCount;
      if (lastCrushDate != todayDate) {
        newCrushCount = 1;
      } else {
        if (!isPremium && crushesToday >= 5) {
          _showCrushLimitPopup();
          return;
        }
        newCrushCount = crushesToday + 1;
      }

      // === CHECK FOR MUTUAL CRUSH (MATCH) ===
      final mutualCrushDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .collection('crushesMe')
          .doc(receiverUserId)
          .get();

      if (mutualCrushDoc.exists) {
        // IT'S A MUTUAL CRUSH! - Create crushesMe and let Cloud Function handle it
        if (kDebugMode) print('MUTUAL CRUSH DETECTED!');

        // Create crushesMe document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(receiverUserId)
            .collection('crushesMe')
            .doc(currentUserUid)
            .set({'timestamp': FieldValue.serverTimestamp()});

        // Update crushes_sent
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .update({
          'crushes_sent': FieldValue.arrayUnion([receiverUserId]),
          'crushes_sent_today': newCrushCount,
          'last_crush_date': todayDate,
        });

        // Listen for match creation
        final matchRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .collection('matches')
            .doc(receiverUserId);

        StreamSubscription? matchListener;
        final completer = Completer<bool>();

        matchListener = matchRef.snapshots().listen((snapshot) {
          if (snapshot.exists && !completer.isCompleted) {
            completer.complete(true);
            matchListener?.cancel();
          }
        });

        final isMatch = await completer.future.timeout(
          Duration(seconds: 5),
          onTimeout: () {
            matchListener?.cancel();
            return false;
          },
        );

        // Update local state
        if (_currentUserProfile != null) {
          _currentUserProfile = _currentUserProfile!.copyWith(
            crushesSentToday: newCrushCount,
            lastCrushDate: todayDate,
          );
        }
        _updateCrushCountDisplay();
        _showCrushSentAnimation();

        if (isMatch && mounted && _currentUserProfile != null) {
          // Fetch matched user profile
          final matchedUserDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(receiverUserId)
              .get();

          if (matchedUserDoc.exists) {
            final matchedUser = UserProfileData.fromFirestore(matchedUserDoc);

            // Show match notification
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value:
                      Provider.of<OnlineStatusProvider>(context, listen: false),
                  child: MatchNotificationScreen(
                    currentUserProfile: _currentUserProfile!,
                    matchedUser: matchedUser,
                  ),
                ),
              ),
            );

            if (result == true) {
              _onItemTapped(1);
            }
          }
        }

        return;
      }

      // === SAVE CRUSH (NO MATCH) ===
      await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverUserId)
          .collection('crushesMe')
          .doc(currentUserUid)
          .set({'timestamp': FieldValue.serverTimestamp()});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .update({
        'crushes_sent': FieldValue.arrayUnion([receiverUserId]),
        'crushes_sent_today': newCrushCount,
        'last_crush_date': todayDate,
      });

      if (kDebugMode)
        print('Crush sent successfully! Total today: $newCrushCount');

      // UPDATE LOCAL STATE
      if (_currentUserProfile != null) {
        _currentUserProfile = _currentUserProfile!.copyWith(
          crushesSentToday: newCrushCount,
          lastCrushDate: todayDate,
        );
      }
      _updateCrushCountDisplay();
      _showCrushSentAnimation();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  '🔒 Action blocked. You may have reached your daily limit.'),
              backgroundColor: Colors.orange.shade700,
            ),
          );
        }
      }
    } catch (e) {
      // ✅ Rollback on failure
      if (mounted) {
        setState(() {
          // Check if user still exists in list
          final crushedUserIndex =
              _users.indexWhere((u) => u.uid == receiverUserId);

          if (crushedUserIndex == -1) {
            // User was removed optimistically - keep it removed
            // (We can't easily re-insert without re-fetching)
            if (kDebugMode) print('⚠️ Crush failed - user remains hidden');
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send crush. Please try again.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }

      if (kDebugMode) print('❌ Error sending crush: $e');
    }
  }

  // NAYA AUR SAFE _buildStickyActionButtons FUNCTION
  Widget _buildStickyActionButtons() {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionIcon(
              onTap: _handleUndoButtonTap,
              icon: Icons.undo,
              color: Colors.amber.shade600),
          _buildActionIcon(
              onTap: () => _swiperController.swipe(CardSwiperDirection.left),
              icon: Icons.heart_broken,
              color: customColors.footerGrey!),
          _buildActionIcon(
            onTap: () => _swiperController.swipe(CardSwiperDirection.right),
            icon: Icons.favorite,
            color: theme.colorScheme.onPrimary,
            backgroundColor: theme.colorScheme.primary,
            isLarge: true,
          ),
          _buildActionIcon(
            onTap: () {
              if (_users.isEmpty || _currentCardIndex >= _users.length) {
                debugPrint(
                    'JAASOOS_SWIPE: 🐞 [MESSAGE BTN] Cannot send. Index out of bounds. Index: $_currentCardIndex, List Length: ${_users.length}');
                return;
              }
              final userToSend = _users[_currentCardIndex];
              debugPrint(
                  'JAASOOS_SWIPE: 🐞 [MESSAGE BTN] Sending message to: ${userToSend.name} at index: $_currentCardIndex');
              _handleMessageButtonTap(userToSend);
            },
            icon: Icons.maps_ugc_outlined,
            color: customColors.diamondBlue!,
          ),
          _buildActionIconWithBadge(
            onTap: () => _swiperController.swipe(CardSwiperDirection.top),
            icon: Icons.star,
            color: Colors.purpleAccent.shade200,
            badgeCount:
                _crushesRemainingToday < 5 ? _crushesRemainingToday : null,
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    bool isLarge = false,
    Color? backgroundColor,
  }) {
    final theme = Theme.of(context);
    final double size = isLarge ? 70.w : 55.w;
    final double iconSize = isLarge ? 35.sp : 28.sp;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? theme.colorScheme.surface.withOpacity(0.9),
          boxShadow: [
            if (isLarge)
              BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 20.r,
                  spreadRadius: 2.r),
            BoxShadow(
                color: theme.shadowColor.withOpacity(0.3),
                blurRadius: 10.r,
                offset: Offset(0, 4.h)),
          ],
        ),
        child: Icon(icon, color: color, size: iconSize),
      ),
    );
  }

  Widget _buildActionIconWithBadge({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    int? badgeCount,
  }) {
    final theme = Theme.of(context);
    final double size = 55.w;
    final double iconSize = 28.sp;

    final bool isPremium = _currentUserProfile?.isPremiumActive() ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surface.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.3),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          // BADGE (only for freemium users with remaining crushes < 5)
          if (!isPremium && badgeCount != null)
            Positioned(
              top: -4.h,
              right: -4.w,
              child: Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color:
                      badgeCount > 0 ? theme.colorScheme.primary : Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4.r,
                      spreadRadius: 1.r,
                    ),
                  ],
                ),
                child: Text(
                  badgeCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildCustomAppBar() {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'BAE',
            style: GoogleFonts.anton(
                fontSize: 32.sp,
                color: theme.textTheme.titleLarge?.color,
                letterSpacing: 1.5),
          ),
          Row(
            children: [
              // Diamond Balance Widget
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DiamondStoreScreen())),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.diamond,
                          color: Colors.amber.shade400, size: 16.sp),
                      SizedBox(width: 4.w),
                      Text(_diamondBalance.toString(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10.w),

              // Online Users Widget
              GestureDetector(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final minAge = prefs.getDouble('filter_min_age') ?? 18.0;
                  final maxAge = prefs.getDouble('filter_max_age') ?? 80.0;
                  final maxDistance =
                      prefs.getDouble('filter_distance') ?? 100.0;
                  final List<String> genders =
                      prefs.getStringList('filter_genders') ?? [];
                  final List<String> orientations =
                      prefs.getStringList('filter_orientations') ?? [];
                  final List<String> identities =
                      prefs.getStringList('filter_identities') ?? [];
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: Provider.of<OnlineStatusProvider>(context,
                              listen: false),
                          child: OnlineUsersScreen(
                            minAge: minAge,
                            maxAge: maxAge,
                            maxDistance: maxDistance,
                            genders: genders,
                            orientations: orientations,
                            identities: identities,
                          ),
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi,
                          color: customColors.onlineGreen, size: 16.sp),
                      SizedBox(width: 4.w),
                      Text("Online",
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14.sp, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 4.w),

              // Filter Button
              IconButton(
                icon: const Icon(Icons.filter_list),
                iconSize: 28.sp,
                color: _areFiltersActive
                    ? theme.colorScheme.primary
                    : theme.iconTheme.color,
                onPressed: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FilterScreen()));
                  if (mounted) {
                    setState(() {
                      _isLoading = true;
                    });
                    _fetchUsers();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;

    // ✅ NEW: Auto-refresh when Messages tab is active
    if (_selectedIndex == 1 && ModalRoute.of(context)?.isCurrent == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<OnlineStatusProvider>(context, listen: false)
            .refreshUnreadCounts();
      });
    }

    return Consumer<OnlineStatusProvider>(
      builder: (context, onlineStatusProvider, child) {
        final totalUnreadCount = onlineStatusProvider.totalUnreadCount;

        // ✅ YAHAN PAR DEBUG PRINT LAGANA HAI. YEH SAHI JAGAH HAI.
        debugPrint(
            'JAASOOS: 🎨 [STEP C - UI REBUILD] Home Screen ka BottomNav rebuild ho raha hai. Provider se mila count: $totalUnreadCount');
        return Consumer<NewCountsProvider>(
          builder: (context, countsProvider, child) {
            return BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: theme.colorScheme.surface,
              selectedItemColor: theme.colorScheme.primary,
              unselectedItemColor: customColors.footerGrey,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedLabelStyle:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
              unselectedLabelStyle:
                  TextStyle(fontWeight: FontWeight.normal, fontSize: 12.sp),
              items: [
                const BottomNavigationBarItem(
                    icon: Icon(Icons.explore_outlined),
                    activeIcon: Icon(Icons.explore),
                    label: 'Discover'),
                _buildNavItemWithBadge(
                    icon: Icons.maps_ugc_outlined,
                    activeIcon: Icons.maps_ugc,
                    label: 'Message',
                    count: totalUnreadCount),
                _buildNavItemWithBadge(
                    icon: Icons.favorite_border,
                    activeIcon: Icons.favorite,
                    label: 'Likes',
                    count: countsProvider.newLikesAndMatchesCount),
                _buildNavItemWithBadge(
                    icon: Icons.star_border,
                    activeIcon: Icons.star,
                    label: 'Crush',
                    count: countsProvider.newCrushesCount),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profile'),
              ],
            );
          },
        );
      },
    );
  }

  BottomNavigationBarItem _buildNavItemWithBadge({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int count,
  }) {
    final theme = Theme.of(context);

    return BottomNavigationBarItem(
      label: label,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon),
          if (count > 0)
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                    color: theme.colorScheme.primary, shape: BoxShape.circle),
                child: Text(count.toString(),
                    style: TextStyle(
                        color: theme.colorScheme.onPrimary, fontSize: 10.sp)),
              ),
            ),
        ],
      ),
      activeIcon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(activeIcon),
          if (count > 0)
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                    color: theme.colorScheme.primary, shape: BoxShape.circle),
                child: Text(count.toString(),
                    style: TextStyle(
                        color: theme.colorScheme.onPrimary, fontSize: 10.sp)),
              ),
            ),
        ],
      ),
    );
  }
}
