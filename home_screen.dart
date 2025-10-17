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

  // === ADMOB STATE VARIABLES ===
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
      final currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserUid).get();
      if (!currentUserDoc.exists) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      _currentUserProfile = UserProfileData.fromFirestore(currentUserDoc);
      final List<String> myBlockedList = List<String>.from(currentUserDoc.data()?['blockedUsers'] ?? []);

      final minAge = prefs.getDouble('filter_min_age') ?? 18.0;
      final maxAge = prefs.getDouble('filter_max_age') ?? 80.0;
      final maxDistance = prefs.getDouble('filter_distance') ?? 100.0;
      final List<String> genders = prefs.getStringList('filter_genders') ?? [];
      final List<String> orientations = prefs.getStringList('filter_orientations') ?? [];
      final List<String> identities = prefs.getStringList('filter_identities') ?? [];
      final filterLat = prefs.getDouble('filter_location_lat');
      final filterLng = prefs.getDouble('filter_location_lng');
      final bool isLocationFilterActive = filterLat != null && filterLng != null;

      final bool filtersAreSet = (minAge != 18.0 || maxAge != 80.0 || maxDistance != 100.0 ||
                                  genders.isNotEmpty || orientations.isNotEmpty || identities.isNotEmpty ||
                                  isLocationFilterActive);

      GeoPoint? sourceLocation;
      if (isLocationFilterActive) {
        sourceLocation = GeoPoint(filterLat, filterLng);
      } else {
        sourceLocation = _currentUserProfile?.location;
      }

      if (sourceLocation == null) {
        if (mounted) setState(() {
          _users = [];
          _areFiltersActive = filtersAreSet;
          _isLoading = false;
        });
        return;
      }

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
          final boostLocation = doc.data().containsKey('boostLocation') ? doc.data()['boostLocation'] as GeoPoint? : null;

          final basicConditionsMet = user.uid != currentUserUid && !myBlockedList.contains(user.uid) && !user.blockedUsers.contains(currentUserUid);
          if (!basicConditionsMet) continue;
          
          if (boostLocation != null) {
            final distanceToBoostLocation = Geolocator.distanceBetween(
              sourceLocation.latitude, sourceLocation.longitude,
              boostLocation.latitude, boostLocation.longitude,
            ) / 1000;
            
            if (distanceToBoostLocation <= 100) {
                boostedUsers.add(user);
            }
          }
        }
        
        filteredBoostedUsers = boostedUsers.where((user) {
          final ageMatch = user.age >= minAge && user.age <= maxAge;
          final genderMatch = genders.isEmpty || user.basicGender.any((g) => genders.contains(g));
          final orientationMatch = orientations.isEmpty || user.basicOrientation.any((o) => orientations.contains(o));
          final identityMatch = identities.isEmpty || user.basicIdentity.any((i) => identities.contains(i));
          return ageMatch && genderMatch && orientationMatch && identityMatch;
        }).toList();
      }

      Query query = FirebaseFirestore.instance.collection('users').where('isBoosted', isEqualTo: false);
      
      if (genders.isNotEmpty) query = query.where('myBasics.gender', arrayContainsAny: genders);
      if (orientations.isNotEmpty) query = query.where('myBasics.orientation', arrayContainsAny: orientations);
      if (identities.isNotEmpty) query = query.where('myBasics.identity', arrayContainsAny: identities);
      
      final normalUsersSnapshot = await query.get();

      List<UserProfileData> normalUsers = [];
      final Set<String> boostedUserIds = filteredBoostedUsers.map((u) => u.uid).toSet();

      for (var doc in normalUsersSnapshot.docs) {
        final user = UserProfileData.fromFirestore(doc);

        if (boostedUserIds.contains(user.uid)) continue;

        final basicConditionsMet = user.uid != currentUserUid && !myBlockedList.contains(user.uid) && !user.blockedUsers.contains(currentUserUid);
        if (!basicConditionsMet) continue;

        final ageMatch = user.age >= minAge && user.age <= maxAge;
        
        double distanceInKm = double.maxFinite;
        if (user.location != null) {
          distanceInKm = Geolocator.distanceBetween(
            sourceLocation.latitude, sourceLocation.longitude,
            user.location!.latitude, user.location!.longitude,
          ) / 1000;
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
        });
      }

    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (kDebugMode) print("Error fetching users with FILTERS-FIRST logic: $e");
      if (e is FirebaseException && e.code == 'failed-precondition') {
        debugPrint("FIRESTORE INDEX REQUIRED: ${e.message}");
      }
    }
  }

  void _setupRealtimeCountListeners() {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null || !mounted) return;

    final countsProvider = Provider.of<NewCountsProvider>(context, listen: false);

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

    FirebaseFirestore.instance.collection('users').doc(currentUserUid).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        if (mounted) {
          setState(() {
            _diamondBalance = snapshot.data()!['diamonds'] ?? 0;
          });
        }
      }
    });
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
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadRewardedAd();
        }, 
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadRewardedAd();
        }
      );
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) => onSuccess());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Ad not ready yet. Please try again.'), backgroundColor: Colors.orange.shade800),
      );
      _loadRewardedAd();
    }
  }

  Future<void> _payWithDiamondsForAction(int cost, VoidCallback onSuccess) async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null || _diamondBalance < cost) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUserUid).update({
        'diamonds': FieldValue.increment(-cost),
      });
      onSuccess();
    } catch (e) {
      if (kDebugMode) print("Error spending diamonds: $e");
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
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Pack Activated Successfully!'), backgroundColor: Colors.green.shade700),
      );

      setState(() {
        if (_currentUserProfile != null) {
          final expiryDate = DateTime.now().add(const Duration(days: 30));
          _currentUserProfile!.activeSubscriptions['${packId}_expiry'] = expiryDate.toIso8601String();
        }
      });

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Purchase failed. You may not have enough diamonds.'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  void _actuallySendMessage(UserProfileData receiverUser) async {
    final bool? messageSent = await showSendMessagePopup(
      context: context,
      receiverUser: receiverUser,
    );

    if (!mounted) return;

    if (messageSent == true) {
      _onItemTapped(1);
    } else if (messageSent == false) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Could not send message. Please try again.'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  void _handleMessageButtonTap(UserProfileData tappedUser) async {
    if (_currentUserProfile != null && 
        (_currentUserProfile!.isPremiumActive() || _currentUserProfile!.isSubscriptionActive('unlimited_messages'))) 
    {
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
             SnackBar(content: Text('Premium Activated Successfully!'), backgroundColor: Colors.green.shade700),
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
        (_currentUserProfile!.isPremiumActive() || _currentUserProfile!.isSubscriptionActive('unlimited_undos'))) 
    {
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
             SnackBar(content: Text('Premium Activated Successfully!'), backgroundColor: Colors.green.shade700),
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
  // Change 1: Hardcoded black ko theme ke background color se replace kiya
  backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
  appBar: _selectedIndex == 0 ? _buildCustomAppBar() : null,
  
  body: Column(
    children: [
      if (_selectedIndex == 0)
        // Change 2: Hardcoded grey line ko theme ke divider color se replace kiya
        Container(height: 1.h, color: Theme.of(context).dividerColor.withOpacity(0.2)),
      
      Expanded(child: pages[_selectedIndex]),
    ],
  ),

  bottomNavigationBar: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Change 3: Niche wali line ko bhi theme ke divider color se replace kiya
      Container(height: 1.h, color: Theme.of(context).dividerColor.withOpacity(0.2)),
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
          child: // === NAYA TEXT WIDGET ===
Text(
  "No new people around you right now.",
  textAlign: TextAlign.center,
  // Change: Hardcoded grey ko theme ke text color se replace kiya (thodi kam opacity ke saath)
  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
    fontSize: 18.sp,
    color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6)
  ),
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
            cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
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

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    setState(() {
      _currentCardIndex = currentIndex ?? 0;
    });

    final receiverUser = _users[previousIndex];
    if (direction == CardSwiperDirection.top) {
      _handleCrush(receiverUser.uid);
    } else if (direction == CardSwiperDirection.right) {
      _recordLike(receiverUser);
    }

    if (kDebugMode) print('Swiped ${direction.name} on user ${_users[previousIndex].name}');
    return true;
  }

  bool _onUndo(int? previousIndex, int currentIndex, CardSwiperDirection direction) {
    setState(() {
      _currentCardIndex = currentIndex;
    });

    if (previousIndex != null) {
      if (kDebugMode) print('Undo on user ${_users[previousIndex].name}');
    }
    return true;
  }

  Future<void> _recordLike(UserProfileData likedUser) async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) return;

    final likedUserId = likedUser.uid;

    try {
      final potentialMatchDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .collection('likedBy')
          .doc(likedUserId)
          .get();

      if (potentialMatchDoc.exists) {
        // IT'S A MATCH!
        if (kDebugMode) print('IT\'S A MATCH with ${likedUser.name}');
        if (_currentUserProfile != null) {
          await _handleMatch(_currentUserProfile!, likedUser);
        }
      } else {
        // No match - save like
        await FirebaseFirestore.instance
            .collection('users')
            .doc(likedUserId)
            .collection('likedBy')
            .doc(currentUserUid)
            .set({'timestamp': FieldValue.serverTimestamp()});

        // === NEW: Update likes_sent array ===
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .update({
          'likes_sent': FieldValue.arrayUnion([likedUserId])
        });

        if (kDebugMode) print('Like recorded for ${likedUser.name}');
      }
    } catch (e) {
      if (kDebugMode) print("Error in _recordLike: $e");
    }
  }
  
  Future<void> _handleMatch(UserProfileData currentUserProfile, UserProfileData matchedUser) async {
    try {
      final currentUserUid = currentUserProfile.uid;
      final matchedUserId = matchedUser.uid;
      final batch = FirebaseFirestore.instance.batch();

      final currentUserMatchRef = FirebaseFirestore.instance.collection('users').doc(currentUserUid).collection('matches').doc(matchedUserId);
      batch.set(currentUserMatchRef, {'timestamp': FieldValue.serverTimestamp()});

      final matchedUserMatchRef = FirebaseFirestore.instance.collection('users').doc(matchedUserId).collection('matches').doc(currentUserUid);
      batch.set(matchedUserMatchRef, {'timestamp': FieldValue.serverTimestamp()});

      final oldLikeRef = FirebaseFirestore.instance.collection('users').doc(currentUserUid).collection('likedBy').doc(matchedUserId);
      batch.delete(oldLikeRef);

       await batch.commit();

       // === NEW: Increment match count for both users ===
await FirebaseFirestore.instance.collection('users').doc(currentUserUid).update({
  'match_count': FieldValue.increment(1),
});

await FirebaseFirestore.instance.collection('users').doc(matchedUserId).update({
  'match_count': FieldValue.increment(1),
});

       // === NEW: Remove from likes_sent array for both users ===
       await FirebaseFirestore.instance.collection('users').doc(currentUserUid).update({
      'likes_sent': FieldValue.arrayRemove([matchedUserId])
       });

       await FirebaseFirestore.instance.collection('users').doc(matchedUserId).update({
      'likes_sent': FieldValue.arrayRemove([currentUserUid])
      });

      if (mounted) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: Provider.of<OnlineStatusProvider>(context, listen: false),
              child: MatchNotificationScreen(
                currentUserProfile: currentUserProfile,
                matchedUser: matchedUser,
              ),
            ),
          ),
        );

        if (result == true) {
          _onItemTapped(1);
        }
      }
    } catch (e) {
      if (kDebugMode) print("Error handling match: $e");
    }
  }

  // === NEW FUNCTION: Handle Mutual Crush Match ===
