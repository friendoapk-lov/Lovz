// lib/screens/edit_height_weight_screen.dart - THEME REFACTORED

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovz/utils/theme.dart'; // THEME: Custom theme file import kiya gaya

class EditHeightWeightScreen extends StatefulWidget {
  final String initialFeet;
  final String initialInches;
  final String initialWeight;

  const EditHeightWeightScreen({
    Key? key,
    this.initialFeet = '',
    this.initialInches = '',
    this.initialWeight = '',
  }) : super(key: key);

  @override
  State<EditHeightWeightScreen> createState() => _EditHeightWeightScreenState();
}

class _EditHeightWeightScreenState extends State<EditHeightWeightScreen> {
  // --- STATE & LOGIC (No Changes) ---
  final _feetController = TextEditingController();
  final _inchesController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _feetController.text = widget.initialFeet;
    _inchesController.text = widget.initialInches;
    _weightController.text = widget.initialWeight;
  }

  @override
  void dispose() {
    _feetController.dispose();
    _inchesController.dispose();
    _weightController.dispose();
    super.dispose();
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
        title: const Text('HEIGHT & WEIGHT'),
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
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.h),

                  // === HEIGHT SECTION ===
                  Text(
                    "MY HEIGHT",
                    // UPDATED: Text style ab theme se aa raha hai.
                    style: theme.textTheme.titleMedium?.copyWith(
                      letterSpacing: 1.5,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          theme: theme,
                          customColors: customColors,
                          controller: _feetController,
                          label: 'Feet',
                          icon: Icons.height_outlined,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: _buildInputField(
                          theme: theme,
                          customColors: customColors,
                          controller: _inchesController,
                          label: 'Inches',
                          icon: Icons.straighten_outlined,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 32.h),

                  // === WEIGHT SECTION ===
                  Text(
                    "MY WEIGHT",
                    // UPDATED: Text style ab theme se aa raha hai.
                    style: theme.textTheme.titleMedium?.copyWith(
                      letterSpacing: 1.5,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          theme: theme,
                          customColors: customColors,
                          controller: _weightController,
                          label: 'Weight',
                          icon: Icons.monitor_weight_outlined,
                        ),
                      ),
                      SizedBox(width: 16.w),

                      // === KG Label (Refactored) ===
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                        decoration: BoxDecoration(
                          // UPDATED: Colors ab theme se aa rahe hain.
                          color: customColors.surface_2,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Text(
                          "KG",
                          // UPDATED: Text style ab theme se aa raha hai.
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // === SAVE BUTTON - CORRECTED as per the Masterplan ===
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // LOGIC (No Change): Data ko Map me pack karke return karna.
                  final result = {
                    'feet': _feetController.text.trim(),
                    'inches': _inchesController.text.trim(),
                    'weight': _weightController.text.trim(),
                  };
                  Navigator.of(context).pop(result);
                },
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
  // HELPER WIDGET: INPUT FIELD - REFACTORED
  // ========================================
  Widget _buildInputField({
    required ThemeData theme,
    required CustomColors customColors,
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      // UPDATED: Text style ab theme se aa raha hai.
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        // UPDATED: Label style ab theme se aa raha hai.
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        prefixIcon: Icon(
          icon,
          // UPDATED: Icon color ab theme se aa raha hai.
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          size: 24.sp,
        ),
        filled: true,
        // UPDATED: Fill color ab theme se aa raha hai.
        fillColor: customColors.surface_2,
        // Using specific borders for consistent look
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none, // Base border is invisible
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            // UPDATED: Border color ab theme se aa raha hai.
            color: theme.dividerColor,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            // UPDATED: Focused border color ab theme se aa raha hai.
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}