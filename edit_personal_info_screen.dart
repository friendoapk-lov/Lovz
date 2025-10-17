// lib/screens/edit_personal_info_screen.dart - Dark Theme Redesigned

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class EditPersonalInfoScreen extends StatefulWidget {
  final String initialName;
  final String initialAge;
  final String initialLocation;

  const EditPersonalInfoScreen({
    Key? key,
    required this.initialName,
    required this.initialAge,
    required this.initialLocation,
  }) : super(key: key);

  @override
  _EditPersonalInfoScreenState createState() => _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState extends State<EditPersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _ageController = TextEditingController(text: widget.initialAge);
    _locationController = TextEditingController(text: widget.initialLocation);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final updatedData = {
        'name': _nameController.text,
        'age': _ageController.text,
        'location': _locationController.text,
      };
      Navigator.of(context).pop(updatedData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A), // Pure dark black
      
      // === DARK THEMED HEADER ===
      appBar: PreferredSize(
        preferredSize: Size(0.95.sw, 56.h + MediaQuery.of(context).padding.top),
        child: Container(
          width: 0.95.sw,
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 10.w,
            right: 10.w,
          ),
          height: 56.h,
          decoration: BoxDecoration(
            color: Color(0xFF0A0A0A),
          ),
          child: Stack(
            children: [
              // Back Button - Left
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              // Title - Center
              Center(
                child: Text(
                  'EDIT PERSONAL INFO',
                  style: GoogleFonts.anton(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      
      body: Column(
        children: [
          // Divider line
          Container(
            height: 1.h,
            color: Color(0xFF424242),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 20.h),
                    
                    // === NAME FIELD ===
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Your Name',
                        labelStyle: TextStyle(
                          color: Colors.white54,
                          fontSize: 15.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white54,
                          size: 24.sp,
                        ),
                        filled: true,
                        fillColor: Color(0xFF2A2A2A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: Color(0xFFFF453A).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: Color(0xFFFF453A),
                            width: 1.5,
                          ),
                        ),
                        errorStyle: TextStyle(
                          color: Color(0xFFFF453A).withOpacity(0.8),
                          fontSize: 13.sp,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 20.h),
                    
                    // === AGE FIELD ===
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Your Age',
                        labelStyle: TextStyle(
                          color: Colors.white54,
                          fontSize: 15.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.cake_outlined,
                          color: Colors.white54,
                          size: 24.sp,
                        ),
                        filled: true,
                        fillColor: Color(0xFF2A2A2A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: Color(0xFFFF453A).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: Color(0xFFFF453A),
                            width: 1.5,
                          ),
                        ),
                        errorStyle: TextStyle(
                          color: Color(0xFFFF453A).withOpacity(0.8),
                          fontSize: 13.sp,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your age';
                        }
                        if (int.tryParse(value) == null || int.parse(value) < 18) {
                          return 'You must be at least 18 years old';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 20.h),
                    
                    // === LOCATION FIELD (READ ONLY) ===
                    TextFormField(
                      controller: _locationController,
                      readOnly: true,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 16.sp,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Location', // NO "Fixed" text
                        labelStyle: TextStyle(
                          color: Colors.white54,
                          fontSize: 15.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF5AC8FA), // Cyan blue for location
                          size: 24.sp,
                        ),
                        filled: true,
                        fillColor: Color(0xFF2A2A2A).withOpacity(0.5), // Slightly dimmed
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.05),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 40.h),
                    
                    // === SAVE BUTTON ===
                    ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        backgroundColor: Colors.white, // White button
                        foregroundColor: Color(0xFF0A0A0A), // Dark text
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save', // Simple text (no Google Fonts)
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}