Future<void> _handleCrushMatch(String matchedUserId) async {
  try {
    final currentUserUid = _currentUserProfile?.uid;
    if (currentUserUid == null) return;

    // Fetch matched user's profile
    final matchedUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(matchedUserId)
        .get();

    if (!matchedUserDoc.exists) return;

    final matchedUser = UserProfileData.fromFirestore(matchedUserDoc);
    final batch = FirebaseFirestore.instance.batch();

    // Create match entry for both users
    final currentUserMatchRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .collection('matches')
        .doc(matchedUserId);
    batch.set(currentUserMatchRef, {'timestamp': FieldValue.serverTimestamp()});

    final matchedUserMatchRef = FirebaseFirestore.instance
        .collection('users')
        .doc(matchedUserId)
        .collection('matches')
        .doc(currentUserUid);
    batch.set(matchedUserMatchRef, {'timestamp': FieldValue.serverTimestamp()});

    // Delete crush entries from both users
    final currentUserCrushRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .collection('crushesMe')
        .doc(matchedUserId);
    batch.delete(currentUserCrushRef);

    final matchedUserCrushRef = FirebaseFirestore.instance
        .collection('users')
        .doc(matchedUserId)
        .collection('crushesMe')
        .doc(currentUserUid);
    batch.delete(matchedUserCrushRef);

    // === NEW: Remove from crushes_sent array for both users ===
await FirebaseFirestore.instance.collection('users').doc(currentUserUid).update({
  'crushes_sent': FieldValue.arrayRemove([matchedUserId])
});

await FirebaseFirestore.instance.collection('users').doc(matchedUserId).update({
  'crushes_sent': FieldValue.arrayRemove([currentUserUid])
});

    await batch.commit();

    // === NEW: Increment match count for crush matches ===
await FirebaseFirestore.instance.collection('users').doc(currentUserUid).update({
  'match_count': FieldValue.increment(1),
});

await FirebaseFirestore.instance.collection('users').doc(matchedUserId).update({
  'match_count': FieldValue.increment(1),
});

    if (kDebugMode) print('CRUSH MATCH created with ${matchedUser.name}!');

    // Show match notification screen
    if (mounted) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: Provider.of<OnlineStatusProvider>(context, listen: false),
            child: MatchNotificationScreen(
              currentUserProfile: _currentUserProfile!,
              matchedUser: matchedUser,
            ),
          ),
        ),
      );

      if (result == true) {
        _onItemTapped(1); // Navigate to chat list
      }
    }
  } catch (e) {
    if (kDebugMode) print("Error handling crush match: $e");
  }
}


  Future<void> _handleCrush(String receiverUserId) async {
  final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserUid == null) return;

  try {
    // === STEP 1: DAILY CRUSH LIMIT CHECK ===
    final currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .get();

    if (!currentUserDoc.exists) return;

    final userData = currentUserDoc.data()!;
    final int crushesToday = userData['crushes_sent_today'] ?? 0;
    final String lastCrushDate = userData['last_crush_date'] ?? '';
    final bool isPremium = _currentUserProfile?.isPremiumActive() ?? false;

    // Current date in YYYY-MM-DD format
    final String todayDate = DateTime.now().toIso8601String().split('T')[0];

    // Check if date has changed (midnight reset)
    int newCrushCount;
    if (lastCrushDate != todayDate) {
      // New day - reset count
      newCrushCount = 1;
    } else {
      // Same day - check limit
      if (!isPremium && crushesToday >= 5) {
        // Show premium popup for unlimited crushes
        if (mounted) {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const PremiumPlansScreen()),
          );
          if (result == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                content: Text('Premium Activated! You can now send unlimited crushes.'),
                backgroundColor: Colors.green.shade700,
              ),
            );
            setState(() {
              if (_currentUserProfile != null) {
                final expiryDate = DateTime.now().add(const Duration(days: 30));
                _currentUserProfile = _currentUserProfile!.copyWith(
                  premiumExpiry: expiryDate.toIso8601String(),
                );
              }
            });
            // Retry crush send
            _handleCrush(receiverUserId);
          }
        }
        return; // Don't send crush if limit exceeded
      }
      newCrushCount = crushesToday + 1;
    }

    // === STEP 2: CHECK FOR MUTUAL CRUSH (MATCH DETECTION) ===
    final mutualCrushDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .collection('crushesMe')
        .doc(receiverUserId)
        .get();

    if (mutualCrushDoc.exists) {
      // ðŸ”¥ IT'S A MUTUAL CRUSH! CREATE MATCH
      await _handleCrushMatch(receiverUserId);
      
      // Update crush count in database
      await FirebaseFirestore.instance.collection('users').doc(currentUserUid).update({
        'crushes_sent_today': newCrushCount,
        'last_crush_date': todayDate,
        // 'crushes_sent' is NOT updated here because a match was made and the crush is consumed.
      });
      
      return; // Exit after match creation
    }

    // === STEP 3: SAVE CRUSH (NO MATCH CASE) ===
    // Save to receiver's crushesMe collection
    await FirebaseFirestore.instance
        .collection('users')
        .doc(receiverUserId)
        .collection('crushesMe')
        .doc(currentUserUid)
        .set({'timestamp': FieldValue.serverTimestamp()});

    // Update sender's database
    await FirebaseFirestore.instance.collection('users').doc(currentUserUid).update({
      'crushes_sent': FieldValue.arrayUnion([receiverUserId]),
      'crushes_sent_today': newCrushCount,
      'last_crush_date': todayDate,
    });

    if (kDebugMode) print('Crush sent successfully! Total today: $newCrushCount');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPremium 
              ? 'Crush sent! ðŸ’–' 
              : 'Crush sent! (${5 - newCrushCount} free crushes left today) ðŸ’–'
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  } catch (e) {
    if (kDebugMode) print('Error sending crush: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }
}

  // === IN DONO METHODS KO NAYE CODE SE REPLACE KAREIN ===

Widget _buildStickyActionButtons() {
  final theme = Theme.of(context);
  final customColors = theme.extension<CustomColors>()!;

  return Padding(
    padding: EdgeInsets.symmetric(vertical: 12.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Change: Sabhi hardcoded AppColors ko theme colors se replace kiya
        _buildActionIcon(onTap: _handleUndoButtonTap, icon: Icons.undo, color: Colors.amber.shade600),
        _buildActionIcon(onTap: () => _swiperController.swipe(CardSwiperDirection.left), icon: Icons.heart_broken, color: customColors.footerGrey!),
        
        _buildActionIcon(
          onTap: () => _swiperController.swipe(CardSwiperDirection.right),
          icon: Icons.favorite,
          color: theme.colorScheme.onPrimary, // White on red
          backgroundColor: theme.colorScheme.primary, // Red from theme
          isLarge: true,
        ),

        _buildActionIcon(
          onTap: () {
            if (_users.isEmpty) return;
            final currentUser = _users[_currentCardIndex.clamp(0, _users.length - 1)];
            _handleMessageButtonTap(currentUser);
          },
          icon: Icons.maps_ugc_outlined,
          color: customColors.diamondBlue!,
        ),

        _buildActionIcon(onTap: () => _swiperController.swipe(CardSwiperDirection.top), icon: Icons.star, color: Colors.purpleAccent.shade200),
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
        // Change: Hardcoded black ko theme ke surface color se replace kiya
        color: backgroundColor ?? theme.colorScheme.surface.withOpacity(0.9),
        boxShadow: [
          if (isLarge)
            BoxShadow(color: color.withOpacity(0.5), blurRadius: 20.r, spreadRadius: 2.r),
          // Change: Hardcoded black shadow ko theme ke shadow color se replace kiya (safe fallback ke saath)
            BoxShadow(color: theme.shadowColor.withOpacity(0.3), blurRadius: 10.r, offset: Offset(0, 4.h)),        ],
      ),
      child: Icon(icon, color: color, size: iconSize),
    ),
  );
}

 // === IS POORE METHOD KO NAYE CODE SE REPLACE KAREIN ===
