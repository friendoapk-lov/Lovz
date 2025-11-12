import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lovz/firebase_options.dart';
import 'package:lovz/screens/splash_screen.dart';
import 'package:lovz/services/profanity_service.dart';
import 'package:lovz/screens/user_status_checker.dart';
import 'package:lovz/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:lovz/providers/new_counts_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/services.dart';
// ❌ REMOVE: import 'package:lovz/services/websocket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await MobileAds.instance.initialize();
  await ProfanityService.instance.initialize();

  // ❌ REMOVE THESE LINES:
  // await WebSocketService.instance.initialize();

  // ✅ WebSocket initialization ab main_wrapper.dart me hoga
  // jab user login ho chuka hoga

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
          return MaterialApp(
            title: 'Lovz',
            debugShowCheckedModeBanner: false,
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
        },
      ),
    );
  }
}
