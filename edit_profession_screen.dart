// lib/screens/edit_profession_screen.dart - THEME REFACTORED

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovz/utils/theme.dart'; // THEME: Custom theme file import kiya gaya (CustomColors ke liye)

class EditProfessionScreen extends StatefulWidget {
  final String initialTitle;
  final String initialCompany;

  const EditProfessionScreen({
    Key? key,
    this.initialTitle = '',
    this.initialCompany = '',
  }) : super(key: key);

  @override
  _EditProfessionScreenState createState() => _EditProfessionScreenState();
}

class _EditProfessionScreenState extends State<EditProfessionScreen> {
  late TextEditingController _titleController;
  late TextEditingController _companyController;

  // ========================================
  // INIT STATE - KOI CHANGE NAHI
  // ========================================
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _companyController = TextEditingController(text: widget.initialCompany);
  }

  // ========================================
  // DISPOSE - KOI CHANGE NAHI
  // ========================================
  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    super.dispose();
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
        title: const Text('MY PROFESSION'),
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
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.h),
                  
                  // UPDATED: Question Text ab theme se style ho raha hai
                  Text(
                    "What do you do?",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  SizedBox(height: 24.h),

                  // === JOB TITLE FIELD - THEME REFACTORED ===
                  _buildTextField(
                    theme: theme,
                    customColors: customColors,
                    controller: _titleController,
                    labelText: 'Job Title',
                    hintText: 'e.g. Software Engineer, Doctor, Student',
                    icon: Icons.work_outline_rounded,
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // === COMPANY FIELD - THEME REFACTORED ===
                  _buildTextField(
                    theme: theme,
                    customColors: customColors,
                    controller: _companyController,
                    labelText: 'Company / University',
                    hintText: 'e.g. Google, AIIMS, Delhi University',
                    icon: Icons.business_outlined,
                  ),
                ],
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
                  // Data ko Map me pack karke return (KOI LOGIC CHANGE NAHI)
                  final result = {
                    'title': _titleController.text.trim(),
                    'company': _companyController.text.trim(),
                  };
                  Navigator.of(context).pop(result);
                },
                // UPDATED: Save button styling ab Masterplan ke anusaar hai
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface, // White background
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
  // HELPER WIDGET: TEXT FIELD - THEME REFACTORED
  // ========================================
  Widget _buildTextField({
    required ThemeData theme,
    required CustomColors customColors,
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      // UPDATED: Text style ab theme se aa raha hai
      style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16.sp),
      decoration: InputDecoration(
        labelText: labelText,
        // UPDATED: Label style ab theme se aa raha hai
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          fontSize: 15.sp,
        ),
        hintText: hintText,
        // UPDATED: Hint style ab theme se aa raha hai
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.4),
          fontSize: 14.sp,
        ),
        prefixIcon: Icon(
          icon,
          // UPDATED: Icon color ab theme se aa raha hai
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          size: 24.sp,
        ),
        filled: true,
        // UPDATED: Fill color ab theme se aa raha hai
        fillColor: customColors.surface_2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          // UPDATED: Border color ab theme se aa raha hai
          borderSide: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          // UPDATED: Focused border ab primary color se aa raha hai
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}