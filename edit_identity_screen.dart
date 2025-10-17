// lib/screens/edit_identity_screen.dart - THEME REFACTORED

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovz/utils/theme.dart'; // THEME: Custom theme file import kiya gaya

class EditIdentityScreen extends StatefulWidget {
  final List<String> initialIdentities;
  final bool initialPreferNotToSay;

  const EditIdentityScreen({
    Key? key,
    required this.initialIdentities,
    required this.initialPreferNotToSay,
  }) : super(key: key);

  @override
  _EditIdentityScreenState createState() => _EditIdentityScreenState();
}

class _EditIdentityScreenState extends State<EditIdentityScreen> {
  // --- STATE & LOGIC (No Changes) ---
  final List<String> _allIdentities = [
    'Top', 'Bottom', 'Versatile', 'Bear', 'Bio', 'Butch', 'Drag king',
    'Drag queen', 'Femme', 'Hard femme', 'High femme', 'Leather', 'Otter',
    'Soft butch', 'Stone butch', 'Stone femme', 'Stud', 'Switch', 'Twink'
  ];

  late List<String> _selectedIdentities;
  late bool _preferNotToSay;

  @override
  void initState() {
    super.initState();
    _selectedIdentities = List.from(widget.initialIdentities);
    _preferNotToSay = widget.initialPreferNotToSay;
  }

  void _onIdentityTap(String identityTitle) {
    setState(() {
      if (_selectedIdentities.contains(identityTitle)) {
        _selectedIdentities.remove(identityTitle);
      } else {
        _selectedIdentities.add(identityTitle);
      }
      if (_selectedIdentities.isNotEmpty) {
        _preferNotToSay = false;
      }
    });
  }

  void _onPreferNotToSayChanged(bool? value) {
    setState(() {
      _preferNotToSay = value ?? false;
      if (_preferNotToSay) {
        _selectedIdentities.clear();
      }
    });
  }

  void _onSave() {
    Navigator.of(context).pop({
      'identities': _selectedIdentities,
      'preferNotToSay': _selectedIdentities.isEmpty,
    });
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
        title: const Text('SELECT IDENTITY'),
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
              itemCount: _allIdentities.length,
              itemBuilder: (context, index) {
                final identity = _allIdentities[index];
                final isSelected = _selectedIdentities.contains(identity);

                // === IDENTITY OPTION - REFACTORED into a helper widget ===
                return _buildIdentityOption(theme, customColors, identity, isSelected);
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

  /// Builds a single selectable identity tile.
  Widget _buildIdentityOption(ThemeData theme, CustomColors customColors, String identity, bool isSelected) {
    final bool isDisabled = _preferNotToSay;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: isDisabled ? null : () => _onIdentityTap(identity),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
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
                  border: Border.all(
                    // UPDATED: Border colors theme par adharit hain.
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(isDisabled ? 0.3 : 0.6),
                    width: 2,
                  ),
                  // UPDATED: Background color theme par adharit hai.
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
              
              // --- Identity Name (Refactored) ---
              Expanded(
                child: Text(
                  identity,
                  // UPDATED: Text style ab theme se aa raha hai.
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(isDisabled ? 0.4 : 1.0),
                    fontSize: 16.sp,
                  ),
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
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 12.w, 20.h), // Right padding adjusted for switch
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Prefer not to say",
                  // UPDATED: Text style ab theme se aa raha hai.
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  "Your identity won't be shown on your profile.",
                  // UPDATED: Secondary text style bhi theme se aa raha hai.
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
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