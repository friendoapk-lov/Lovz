import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lovz/models/user_profile_data.dart';
import 'package:provider/provider.dart';
import 'package:lovz/providers/new_counts_provider.dart';
import 'package:lovz/helpers/monetization_helper.dart';
import 'package:lovz/widgets/monetization_popup.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lovz/services/subscription_service.dart';
import 'package:lovz/screens/premium_plans_screen.dart';
import 'package:lovz/widgets/message_popup.dart';
import 'package:lovz/utils/theme.dart'; // THEME: Custom theme file import kiya gaya

class CrushScreen extends StatefulWidget {
  final int currentUserDiamondBalance;
  final VoidCallback onMessageSent;

  const CrushScreen({
    super.key,
    required this.currentUserDiamondBalance,
    required this.onMessageSent,
  });

  @override
  State<CrushScreen> createState() => _CrushScreenState();
}

class _CrushScreenState extends State<CrushScreen> {
  // === STATE VARIABLES (No Change) ===
  UserProfileData? _currentUserProfile;
  bool _isLoading = true;
  List<UserProfileData> _crushedYouList = [];
  List<UserProfileData> _yourCrushesList = [];
  int _selectedTab = 1;
  final Set<String> _unlockedProfiles = {};
  final Set<String> _likedCrushes = {};
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  late int _localDiamondBalance;
  
  final String r2PublicUrlBase = "https://pub-20b75325021441f58867571ca62aa1aa.r2.dev";
  final String _adUnitId = "ca-app-pub-3940256099942544/5224354917"; // Test Ad ID

