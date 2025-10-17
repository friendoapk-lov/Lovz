// lib/screens/edit_habits_screen.dart - THEME REFACTORED

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovz/utils/theme.dart'; // THEME: Custom theme file import kiya gaya (CustomColors ke liye)

class EditHabitsScreen extends StatefulWidget {
  // Hum yahan teeno habits ki purani values ek saath receive karenge
  final Map<String, String> initialHabits;

  const EditHabitsScreen({
    Key? key,
    required this.initialHabits,
  }) : super(key: key);

  @override
  _EditHabitsScreenState createState() => _EditHabitsScreenState();
}

class _EditHabitsScreenState extends State<EditHabitsScreen> {
  // Teeno habits ke liye alag-alag state variables
  late String _selectedDrinking;
  late String _selectedSmoking;
  late String _selectedMarijuana;

  // ========================================
  // INIT STATE - KOI CHANGE NAHI
  // ========================================
  @override
  void initState() {
    super.initState();
    // Shuruaat me, hum purani values se in variables ko set kar denge
    _selectedDrinking = widget.initialHabits['drinking'] ?? '';
    _selectedSmoking = widget.initialHabits['smoking'] ?? '';
    _selectedMarijuana = widget.initialHabits['marijuana'] ?? '';
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
        title: const Text('HABITS'),
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
          
          // ==================== SCROLLABLE HABITS SECTIONS - KOI LOGIC CHANGE NAHI ====================
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                children: [
                  // Drinking Section
                  _buildHabitSection(
                    theme: theme,
                    customColors: customColors,
                    title: 'Drinking',
                    icon: Icons.local_bar_outlined,
                    options: ['Frequently', 'Socially', 'Never', 'Sober', 'Prefer not to say'],
                    groupValue: _selectedDrinking,
                    onChanged: (value) => setState(() => _selectedDrinking = value ?? ''),
                  ),

                  SizedBox(height: 16.h),

                  // Smoking Section
                  _buildHabitSection(
                    theme: theme,
                    customColors: customColors,
                    title: 'Smoking',
                    icon: Icons.smoking_rooms_outlined,
                    options: ['Yes', 'Socially', 'Never', 'Trying to quit', 'Prefer not to say'],
                    groupValue: _selectedSmoking,
                    onChanged: (value) => setState(() => _selectedSmoking = value ?? ''),
                  ),

                  SizedBox(height: 16.h),

                  // Marijuana Section
                  _buildHabitSection(
                    theme: theme,
                    customColors: customColors,
                    title: 'Marijuana',
                    icon: Icons.eco_outlined,
                    options: ['Yes', 'Sometimes', 'Never', 'Prefer not to say'],
                    groupValue: _selectedMarijuana,
                    onChanged: (value) => setState(() => _selectedMarijuana = value ?? ''),
                  ),
                ],
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
                  // Teeno values ko ek Map me daal kar wapas bhejna (KOI LOGIC CHANGE NAHI)
                  final result = {
                    'drinking': _selectedDrinking,
                    'smoking': _selectedSmoking,
                    'marijuana': _selectedMarijuana,
                  };
                  Navigator.of(context).pop(result);
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
  // HELPER WIDGET: HABIT SECTION - THEME REFACTORED
  // ========================================
  Widget _buildHabitSection({
    required ThemeData theme,
    required CustomColors customColors,
    required String title,
    required IconData icon,
    required List<String> options,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        // UPDATED: Background color ab theme se aa raha hai
        color: customColors.surface_2,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with Icon
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
            child: Row(
              children: [
                Icon(
                  icon,
                  // UPDATED: Icon color ab theme se aa raha hai
                  color: theme.colorScheme.primary,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  title.toUpperCase(),
                  // UPDATED: Text style ab theme se aa raha hai
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // UPDATED: Divider ab Container se banaya (Masterplan ke anusaar)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Container(
              height: 1.h,
              color: theme.dividerColor,
            ),
          ),

          // Radio Options
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = groupValue == option;
            final isLastItem = index == options.length - 1;

            return Column(
              children: [
                InkWell(
                  onTap: () => onChanged(option),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Row(
                      children: [
                        // UPDATED: Custom Radio Button ab theme colors se
                        Container(
                          width: 22.w,
                          height: 22.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected 
                                  ? theme.colorScheme.primary // Selected: primary color
                                  : theme.dividerColor, // Unselected: divider grey
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 12.w,
                                    height: 12.h,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: theme.colorScheme.primary, // Primary color
                                    ),
                                  ),
                                )
                              : null,
                        ),

                        SizedBox(width: 16.w),

                        // UPDATED: Option Text ab theme se style ho raha hai
                        Expanded(
                          child: Text(
                            option,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 15.sp,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected 
                                  ? theme.colorScheme.onSurface // Selected: full white
                                  : theme.colorScheme.onSurface.withOpacity(0.7), // Unselected: 70% opacity
                            ),
                          ),
                        ),

                        // Checkmark for selected option - UPDATED color
                        if (isSelected)
                          Icon(
                            Icons.check_circle_outlined,
                            color: theme.colorScheme.primary, // Primary color
                            size: 20.sp,
                          ),
                      ],
                    ),
                  ),
                ),

                // UPDATED: Divider between options ab Container se (Masterplan ke anusaar)
                if (!isLastItem)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Container(
                      height: 1.h,
                      color: theme.dividerColor,
                    ),
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}