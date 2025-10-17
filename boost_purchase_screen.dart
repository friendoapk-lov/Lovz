// lib/screens/boost_purchase_screen.dart (PROFESSIONAL REDESIGN - THEME-BASED & RESPONSIVE)

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lovz/models/user_profile_model.dart';
import 'package:lovz/widgets/location_search_sheet.dart';
import 'package:lovz/screens/diamond_store_screen.dart';
import 'package:lovz/services/boost_service.dart';
import 'package:lovz/utils/theme.dart'; // For CustomColors

// ============================================
// BOOST PURCHASE SCREEN WIDGET
// ============================================
class BoostPurchaseScreen extends StatefulWidget {
  const BoostPurchaseScreen({Key? key}) : super(key: key);

  @override
  State<BoostPurchaseScreen> createState() => _BoostPurchaseScreenState();
}

// ============================================
// BOOST PURCHASE SCREEN STATE
// ============================================
class _BoostPurchaseScreenState extends State<BoostPurchaseScreen>
    with TickerProviderStateMixin {
  // ============================================
  // STATE VARIABLES (NO CHANGE)
  // ============================================
  UserProfileModel? _userProfile;
  bool _isLoading = true;

  // Boost location storage
  String? _selectedLocationName;
  GeoPoint? _selectedLocationGeoPoint;

  bool _isProcessing = false; // Purchase/Activation processing flag

  // Animation controllers for smooth effects
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  // ============================================
  // INIT STATE (ADDED ANIMATIONS)
  // ============================================
  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Pulse animation for activate button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Shimmer animation for cards
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  // ============================================
  // DISPOSE CONTROLLERS
  // ============================================
  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // ============================================
  // LOAD USER DATA FROM FIRESTORE (NO CHANGE)
  // ============================================
  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (docSnapshot.exists && mounted) {
        setState(() {
          _userProfile = UserProfileModel.fromMap(docSnapshot.data()!);
          _isLoading = false;
        });
      } else {
        throw Exception("User profile not found");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading data: $e")),
        );
      }
    }
  }

  // ============================================
  // PURCHASE BOOSTS FUNCTION (NO CHANGE)
  // ============================================
  Future<void> _purchaseBoosts(int boostAmount, int diamondCost) async {
    // Check if user has enough diamonds
    if (_userProfile!.diamonds < diamondCost) {
      _showInsufficientDiamondsDialog();
      return;
    }

    // Prevent multiple simultaneous purchases
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final success = await BoostService.purchaseBoosts(
      userId: _userProfile!.uid,
      diamondCost: diamondCost,
      boostAmount: boostAmount,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$boostAmount Boosts added successfully! ✨"),
            backgroundColor: Colors.green,
          ),
        );
        await _loadUserData(); // Refresh data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Purchase failed. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // ============================================
  // ACTIVATE BOOST FUNCTION (NO CHANGE)
  // ============================================
  Future<void> _activateBoost() async {
    // Basic validation
    if (_userProfile!.boostCount < 1) return;
    if (_selectedLocationGeoPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a location to boost your profile."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final success = await BoostService.activateBoost(
      userId: _userProfile!.uid,
      location: _selectedLocationGeoPoint!,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Success! Your profile is boosted in $_selectedLocationName for 30 minutes."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Close screen after activation
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Activation failed. You might not have enough boosts."),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // ============================================
  // PICK LOCATION FUNCTION (NO CHANGE)
  // ============================================
  Future<void> _pickLocation() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext context) {
        return const LocationSearchSheet();
      },
    );

    if (result != null &&
        result.containsKey('lat') &&
        result.containsKey('lng')) {
      if (mounted) {
        setState(() {
          _selectedLocationName = result['name'];
          _selectedLocationGeoPoint = GeoPoint(result['lat'], result['lng']);
        });
      }
    }
  }

  // ============================================
  // INSUFFICIENT DIAMONDS DIALOG (THEME-BASED)
  // ============================================
  void _showInsufficientDiamondsDialog() {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: customColors.surface_2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          "Insufficient Diamonds",
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 20.sp),
        ),
        content: Text(
          "You don't have enough diamonds to purchase this pack. Would you like to buy more?",
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 15.sp,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              "Cancel",
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 15.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: customColors.diamondBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            ),
            child: Text(
              "Get Diamonds",
              style: theme.textTheme.labelLarge?.copyWith(fontSize: 15.sp),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DiamondStoreScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================
  // MAIN BUILD METHOD (PROFESSIONAL & RESPONSIVE)
  // ============================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // === STANDARD APPBAR (THEME-BASED) ===
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rocket_launch, size: 24.sp),
            SizedBox(width: 8.w),
            const Text('BOOST'),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _userProfile == null
              ? Center(
                  child: Text(
                    "Could not load your data. Please try again.",
                    style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16.sp),
                  ),
                )
              : Column(
                  children: [
                    // === DIVIDER (THEME-BASED) ===
                    Container(
                      height: 1.h,
                      color: theme.dividerColor,
                    ),

                    // === SCROLLABLE CONTENT ===
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // === BALANCE SECTION (ANIMATED) ===
                            _buildBalanceSection(theme, customColors),
                            SizedBox(height: 32.h),

                            // === BUY BOOSTS TITLE ===
                            Text(
                              "BUY BOOSTS",
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontSize: 22.sp,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              "Get more profile views by buying boosts with your diamonds.",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 14.sp,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            SizedBox(height: 16.h),

                            // === BOOST PACKS (ANIMATED SHIMMER) ===
                            _buildPackCard(
                              theme: theme,
                              customColors: customColors,
                              boosts: 1,
                              diamonds: 49,
                              primaryColor: const Color(0xFFFF6B00),
                              secondaryColor: const Color(0xFFFF8C00),
                            ),
                            SizedBox(height: 12.h),
                            _buildPackCard(
                              theme: theme,
                              customColors: customColors,
                              boosts: 3,
                              diamonds: 130,
                              savings: "Save 12%",
                              primaryColor: const Color(0xFFFF1493),
                              secondaryColor: const Color(0xFFFF69B4),
                            ),
                            SizedBox(height: 12.h),
                            _buildPackCard(
                              theme: theme,
                              customColors: customColors,
                              boosts: 5,
                              diamonds: 200,
                              savings: "Best Value! Save 18%",
                              primaryColor: const Color(0xFF9C27B0),
                              secondaryColor: const Color(0xFFE91E63),
                            ),
                            SizedBox(height: 40.h),

                            // === DIVIDER (THEME-BASED) ===
                            Container(height: 1.h, color: theme.dividerColor),
                            SizedBox(height: 32.h),

                            // === ACTIVATE BOOST SECTION ===
                            Text(
                              "ACTIVATE A BOOST",
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontSize: 22.sp,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            _buildLocationSelector(theme, customColors),
                            SizedBox(height: 24.h),
                            _buildActivateBoostButton(theme, customColors),
                            SizedBox(height: 30.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  // ============================================
  // BALANCE SECTION (GLASS MORPHISM DESIGN)
  // ============================================
  Widget _buildBalanceSection(ThemeData theme, CustomColors customColors) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            customColors.surface_2!,
            customColors.surface_2!.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 20.r,
            spreadRadius: 2.r,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBalanceItem(
            theme: theme,
            icon: Icons.diamond,
            value: _userProfile!.diamonds.toString(),
            label: "Diamonds",
            iconColor: customColors.diamondBlue!,
          ),
          Container(
            height: 50.h,
            width: 1.w,
            color: theme.dividerColor,
          ),
          _buildBalanceItem(
            theme: theme,
            icon: Icons.rocket_launch,
            value: _userProfile!.boostCount.toString(),
            label: "Boosts Left",
            iconColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  // ============================================
  // BALANCE ITEM (THEME-BASED)
  // ============================================
  Widget _buildBalanceItem({
    required ThemeData theme,
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
  }) {
    return Column(
      children: [
        // Animated icon container
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, val, child) {
            return Transform.scale(
              scale: 0.8 + (val * 0.2),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 32.sp),
              ),
            );
          },
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 26.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13.sp,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  // ============================================
  // PACK CARD (ANIMATED SHIMMER GRADIENT)
  // ============================================
  Widget _buildPackCard({
    required ThemeData theme,
    required CustomColors customColors,
    required int boosts,
    required int diamonds,
    String? savings,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                _shimmerController.value - 0.3,
                _shimmerController.value,
              ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 15.r,
                spreadRadius: 2.r,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: _isProcessing ? null : () => _purchaseBoosts(boosts, diamonds),
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  children: [
                    // === ROCKET ICON (HERO ANIMATION) ===
                    Hero(
                      tag: 'boost_icon_$boosts',
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.rocket_launch_outlined,
                          color: Colors.white,
                          size: 32.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),

                    // === BOOST INFO ===
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$boosts Boost${boosts > 1 ? 's' : ''}",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 20.sp,
                              color: Colors.white,
                            ),
                          ),
                          if (savings != null) ...[
                            SizedBox(height: 4.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: Colors.greenAccent.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                savings,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),

                    // === DIAMOND COST ===
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "$diamonds",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 18.sp,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(Icons.diamond,
                              color: customColors.diamondBlue, size: 20.sp),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================
  // LOCATION SELECTOR (THEME-BASED)
  // ============================================
  Widget _buildLocationSelector(ThemeData theme, CustomColors customColors) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: customColors.surface_2,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _selectedLocationGeoPoint != null
              ? theme.colorScheme.primary
              : theme.dividerColor,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: _pickLocation,
        child: Row(
          children: [
            // === LOCATION ICON ===
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                color: theme.colorScheme.primary,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),

            // === LOCATION NAME ===
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Boost Location",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _selectedLocationName ?? "Select Location",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16.sp,
                      color: _selectedLocationName != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // === CHANGE BUTTON ===
            Text(
              "Change",
              style: theme.textTheme.labelLarge?.copyWith(
                color: customColors.locationSkyBlue,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // ACTIVATE BOOST BUTTON (PULSING ANIMATION)
  // ============================================
  Widget _buildActivateBoostButton(ThemeData theme, CustomColors customColors) {
    final bool canActivate =
        _userProfile!.boostCount > 0 && _selectedLocationGeoPoint != null;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = canActivate && !_isProcessing
            ? 1.0 + (_pulseController.value * 0.05)
            : 1.0;

        return Transform.scale(
          scale: pulseValue,
          child: Container(
            decoration: BoxDecoration(
              gradient: canActivate && !_isProcessing
                  ? LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: !canActivate || _isProcessing
                  ? theme.colorScheme.onSurface.withOpacity(0.2)
                  : null,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: canActivate && !_isProcessing
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        blurRadius: 20.r,
                        spreadRadius: 2.r,
                      ),
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: canActivate && !_isProcessing ? _activateBoost : null,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 18.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_isProcessing) ...[
                        Icon(Icons.rocket_launch,
                            color: canActivate
                                ? Colors.white
                                : theme.colorScheme.onSurface.withOpacity(0.4),
                            size: 24.sp),
                        SizedBox(width: 12.w),
                      ],
                      _isProcessing
                          ? SizedBox(
                              height: 24.h,
                              width: 24.w,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              "Activate Boost (${_userProfile!.boostCount} left)",
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontSize: 18.sp,
                                color: canActivate
                                    ? Colors.white
                                    : theme.colorScheme.onSurface
                                        .withOpacity(0.4),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}