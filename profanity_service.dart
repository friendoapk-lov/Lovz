import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:profanity_filter/profanity_filter.dart';

/*
  ProfanityService (Singleton) - Final Version with Debugging
  - Hum isme ab extra logging daal rahe hain taaki galti ko pakad sakein.
*/
class ProfanityService {
  // 1. Singleton Setup
  static final ProfanityService instance = ProfanityService._internal();
  factory ProfanityService() => instance;
  ProfanityService._internal();

  // 2. Class Variables
  final ProfanityFilter _englishFilter = ProfanityFilter();
  final List<String> _customWords = []; // Hamari custom list
  bool _isInitialized = false;

  /// App shuru hote hi is function ko `main.dart` se call kiya jayega.
  /// ISME HUMNE EXTRA "CCTV CAMERAS" (debugPrint) ADD KIYE HAIN.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // --- CCTV CAMERA #1: Check if initialization starts ---
    debugPrint("🕵️ [ProfanityService] Initializing...");

    try {
      // Step A: Apni custom list load karke memory me rakho.
      final wordsString = await rootBundle.loadString('assets/profanity_words.txt');
      final loadedWords = wordsString.split('\n')
          .where((word) => word.trim().isNotEmpty)
          .map((word) => word.trim().toLowerCase()) // Lowercase me save karo
          .toList();
      
      _customWords.addAll(loadedWords);

      // --- CCTV CAMERA #2: Check if words were loaded ---
      debugPrint("✅ [ProfanityService] Word list file loaded successfully.");
      debugPrint("   Total custom words found: ${_customWords.length}");
      
      // Yeh check karega ki words sahi se load hue hain ya list khaali hai.
      if (_customWords.isNotEmpty) {
        debugPrint("   First 5 words: ${_customWords.take(5).toList()}");
      } else {
        debugPrint("   ⚠️ WARNING: The profanity list is EMPTY! Check assets/profanity_words.txt file.");
      }

      _isInitialized = true;
      debugPrint("👍 [ProfanityService] Initialization Complete.");

    } catch (e) {
      // --- CCTV CAMERA #3: Catch any file loading error ---
      debugPrint("❌❌❌ CRITICAL ERROR: Could not load profanity list file! ❌❌❌");
      debugPrint("   Error details: $e");
      debugPrint("   Please check if 'assets/profanity_words.txt' exists and is declared in pubspec.yaml");
      // Agar error aaye to bhi service ko initialized mark karo taaki app crash na ho.
      _isInitialized = true;
    }
  }

  /// Yeh check karta hai ki diye gaye text me koi anuchit shabd hai ya nahi.
  bool isProfane(String input) {
    if (!_isInitialized) {
      debugPrint('⚠️ [ProfanityService] Warning: Service not initialized. Check failed.');
      return false;
    }

    final lowercasedInput = input.toLowerCase();

    // Check 1: English ke liye package ka istemal karo.
    if (lowercasedInput != _englishFilter.censor(lowercasedInput)) {
      debugPrint("Profanity detected by English filter.");
      return true;
    }

    // Check 2: Apni custom Hindi/Hinglish list se manually check karo.
    for (final customWord in _customWords) {
      if (lowercasedInput.contains(customWord)) {
        // Yeh line sirf tab print hogi jab gaali milegi
        debugPrint("Profanity detected by custom filter: '$customWord'");
        return true;
      }
    }
    
    // Agar koi gaali nahi mili, to yeh return hoga
    return false;
  }
  
  /// (Reference ke liye) Censor function dono lists ke hisaab se kaam karega.
  String censor(String input) {
    if (!_isInitialized) return input;
    
    // Pehle English filter se censor karo
    String censoredText = _englishFilter.censor(input);
    
    // Fir custom list se censor karo
    for (final customWord in _customWords) {
      final wordBoundary = RegExp(r'\b' + customWord + r'\b', caseSensitive: false);
      censoredText = censoredText.replaceAll(wordBoundary, '*' * customWord.length);
    }
    
    return censoredText;
  }
}