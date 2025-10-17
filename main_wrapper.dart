import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:lovz/providers/online_status_provider.dart';
import 'package:lovz/screens/home_screen.dart';
import 'package:lovz/services/notification_service.dart'; // <--- YEH NAYI LINE ADD KAREIN

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

// Hum 'WidgetsBindingObserver' ka istemaal kar rahe hain 
// taaki app ke lifecycle (resume, pause) ka pata chale
class _MainWrapperState extends State<MainWrapper> with WidgetsBindingObserver {
  
  // Provider ka ek instance yahan store karenge taaki woh baar baar na bane
  late final OnlineStatusProvider _onlineStatusProvider;

  @override
  void initState() {
    super.initState();
    // Observer ko register karo
    WidgetsBinding.instance.addObserver(this);

    final userId = FirebaseAuth.instance.currentUser!.uid;
    // Provider ko sirf ek baar yahan banao
    _onlineStatusProvider = OnlineStatusProvider(userId);
    
    // Provider ko turant connect bhi kar do
    _onlineStatusProvider.connect();

    // === NAYA BADLAV: Notification service ko yahan initialize karo ===
    final notificationService = NotificationService();
    notificationService.initNotifications();
    // =============================================================
  }

  @override
  void dispose() {
    // Leaks se bachne ke liye observer ko hatao aur provider ko dispose karo
    WidgetsBinding.instance.removeObserver(this);
    _onlineStatusProvider.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Jab bhi app background se waapis aage aayegi (resume hogi)
    if (state == AppLifecycleState.resumed) {
      // Connection ko dobara shuru karo, taaki agar connection toot gaya ho to jud jaaye
      _onlineStatusProvider.connect();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hum yahan .value constructor ka istemaal kar rahe hain
    // kyunki humne provider pehle hi bana liya hai.
    return ChangeNotifierProvider.value(
      value: _onlineStatusProvider,
      child: const HomeScreen(),
    );
  }
}