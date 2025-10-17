// lib/screens/details_input_screen.dart (UPDATED - FULLY COMPLETE, PROFESSIONAL, RESPONSIVE, THEME-BASED)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // RESPONSIVE: Added
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lovz/screens/main_wrapper.dart';

class DetailsInputScreen extends StatefulWidget {
  final List<String> selectedGenders;
  final List<String> selectedPreferences;

  const DetailsInputScreen({
    super.key,
    required this.selectedGenders,
    required this.selectedPreferences,
  });

  @override
  State<DetailsInputScreen> createState() => _DetailsInputScreenState();
}

class _DetailsInputScreenState extends State<DetailsInputScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isButtonActive = false;
  bool _isLoading = false;
  bool _isFetchingLocation = false;
  GeoPoint? _currentLocationGeoPoint;

  // ANIMATION: Added animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateInputs);
    _ageController.addListener(_validateInputs);
    _locationController.addListener(_validateInputs);

    // ANIMATION: Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  // ============================================
  // VALIDATION LOGIC (NO CHANGE)
  // ============================================
  void _validateInputs() {
    final name = _nameController.text;
    final age = _ageController.text;
    final location = _locationController.text;

    final bool shouldBeActive = name.isNotEmpty && age.isNotEmpty && location.isNotEmpty;

    if (shouldBeActive != _isButtonActive) {
      setState(() {
        _isButtonActive = shouldBeActive;
      });
    }
  }

  // ============================================
  // FIREBASE SAVE LOGIC (NO CHANGE)
  // ============================================
  void _onStartDatingPressed() async {
    if (!_isButtonActive || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No user logged in!");
      }

      final initialUserData = {
        'uid': user.uid,
        'phoneNumber': user.phoneNumber,
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'location': _currentLocationGeoPoint,
        'locationName': _locationController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'preferences': widget.selectedPreferences,
        'myBasics': {
          'gender': widget.selectedGenders,
          'orientation': [],
          'identity': [],
          'relationship': null,
        },
        'profileImageUrls': [],
        'aboutMe': '',
        'heightWeight': {},
        'myWork': {},
        'interests': [],
        'languages': [],
        'habits': {},
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(initialUserData);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainWrapper()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create profile: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================
  // LOCATION DETECTION LOGIC (NO CHANGE)
  // ============================================
  Future<void> _getCurrentLocation() async {
    if (_isFetchingLocation) return;

    setState(() {
      _isFetchingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          setState(() => _isFetchingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied')),
        );
        setState(() => _isFetchingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocationGeoPoint = GeoPoint(position.latitude, position.longitude);
      });

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = "${place.locality}, ${place.country}";
        _locationController.text = address;
      } else {
        _locationController.text = "Could not determine location";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    } finally {
      setState(() {
        _isFetchingLocation = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ============================================
  // UI BUILD METHOD (UPDATED - MODERN & RESPONSIVE)
  // ============================================
  @override
  Widget build(BuildContext context) {
    // THEME: Access theme data
    final theme = Theme.of(context);

    return Scaffold(
      // UPDATED: Using scaffoldBackgroundColor
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        // UPDATED: Modern gradient
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.15),
              theme.colorScheme.primary.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildDetailsCard(theme),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // DETAILS CARD (UPDATED - MODERN DESIGN)
  // ============================================
  Widget _buildDetailsCard(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        // UPDATED: Using surface color
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20.r,
            spreadRadius: 2.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back Button
          Align(
            alignment: Alignment.topLeft,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20.sp,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),

          // Header
          _buildHeader(theme),
          SizedBox(height: 40.h),

          // Name Field
          _buildTextField(
            theme: theme,
            label: 'First Name',
            controller: _nameController,
            icon: Icons.person_outline_rounded,
          ),
          SizedBox(height: 20.h),

          // Age Field
          _buildTextField(
            theme: theme,
            label: 'Age',
            controller: _ageController,
            icon: Icons.cake_outlined,
            isNumeric: true,
          ),
          SizedBox(height: 20.h),

          // Location Field
          _buildLocationField(theme),
          SizedBox(height: 40.h),

          // Start Dating Button
          _buildStartDatingButton(theme),
          SizedBox(height: 24.h),

          // Footer Text
          Text(
            'You can always add more details later in your profile',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // HEADER (UPDATED - MODERN DESIGN)
  // ============================================
  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        // App Logo
        Text(
          'Lovz',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 40.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: 8.h),

        // Step Indicator
        Text(
          'Step 3 of 3',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14.sp,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        SizedBox(height: 16.h),

        // Progress Bar (Full - 100%)
        Container(
          height: 8.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.7),
              ],
            ),
          ),
        ),
        SizedBox(height: 32.h),

        // Icon
        Container(
          width: 80.w,
          height: 80.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 20.r,
                spreadRadius: 2.r,
              ),
            ],
          ),
          child: Icon(
            Icons.favorite_border_rounded,
            color: theme.colorScheme.onPrimary,
            size: 40.sp,
          ),
        ),
        SizedBox(height: 20.h),

        // Title
        Text(
          'Almost there!',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),

        // Subtitle
        Text(
          'Tell us a bit about yourself',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 16.sp,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  // ============================================
  // TEXT FIELD (UPDATED - MODERN STYLING WITH ICONS)
  // ============================================
  Widget _buildTextField({
    required ThemeData theme,
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isNumeric = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),

        // Text Field
        TextFormField(
          controller: controller,
          enabled: !_isLoading,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.name,
          inputFormatters: isNumeric ? [FilteringTextInputFormatter.digitsOnly] : [],
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 16.sp,
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 22.sp,
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: theme.dividerColor,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // LOCATION FIELD (UPDATED - WITH DETECTION BUTTON)
  // ============================================
  Widget _buildLocationField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          'Location',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),

        // Location Field with Detection Button
        TextFormField(
          controller: _locationController,
          readOnly: true, // User cannot type, must use location detection
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 16.sp,
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.location_on_outlined,
              color: theme.colorScheme.primary,
              size: 22.sp,
            ),
            hintText: 'Tap the icon to detect location',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              fontSize: 14.sp,
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: theme.dividerColor,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            // Suffix Icon: Loading or Detect Button
            suffixIcon: _isFetchingLocation
                ? Padding(
                    padding: EdgeInsets.all(12.w),
                    child: SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      Icons.my_location_rounded,
                      color: theme.colorScheme.primary,
                      size: 24.sp,
                    ),
                    onPressed: _getCurrentLocation,
                  ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // START DATING BUTTON (UPDATED - SAVE BUTTON RULE)
  // ============================================
  Widget _buildStartDatingButton(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isButtonActive && !_isLoading ? _onStartDatingPressed : null,
        style: ElevatedButton.styleFrom(
          // UPDATED: Following Save Button Rule
          backgroundColor: _isButtonActive && !_isLoading
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withOpacity(0.3),
          foregroundColor: theme.colorScheme.surface,
          padding: EdgeInsets.symmetric(vertical: 18.h),
          elevation: _isButtonActive && !_isLoading ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.surface,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  const Text('Creating your profile...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Start Dating!'),
                  SizedBox(width: 8.w),
                  Icon(Icons.favorite_rounded, size: 20.sp),
                ],
              ),
      ),
    );
  }
}