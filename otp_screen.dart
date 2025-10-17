// lib/screens/otp_screen.dart (UPDATED - PROFESSIONAL, RESPONSIVE, THEME-BASED)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // RESPONSIVE: Added
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinput/pinput.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lovz/screens/gender_selection_screen.dart';
import 'package:lovz/screens/user_status_checker.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OTPScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isButtonActive = false;
  bool _isLoading = false;

  int _resendTimer = 30;
  Timer? _timer;

  // ANIMATION: Added animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _startTimer();

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
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  // ============================================
  // FIREBASE VERIFICATION LOGIC (NO CHANGE)
  // ============================================
  void _verifyOtp() async {
    if (!_isButtonActive || _isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpController.text,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (mounted) {
          if (userDoc.exists) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const UserStatusChecker()),
              (route) => false,
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const GenderSelectionScreen()),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resendCode() {
    if (_resendTimer == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resending OTP...')),
      );
      setState(() => _resendTimer = 30);
      _startTimer();
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
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
        // UPDATED: Modern gradient
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
                  child: _buildOTPCard(theme),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // OTP CARD (UPDATED - MODERN DESIGN)
  // ============================================
  Widget _buildOTPCard(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        // UPDATED: Using surface color
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back Button
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20.sp,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Title
          Text(
            'Verify Phone',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12.h),

          // Subtitle
          Text(
            'Enter the 6-digit code sent to\n${widget.phoneNumber}',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              height: 1.5,
            ),
          ),
          SizedBox(height: 40.h),

          // OTP Input (Pinput)
          _buildPinput(theme),
          SizedBox(height: 40.h),

          // Verify Button
          _buildVerifyButton(theme),
          SizedBox(height: 24.h),

          // Resend Code Section
          _buildResendSection(theme),
        ],
      ),
    );
  }

  // ============================================
  // PINPUT WIDGET (UPDATED - THEME BASED)
  // ============================================
  Widget _buildPinput(ThemeData theme) {
    final defaultPinTheme = PinTheme(
      width: 56.w,
      height: 60.h,
      textStyle: theme.textTheme.headlineMedium?.copyWith(
        fontSize: 24.sp,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      decoration: BoxDecoration(
        // UPDATED: Using surface color with border
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.dividerColor,
          width: 1.5,
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
    );

    return Pinput(
      length: 6,
      controller: _otpController,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      enabled: !_isLoading,
      onCompleted: (pin) {
        setState(() {
          _isButtonActive = true;
        });
      },
      onChanged: (value) {
        if (value.length < 6) {
          setState(() {
            _isButtonActive = false;
          });
        }
      },
    );
  }

  // ============================================
  // VERIFY BUTTON (UPDATED - SAVE BUTTON RULE)
  // ============================================
  Widget _buildVerifyButton(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isButtonActive && !_isLoading ? _verifyOtp : null,
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
            : const Text('Verify & Continue'),
      ),
    );
  }

  // ============================================
  // RESEND SECTION (UPDATED - THEME BASED)
  // ============================================
  Widget _buildResendSection(ThemeData theme) {
    return Align(
      alignment: Alignment.center,
      child: _resendTimer > 0
          ? Text(
              'Resend code in $_resendTimer s',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            )
          : InkWell(
              onTap: _resendCode,
              borderRadius: BorderRadius.circular(8.r),
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Text(
                  "Didn't receive code? Resend",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14.sp,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
    );
  }
}