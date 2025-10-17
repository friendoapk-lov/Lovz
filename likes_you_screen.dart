import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lovz/models/user_profile_data.dart';
import 'package:lovz/providers/new_counts_provider.dart';
import 'package:lovz/helpers/monetization_helper.dart';
import 'package:lovz/screens/premium_plans_screen.dart';
import 'package:lovz/services/subscription_service.dart';
import 'package:lovz/utils/theme.dart'; // THEME: Custom theme file imported
import 'package:lovz/widgets/message_popup.dart';
import 'package:lovz/widgets/monetization_popup.dart';
import 'package:provider/provider.dart';

class LikesYouScreen extends StatefulWidget {
  final int currentUserDiamondBalance;
  final VoidCallback? onMessageSent;

  const LikesYouScreen({
    super.key,
    required this.currentUserDiamondBalance,
    this.onMessageSent,
  });

  @override
  State<LikesYouScreen> createState() => _LikesYouScreenState();
}

class _LikesYouScreenState extends State<LikesYouScreen> {
  UserProfileData? _currentUserProfile;
  bool _isLoading = true;
  
  List<UserProfileData> _matchesList = [];
  List<UserProfileData> _yourLikesList = [];
  List<UserProfileData> _likedYouList = [];
  
  int _selectedTab = 2;
  
  final Set<String> _unlockedProfiles = {};
  final Set<String> _likedProfiles = {};
  
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  late int _localDiamondBalance;
  
  final String r2PublicUrlBase = "https://pub-20b75325021441f58867571ca62aa1aa.r2.dev";
  final String _adUnitId = "ca-app-pub-3940256099942544/5224354917";

