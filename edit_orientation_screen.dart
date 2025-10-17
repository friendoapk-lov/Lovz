// lib/screens/edit_orientation_screen.dart - THEME REFACTORED

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovz/models/orientation_option_model.dart';
import 'package:lovz/utils/theme.dart'; // THEME: Custom theme file import kiya gaya

class EditOrientationScreen extends StatefulWidget {
  final List<String> initialOrientations;

  const EditOrientationScreen({
    Key? key,
    required this.initialOrientations,
  }) : super(key: key);

  @override
  _EditOrientationScreenState createState() => _EditOrientationScreenState();
}

class _EditOrientationScreenState extends State<EditOrientationScreen> {
  // --- STATE & LOGIC (No Changes) ---
  final List<OrientationOption> _allOrientations = [
    OrientationOption(title: 'Straight', description: 'Attracted to people of the opposite gender.'),
    OrientationOption(title: 'Gay', description: 'Attracted to people of the same gender.'),
    OrientationOption(title: 'Bisexual', description: 'Attracted to multiple genders.'),
    OrientationOption(title: 'Asexual', description: 'Experiences little to no sexual attraction.'),
    OrientationOption(title: 'Demisexual', description: 'Feels attraction only after emotional connection.'),
    OrientationOption(title: 'Homoflexible', description: 'Mainly attracted to same gender with some flexibility.'),
    OrientationOption(title: 'Heteroflexible', description: 'Mainly attracted to opposite gender with flexibility.'),
    OrientationOption(title: 'Lesbian', description: 'Woman attracted to other women.'),
    OrientationOption(title: 'Pansexual', description: 'Attracted to people of all genders.'),
    OrientationOption(title: 'Queer', description: 'Broad term for non-heterosexual identities.'),
    OrientationOption(title: 'Questioning', description: 'Exploring personal sexual orientation.'),
    OrientationOption(title: 'Gray-asexual', description: 'Experiences attraction rarely or weakly.'),
    OrientationOption(title: 'Reciprosexual', description: 'Feels attraction when others show interest first.'),
    OrientationOption(title: 'Akiosexual', description: 'Feels attraction but prefers it not reciprocated.'),
    OrientationOption(title: 'Aceflux', description: 'Attraction level fluctuates over time.'),
    OrientationOption(title: 'Grayromantic', description: 'Experiences romantic feelings rarely or weakly.'),
    OrientationOption(title: 'Demiromantic', description: 'Romantic feelings develop after emotional bond.'),
    OrientationOption(title: 'Recipromantic', description: 'Feels romance when others show interest first.'),
    OrientationOption(title: 'Akioromantic', description: 'Feels romance but prefers it not reciprocated.'),
    OrientationOption(title: 'Aroflux', description: 'Romantic feelings fluctuate over time.'),
  ];

  late List<String> _selectedOrientations;
  bool _preferNotToSay = false;

  @override
  void initState() {
    super.initState();
    _selectedOrientations = List.from(widget.initialOrientations);
    if (_selectedOrientations.contains('Prefer not to say')) {
      _preferNotToSay = true;
      _selectedOrientations.clear();
    }
  }

  void _onSelectionTap(String title) {
    setState(() {
      if (_preferNotToSay) _preferNotToSay = false;
      if (_selectedOrientations.contains(title)) {
        _selectedOrientations.remove(title);
      } else {
        _selectedOrientations.add(title);
      }
    });
  }

  void _onPreferNotToSayChanged(bool? value) {
    setState(() {
      _preferNotToSay = value ?? false;
      if (_preferNotToSay) {
        _selectedOrientations.clear();
      }
    });
  }

  void _onSave() {
    if (_preferNotToSay) {
      Navigator.of(context).pop(['Prefer not to say']);
    } else {
      Navigator.of(context).pop(_selectedOrientations);
    }
  }

  // ========================================
  // BUILD METHOD - UI REFACTORED
  // ========================================
  @override
  Widget build(BuildContext context) {
    // THEME: Theme data aur custom colors ko ek baar build method me access karna.
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;

    return Scaffold(
      // UPDATED: Background color ab theme se aa raha hai.
      backgroundColor: theme.scaffoldBackgroundColor,

      // UPDATED: Custom header ko standard AppBar se replace kiya gaya hai.
      appBar: AppBar(
        title: const Text('SELECT ORIENTATION'),
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
              itemCount: _allOrientations.length,
              itemBuilder: (context, index) {
                final option = _allOrientations[index];
                final isSelected = _selectedOrientations.contains(option.title);

                // === ORIENTATION OPTION - REFACTORED into a helper widget ===
                return _buildOrientationOption(theme, customColors, option, isSelected);
              },
            ),
          ),
          
          // UPDATED: Divider color ab theme se aa raha hai.
          Container(height: 1.h, color: theme.dividerColor),
          
          // === "PREFER NOT TO SAY" TOGGLE - REFACTORED into a helper widget ===
          _buildPreferNotToSayToggle(theme, customColors),
          
          // === SAVE BUTTON - CORRECTED as per the Masterplan ===
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onSave,
                // UPDATED: Style ko Masterplan ke anusaar set kiya gaya hai.
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
                child: const Text('Save'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // HELPER WIDGETS - Refactored for Theme & Best Practices
  // ========================================

  /// Builds a single selectable orientation tile.
  Widget _buildOrientationOption(ThemeData theme, CustomColors customColors, OrientationOption option, bool isSelected) {
    final bool isDisabled = _preferNotToSay;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: isDisabled ? null : () => _onSelectionTap(option.title),
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
              // --- Checkbox (Refactored) ---
              Container(
                width: 24.w,
                height: 24.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.r),
                  // UPDATED: Border and background colors theme par adharit hain.
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(isDisabled ? 0.3 : 0.6),
                    width: 2,
                  ),
                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 16.sp,
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
                      option.title,
                      // UPDATED: Text style ab theme se aa raha hai.
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(isDisabled ? 0.4 : 1.0),
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      option.description,
                      // UPDATED: Secondary text style bhi theme se aa raha hai.
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(isDisabled ? 0.3 : 0.6),
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

  /// Builds the "Prefer not to say" toggle section at the bottom.
  Widget _buildPreferNotToSayToggle(ThemeData theme, CustomColors customColors) {
    return Container(
      // UPDATED: Color ab theme se aa raha hai.
      color: customColors.surface_2,
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 12.w, 12.h), // Right padding adjusted for switch
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Prefer not to say",
              // UPDATED: Text style ab theme se aa raha hai.
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16.sp),
            ),
          ),
          // UPDATED: Switch ab theme se apne aap style ho jayega.
          Switch(
            value: _preferNotToSay,
            onChanged: _onPreferNotToSayChanged,
          ),
        ],
      ),
    );
  }
}