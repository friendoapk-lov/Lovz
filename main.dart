import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lovz/firebase_options.dart';
import 'package:lovz/screens/splash_screen.dart';
import 'package:lovz/services/profanity_service.dart';
import 'package:lovz/screens/user_status_checker.dart';
// === YEH NAYI FILE IMPORT HUI HAI ===
import 'package:lovz/utils/theme.dart'; 
// === YEH PURANI FILE KI LINE DELETE HO GAYI: import 'package:lovz/utils/app_colors.dart'; ===
import 'package:provider/provider.dart';
import 'package:lovz/providers/new_counts_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/services.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // === PORTRAIT MODE LOCK ===
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // === YAHAN TAK ===

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


   // === NAYI LINE: AdMob SDK ko initialize karein ===
  await MobileAds.instance.initialize();
  // ===============================================
  await ProfanityService.instance.initialize();
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NewCountsProvider()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(393, 851),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          // === SIRF MaterialApp WIDGET KE ANDAR BADLAV HUA HAI ===
          return MaterialApp(
            title: 'Lovz',
            debugShowCheckedModeBanner: false,
            // Ab hum apni central darkTheme file ka istemal kar rahe hain.
            theme: darkTheme, 
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SplashScreen();
                }

                if (snapshot.hasData) {
                  return const UserStatusChecker();
                }

                return const SplashScreen();
              },
            ),
          );
          // === YAHAN TAK BADLAV HUA HAI ===
        },
      ),
    );
  }
}