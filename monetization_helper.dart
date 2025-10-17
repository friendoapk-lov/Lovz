import 'package:flutter/material.dart';

// Yeh enum batata hai ki user ne popup mein kaunsa action chuna.
enum MonetizationAction {
  // Common Actions
  watchAd,
  payWithDiamonds,

  // One-time Purchase Actions (Future use, optional)
  sendMessage, // Specific action for sending a single message
  undoSwipe,   // Specific action for a single undo

  // Microservice Subscription Actions
  buySubscriptionMessage,
  buySubscriptionUndo,
  buySubscriptionLikes,
  buySubscriptionCrush,

  // Premium Subscription Action
  buyPremium,
}
// Yeh class popup mein dikhne wale har ek option ko define karti hai.
class MonetizationOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final int? diamondCost;
  final MonetizationAction action;
  final Color color;
  // === NAYI PROPERTY: Option ko enable/disable karne ke liye ===
  final bool isEnabled; 
  // =============================================================

  MonetizationOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.action,
    required this.color,
    this.diamondCost,
    this.isEnabled = true, // Default value 'true' hai, yaani option by default enabled rahega
  });
}