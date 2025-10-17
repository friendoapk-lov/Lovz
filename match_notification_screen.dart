import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovz/models/user_profile_data.dart';
import 'package:lovz/widgets/message_popup.dart';

class MatchNotificationScreen extends StatefulWidget {
  final UserProfileData currentUserProfile;
  final UserProfileData matchedUser;

  const MatchNotificationScreen({
    super.key,
    required this.currentUserProfile,
    required this.matchedUser,
  });

  @override
  State<MatchNotificationScreen> createState() => _MatchNotificationScreenState();
}

class _MatchNotificationScreenState extends State<MatchNotificationScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _heartController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation for avatars
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Fade animation for text
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Slide animation for buttons
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Heart beat animation
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Start all animations
    _scaleController.forward();
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
    _heartController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const String r2PublicUrlBase = "https://pub-20b75325021441f58867571ca62aa1aa.r2.dev";

    // Matched user ki image URL
    final matchedUserImageUrl = widget.matchedUser.profileImageUrls.isNotEmpty
        ? '$r2PublicUrlBase/${widget.matchedUser.profileImageUrls.first}_thumb.webp'
        : null;

    // Current user ki image URL
    final currentUserImageUrl = widget.currentUserProfile.profileImageUrls.isNotEmpty
        ? '$r2PublicUrlBase/${widget.currentUserProfile.profileImageUrls.first}_thumb.webp'
        : null;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.3),
              theme.scaffoldBackgroundColor,
              theme.colorScheme.primary.withOpacity(0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // === FLOATING HEARTS BACKGROUND ===
              ..._buildFloatingHearts(theme),

              // === MAIN CONTENT ===
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // === ANIMATED TITLE ===
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 60.sp,
                              color: theme.colorScheme.primary,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              "It's a Match!",
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontSize: 48.sp,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                letterSpacing: 2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // === SUBTITLE TEXT ===
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          "You and ${widget.matchedUser.name} have liked each other.",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 18.sp,
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 50.h),

                      // === ANIMATED AVATARS WITH HEART ===
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Current User Avatar
                                _buildAnimatedAvatar(
                                  currentUserImageUrl,
                                  theme,
                                  isLeft: true,
                                ),
                                SizedBox(width: 80.w), // Space for center heart
                                // Matched User Avatar
                                _buildAnimatedAvatar(
                                  matchedUserImageUrl,
                                  theme,
                                  isLeft: false,
                                ),
                              ],
                            ),

                            // === CENTER HEART ICON ===
                            Positioned(
                              child: AnimatedBuilder(
                                animation: _heartController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1.0 + (_heartController.value * 0.2),
                                    child: Container(
                                      padding: EdgeInsets.all(12.w),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.colorScheme.primary.withOpacity(0.4),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.favorite,
                                        color: theme.colorScheme.onPrimary,
                                        size: 32.sp,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 60.h),

                      // === ANIMATED BUTTONS ===
                      SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            // === SEND MESSAGE BUTTON ===
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final bool? messageSent = await showSendMessagePopup(
                                    context: context,
                                    receiverUser: widget.matchedUser,
                                  );

                                  if (!context.mounted) return;

                                  if (messageSent == true) {
                                    Navigator.of(context).pop(true);
                                  } else if (messageSent == false) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Could not send message. Please try again.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.onSurface,
                                  foregroundColor: theme.colorScheme.surface,
                                  padding: EdgeInsets.symmetric(vertical: 18.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.r),
                                  ),
                                  elevation: 8,
                                  shadowColor: theme.colorScheme.onSurface.withOpacity(0.4),
                                  textStyle: theme.textTheme.labelLarge?.copyWith(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                child: const Text("SEND A MESSAGE"),
                              ),
                            ),
                            SizedBox(height: 16.h),

                            // === KEEP SWIPING BUTTON ===
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface.withOpacity(0.6),
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                              ),
                              child: Text(
                                "KEEP SWIPING",
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontSize: 16.sp,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === HELPER: Build Animated Avatar ===
  Widget _buildAnimatedAvatar(String? imageUrl, ThemeData theme, {required bool isLeft}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 70.r,
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
        backgroundColor: theme.colorScheme.surface,
        child: imageUrl == null
            ? Icon(
                Icons.person,
                size: 60.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              )
            : null,
      ),
    );
  }

  // === HELPER: Build Floating Hearts ===
  List<Widget> _buildFloatingHearts(ThemeData theme) {
    return List.generate(8, (index) {
      return Positioned(
        left: (index * 50.w) % 350.w,
        top: (index * 80.h) % 600.h,
        child: TweenAnimationBuilder(
          duration: Duration(milliseconds: 2000 + (index * 200)),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(0, -value * 100.h),
              child: Opacity(
                opacity: (1 - value).clamp(0.0, 0.5),
                child: Icon(
                  Icons.favorite,
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  size: (20 + (index * 4)).sp,
                ),
              ),
            );
          },
          onEnd: () {
            if (mounted) setState(() {});
          },
        ),
      );
    });
  }
}