  @override
  void initState() {
    super.initState();
    _localDiamondBalance = widget.currentUserDiamondBalance;
    _loadRewardedAd();
    _fetchData();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NewCountsProvider>(context, listen: false).resetCrushesCount();
    });
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  // --- LOGIC FUNCTIONS (No UI Changes Here) --- //
  // Niche ke saare functions (_loadRewardedAd se lekar _payWithDiamondsForMessage tak)
  // waise ke waise hi rakhe gaye hain kyunki yeh sirf logic handle karte hain, UI nahi.

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
      final unlockedIds = List<String>.from(currentUserDoc.data()?['unlockedCrushProfiles'] ?? []);
      
      if (mounted) {
        setState(() {
          _unlockedProfiles.addAll(unlockedIds);
        });
      }

      final crushedYouSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .collection('crushesMe')
          .orderBy('timestamp', descending: true)
          .get();

      List<UserProfileData> crushedYouProfiles = [];
      if (crushedYouSnapshot.docs.isNotEmpty) {
        final crushedYouUserIds = crushedYouSnapshot.docs.map((doc) => doc.id).toList();
        final crushedYouProfilesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: crushedYouUserIds)
            .get();
        
        crushedYouProfiles = crushedYouProfilesSnapshot.docs
            .map((doc) => UserProfileData.fromFirestore(doc))
            .toList();
      }

      final crushesSentList = currentUserData.crushesSent;
      List<UserProfileData> yourCrushesProfiles = [];
      
      if (crushesSentList.isNotEmpty) {
        final batches = <List<String>>[];
        for (var i = 0; i < crushesSentList.length; i += 10) {
          batches.add(
            crushesSentList.sublist(
              i,
              i + 10 > crushesSentList.length ? crushesSentList.length : i + 10,
            ),
          );
        }

        for (var batch in batches) {
          final batchSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get();
          
          yourCrushesProfiles.addAll(
            batchSnapshot.docs.map((doc) => UserProfileData.fromFirestore(doc)).toList(),
          );
        }
      }

      if (mounted) {
        setState(() {
          _currentUserProfile = currentUserData;
          _crushedYouList = crushedYouProfiles;
          _yourCrushesList = yourCrushesProfiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleProfileTap(UserProfileData tappedUser, bool isYourCrush) async {
    final bool isPremium = _currentUserProfile?.isPremiumActive() ?? false;
    final bool hasCrushPack = _currentUserProfile?.isSubscriptionActive('unlimited_crushes') ?? false;
    
    final bool isUnlocked = isYourCrush || 
                            isPremium || 
                            hasCrushPack || 
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
        subtitle: 'Use your diamonds to see this profile',
        icon: Icons.lock_open_rounded,
        action: MonetizationAction.payWithDiamonds,
        diamondCost: 10,
        color: Colors.blueAccent,
      ),
      MonetizationOption(
        title: 'Unlimited Crushes',
        subtitle: 'Get a monthly pack for unlimited reveals',
        icon: Icons.all_inclusive_rounded,
        action: MonetizationAction.buySubscriptionCrush,
        diamondCost: 199,
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
      title: 'Reveal this Crush?',
      options: options,
      currentUserDiamondBalance: _localDiamondBalance,
    );

    if (selectedAction == null || !mounted) return;

    switch (selectedAction) {
      case MonetizationAction.watchAd:
        _showAdToUnlock(tappedUser);
        break;
      case MonetizationAction.payWithDiamonds:
        _payWithDiamondsToUnlock(tappedUser, 10);
        break;
      case MonetizationAction.buySubscriptionCrush:
        _handleSubscriptionPurchase('unlimited_crushes', 199);
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
              final allCrushedYouIds = _crushedYouList.map((p) => p.uid).toList();
              _unlockedProfiles.addAll(allCrushedYouIds);
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
              'unlockedCrushProfiles': FieldValue.arrayUnion([userToUnlock.uid])
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
        'unlockedCrushProfiles': FieldValue.arrayUnion([userToUnlock.uid])
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
          content: Text('Pack Activated Successfully! All crushes in this list are now unlocked.'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        final allCrushedYouIds = _crushedYouList.map((p) => p.uid).toList();
        _unlockedProfiles.addAll(allCrushedYouIds);
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
      if (_likedCrushes.contains(userId)) {
        _likedCrushes.remove(userId);
      } else {
        _likedCrushes.add(userId);
      }
    });
  }

  Future<void> _handleDislike(UserProfileData user, bool isYourCrush) async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) return;

    try {
      if (isYourCrush) {
        await FirebaseFirestore.instance.collection('users').doc(currentUserUid).update({
          'crushes_sent': FieldValue.arrayRemove([user.uid])
        });
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('crushesMe')
            .doc(currentUserUid)
            .delete();

        setState(() {
          _yourCrushesList.removeWhere((u) => u.uid == user.uid);
          _likedCrushes.remove(user.uid);
        });
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .collection('crushesMe')
            .doc(user.uid)
            .delete();

        setState(() {
          _crushedYouList.removeWhere((u) => u.uid == user.uid);
          _unlockedProfiles.remove(user.uid);
          _likedCrushes.remove(user.uid);
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

  Future<void> _handleMessageButton(UserProfileData receiverUser, bool isYourCrush) async {
    final bool isPremium = _currentUserProfile?.isPremiumActive() ?? false;
    final bool hasMessagePack = _currentUserProfile?.isSubscriptionActive('unlimited_messages') ?? false;

    if (!isPremium && !hasMessagePack) {
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
      return;
    }
    _sendMessage(receiverUser);
  }

  Future<void> _sendMessage(UserProfileData receiverUser) async {
    final bool? messageSent = await showSendMessagePopup(
      context: context,
      receiverUser: receiverUser,
    );

    if (!mounted) return;

    if (messageSent == true) {
      widget.onMessageSent();
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
  
  // --- UI WIDGETS START FROM HERE (Saare UI Updates Niche Hain) --- //

  @override
  Widget build(BuildContext context) {
    // THEME: Theme data aur custom colors ko ek baar build method me access karna.
    final theme = Theme.of(context);
    
    return Scaffold(
      // UPDATED: Ab scaffoldBackgroundColor aam theme se aa raha hai.
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        // NOTE: Ab style lagane ki zaroorat nahi. Yeh aam taur par
        // theme.appBarTheme.titleTextStyle se Anton font le lega.
        title: const Text('CRUSH'),
        centerTitle: true,
      ),
      body: Column(
        children: [
           // UPDATED: Ab dividerColor aam theme se aa raha hai.
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
    // THEME: Custom components ke liye custom colors ka istemal.
    final customColors = Theme.of(context).extension<CustomColors>()!;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        // UPDATED: Aam theme se custom surface color ka istemal.
        color: customColors.surface_2,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          _buildToggleButton("Your Crushes", 0),
          _buildToggleButton("Crushed You", 1),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String title, int index) {
    final isSelected = _selectedTab == index;
    // THEME: Dynamic styling ke liye theme data ka istemal.
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            // UPDATED: Selection ke liye primary color, anyatha transparent.
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            // UPDATED: Aam theme se ek pehle se tay text style aur color ka istemal.
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final currentList = _selectedTab == 0 ? _yourCrushesList : _crushedYouList;
    final isYourCrushTab = _selectedTab == 0;
    // THEME: Styling ke liye theme data ka istemal.
    final theme = Theme.of(context);

    if (currentList.isEmpty) {
      return Center(
        child: Text(
          isYourCrushTab 
              ? 'You haven\'t sent any crushes yet.' 
              : 'No one has crushed you yet.',
          textAlign: TextAlign.center,
          // UPDATED: Aam theme se text style aur color ka istemal.
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
        return _buildCrushCard(user, isYourCrushTab);
      },
    );
  }

  Widget _buildCrushCard(UserProfileData user, bool isYourCrush) {
    // THEME: Detailed component styling ke liye theme aur custom colors ka istemal.
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;
    
    final bool isPremium = _currentUserProfile?.isPremiumActive() ?? false;
    final bool hasCrushPack = _currentUserProfile?.isSubscriptionActive('unlimited_crushes') ?? false;
    final bool isUnlocked = isYourCrush || isPremium || hasCrushPack || _unlockedProfiles.contains(user.uid);
    final bool isLiked = _likedCrushes.contains(user.uid);

    if (user.profileImageUrls.isEmpty) {
      return Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        // UPDATED: Theme se custom surface color ka istemal.
        color: customColors.surface_2,
        child: Center(
          // UPDATED: Placeholder icon ke liye theme-appropriate color ka istemal.
          child: Icon(Icons.person, size: 50.sp, color: Colors.grey.shade700),
        ),
      );
    }

    final imageUrl = '$r2PublicUrlBase/${user.profileImageUrls.first}_medium.webp';

    return GestureDetector(
      onTap: () => _handleProfileTap(user, isYourCrush),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 6,
        // UPDATED: Theme se custom surface color ka istemal.
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
                  // UPDATED: Error icon ke liye theme-appropriate color ka istemal.
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
                  onTap: () => _toggleHeart(user.uid),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      // UPDATED: Consistent look ke liye theme se surface color ka istemal.
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
                      // UPDATED: Custom "love" color aur theme se aam grey color ka istemal.
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
                        // UPDATED: Theme se text style aur color ka istemal.
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
                          // UPDATED: Icon ka color ab theme se aa raha hai.
                          Icon(Icons.lock, color: theme.colorScheme.onSurface, size: 16.sp),
                          SizedBox(width: 6.w),
                          Text(
                            'Crushed You',
                            // UPDATED: Theme se text style aur color ka istemal.
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
                              onTap: () => _handleDislike(user, isYourCrush),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                decoration: BoxDecoration(
                                  // UPDATED: Theme se custom surface color ka istemal.
                                  color: customColors.surface_2,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    // UPDATED: Theme se divider color ka istemal.
                                    color: theme.dividerColor,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.heart_broken,
                                  // UPDATED: Theme se icon color ka istemal.
                                  color: theme.colorScheme.onSurface,
                                  size: 22.sp,
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(width: 8.w),
                          
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _handleMessageButton(user, isYourCrush),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                decoration: BoxDecoration(
                                  // UPDATED: Custom diamond blue color ka istemal.
                                  color: customColors.diamondBlue,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  Icons.maps_ugc_outlined,
                                  // NOTE: White yahan rakha gaya hai taaki bright blue par achha contrast mile.
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