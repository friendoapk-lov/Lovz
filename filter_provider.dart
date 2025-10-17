// lib/providers/filter_provider.dart (NAYI FILE)

import 'package:flutter/foundation.dart';

class FilterProvider with ChangeNotifier {
  // Yeh temporary location store karega jab user search karta hai
  String? _temporaryLocationName;
  double? _temporaryLat;
  double? _temporaryLng;

  // Getters
  String? get temporaryLocationName => _temporaryLocationName;
  double? get temporaryLat => _temporaryLat;
  double? get temporaryLng => _temporaryLng;

  // Yeh function location ko temporary update karega
  void setTemporaryLocation({
    required String name,
    required double lat,
    required double lng,
  }) {
    _temporaryLocationName = name;
    _temporaryLat = lat;
    _temporaryLng = lng;
    notifyListeners(); // UI ko update karne ke liye
  }

  // Yeh function temporary location ko clear kar dega
  void clearTemporaryLocation() {
    _temporaryLocationName = null;
    _temporaryLat = null;
    _temporaryLng = null;
    notifyListeners();
  }
}