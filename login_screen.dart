// lib/screens/login_screen.dart (UPDATED - PROFESSIONAL, RESPONSIVE, THEME-BASED)

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // RESPONSIVE: Added
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lovz/screens/otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isButtonActive = false;
  bool _isLoading = false;

  // ANIMATION: Added animation controller for smooth transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // ANIMATION: Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();

    _phoneController.addListener(() {
      final isButtonActive = _phoneController.text.length == 10;
      if (isButtonActive != _isButtonActive) {
        setState(() {
          _isButtonActive = isButtonActive;
        });
      }
    });
  }

  // ============================================
  // FIREBASE LOGIC (NO CHANGE)
  // ============================================
  void _onContinuePressed() async {
    if (!_isButtonActive || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final phoneNumber = "+91${_phoneController.text}";

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OTPScreen(
                phoneNumber: phoneNumber,
                verificationId: verificationId,
              ),
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send OTP. Please try again.')),
        );
        setState(() {
          _isLoading = false;
        });
      },
      verificationCompleted: (PhoneAuthCredential credential) {},
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ============================================
  // UI BUILD METHOD (UPDATED - MODERN & RESPONSIVE)
  // ============================================
  @override
  Widget build(BuildContext context) {
    // THEME: Access theme data
    final theme = Theme.of(context);

    return Scaffold(
      // UPDATED: Using scaffoldBackgroundColor from theme
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        // UPDATED: Modern gradient with theme colors
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.primary.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildLoginCard(theme),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // LOGIN CARD (UPDATED - MODERN DESIGN)
  // ============================================
  Widget _buildLoginCard(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        // UPDATED: Using surface color from theme
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20.r,
            spreadRadius: 2.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo Icon
          _buildLogoIcon(theme),
          SizedBox(height: 24.h),

          // App Title
          Text(
            'Lovz',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: 40.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 8.h),

          // Subtitle
          Text(
            'Find your perfect match',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 40.h),

          // Phone Number Label
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Phone Number',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Phone Input Field
          _buildPhoneInputField(theme),
          SizedBox(height: 32.h),

          // Continue Button
          _buildContinueButton(theme),
          SizedBox(height: 24.h),

          // Terms Text
          Text(
            'By continuing, you agree to our Terms of Service\nand Privacy Policy',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // LOGO ICON (UPDATED - ANIMATED)
  // ============================================
  Widget _buildLogoIcon(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 80.w,
            height: 80.h,
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
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 20.r,
                  spreadRadius: 2.r,
                ),
              ],
            ),
            child: Icon(
              Icons.favorite,
              color: theme.colorScheme.onPrimary,
              size: 40.sp,
            ),
          ),
        );
      },
    );
  }

  // ============================================
  // PHONE INPUT FIELD (UPDATED - MODERN STYLING)
  // ============================================
  Widget _buildPhoneInputField(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        // UPDATED: Using surface color with slight elevation
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.dividerColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Country Code
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              '+91',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),

          // Divider
          Container(
            width: 1.5,
            height: 24.h,
            color: theme.dividerColor,
          ),

          SizedBox(width: 12.w),

          // Phone Number TextField
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              enabled: !_isLoading,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                counterText: '',
                hintText: 'Enter phone number',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // CONTINUE BUTTON (UPDATED - SAVE BUTTON RULE)
  // ============================================
  Widget _buildContinueButton(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isButtonActive && !_isLoading ? _onContinuePressed : null,
        style: ElevatedButton.styleFrom(
          // UPDATED: Following Save Button Rule
          backgroundColor: _isButtonActive && !_isLoading
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withOpacity(0.3),
          foregroundColor: theme.colorScheme.surface,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          elevation: _isButtonActive && !_isLoading ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20.h,
                width: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.surface,
                ),
              )
            : const Text('Continue'),
      ),
    );
  }
}