  @override
  void initState() {
    super.initState();
    _localDiamondBalance = widget.currentUserDiamondBalance;
    _loadRewardedAd();
    _fetchData();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NewCountsProvider>(context, listen: false).resetLikesCount();
    });
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  // --- DATA FETCHING & LOGIC (No UI Changes Here) --- //
  // All the functions from _loadRewardedAd to _payWithDiamondsForMessage
  // are kept exactly the same as they handle logic, not UI.
  // We will only change the `build` methods below.

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

  Future<void> _fetchData() async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .get();
      
      if (!currentUserDoc.exists) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final currentUserData = UserProfileData.fromFirestore(currentUserDoc);
      final unlockedIds = List<String>.from(currentUserDoc.data()?['unlockedLikedProfiles'] ?? []);
      
      if (mounted) {
        setState(() {
          _unlockedProfiles.addAll(unlockedIds);
        });
      }

      // Fetch MATCHES
      final matchesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .collection('matches')
          .orderBy('timestamp', descending: true)
          .get();

      List<UserProfileData> matchesProfiles = [];
      if (matchesSnapshot.docs.isNotEmpty) {
        final matchUserIds = matchesSnapshot.docs.map((doc) => doc.id).toList();
        
        final batches = <List<String>>[];
        for (var i = 0; i < matchUserIds.length; i += 10) {
          batches.add(matchUserIds.sublist(i, i + 10 > matchUserIds.length ? matchUserIds.length : i + 10));
        }

        for (var batch in batches) {
          final matchProfilesSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get();
          
          matchesProfiles.addAll(
            matchProfilesSnapshot.docs.map((doc) => UserProfileData.fromFirestore(doc)).toList(),
          );
        }
      }

      // Fetch LIKED YOU
      final likedYouSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .collection('likedBy')
          .orderBy('timestamp', descending: true)
          .get();

      List<UserProfileData> likedYouProfiles = [];
      if (likedYouSnapshot.docs.isNotEmpty) {
        final likedYouUserIds = likedYouSnapshot.docs.map((doc) => doc.id).toList();
        
        final batches = <List<String>>[];
        for (var i = 0; i < likedYouUserIds.length; i += 10) {
          batches.add(likedYouUserIds.sublist(i, i + 10 > likedYouUserIds.length ? likedYouUserIds.length : i + 10));
        }

        for (var batch in batches) {
          final likedYouProfilesSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get();
          
          likedYouProfiles.addAll(
            likedYouProfilesSnapshot.docs.map((doc) => UserProfileData.fromFirestore(doc)).toList(),
          );
        }
      }

      // Fetch YOUR LIKES
      final likesSentList = currentUserData.likesSent;
      List<UserProfileData> yourLikesProfiles = [];
      
      if (likesSentList.isNotEmpty) {
        final batches = <List<String>>[];
        for (var i = 0; i < likesSentList.length; i += 10) {
          batches.add(likesSentList.sublist(i, i + 10 > likesSentList.length ? likesSentList.length : i + 10));
        }

        for (var batch in batches) {
          final batchSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get();
          
          yourLikesProfiles.addAll(
            batchSnapshot.docs.map((doc) => UserProfileData.fromFirestore(doc)).toList(),
          );
        }
      }

      if (mounted) {
        setState(() {
          _currentUserProfile = currentUserData;
          _matchesList = matchesProfiles;
          _yourLikesList = yourLikesProfiles;
          _likedYouList = likedYouProfiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleProfileTap(UserProfileData tappedUser, int tabIndex) async {
    final bool isPremium = _currentUserProfile?.isPremiumActive() ?? false;
    final bool hasLikesPack = _currentUserProfile?.isSubscriptionActive('unlimited_likes') ?? false;
    
    final bool isUnlocked = (tabIndex == 0 || tabIndex == 1) || 
                            isPremium || 
                            hasLikesPack || 
                            _unlockedProfiles.contains(tappedUser.uid);

    if (!isUnlocked) {
      _showMonetizationPopup(tappedUser);
      return;
    }
  }

  Future<void> _showMonetizationPopup(UserProfileData tappedUser) async {
    List<MonetizationOption> options = [
      MonetizationOption(
        title: 'Unlock for Free',
        subtitle: 'Watch a short video ad to reveal',
        icon: Icons.smart_display_rounded,
        action: MonetizationAction.watchAd,
        color: Colors.green,
      ),
      MonetizationOption(
        title: 'Reveal Instantly',
        subtitle: 'Use 7 diamonds to see this profile',
        icon: Icons.lock_open_rounded,
        action: MonetizationAction.payWithDiamonds,
        diamondCost: 7,
        color: Colors.blueAccent,
      ),
      MonetizationOption(
        title: 'Unlimited Profiles',
        subtitle: 'Get a monthly pack for unlimited reveals',
        icon: Icons.all_inclusive_rounded,
        action: MonetizationAction.buySubscriptionLikes,
        diamondCost: 149,
        color: const Color(0xFF8A2BE2),
      ),
      MonetizationOption(
        title: 'Get Premium',
        subtitle: 'Unlock all features & remove ads',
        icon: Icons.star_rounded,
        action: MonetizationAction.buyPremium,
        diamondCost: 499,
        color: const Color(0xFFFFD700),
      ),
    ];

    final MonetizationAction? selectedAction = await showMonetizationPopup(
      context: context,
      title: 'Reveal this Profile?',
      options: options,
      currentUserDiamondBalance: _localDiamondBalance,
    );

    if (selectedAction == null || !mounted) return;

    switch (selectedAction) {
      case MonetizationAction.watchAd:
        _showAdToUnlock(tappedUser);
        break;
      case MonetizationAction.payWithDiamonds:
        _payWithDiamondsToUnlock(tappedUser, 7);
        break;
      case MonetizationAction.buySubscriptionLikes:
        _handleSubscriptionPurchase('unlimited_likes', 149);
        break;
      case MonetizationAction.buyPremium:
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => const PremiumPlansScreen()),
        );
        if (result == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Premium Activated Successfully!'), backgroundColor: Colors.green),
          );
          setState(() {
            if (_currentUserProfile != null) {
              final expiryDate = DateTime.now().add(const Duration(days: 30));
              _currentUserProfile = _currentUserProfile!.copyWith(
                premiumExpiry: expiryDate.toIso8601String(),
              );
              final allLikedYouIds = _likedYouList.map((p) => p.uid).toList();
              _unlockedProfiles.addAll(allLikedYouIds);
            }
          });
        }
        break;
      default:
        break;
    }
  }

  void _showAdToUnlock(UserProfileData userToUnlock) {
    if (_rewardedAd != null && _isAdLoaded) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) { ad.dispose(); _loadRewardedAd(); },
        onAdFailedToShowFullScreenContent: (ad, error) { ad.dispose(); _loadRewardedAd(); },
      );
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
          final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
          if (currentUserUid == null) return;

          try {
            await FirebaseFirestore.instance.collection('users').doc(currentUserUid).update({
              'unlockedLikedProfiles': FieldValue.arrayUnion([userToUnlock.uid])
            });

            setState(() {
              _unlockedProfiles.add(userToUnlock.uid);
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile Unlocked!'), backgroundColor: Colors.green),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Something went wrong!'), backgroundColor: Colors.red),
              );
            }
          }
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad not ready yet. Please try again.'), backgroundColor: Colors.orange),
      );
      _loadRewardedAd();
    }
  }

  Future<void> _payWithDiamondsToUnlock(UserProfileData userToUnlock, int cost) async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) return;

    if (_localDiamondBalance < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You don't have enough diamonds!"), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUserUid).update({
        'diamonds': FieldValue.increment(-cost),
        'unlockedLikedProfiles': FieldValue.arrayUnion([userToUnlock.uid])
      });

      setState(() {
        _localDiamondBalance -= cost;
        _unlockedProfiles.add(userToUnlock.uid);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$cost diamonds used. Profile Unlocked!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.'), backgroundColor: Colors.red),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pack Activated Successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() {
        if (_currentUserProfile != null) {
          final expiryDate = DateTime.now().add(const Duration(days: 30));
          _currentUserProfile = _currentUserProfile!.copyWith(
            activeSubscriptions: {
              ..._currentUserProfile!.activeSubscriptions,
              '${packId}_expiry': expiryDate.toIso8601String(),
            },
          );
          
          if (packId == 'unlimited_likes') {
            final allLikedYouIds = _likedYouList.map((p) => p.uid).toList();
            _unlockedProfiles.addAll(allLikedYouIds);
          }
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase failed. You may not have enough diamonds.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleHeart(String userId) {
    setState(() {
      if (_likedProfiles.contains(userId)) {
        _likedProfiles.remove(userId);
      } else {
        _likedProfiles.add(userId);
      }
    });
  }

  Future<void> _handleDislike(UserProfileData user, int tabIndex) async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) return;

    try {
      if (tabIndex == 0) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .collection('matches')
            .doc(user.uid)
            .delete();

        setState(() {
          _matchesList.removeWhere((u) => u.uid == user.uid);
          _likedProfiles.remove(user.uid);
        });
      } else if (tabIndex == 1) {
        await FirebaseFirestore.instance.collection('users').doc(currentUserUid).update({
          'likes_sent': FieldValue.arrayRemove([user.uid])
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('likedBy')
            .doc(currentUserUid)
            .delete();

        setState(() {
          _yourLikesList.removeWhere((u) => u.uid == user.uid);
          _likedProfiles.remove(user.uid);
        });
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .collection('likedBy')
            .doc(user.uid)
            .delete();

        setState(() {
          _likedYouList.removeWhere((u) => u.uid == user.uid);
          _unlockedProfiles.remove(user.uid);
          _likedProfiles.remove(user.uid);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile removed'), backgroundColor: Colors.grey),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong!'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleMessageButton(UserProfileData receiverUser, int tabIndex) async {
    final bool isPremium = _currentUserProfile?.isPremiumActive() ?? false;
    final bool hasMessagePack = _currentUserProfile?.isSubscriptionActive('unlimited_messages') ?? false;

    if (isPremium || hasMessagePack) {
      _sendMessage(receiverUser);
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
      title: 'Send Message?',
      options: options,
      currentUserDiamondBalance: _localDiamondBalance,
    );

    if (selectedAction == null || !mounted) return;

    switch (selectedAction) {
      case MonetizationAction.watchAd:
        _showAdForMessage(() => _sendMessage(receiverUser));
        break;
      case MonetizationAction.payWithDiamonds:
        _payWithDiamondsForMessage(receiverUser, 7);
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
            const SnackBar(content: Text('Premium Activated Successfully!'), backgroundColor: Colors.green),
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

  Future<void> _sendMessage(UserProfileData receiverUser) async {
    final bool? messageSent = await showSendMessagePopup(
      context: context,
      receiverUser: receiverUser,
    );

    if (!mounted) return;

    if (messageSent == true) {
      widget.onMessageSent?.call();
    } else if (messageSent == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send message. Please try again.'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAdForMessage(VoidCallback onSuccess) {
    if (_rewardedAd != null && _isAdLoaded) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) { ad.dispose(); _loadRewardedAd(); },
        onAdFailedToShowFullScreenContent: (ad, error) { ad.dispose(); _loadRewardedAd(); },
      );
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) => onSuccess());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad not ready yet. Please try again.'), backgroundColor: Colors.orange),
      );
      _loadRewardedAd();
    }
  }

  Future<void> _payWithDiamondsForMessage(UserProfileData receiverUser, int cost) async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) return;

    if (_localDiamondBalance < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You don't have enough diamonds!"), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUserUid).update({
        'diamonds': FieldValue.increment(-cost),
      });

      setState(() {
        _localDiamondBalance -= cost;
      });

      _sendMessage(receiverUser);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong!'), backgroundColor: Colors.red),
      );
    }
  }
  
  // --- UI WIDGETS START FROM HERE (All UI Updates are Below) --- //

  @override
  Widget build(BuildContext context) {
    // THEME: Access theme data and custom colors once in the build method.
    final theme = Theme.of(context);
    
    return Scaffold(
      // UPDATED: Using scaffoldBackgroundColor from the central theme.
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        // NOTE: Ab style lagane ki zaroorat nahi. Yeh automatically
        // theme.appBarTheme.titleTextStyle se Anton font le lega.
        title: const Text('LIKES'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // UPDATED: Using dividerColor from the central theme.
          Container(height: 1.h, color: theme.dividerColor),
          _buildToggleButtons(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    // THEME: Access custom colors for custom components.
    final customColors = Theme.of(context).extension<CustomColors>()!;

    return Consumer<NewCountsProvider>(
      builder: (context, countsProvider, child) {
        final newMatches = countsProvider.newMatchesCount;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          decoration: BoxDecoration(
            // UPDATED: Using a custom surface color from the central theme.
            color: customColors.surface_2,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              _buildToggleButton("Matches", 0, count: newMatches),
              _buildToggleButton("Your Likes", 1),
              _buildToggleButton("Liked You", 2),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleButton(String title, int index, {int count = 0}) {
    final isSelected = _selectedTab == index;
    // THEME: Access theme data for dynamic styling.
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 0) {
            Provider.of<NewCountsProvider>(context, listen: false).resetMatchesCount();
          }
          if (index == 2) {
             Provider.of<NewCountsProvider>(context, listen: false).resetLikesCount();
          }
          setState(() => _selectedTab = index);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            // UPDATED: Using primary color for selection, transparent otherwise.
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                // UPDATED: Using a predefined text style and color from the theme.
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (count > 0)
                Positioned(
                  right: 8.w,
                  top: -5.h,
                  child: Container(
                    padding: EdgeInsets.all(5.w),
                    decoration: BoxDecoration(
                      // UPDATED: Using primary color for the notification badge.
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 18.w,
                      minHeight: 18.h,
                    ),
                    child: Text(
                      count.toString(),
                      // UPDATED: Using predefined text style and color for text on primary color.
                      style: theme.textTheme.labelSmall!.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    List<UserProfileData> currentList;
    String emptyMessage;
    // THEME: Access theme data for styling.
    final theme = Theme.of(context);

    switch (_selectedTab) {
      case 0:
        currentList = _matchesList;
        emptyMessage = 'No matches yet.\nKeep swiping!';
        break;
      case 1:
        currentList = _yourLikesList;
        emptyMessage = 'You haven\'t liked anyone yet.';
        break;
      case 2:
      default:
        currentList = _likedYouList;
        emptyMessage = 'No one has liked you yet.';
        break;
    }

    if (currentList.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          // UPDATED: Using text style and color from the central theme.
          style: theme.textTheme.bodyLarge!.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(12.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.7,
      ),
      itemCount: currentList.length,
      itemBuilder: (context, index) {
        final user = currentList[index];
        return _buildLikeCard(user, _selectedTab);
      },
    );
  }

  Widget _buildLikeCard(UserProfileData user, int tabIndex) {
    // THEME: Access theme and custom colors for detailed component styling.
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;
    
    final bool isPremium = _currentUserProfile?.isPremiumActive() ?? false;
    final bool hasLikesPack = _currentUserProfile?.isSubscriptionActive('unlimited_likes') ?? false;
    
    final bool isUnlocked = (tabIndex == 0 || tabIndex == 1) || 
                            isPremium || 
                            hasLikesPack || 
                            _unlockedProfiles.contains(user.uid);
    
    final bool isLiked = (tabIndex == 1) ? true : _likedProfiles.contains(user.uid);

    if (user.profileImageUrls.isEmpty) {
      return Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        // UPDATED: Using custom surface color from the theme.
        color: customColors.surface_2,
        child: Center(
          // UPDATED: Using a theme-appropriate color for the placeholder icon.
          child: Icon(Icons.person, size: 50.sp, color: Colors.grey.shade700),
        ),
      );
    }

    final imageUrl = '$r2PublicUrlBase/${user.profileImageUrls.first}_medium.webp';

    return GestureDetector(
      onTap: () => _handleProfileTap(user, tabIndex),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 6,
        // UPDATED: Using custom surface color from the theme.
        color: customColors.surface_2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: isUnlocked ? 0 : 10,
                sigmaY: isUnlocked ? 0 : 10,
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Center(
                  // UPDATED: Using a theme-appropriate color for the error icon.
                  child: Icon(Icons.broken_image, size: 50.sp, color: Colors.grey.shade700),
                ),
              ),
            ),

            if (!isUnlocked)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),

            if (isUnlocked)
              Positioned(
                top: 12.h,
                right: 12.w,
                child: GestureDetector(
                  onTap: () {
                    if (tabIndex != 1) { _toggleHeart(user.uid); }
                  },
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      // UPDATED: Using surface color from theme for a consistent look.
                      color: theme.colorScheme.surface.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      // UPDATED: Using custom "love" color and a standard grey from the theme.
                      color: isLiked ? customColors.love : Colors.grey.shade700,
                      size: 22.sp,
                    ),
                  ),
                ),
              ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [ Colors.transparent, Colors.black.withOpacity(0.8), ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isUnlocked)
                      Text(
                        '${user.name}, ${user.age}',
                        // UPDATED: Using text style and color from the theme.
                        style: theme.textTheme.titleMedium!.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    if (!isUnlocked)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // UPDATED: Icon color now comes from the theme.
                          Icon(Icons.lock, color: theme.colorScheme.onSurface, size: 16.sp),
                          SizedBox(width: 6.w),
                          Text(
                            'Liked You',
                            // UPDATED: Text style and color from the theme.
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                    if (isUnlocked) ...[
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _handleDislike(user, tabIndex),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                decoration: BoxDecoration(
                                  // UPDATED: Using custom surface color from theme.
                                  color: customColors.surface_2,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    // UPDATED: Using divider color from theme.
                                    color: theme.dividerColor,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.heart_broken,
                                  // UPDATED: Icon color from theme.
                                  color: theme.colorScheme.onSurface,
                                  size: 22.sp,
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(width: 8.w),
                          
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _handleMessageButton(user, tabIndex),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                decoration: BoxDecoration(
                                  // UPDATED: Using custom diamond blue color.
                                  color: customColors.diamondBlue,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  Icons.maps_ugc_outlined,
                                  // NOTE: White is kept here for good contrast on the bright blue.
                                  color: Colors.white,
                                  size: 22.sp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}