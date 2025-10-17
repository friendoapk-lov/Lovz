// new_counts_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewCountsProvider with ChangeNotifier {
  late SharedPreferences _prefs;

  int _totalLikes = 0;
  int _totalMatches = 0;
  int _totalCrushes = 0;

  int _lastViewedLikes = 0;
  int _lastViewedMatches = 0;
  int _lastViewedCrushes = 0;

  // --- Getters ---
  int get newLikesCount => _totalLikes - _lastViewedLikes;
  int get newMatchesCount => _totalMatches - _lastViewedMatches;
  int get newCrushesCount => _totalCrushes - _lastViewedCrushes;

  // === NEW GETTER: For the footer badge on HomeScreen ===
  // This combines new likes and new matches.
  int get newLikesAndMatchesCount => newLikesCount + newMatchesCount;

  NewCountsProvider() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _lastViewedLikes = _prefs.getInt('last_viewed_likes') ?? 0;
    _lastViewedMatches = _prefs.getInt('last_viewed_matches') ?? 0;
    _lastViewedCrushes = _prefs.getInt('last_viewed_crushes') ?? 0;
    
    _totalLikes = _prefs.getInt('total_likes') ?? 0;
    _totalMatches = _prefs.getInt('total_matches') ?? 0;
    _totalCrushes = _prefs.getInt('total_crushes') ?? 0;

    notifyListeners();
  }
  
  void updateTotalLikes(int count) {
    if (_totalLikes == count) return; // No change, no need to notify
    _totalLikes = count;
    _prefs.setInt('total_likes', count);
    notifyListeners();
  }

  void updateTotalMatches(int count) {
    if (_totalMatches == count) return; // No change, no need to notify
    _totalMatches = count;
    _prefs.setInt('total_matches', count);
    notifyListeners();
  }
  
  void updateTotalCrushes(int count) {
    if (_totalCrushes == count) return; // No change, no need to notify
    _totalCrushes = count;
    _prefs.setInt('total_crushes', count);
    notifyListeners();
  }

  // This function is no longer needed as the subcollection listener is more reliable.
  // void updateMatchCountFromField(int count) { ... }

  void resetLikesCount() {
    if (newLikesCount > 0) {
      _lastViewedLikes = _totalLikes;
      _prefs.setInt('last_viewed_likes', _lastViewedLikes);
      notifyListeners();
    }
  }

  void resetMatchesCount() {
    if (newMatchesCount > 0) {
      _lastViewedMatches = _totalMatches;
      _prefs.setInt('last_viewed_matches', _lastViewedMatches);
      notifyListeners();
    }
  }
  
  void resetCrushesCount() {
    if (newCrushesCount > 0) {
      _lastViewedCrushes = _totalCrushes;
      _prefs.setInt('last_viewed_crushes', _lastViewedCrushes);
      notifyListeners();
    }
  }
}