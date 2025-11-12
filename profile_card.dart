// lib/screens/profile_card.dart (PROFESSIONAL DATING APP VERSION)

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovz/models/user_profile_data.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lovz/utils/theme.dart';
import 'dart:math' as math;

// ============================================
// SWIPE INDICATOR DATA CLASS (NO CHANGE)
// ============================================
class _SwipeIndicator {
  final IconData icon;
  final Color color;
  final String label;
  _SwipeIndicator(
      {required this.icon, required this.color, required this.label});
}

// ============================================
// PROFILE CARD WIDGET (RESPONSIVE)
// ============================================
class ProfileCard extends StatefulWidget {
  final UserProfileData user;
  final UserProfileData? currentUserProfile;
  final double percentThresholdX;
  final double percentThresholdY;

  const ProfileCard({
    super.key,
    required this.user,
    this.currentUserProfile,
    required this.percentThresholdX,
    required this.percentThresholdY,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

// ============================================
// PROFILE CARD STATE (RESPONSIVE)
// ============================================
class _ProfileCardState extends State<ProfileCard>
    with SingleTickerProviderStateMixin {
  int _currentImageIndex = 0;
  final DraggableScrollableController _scrollController =
      DraggableScrollableController();
  late AnimationController _borderAnimationController;
  late Animation<double> _borderAnimation;

  @override
  void initState() {
    super.initState();
    // Border glow animation
    _borderAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _borderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _borderAnimationController, curve: Curves.easeInOut),
    );
  }

  // ============================================
  // IMAGE URL HELPER (BACKWARD COMPATIBLE)
  // ============================================
  String _getImageUrl(String imageName) {
    const r2BaseUrl = 'https://pub-20b75325021441f58867571ca62aa1aa.r2.dev';

    if (imageName.contains('/')) {
      // New format: full path already stored
      return '$r2BaseUrl/$imageName';
    } else {
      // Old format: just filename (backward compatibility)
      return '$r2BaseUrl/${imageName}_medium.webp';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _borderAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Start animation when swiping
    if (widget.percentThresholdX.abs() > 15 ||
        widget.percentThresholdY.abs() > 15) {
      if (!_borderAnimationController.isAnimating) {
        _borderAnimationController.repeat(reverse: true);
      }
    } else {
      _borderAnimationController.stop();
      _borderAnimationController.reset();
    }
  }

  // ============================================
  // DISTANCE CALCULATION (NO CHANGE)
  // ============================================
  String _getDistance() {
    final currentUserLocation = widget.currentUserProfile?.location;
    final otherUserLocation = widget.user.location;
    if (currentUserLocation != null && otherUserLocation != null) {
      final distanceInMeters = Geolocator.distanceBetween(
          currentUserLocation.latitude,
          currentUserLocation.longitude,
          otherUserLocation.latitude,
          otherUserLocation.longitude);
      final distanceInKm = distanceInMeters / 1000;
      if (distanceInKm < 0.1) return "Nearby";
      return "${distanceInKm.toStringAsFixed(1)} km away";
    }
    return "";
  }

  // ============================================
  // MAIN BUILD METHOD (RESPONSIVE + THEME-BASED)
  // ============================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;
    final indicator = _getSwipeIndicator(theme, customColors);

    return AnimatedBuilder(
      animation: _borderAnimation,
      builder: (context, child) {
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              // Animated border glow effect
              if (indicator != null)
                BoxShadow(
                  color: indicator.color
                      .withOpacity(0.3 + (_borderAnimation.value * 0.4)),
                  spreadRadius: 4.r + (_borderAnimation.value * 8.r),
                  blurRadius: 20.r + (_borderAnimation.value * 15.r),
                ),
              // Standard depth shadow
              BoxShadow(
                color: theme.scaffoldBackgroundColor.withOpacity(0.3),
                spreadRadius: 1.r,
                blurRadius: 10.r,
              )
            ],
            // Animated border
            border: indicator != null
                ? Border.all(
                    color: indicator.color
                        .withOpacity(0.4 + (_borderAnimation.value * 0.4)),
                    width: 2 + (_borderAnimation.value * 2),
                  )
                : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Layer 1: Image with Progress Bars
              _buildImageSection(theme, customColors),

              // Layer 2: Draggable Details Sheet
              _buildDraggableDetailsSheet(theme, customColors),

              // Layer 3: Swipe Indicator with Label (IMPROVED)
              if (indicator != null)
                Center(
                  child: Opacity(
                    opacity: _getSwipeOpacity().clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 1.0 + (_getSwipeOpacity() * 0.3),
                      child: Transform.rotate(
                        angle: _getSwipeRotation(),
                        child: Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: indicator.color.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: indicator.color,
                              width: 4,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                indicator.icon,
                                color: indicator.color,
                                size: 80.sp,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                indicator.label,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: indicator.color,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Layer 4: Corner Labels (Professional touch)
              if (indicator != null)
                Positioned(
                  top: 40.h,
                  left: indicator.label == "NOPE" ? 30.w : null,
                  right: indicator.label == "LIKE" ? 30.w : null,
                  child: Transform.rotate(
                    angle: indicator.label == "NOPE" ? -0.3 : 0.3,
                    child: Opacity(
                      opacity: _getSwipeOpacity().clamp(0.0, 0.9),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          border: Border.all(color: indicator.color, width: 4),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          indicator.label,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontSize: 32.sp,
                            color: indicator.color,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ============================================
  // IMAGE SECTION (RESPONSIVE + THEME-BASED)
  // ============================================
  Widget _buildImageSection(ThemeData theme, CustomColors customColors) {
    final imageList = widget.user.profileImageUrls.isNotEmpty
        ? widget.user.profileImageUrls
        : ['placeholder'];

    return Stack(
      fit: StackFit.expand,
      children: [
        // === IMAGE DISPLAY ===
        (imageList.first != 'placeholder')
            ? CachedNetworkImage(
                imageUrl: _getImageUrl(imageList[_currentImageIndex]),
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: customColors.surface_2,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: customColors.surface_2,
                  child: Icon(
                    Icons.error,
                    color: theme.colorScheme.error,
                    size: 50.sp,
                  ),
                ),
              )
            : Container(
                color: customColors.surface_2,
                child: Center(
                  child: Icon(
                    Icons.person,
                    size: 100.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ),

        // === PROGRESS BARS (THEME-BASED) ===
        if (imageList.length > 1)
          Positioned(
            top: 15.h,
            left: 10.w,
            right: 10.w,
            child: Row(
              children: List.generate(imageList.length, (index) {
                return Expanded(
                  child: Container(
                    height: 3.5.h,
                    margin: EdgeInsets.symmetric(horizontal: 2.w),
                    decoration: BoxDecoration(
                      color: _currentImageIndex == index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2.r),
                      boxShadow: [
                        BoxShadow(
                          color: theme.scaffoldBackgroundColor.withOpacity(0.6),
                          blurRadius: 3.r,
                        )
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

        // === LEFT/RIGHT TAP ZONES (NO CHANGE IN LOGIC) ===
        if (imageList.length > 1)
          Row(
            children: [
              // Left Half - Previous Image
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_currentImageIndex > 0) {
                      setState(() {
                        _currentImageIndex--;
                      });
                    }
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
              // Right Half - Next Image
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_currentImageIndex < imageList.length - 1) {
                      setState(() {
                        _currentImageIndex++;
                      });
                    }
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ============================================
  // DRAGGABLE DETAILS SHEET (THEME-BASED - NO LOGIC CHANGE)
  // ============================================
  Widget _buildDraggableDetailsSheet(
      ThemeData theme, CustomColors customColors) {
    return DraggableScrollableSheet(
      controller: _scrollController,
      initialChildSize: 0.25,
      minChildSize: 0.25,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                theme.scaffoldBackgroundColor.withOpacity(0.95)
              ],
              stops: const [0.0, 0.3],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                // === HEADER SECTION (TAPPABLE - NO LOGIC CHANGE) ===
                GestureDetector(
                  onTap: () {
                    if (_scrollController.size < 0.8) {
                      _scrollController.animateTo(
                        0.85,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    } else {
                      _scrollController.animateTo(
                        0.25,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    color: Colors.transparent,
                    padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 15.h),
                    child: _buildHeaderContent(theme, customColors),
                  ),
                ),

                // === DETAILS SECTION ===
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 40.h),
                  child: _buildScrollableDetails(theme, customColors),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================
  // HEADER CONTENT (THEME-BASED)
  // ============================================
  Widget _buildHeaderContent(ThemeData theme, CustomColors customColors) {
    final distanceText = _getDistance();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === NAME AND AGE ===
        Text(
          '${widget.user.name}, ${widget.user.age}',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(blurRadius: 8, color: Colors.black87),
            ],
          ),
        ),

        // === LOCATION AND ARROW ===
        if (distanceText.isNotEmpty) ...[
          SizedBox(height: 5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Location
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: customColors.locationSkyBlue,
                    size: 18.sp,
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    distanceText,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: customColors.locationSkyBlue,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      shadows: const [
                        Shadow(blurRadius: 8, color: Colors.black87)
                      ],
                    ),
                  ),
                ],
              ),
              // Down Arrow (Indicator to expand)
              Icon(
                Icons.keyboard_arrow_down,
                color: theme.colorScheme.primary,
                size: 36.sp,
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ============================================
  // SCROLLABLE DETAILS SECTION (THEME-BASED)
  // ============================================
  Widget _buildScrollableDetails(ThemeData theme, CustomColors customColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === ABOUT ME ===
        if (widget.user.aboutMe.isNotEmpty) ...[
          _buildDetailRow(theme, "About Me", widget.user.aboutMe),
          SizedBox(height: 16.h),
          Container(height: 1.h, color: theme.dividerColor),
          SizedBox(height: 16.h),
        ],

        // === INFO TILES ===
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            if (widget.user.basicGender.isNotEmpty)
              _buildInfoTile(
                theme,
                customColors,
                icon: Icons.wc,
                text: widget.user.basicGender.join(', '),
              ),
            if (widget.user.basicOrientation.isNotEmpty)
              _buildInfoTile(
                theme,
                customColors,
                icon: Icons.favorite_border,
                text: widget.user.basicOrientation.join(', '),
              ),
            if (widget.user.jobTitle.isNotEmpty)
              _buildInfoTile(
                theme,
                customColors,
                icon: Icons.work_outline,
                text: widget.user.jobTitle,
              ),
            if (widget.user.drinkingHabit.isNotEmpty)
              _buildInfoTile(
                theme,
                customColors,
                icon: Icons.local_bar_outlined,
                text: widget.user.drinkingHabit,
              ),
            if (widget.user.smokingHabit.isNotEmpty)
              _buildInfoTile(
                theme,
                customColors,
                icon: Icons.smoking_rooms,
                text: widget.user.smokingHabit,
              ),
          ],
        ),

        // === INTERESTS ===
        if (widget.user.interests.isNotEmpty) ...[
          SizedBox(height: 16.h),
          Container(height: 1.h, color: theme.dividerColor),
          SizedBox(height: 16.h),
          _buildDetailRow(theme, "Interests", widget.user.interests.join(', ')),
        ],
      ],
    );
  }

  // ============================================
  // DETAIL ROW (THEME-BASED)
  // ============================================
  Widget _buildDetailRow(ThemeData theme, String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 16.sp,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ============================================
  // INFO TILE (THEME-BASED)
  // ============================================
  Widget _buildInfoTile(
    ThemeData theme,
    CustomColors customColors, {
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 8.h,
        horizontal: 12.w,
      ),
      decoration: BoxDecoration(
        color: customColors.surface_2?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: theme.dividerColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // SWIPE INDICATOR LOGIC (IMPROVED - THEME-BASED)
  // ============================================
  _SwipeIndicator? _getSwipeIndicator(
      ThemeData theme, CustomColors customColors) {
    final percentX = widget.percentThresholdX;
    final percentY = widget.percentThresholdY;

    if (percentY < -20) {
      return _SwipeIndicator(
        icon: Icons.star_rounded,
        color: const Color(0xFF9C27B0), // Purple for superlike
        label: "SUPER",
      );
    }
    if (percentX > 20) {
      return _SwipeIndicator(
        icon: Icons.favorite_rounded,
        color: theme.colorScheme.primary,
        label: "LIKE",
      );
    }
    if (percentX < -20) {
      return _SwipeIndicator(
        icon: Icons.heart_broken_rounded, // HEARTBREAK ICON!
        color: theme.colorScheme.onSurface.withOpacity(0.5),
        label: "NOPE",
      );
    }
    return null;
  }

  // ============================================
  // SWIPE OPACITY (NO CHANGE)
  // ============================================
  double _getSwipeOpacity() {
    final percentX = widget.percentThresholdX.abs();
    final percentY = widget.percentThresholdY.abs();
    return math.max(percentX, percentY) / 100;
  }

  // ============================================
  // SWIPE ROTATION (NO CHANGE)
  // ============================================
  double _getSwipeRotation() {
    return widget.percentThresholdX / 100 * -0.2;
  }
}
