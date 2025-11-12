import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:lovz/providers/online_status_provider.dart';
import 'package:lovz/screens/home_screen.dart';
import 'package:lovz/services/notification_service.dart';
import 'package:lovz/services/websocket_service.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> with WidgetsBindingObserver {
  late final OnlineStatusProvider _onlineStatusProvider;
  bool _isWebSocketInitialized = false; // ✅ NEW: Track initialization

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final userId = FirebaseAuth.instance.currentUser!.uid;
    _onlineStatusProvider = OnlineStatusProvider(userId);
    _onlineStatusProvider.connect();

    // ✅ UPDATED: Initialize WebSocket properly AFTER login
    _initializeWebSocket();

    // Notification service
    final notificationService = NotificationService();
    notificationService.initNotifications();
  }

  // ✅ NEW: Separate initialization function
  Future<void> _initializeWebSocket() async {
    if (_isWebSocketInitialized) {
      debugPrint('⏸️ WebSocket already initialized');
      return;
    }

    try {
      debugPrint('🚀 Initializing WebSocket service...');
      await WebSocketService.instance.initialize();
      _isWebSocketInitialized = true;
      debugPrint('✅ WebSocket service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize WebSocket: $e');
      // Retry after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && !_isWebSocketInitialized) {
          _initializeWebSocket();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _onlineStatusProvider.dispose();
    WebSocketService.instance.disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 App resumed - reconnecting...');
      _onlineStatusProvider.connect();

      // ✅ UPDATED: Only reconnect if already initialized
      if (_isWebSocketInitialized) {
        WebSocketService.instance.connect();
      }
    } else if (state == AppLifecycleState.paused) {
      debugPrint('⏸️ App paused');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _onlineStatusProvider,
      child: const HomeScreen(),
    );
  }
}
