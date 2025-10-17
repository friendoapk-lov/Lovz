// lib/screens/premium_plans_screen.dart (ULTRA PROFESSIONAL VERSION)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovz/services/subscription_service.dart';
import 'package:lovz/utils/theme.dart';

// ============================================
// PLAN MODEL (SAME HAI - NO CHANGE)
// ============================================
class PremiumPlan {
  final String title;
  final String monthlyPrice;
  final String totalPrice;
  final String? discount;
  final int diamondCost;
  final int durationInDays;
  final bool isPopular;

  const PremiumPlan({
    required this.title,
    required this.monthlyPrice,
    required this.totalPrice,
    this.discount,
    required this.diamondCost,
    required this.durationInDays,
    this.isPopular = false,
  });
}

class PremiumPlansScreen extends StatefulWidget {
  const PremiumPlansScreen({super.key});

  @override
  State<PremiumPlansScreen> createState() => _PremiumPlansScreenState();
}

class _PremiumPlansScreenState extends State<PremiumPlansScreen>
    with TickerProviderStateMixin {
  // ============================================
  // PLANS DATA (SAME + POPULAR TAG)
  // ============================================
  final List<PremiumPlan> _plans = const [
    PremiumPlan(
      title: '12 Months',
      monthlyPrice: '₹333/month',
      totalPrice: '3,999',
      discount: 'SAVE 33%',
      diamondCost: 3999,
      durationInDays: 365,
      isPopular: true,
    ),
    PremiumPlan(
      title: '6 Months',
      monthlyPrice: '₹400/month',
      totalPrice: '2,399',
      discount: 'SAVE 20%',
      diamondCost: 2399,
      durationInDays: 180,
      isPopular: false,
    ),
    PremiumPlan(
      title: '3 Months',
      monthlyPrice: '₹433/month',
      totalPrice: '1,299',
      discount: 'SAVE 13%',
      diamondCost: 1299,
      durationInDays: 90,
      isPopular: false,
    ),
    PremiumPlan(
      title: '1 Month',
      monthlyPrice: '',
      totalPrice: '499',
      diamondCost: 499,
      durationInDays: 30,
      isPopular: false,
    ),
  ];

  int _selectedIndex = 0;
  bool _isProcessing = false;

  // Animation controllers
  late AnimationController _crownController;
  late AnimationController _shineController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _sparkleController;

  late Animation<double> _crownRotation;
  late Animation<double> _crownScale;
  late Animation<double> _shineAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Crown animation - rotation + scale
    _crownController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _crownRotation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _crownController, curve: Curves.easeInOut),
    );

    _crownScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _crownController, curve: Curves.easeInOut),
    );

    // Shine effect animation
    _shineController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _shineAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shineController, curve: Curves.easeInOut),
    );

    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Slide up animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Sparkle animation
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _crownController.dispose();
    _shineController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  // ============================================
  // PURCHASE LOGIC (SAME HAI - NO CHANGE)
  // ============================================
  Future<void> _handlePurchase() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: You are not logged in.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    final selectedPlan = _plans[_selectedIndex];

    final bool success = await SubscriptionService.purchasePremiumSubscription(
      userId: currentUserUid,
      cost: selectedPlan.diamondCost,
      durationInDays: selectedPlan.durationInDays,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase failed. Not enough diamonds.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isProcessing = false;
    });
  }

  // ============================================
  // MAIN BUILD
  // ============================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.15),
              theme.scaffoldBackgroundColor,
              theme.colorScheme.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Floating sparkles background
              ..._buildFloatingSparkles(theme),

              // Main content
              Column(
                children: [
                  _buildHeader(theme),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Column(
                          children: [
                            SizedBox(height: 20.h),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildHeroSection(theme, customColors),
                            ),
                            SizedBox(height: 32.h),
                            SlideTransition(
                              position: _slideAnimation,
                              child: _buildBenefitsSection(theme, customColors),
                            ),
                            SizedBox(height: 32.h),
                            SlideTransition(
                              position: _slideAnimation,
                              child: _buildPlansSection(theme, customColors),
                            ),
                            SizedBox(height: 24.h),
                            SlideTransition(
                              position: _slideAnimation,
                              child: _buildContinueButton(theme),
                            ),
                            SizedBox(height: 20.h),
                            _buildFooterText(theme),
                            SizedBox(height: 20.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // FLOATING SPARKLES
  // ============================================
  List<Widget> _buildFloatingSparkles(ThemeData theme) {
    return List.generate(12, (index) {
      return Positioned(
        left: (index * 35.w) % 350.w,
        top: (index * 70.h) % 700.h,
        child: AnimatedBuilder(
          animation: _sparkleController,
          builder: (context, child) {
            final delay = (index * 0.1) % 1.0;
            final animValue = (_sparkleController.value + delay) % 1.0;
            return Transform.translate(
              offset: Offset(0, -animValue * 100.h),
              child: Opacity(
                opacity: (1 - animValue).clamp(0.0, 0.3),
                child: Icon(
                  index % 3 == 0
                      ? Icons.star_rounded
                      : index % 3 == 1
                          ? Icons.diamond_rounded
                          : Icons.favorite_rounded,
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  size: (12 + (index * 2)).sp,
                ),
              ),
            );
          },
        ),
      );
    });
  }

  // ============================================
  // HEADER
  // ============================================
  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: theme.colorScheme.onSurface,
              size: 28.sp,
            ),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ============================================
  // HERO SECTION
  // ============================================
  Widget _buildHeroSection(ThemeData theme, CustomColors customColors) {
    return Column(
      children: [
        // Animated crown with rotating shine effect
        AnimatedBuilder(
          animation: Listenable.merge([_crownRotation, _crownScale]),
          builder: (context, child) {
            return Transform.rotate(
              angle: _crownRotation.value,
              child: Transform.scale(
                scale: _crownScale.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulsating glow
                    Container(
                      width: 100.w,
                      height: 100.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.5),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    // Crown icon
                    Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        size: 52.sp,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    // Shine effect
                    AnimatedBuilder(
                      animation: _shineAnimation,
                      builder: (context, child) {
                        return ClipOval(
                          child: Container(
                            width: 100.w,
                            height: 100.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.transparent,
                                  theme.colorScheme.onPrimary.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                                stops: [
                                  _shineAnimation.value - 0.3,
                                  _shineAnimation.value,
                                  _shineAnimation.value + 0.3,
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        SizedBox(height: 24.h),

        // Title with gradient
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.7),
            ],
          ).createShader(bounds),
          child: Text(
            'Lovz Premium',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: 40.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 12.h),

        Text(
          'Unlock the Full Experience',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 16.sp,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ============================================
  // BENEFITS SECTION
  // ============================================
  Widget _buildBenefitsSection(ThemeData theme, CustomColors customColors) {
    final benefits = [
      {
        'icon': Icons.favorite_rounded,
        'title': 'Unlimited Likes',
        'color': const Color(0xFFFF453A)
      },
      {
        'icon': Icons.chat_bubble_rounded,
        'title': 'Unlimited Messages',
        'color': const Color(0xFF30D158)
      },
      {
        'icon': Icons.undo_rounded,
        'title': 'Unlimited Undos',
        'color': const Color(0xFFBF5AF2)
      },
      {
        'icon': Icons.visibility_rounded,
        'title': 'See Who Likes You',
        'color': const Color(0xFF0A84FF)
      },
      {
        'icon': Icons.rocket_launch_rounded,
        'title': '1 Free Boost/Month',
        'color': const Color(0xFFFF9500)
      },
      {
        'icon': Icons.block_rounded,
        'title': 'No Ads',
        'color': const Color(0xFF64D2FF)
      },
      {
        'icon': Icons.star_rounded,
        'title': 'Priority Support',
        'color': const Color(0xFFFFD60A)
      },
      {
        'icon': Icons.security_rounded,
        'title': 'Enhanced Privacy',
        'color': const Color(0xFF32ADE6)
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 2.5,
      ),
      itemCount: benefits.length,
      itemBuilder: (context, index) {
        final benefit = benefits[index];
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: customColors.surface_2,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: theme.dividerColor,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                benefit['icon'] as IconData,
                color: benefit['color'] as Color,
                size: 22.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  benefit['title'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================
  // PLANS SECTION
  // ============================================
  Widget _buildPlansSection(ThemeData theme, CustomColors customColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Plan',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        ...List.generate(_plans.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildPlanCard(
              theme: theme,
              customColors: customColors,
              plan: _plans[index],
              index: index,
            ),
          );
        }),
      ],
    );
  }

  // ============================================
  // PLAN CARD
  // ============================================
  Widget _buildPlanCard({
    required ThemeData theme,
    required CustomColors customColors,
    required PremiumPlan plan,
    required int index,
  }) {
    final bool isSelected = (_selectedIndex == index);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : customColors.surface_2,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (plan.isPopular) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : const Color(0xFFFFD700),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                'POPULAR',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.scaffoldBackgroundColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (plan.monthlyPrice.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          plan.monthlyPrice,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13.sp,
                            color: isSelected
                                ? theme.colorScheme.onPrimary.withOpacity(0.8)
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.diamond_rounded,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : customColors.diamondBlue,
                          size: 22.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          plan.totalPrice,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (plan.discount != null) ...[
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.onPrimary.withOpacity(0.2)
                              : const Color(0xFF30D158).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.onPrimary.withOpacity(0.4)
                                : const Color(0xFF30D158),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          plan.discount!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : const Color(0xFF30D158),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: -8.h,
                right: -8.w,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                    size: 24.sp,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // CONTINUE BUTTON
  // ============================================
  Widget _buildContinueButton(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isProcessing
              ? [
                  theme.colorScheme.onSurface.withOpacity(0.3),
                  theme.colorScheme.onSurface.withOpacity(0.2),
                ]
              : [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.8),
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: _isProcessing
            ? null
            : [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28.r),
          onTap: _isProcessing ? null : _handlePurchase,
          child: Center(
            child: _isProcessing
                ? SizedBox(
                    height: 24.h,
                    width: 24.w,
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.onPrimary,
                      strokeWidth: 3,
                    ),
                  )
                : Text(
                    'CONTINUE',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                      letterSpacing: 1.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // FOOTER TEXT
  // ============================================
  Widget _buildFooterText(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Subscription renews automatically. Cancel anytime.',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12.sp,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Terms of Service',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12.sp,
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
            Text(
              '  •  ',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            Text(
              'Privacy Policy',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12.sp,
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ],
    );
  }
}