PreferredSizeWidget _buildCustomAppBar() {
  // Theme colors ko pehle hi le liya taaki code saaf dikhe
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
          // Change: Hardcoded color ko theme ke text style se replace kiya
          style: GoogleFonts.anton(
            fontSize: 32.sp,
            color: theme.textTheme.titleLarge?.color,
            letterSpacing: 1.5
          ),
        ),
        Row(
          children: [
            // Diamond Balance Widget
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DiamondStoreScreen())),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  // Change: Hardcoded grey ko theme ke surface color se replace kiya
                  color: theme.colorScheme.surface.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    // Change: Hardcoded yellow ko theme-friendly amber color diya
                    Icon(Icons.diamond, color: Colors.amber.shade400, size: 16.sp),
                    SizedBox(width: 4.w),
                    Text(
                      _diamondBalance.toString(),
                      // Change: Hardcoded text color ko theme ke color se replace kiya
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16.sp, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 10.w),

            // Online Users Widget
            GestureDetector(
              onTap: () async {
                 // ... (andar ka logic same hai, koi badlav nahi)
                 final prefs = await SharedPreferences.getInstance();
                  final minAge = prefs.getDouble('filter_min_age') ?? 18.0;
                  final maxAge = prefs.getDouble('filter_max_age') ?? 80.0;
                  final maxDistance = prefs.getDouble('filter_distance') ?? 100.0;
                  final List<String> genders = prefs.getStringList('filter_genders') ?? [];
                  final List<String> orientations = prefs.getStringList('filter_orientations') ?? [];
                  final List<String> identities = prefs.getStringList('filter_identities') ?? [];
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: Provider.of<OnlineStatusProvider>(context, listen: false),
                          child: OnlineUsersScreen(
                            minAge: minAge, maxAge: maxAge, maxDistance: maxDistance,
                            genders: genders, orientations: orientations, identities: identities,
                          ),
                        ),
                      ),
                    );
                  }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  // Change: Hardcoded grey ko theme ke surface color se replace kiya
                  color: theme.colorScheme.surface.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    // Change: Custom color ko theme extension se liya
                    Icon(Icons.wifi, color: customColors.onlineGreen, size: 16.sp),
                    SizedBox(width: 4.w),
                    Text(
                      "Online",
                      // Change: Hardcoded text color ko theme ke color se replace kiya
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w600)
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 4.w),

            // Filter Button
            IconButton(
              icon: const Icon(Icons.filter_list),
              iconSize: 28.sp,
              // Change: Hardcoded colors ko theme ke primary aur default colors se replace kiya
              color: _areFiltersActive ? theme.colorScheme.primary : theme.iconTheme.color,
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const FilterScreen()));
                if (mounted) {
                  setState(() { _isLoading = true; });
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

 // home_screen.dart

// ... (all imports and existing code)

// In _HomeScreenState class

// ... (all other functions remain the same)

// Find the _buildBottomNavigationBar method and update it

 // === IN DONO METHODS KO BHI NAYE CODE SE REPLACE KAREIN ===

Widget _buildBottomNavigationBar() {
  final theme = Theme.of(context);
  final customColors = theme.extension<CustomColors>()!;

  return Consumer<OnlineStatusProvider>(
    builder: (context, onlineStatusProvider, child) {
      final totalUnreadCount = onlineStatusProvider.totalUnreadCount;
      return Consumer<NewCountsProvider>(
        builder: (context, countsProvider, child) {
          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            // Change: Hardcoded black ko theme ke surface color se replace kiya, jo thoda alag shade hai
            backgroundColor: theme.colorScheme.surface,
            // Change: Hardcoded colors ko theme colors se replace kiya
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: customColors.footerGrey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 12.sp),
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Discover'),
              _buildNavItemWithBadge(icon: Icons.maps_ugc_outlined, activeIcon: Icons.maps_ugc, label: 'Message', count: totalUnreadCount),
              _buildNavItemWithBadge(
                icon: Icons.favorite_border, 
                activeIcon: Icons.favorite, 
                label: 'Likes', 
                count: countsProvider.newLikesAndMatchesCount
              ),
              _buildNavItemWithBadge(icon: Icons.star_border, activeIcon: Icons.star, label: 'Crush', count: countsProvider.newCrushesCount),
              const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
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
              // Change: Hardcoded red ko theme ke primary color se replace kiya
              decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
              // Change: Hardcoded white ko theme ke onPrimary color se replace kiya
              child: Text(count.toString(), style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 10.sp)),
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
              // Change: Yahan bhi same badlav
              decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
              child: Text(count.toString(), style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 10.sp)),
            ),
          ),
      ],
    ),
  );
}
}