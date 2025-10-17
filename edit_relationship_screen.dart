// lib/screens/edit_relationship_screen.dart - THEME REFACTORED

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovz/models/user_profile_model.dart';
import 'package:lovz/utils/theme.dart'; // THEME: Custom theme file import kiya gaya

class EditRelationshipScreen extends StatefulWidget {
  final Map<String, dynamic> initialRelationshipData;

  const EditRelationshipScreen({
    Key? key,
    required this.initialRelationshipData,
  }) : super(key: key);

  @override
  _EditRelationshipScreenState createState() => _EditRelationshipScreenState();
}

class _EditRelationshipScreenState extends State<EditRelationshipScreen> {
  // --- STATE & LOGIC (No Changes) ---
  late RelationshipType _selectedType;
  NonMonogamousStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialRelationshipData['type'] ?? RelationshipType.none;
    _selectedStatus = widget.initialRelationshipData['status'];
  }

  void _onSave() {
    final Map<String, dynamic> result = {
      'type': _selectedType,
      'status': _selectedType == RelationshipType.nonMonogamous ? _selectedStatus : null,
    };
    Navigator.of(context).pop(result);
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
        title: const Text('RELATIONSHIP STATUS'),
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
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              children: [
                // === OPTION 1: MONOGAMOUS ===
                _buildRadioOption(
                  theme: theme,
                  customColors: customColors,
                  title: 'Monogamous',
                  value: RelationshipType.monogamous,
                  groupValue: _selectedType,
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),
                SizedBox(height: 12.h),

                // === OPTION 2: NON-MONOGAMOUS ===
                _buildRadioOption(
                  theme: theme,
                  customColors: customColors,
                  title: 'Non-monogamous',
                  value: RelationshipType.nonMonogamous,
                  groupValue: _selectedType,
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),

                // === SUB-OPTIONS FOR NON-MONOGAMOUS (LOGIC UNCHANGED) ===
                if (_selectedType == RelationshipType.nonMonogamous) ...[
                  SizedBox(height: 12.h),
                  _buildSubOptionsContainer(theme, customColors),
                ],
                SizedBox(height: 12.h),

                // === OPTION 3: OPEN TO EITHER ===
                _buildRadioOption(
                  theme: theme,
                  customColors: customColors,
                  title: 'Open to either',
                  value: RelationshipType.openToEither,
                  groupValue: _selectedType,
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),
              ],
            ),
          ),

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
                  foregroundColor: theme.colorScheme.surface, // Dark Grey/Black for text
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
  // HELPER WIDGETS - Refactored for Theme
  // ========================================

  /// Main relationship type radio option tile.
  Widget _buildRadioOption<T>({
    required ThemeData theme,
    required CustomColors customColors,
    required String title,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    final bool isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
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
            // --- Radio Circle (Refactored) ---
            Container(
              width: 24.w,
              height: 24.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // UPDATED: Border color theme par adharit hai.
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6),
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
                          // UPDATED: Inner circle color theme se aa raha hai.
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 16.w),

            // --- Title Text (Refactored) ---
            Expanded(
              child: Text(
                title,
                // UPDATED: Text style ab theme se aa raha hai.
                style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Container for the non-monogamous sub-options.
  Widget _buildSubOptionsContainer(ThemeData theme, CustomColors customColors) {
    return Padding(
      padding: EdgeInsets.only(left: 30.w),
      child: Container(
        decoration: BoxDecoration(
          // UPDATED: Background aur border color ab theme se aa rahe hain.
          color: customColors.surface_2!.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: theme.dividerColor.withOpacity(0.5), width: 1),
        ),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          children: [
            _buildSubRadioOption(theme, 'Single', NonMonogamousStatus.single),
            _buildSubRadioOption(theme, 'Partnered', NonMonogamousStatus.partnered),
            _buildSubRadioOption(theme, 'Married', NonMonogamousStatus.married),
          ],
        ),
      ),
    );
  }

  /// Radio option tile specifically for sub-options.
  Widget _buildSubRadioOption(ThemeData theme, String title, NonMonogamousStatus value) {
    final bool isSelected = value == _selectedStatus;

    return InkWell(
      onTap: () => setState(() => _selectedStatus = value),
      child: Container(
        color: Colors.transparent, // For larger tap area inside InkWell
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            // --- Sub Radio Circle (Refactored) ---
            Container(
              width: 20.w,
              height: 20.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10.w,
                        height: 10.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 12.w),
            
            // --- Sub-option Title (Refactored) ---
            Expanded(
              child: Text(
                title,
                // UPDATED: Text style ab theme se aa raha hai.
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}