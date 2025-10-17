import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// STEP 1: Define all custom colors using a ThemeExtension.
@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({
    required this.diamondBlue,
    required this.onlineGreen,
    required this.footerRed,
    required this.footerGrey,
    required this.cardArrowPink,
    required this.locationSkyBlue,
    required this.dividerGrey,
    // === YEH ADD KAREIN ===
    required this.surface_2,
    required this.love,
  });

  final Color? diamondBlue;
  final Color? onlineGreen;
  final Color? footerRed;
  final Color? footerGrey;
  final Color? cardArrowPink;
  final Color? locationSkyBlue;
  final Color? dividerGrey;
  // === YEH ADD KAREIN ===
  final Color? surface_2; // Color for cards and specific surfaces
  final Color? love;      // Color for liked hearts and primary actions

  @override
  CustomColors copyWith({
    Color? diamondBlue,
    Color? onlineGreen,
    Color? footerRed,
    Color? footerGrey,
    Color? cardArrowPink,
    Color? locationSkyBlue,
    Color? dividerGrey,
    // === YEH ADD KAREIN ===
    Color? surface_2,
    Color? love,
  }) {
    return CustomColors(
      diamondBlue: diamondBlue ?? this.diamondBlue,
      onlineGreen: onlineGreen ?? this.onlineGreen,
      footerRed: footerRed ?? this.footerRed,
      footerGrey: footerGrey ?? this.footerGrey,
      cardArrowPink: cardArrowPink ?? this.cardArrowPink,
      locationSkyBlue: locationSkyBlue ?? this.locationSkyBlue,
      dividerGrey: dividerGrey ?? this.dividerGrey,
      // === YEH ADD KAREIN ===
      surface_2: surface_2 ?? this.surface_2,
      love: love ?? this.love,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      diamondBlue: Color.lerp(diamondBlue, other.diamondBlue, t),
      onlineGreen: Color.lerp(onlineGreen, other.onlineGreen, t),
      footerRed: Color.lerp(footerRed, other.footerRed, t),
      footerGrey: Color.lerp(footerGrey, other.footerGrey, t),
      cardArrowPink: Color.lerp(cardArrowPink, other.cardArrowPink, t),
      locationSkyBlue: Color.lerp(locationSkyBlue, other.locationSkyBlue, t),
      dividerGrey: Color.lerp(dividerGrey, other.dividerGrey, t),
      // === YEH ADD KAREIN ===
      surface_2: Color.lerp(surface_2, other.surface_2, t),
      love: Color.lerp(love, other.love, t),
    );
  }
}

// STEP 2: Create our main ThemeData object for the Dark Theme.
final ThemeData darkTheme = ThemeData(
  // GENERAL APP SETTINGS
  brightness: Brightness.dark,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  
  // COLOR SCHEME
  scaffoldBackgroundColor: const Color(0xFF121212), // Eye-comfortable dark grey
  primaryColor: const Color(0xFFE91E63), // A vibrant pink/red as the main accent color
  dividerColor: const Color(0xFF424242), // Added for consistent dividers
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFE91E63),     // Main accent color (e.g., buttons, highlights)
    secondary: Color(0xFF03A9F4),    // Secondary accent color (e.g., location text)
    background: Color(0xFF121212), // Background of components like cards
    surface: Color(0xFF1E1E1E),     // Surface of components like cards, dialogs
    onPrimary: Colors.white,       // Text on top of primary color
    onSecondary: Colors.white,     // Text on top of secondary color
    onBackground: Colors.white,    // Main text color
    onSurface: Colors.white,       // Text on components
    error: Color(0xFFCF6679),      // Standard dark theme error color
    onError: Colors.black,
  ),

  // TEXT THEME
  textTheme: GoogleFonts.robotoTextTheme(
    ThemeData.dark().textTheme.copyWith(
          bodyLarge: const TextStyle(color: Colors.white),
          bodyMedium: const TextStyle(color: Colors.white70),
          titleLarge: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleMedium: const TextStyle(color: Colors.white),
          // Added for AppBars and major headings
          headlineLarge: GoogleFonts.anton(
              fontSize: 32, // Responsive size will be applied in screen using .sp
              color: Colors.white,
              letterSpacing: 1.5,
          ),
          // Added for smaller text like on badges
          labelSmall: const TextStyle(color: Colors.white, fontSize: 10),
        ),
  ),

  // APP BAR THEME
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFF121212), // Match scaffold background
    elevation: 0, // No shadow for a flatter look
    iconTheme: const IconThemeData(color: Colors.white),
    // Title text style is now handled globally by textTheme.headlineLarge for consistency
    titleTextStyle: GoogleFonts.anton(
      color: Colors.white,
      fontSize: 32, // Base size, will be scaled with .sp in the UI
      letterSpacing: 1.5
    ),
  ),

  // ICON THEME
  iconTheme: const IconThemeData(
    color: Colors.white70, // Default color for icons
  ),
  
  // CUSTOM COLORS EXTENSION
  // Here we register our custom colors so we can use them throughout the app.
  extensions: const <ThemeExtension<dynamic>>[
    CustomColors(
      diamondBlue: Color(0xFF2196F3),
      onlineGreen: Color(0xFF4CAF50),
      footerRed: Color(0xFFE91E63),
      footerGrey: Color(0xFF616161),
      cardArrowPink: Color(0xFFE91E63),
      locationSkyBlue: Color(0xFF03A9F4),
      dividerGrey: Color(0xFF333333),
      // === YEH VALUES ADD KAREIN ===
      surface_2: Color(0xFF2A2A2A), // The specific grey used for cards
      love: Color(0xFFE91E63),      // The primary pink/red for 'like' actions
    ),
  ],
);