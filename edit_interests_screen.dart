// lib/screens/edit_interests_screen.dart - THEME REFACTORED (ERRORS FIXED)

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovz/utils/theme.dart'; // THEME: Custom theme file import kiya gaya (CustomColors ke liye)

class EditInterestsScreen extends StatefulWidget {
  final List<String> initialInterests;

  const EditInterestsScreen({
    Key? key,
    required this.initialInterests,
  }) : super(key: key);

  @override
  _EditInterestsScreenState createState() => _EditInterestsScreenState();
}

class _EditInterestsScreenState extends State<EditInterestsScreen> {
  late List<String> _selectedInterests;
  final int _maxSelection = 7;

  // ========================================
  // INIT STATE - KOI CHANGE NAHI
  // ========================================
  @override
  void initState() {
    super.initState();
    _selectedInterests = List.from(widget.initialInterests);
  }

  // ========================================
  // INTEREST CATEGORIES - KOI CHANGE NAHI
  // EMOJIS/ICONS SAME RAHENGE
  // ========================================
  final Map<String, List<String>> _interestCategories = {
    'Creative Hobbies': [
      '🎨 Painting',
      '✍️ Writing',
      '📷 Photography',
      '🎸 Guitar',
      '💃 Dancing',
      '🎬 Filmmaking',
      '🍳 Cooking',
      '🪴 Gardening'
    ],
    'Sports & Fitness': [
      '💪 Gym',
      '🏏 Cricket',
      '⚽ Football',
      '🏃 Running',
      '🧘 Yoga',
      '🚶‍♂️ Hiking',
      '🏊 Swimming',
      '🏸 Badminton'
    ],
    'Entertainment': [
      '🎬 Movies',
      '📺 TV Shows',
      '🎵 Music',
      '📚 Reading',
      '🎮 Gaming',
      '😂 Stand-up Comedy',
      '🎭 Theatre',
      '🎧 Podcasts'
    ],
    'Social & Going Out': [
      '☕ Coffee',
      '🍽️ New Restaurants',
      '🕺 Clubbing',
      '🍻 Brewery Hopping',
      '🎤 Live Music',
      '🤝 Volunteering'
    ],
    'Travel & Adventure': [
      '✈️ Travel',
      '🚗 Road Trips',
      '🏞️ Nature',
      '🏖️ Beaches',
      '🏔️ Mountains',
      '🏕️ Camping'
    ],
  };

  // ========================================
  // SELECTION LOGIC - IMPROVED (Theme parameters pass kiye)
  // ========================================
  void _onInterestSelected(String interest, ThemeData theme, CustomColors customColors) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else if (_selectedInterests.length < _maxSelection) {
        _selectedInterests.add(interest);
      } else {
        // UPDATED: Ab theme dobara fetch nahi kar rahe, parameters se use kar rahe hain
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You can select a maximum of $_maxSelection interests.',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15.sp), // FIXED: ?. wapas add kiya
            ),
            backgroundColor: customColors.surface_2,
            duration: const Duration(seconds: 2),
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
        title: const Text('YOUR INTERESTS'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // NOTE: backgroundColor aur titleTextStyle ab theme se automatically aa rahe hain
      ),
      
      body: Column(
        children: [
          // UPDATED: Divider color ab theme se aa raha hai
          Container(height: 1.h, color: theme.dividerColor),
          
          // === INTERESTS LIST (SCROLLABLE) - KOI LOGIC CHANGE NAHI ===
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _interestCategories.entries.map((entry) {
                  return _buildCategory(theme, customColors, entry.key, entry.value);
                }).toList(),
              ),
            ),
          ),
          
          // === SAVE BUTTON - MASTERPLAN KE ANUSAAR ===
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(_selectedInterests);
                },
                // UPDATED: Save button styling ab Masterplan ke anusaar hai
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface, // White background
                  foregroundColor: theme.colorScheme.surface,   // Dark Grey/Black for text
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  textStyle: theme.textTheme.labelLarge?.copyWith( // FIXED: ?. wapas add kiya
                    fontSize: 18.sp,
                  ),
                ),
                child: Text('Save (${_selectedInterests.length}/$_maxSelection)'),
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
  Widget _buildCategory(ThemeData theme, CustomColors customColors, String title, List<String> interests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // UPDATED: Category Title ab theme se style ho raha hai
        Padding(
          padding: EdgeInsets.only(top: 16.h, bottom: 12.h, left: 4.w),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.headlineLarge?.copyWith( // FIXED: ?. wapas add kiya
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
        ),
        
        // Interest Chips - UPDATED for theme
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: interests.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            
            return InkWell(
              // UPDATED: Ab theme aur customColors pass kar rahe hain
              onTap: () => _onInterestSelected(interest, theme, customColors),
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 10.h,
                ),
                decoration: BoxDecoration(
                  // UPDATED: Colors ab theme se aa rahe hain
                  color: isSelected
                      ? theme.colorScheme.onSurface.withOpacity(0.15) // White with opacity for selected
                      : customColors.surface_2, // Grey card background
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary // Primary color for selected border
                        : theme.dividerColor, // Divider color for unselected border
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // UPDATED: Interest Text ab theme se style ho raha hai
                    Text(
                      interest,
                      style: theme.textTheme.bodyLarge?.copyWith( // FIXED: ?. wapas add kiya
                        color: isSelected 
                            ? theme.colorScheme.onSurface // Full white for selected
                            : theme.colorScheme.onSurface.withOpacity(0.7), // 70% opacity for unselected
                        fontSize: 15.sp,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    
                    // Checkmark for selected - UPDATED color
                    if (isSelected) ...[
                      SizedBox(width: 6.w),
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary, // Primary color for checkmark
                        size: 16.sp,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        
        // UPDATED: Divider color ab theme se aa raha hai
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
}