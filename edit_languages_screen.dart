// lib/screens/edit_languages_screen.dart - THEME REFACTORED

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovz/utils/theme.dart'; // THEME: Custom theme file import kiya gaya (CustomColors ke liye)

class EditLanguagesScreen extends StatefulWidget {
  final List<String> initialLanguages;

  const EditLanguagesScreen({
    Key? key,
    required this.initialLanguages,
  }) : super(key: key);

  @override
  _EditLanguagesScreenState createState() => _EditLanguagesScreenState();
}

class _EditLanguagesScreenState extends State<EditLanguagesScreen> {
  late List<String> _selectedLanguages;
  final int _maxSelection = 10; // User max 10 languages select kar sakta hai

  // ========================================
  // INIT STATE - KOI CHANGE NAHI
  // ========================================
  @override
  void initState() {
    super.initState();
    _selectedLanguages = List.from(widget.initialLanguages);
  }

  // ========================================
  // LANGUAGE CATEGORIES - KOI CHANGE NAHI
  // ========================================
  final Map<String, List<String>> _languageCategories = {
    'Commonly Spoken': [
      'English',
      'Hindi (हिन्दी)',
      'Spanish (Español)',
      'French (Français)',
      'German (Deutsch)',
      'Mandarin (普通话)',
      'Japanese (日本語)',
      'Arabic (العربية)'
    ],
    'Indian Regional Languages': [
      'Bengali (বাংলা)',
      'Marathi (मराठी)',
      'Telugu (తెలుగు)',
      'Tamil (தமிழ்)',
      'Gujarati (ગુજરાતી)',
      'Urdu (اردو)',
      'Kannada (ಕನ್ನಡ)',
      'Malayalam (മലയാളം)',
      'Odia (ଓଡ଼ିଆ)',
      'Punjabi (ਪੰਜਾਬੀ)',
      'Assamese (অসমীয়া)'
    ],
  };

  // ========================================
  // SELECTION LOGIC - IMPROVED (Theme parameters pass kiye)
  // ========================================
  void _onLanguageSelected(String language, ThemeData theme, CustomColors customColors) {
    setState(() {
      if (_selectedLanguages.contains(language)) {
        _selectedLanguages.remove(language);
      } else if (_selectedLanguages.length < _maxSelection) {
        _selectedLanguages.add(language);
      } else {
        // UPDATED: SnackBar styling ab theme se aa rahi hai
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You can select a maximum of $_maxSelection languages.',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15.sp),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: customColors.surface_2,
          ),
        );
      }
    });
  }

  // ========================================
  // BUILD METHOD - UI REFACTORED FOR THEME
  // ========================================
  @override
  Widget build(BuildContext context) {
    // THEME: Theme data aur custom colors ko ek baar build method me access karna
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;

    return Scaffold(
      // UPDATED: Background color ab theme se aa raha hai
      backgroundColor: theme.scaffoldBackgroundColor,

      // UPDATED: Custom PreferredSize ko standard AppBar se replace kiya gaya
      appBar: AppBar(
        title: const Text('LANGUAGES I KNOW'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_outlined, size: 24.sp),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // NOTE: backgroundColor aur titleTextStyle ab theme se automatically aa rahe hain
      ),

      body: Column(
        children: [
          // UPDATED: Divider color ab theme se aa raha hai
          Container(height: 1.h, color: theme.dividerColor),
          
          // ==================== SCROLLABLE LANGUAGE LIST - KOI LOGIC CHANGE NAHI ====================
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _languageCategories.entries.map((entry) {
                  return _buildCategory(theme, customColors, entry.key, entry.value);
                }).toList(),
              ),
            ),
          ),

          // ==================== SAVE BUTTON - MASTERPLAN KE ANUSAAR ====================
          Padding(
            padding: EdgeInsets.all(20.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(_selectedLanguages);
                },
                // UPDATED: Save button styling ab Masterplan ke anusaar hai
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface, // White background
                  foregroundColor: theme.colorScheme.surface,   // Dark Grey/Black for text
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 16.sp,
                  ),
                ),
                child: const Text('Save'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // HELPER WIDGET: CATEGORY SECTION - THEME REFACTORED
  // ========================================
  Widget _buildCategory(ThemeData theme, CustomColors customColors, String title, List<String> languages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // UPDATED: Category Title ab theme se style ho raha hai
        Padding(
          padding: EdgeInsets.only(top: 8.h, bottom: 12.h),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
            ),
          ),
        ),

        // Language Chips - UPDATED for theme
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: languages.map((language) {
            final isSelected = _selectedLanguages.contains(language);
            return _buildLanguageChip(theme, customColors, language, isSelected);
          }).toList(),
        ),

        // UPDATED: Divider color ab theme se aa raha hai (Container use kiya)
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Container(
            height: 1.h,
            color: theme.dividerColor,
          ),
        ),
      ],
    );
  }

  // ========================================
  // HELPER WIDGET: LANGUAGE CHIP - THEME REFACTORED
  // ========================================
  Widget _buildLanguageChip(ThemeData theme, CustomColors customColors, String language, bool isSelected) {
    return GestureDetector(
      // UPDATED: Ab theme aur customColors pass kar rahe hain
      onTap: () => _onLanguageSelected(language, theme, customColors),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          // UPDATED: Colors ab theme se aa rahe hain
          color: isSelected 
              ? customColors.surface_2 // Selected: grey card background
              : theme.colorScheme.surface, // Unselected: darker surface
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            // UPDATED: Border color ab theme se aa raha hai
            color: isSelected 
                ? theme.colorScheme.primary // Selected: primary color
                : theme.dividerColor, // Unselected: divider grey
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // UPDATED: Language Text ab theme se style ho raha hai
            Text(
              language,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                    ? theme.colorScheme.onSurface // Selected: full white
                    : theme.colorScheme.onSurface.withOpacity(0.7), // Unselected: 70% opacity
              ),
            ),
            
            // Checkmark icon for selected languages - UPDATED color
            if (isSelected) ...[
              SizedBox(width: 8.w),
              Icon(
                Icons.check_circle_outlined,
                color: theme.colorScheme.primary, // Primary color for checkmark
                size: 18.sp,
              ),
            ],
          ],
        ),
      ),
    );
  }
}