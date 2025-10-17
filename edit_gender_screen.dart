// lib/screens/edit_gender_screen.dart - THEME REFACTORED

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovz/models/gender_model.dart';
import 'package:lovz/utils/theme.dart'; // THEME: Custom theme file import kiya gaya

class EditGenderScreen extends StatefulWidget {
  final List<String> initialGenders;

  const EditGenderScreen({
    Key? key,
    required this.initialGenders,
  }) : super(key: key);

  @override
  _EditGenderScreenState createState() => _EditGenderScreenState();
}

class _EditGenderScreenState extends State<EditGenderScreen> {
  // --- STATE & LOGIC (No Changes) ---
  final List<Gender> _allGenders = [
    Gender(title: 'Man', description: 'Male-identifying person.'),
    Gender(title: 'Woman', description: 'Female-identifying person.'),
    Gender(title: 'Agender', description: 'Person without a specific gender identity.'),
    Gender(title: 'Androgynous', description: 'Person having both masculine and feminine traits.'),
    Gender(title: 'Bigender', description: 'Person who identifies with two genders.'),
    Gender(title: 'Cis Man', description: 'Male whose gender matches assigned sex at birth.'),
    Gender(title: 'Cis Woman', description: 'Female whose gender matches assigned sex at birth.'),
    Gender(title: 'Genderfluid', description: 'Person whose gender identity changes over time.'),
    Gender(title: 'Genderqueer', description: 'Person outside traditional gender categories.'),
    Gender(title: 'Gender Nonconforming', description: 'Person whose expression differs from typical norms.'),
    Gender(title: 'Hijra', description: 'Third gender identity common in South Asia.'),
    Gender(title: 'Intersex', description: 'Person born with biological traits of both sexes.'),
    Gender(title: 'Non-binary', description: 'Person who identifies outside male-female binary.'),
    Gender(title: 'Other gender', description: 'Person with a different gender expression.'),
    Gender(title: 'Pangender', description: 'Person identifying with many gender identities.'),
    Gender(title: 'Transgender', description: 'Person whose gender differs from assigned sex.'),
    Gender(title: 'Trans Man', description: 'Person assigned female at birth, identifies as male.'),
    Gender(title: 'Transmasculine', description: 'Person with a more masculine gender expression.'),
    Gender(title: 'Transsexual', description: 'Person who medically transitions their gender.'),
    Gender(title: 'Trans Woman', description: 'Person assigned male at birth, identifies as female.'),
    Gender(title: 'Two-Spirit', description: 'Indigenous term for multiple gender identities.'),
  ];

  late List<String> _selectedGenders;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _selectedGenders = List.from(widget.initialGenders);
  }

  void _onGenderTap(String genderTitle) {
    setState(() {
      if (!_showAll) {
        _selectedGenders.clear();
        _selectedGenders.add(genderTitle);
      } else {
        if (_selectedGenders.contains(genderTitle)) {
          _selectedGenders.remove(genderTitle);
        } else {
          if (_selectedGenders.length < 5) {
            _selectedGenders.add(genderTitle);
          } else {
            // THEME: SnackBar ko theme se style kiya gaya hai.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('You can select a maximum of 5 genders.'),
                duration: const Duration(seconds: 2),
                // NOTE: backgroundColor aur style ab main theme se aayenge.
              ),
            );
          }
        }
      }
    });
  }

  void _onSave() {
    Navigator.of(context).pop(_selectedGenders);
  }

  // ========================================
  // BUILD METHOD - UI REFACTORED
  // ========================================
  @override
  Widget build(BuildContext context) {
    // THEME: Theme data aur custom colors ko ek baar build method me access karna.
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;

    List<Gender> currentList;
    if (_showAll) {
      currentList = _allGenders
          .where((g) => g.title != 'Man' && g.title != 'Woman')
          .toList();
    } else {
      currentList = _allGenders
          .where((g) => g.title == 'Man' || g.title == 'Woman')
          .toList();
    }

    return Scaffold(
      // UPDATED: Background color ab theme se aa raha hai.
      backgroundColor: theme.scaffoldBackgroundColor,
      
      // UPDATED: Custom header ko standard AppBar se replace kiya gaya hai.
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: const Text('SELECT GENDER'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      
      body: Column(
        children: [
          // UPDATED: Divider color ab theme se aa raha hai.
          Container(height: 1.h, color: theme.dividerColor),
          
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              itemCount: currentList.length + 1, // +1 for "See all" button
              itemBuilder: (context, index) {
                if (index == currentList.length) {
                  // === "SEE ALL" BUTTON - REFACTORED ===
                  return _buildSeeAllButton(theme, customColors);
                }

                final gender = currentList[index];
                final isSelected = _selectedGenders.contains(gender.title);

                // === GENDER OPTION - REFACTORED ===
                return _buildGenderOption(theme, customColors, gender, isSelected);
              },
            ),
          ),
          
          // === SAVE BUTTON - CORRECTED ===
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onSave,
                // UPDATED: Style ko `edit_basics_hub_screen` ke jaisa kar diya gaya hai.
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface, // White
                  foregroundColor: theme.colorScheme.surface,   // Dark Grey/Black for text
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 18.sp,
                  ),
                ),
                child: const Text(
                  'Save',
                  // UPDATED: Yahan se style hata di gayi hai.
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // HELPER WIDGETS - Refactored for Theme
  // ========================================

  /// "See all genders" / "See fewer" button
  Widget _buildSeeAllButton(ThemeData theme, CustomColors customColors) {
    return Padding(
      padding: EdgeInsets.only(top: 12.h, bottom: 8.h),
      child: InkWell(
        onTap: () => setState(() => _showAll = !_showAll),
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            // UPDATED: Colors ab theme se aa rahe hain.
            color: customColors.surface_2,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: theme.dividerColor, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _showAll ? "See fewer" : "See all genders",
                // UPDATED: Text style ab theme se aa raha hai.
                style: theme.textTheme.bodyLarge,
              ),
              SizedBox(width: 8.w),
              Icon(
                _showAll
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                // UPDATED: Icon color ab theme se aa raha hai.
                color: theme.colorScheme.onSurface,
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Individual gender selection tile
  Widget _buildGenderOption(ThemeData theme, CustomColors customColors, Gender gender, bool isSelected) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () => _onGenderTap(gender.title),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            // UPDATED: Colors ab theme se aa rahe hain.
            color: customColors.surface_2,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // --- Radio/Checkbox Icon (Refactored) ---
              Container(
                width: 24.w,
                height: 24.h,
                decoration: BoxDecoration(
                  shape: _showAll ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: _showAll ? BorderRadius.circular(4.r) : null,
                  // UPDATED: Border and background colors ab theme par adharit hain.
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6),
                    width: 2,
                  ),
                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                ),
                child: isSelected
                    ? Icon(
                        _showAll ? Icons.check : Icons.circle,
                        size: _showAll ? 16.sp : 12.sp,
                        // UPDATED: Icon color primary color ke upar saaf dikhega.
                        color: theme.colorScheme.onPrimary,
                      )
                    : null,
              ),
              
              SizedBox(width: 16.w),
              
              // --- Text Content (Refactored) ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gender.title,
                      // UPDATED: Text style ab theme se aa raha hai.
                      style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16.sp),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      gender.description,
                      // UPDATED: Secondary text style bhi theme se aa raha hai.
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}