// lib/screens/splash_screen.dart (NAYA, SIMPLE, AUR SAHI CODE)

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovz/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Humne yahan se _checkUserStatus() ko HATA diya hai.
    // Saara navigation ka kaam ab main.dart karega.
    
    // YEH EK TEMPORARY FIX HAI TAAKI LOGOUT HONE PAR LOGIN SCREEN AA SAKE
    _navigateToLoginIfLoggedOut();
  }

  // YEH EK TEMPORARY FUNCTION HAI
  Future<void> _navigateToLoginIfLoggedOut() async {
    // 2 second ruko taaki main.dart apna kaam kar le
    await Future.delayed(const Duration(seconds: 2));

    // Agar 2 second baad bhi user isi screen par hai, iska matlab woh logged-out hai.
    if (mounted && FirebaseAuth.instance.currentUser == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
    // Agar user logged-in hoga, to main.dart use MainWrapper par bhej dega,
    // aur yeh code kabhi nahi chalega.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Iska kaam ab sirf UI dikhana hai
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // === LOGO/ICON (Professional touch) ===
            Icon(
              Icons.favorite,
              size: 80.sp,
              color: theme.colorScheme.primary,
            ),
            SizedBox(height: 32.h),

            // === APP NAME (Optional - add if needed) ===
            Text(
              'LOVZ',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontSize: 48.sp,
                letterSpacing: 4,
              ),
            ),
            SizedBox(height: 48.h),

            // === LOADING INDICATOR ===
            SizedBox(
              width: 40.w,
              height: 40.h,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 24.h),

            // === LOADING TEXT ===
            Text(
              'Loading...',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}