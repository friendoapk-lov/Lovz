import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lovz/screens/blocked_screen.dart';
import 'package:lovz/screens/main_wrapper.dart';
import 'package:lovz/screens/splash_screen.dart';

class UserStatusChecker extends StatefulWidget {
  const UserStatusChecker({super.key});

  @override
  State<UserStatusChecker> createState() => _UserStatusCheckerState();
}

class _UserStatusCheckerState extends State<UserStatusChecker> {

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    // Thoda sa delay dena zaroori hai taaki saare services theek se shuru ho jaayein
    await Future.delayed(const Duration(milliseconds: 100));

    final user = FirebaseAuth.instance.currentUser;

    // Agar kisi wajah se user null hai, to use login par bhejo
    if (user == null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
        );
      }
      return;
    }
    
    try {
      // Hamesha server se taaza data laao
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));
      
      bool isBlocked = false;
      if (doc.exists && doc.data()!.containsKey('isBlocked')) {
        isBlocked = doc.data()!['isBlocked'];
      }

      // Faisla lo: Kahan bhejna hai
      if (mounted) {
        if (isBlocked) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const BlockedScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainWrapper()),
          );
        }
      }

    } catch (e) {
      debugPrint("Error checking user status: $e");
      // Agar error aaye, to user ko logout kar do taaki woh phans na jaaye
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Jab tak check ho raha hai, loading screen dikhao
    return const SplashScreen();
  }
}