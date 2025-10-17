// lib/screens/preference_selection_screen.dart (UPDATED - PROFESSIONAL, RESPONSIVE, THEME-BASED)

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // RESPONSIVE: Added
import 'package:lovz/models/gender_model.dart';
import 'package:lovz/screens/details_input_screen.dart';

class PreferenceSelectionScreen extends StatefulWidget {
  final List<String> selectedGenders;

  const PreferenceSelectionScreen({
    super.key,
    required this.selectedGenders,
  });

  @override
  State<PreferenceSelectionScreen> createState() => _PreferenceSelectionScreenState();
}

class _PreferenceSelectionScreenState extends State<PreferenceSelectionScreen> with SingleTickerProviderStateMixin {
  List<String> _selectedPreferences = [];
  bool _isExpandedView = false;
  bool _areAllSelected = false;

  // ANIMATION: Added animation controller
  late AnimationController _animationController;

  final List<Gender> _allGenders = const [
    Gender(title: 'Man', description: 'An adult male human being.'),
    Gender(title: 'Woman', description: 'An adult female human being.'),
    Gender(title: 'Agender', description: 'Individuals with no gender identity or a neutral gender identity.'),
    Gender(title: 'Androgynous', description: 'Individuals with both male and female presentation or nature.'),
    Gender(title: 'Bigender', description: 'Individuals who identify as multiple genders or identities, either simultaneously or at different times.'),
    Gender(title: 'Cis Man', description: 'Individuals whose gender identity matches the male sex they were assigned at birth.'),
    Gender(title: 'Cis Woman', description: 'Individuals whose gender identity matches the female sex they were assigned at birth.'),
    Gender(title: 'Genderfluid', description: 'Individuals who do not have a fixed gender identity.'),
    Gender(title: 'Genderqueer', description: 'Individuals who do not identify with binary gender identity norms.'),
    Gender(title: 'Gender Nonconforming', description: 'Individuals whose gender expressions do not match masculine and feminine gender norms.'),
    Gender(title: 'Hijra', description: 'A third gender identity, largely used in the Indian subcontinent, which typically reflects people who were assigned male at birth, who identify as neither male nor female.'),
    Gender(title: 'Intersex', description: 'Individuals born with a reproductive or sexual anatomy that does not fit the typical definitions of female or male.'),
    Gender(title: 'Non-binary', description: 'A term covering any gender identity or expression that does not fit within the gender binary.'),
    Gender(title: 'Other gender', description: 'Individuals who identify with any other gender expressions.'),
    Gender(title: 'Pangender', description: 'Individuals who identify with a wide multiplicity of gender identities.'),
    Gender(title: 'Transgender', description: 'Individuals whose gender identity differs from their assigned sex. This is an umbrella term.'),
    Gender(title: 'Trans Man', description: 'Individuals who were assigned female at birth (AFAB) but have a male gender identity.'),
    Gender(title: 'Transmasculine', description: 'Transgender individuals whose gender expression is more masculine presenting.'),
    Gender(title: 'Transsexual', description: 'This term is sometimes used to describe trans individuals (who do not identify with the sex they were assigned at birth) who wish to align their gender identity and sex through medical intervention.'),
    Gender(title: 'Trans Woman', description: 'Individuals who were assigned male at birth (AMAB) but have a female gender identity.'),
    Gender(title: 'Two-Spirit', description: 'Term largely used in Indigenous, Native American, and First Nation cultures, reflecting individuals who identify with multiple genders or identities that are neither male nor female.'),
  ];

  late final List<String> _allGenderTitles;

  @override
  void initState() {
    super.initState();
    _allGenderTitles = _allGenders.map((g) => g.title).toList();
    
    // ANIMATION: Initialize controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ============================================
  // NAVIGATION LOGIC (NO CHANGE)
  // ============================================
  void _onContinuePressed() {
    if (_selectedPreferences.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DetailsInputScreen(
            selectedGenders: widget.selectedGenders,
            selectedPreferences: _selectedPreferences,
          ),
        ),
      );
    }
  }

  // ============================================
  // UI BUILD METHOD (UPDATED - MODERN & RESPONSIVE)
  // ============================================
  @override
  Widget build(BuildContext context) {
    // THEME: Access theme data
    final theme = Theme.of(context);
    final bool isButtonActive = _selectedPreferences.isNotEmpty;

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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isExpandedView
                ? _buildExpandedView(theme)
                : _buildInitialView(theme),
          ),
        ),
      ),
      bottomNavigationBar: _buildContinueButton(theme, isButtonActive),
    );
  }

  // ============================================
  // INITIAL VIEW (UPDATED - MODERN DESIGN)
  // ============================================
  Widget _buildInitialView(ThemeData theme) {
    return SingleChildScrollView(
      key: const ValueKey('initialView'),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Container(
        padding: EdgeInsets.all(32.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20.r,
              spreadRadius: 2.r,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme),
            SizedBox(height: 40.h),
            _buildPreferenceOption(theme, 'Man'),
            SizedBox(height: 16.h),
            _buildPreferenceOption(theme, 'Woman'),
            SizedBox(height: 16.h),
            _buildSeeAllOption(theme),
          ],
        ),
      ),
    );
  }

  // ============================================
  // EXPANDED VIEW (UPDATED - THEME BASED)
  // ============================================
  Widget _buildExpandedView(ThemeData theme) {
    return Padding(
      key: const ValueKey('expandedView'),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.only(top: 20.h, left: 8.w, bottom: 10.h),
            child: Row(
              children: [
                InkWell(
                  onTap: () => setState(() => _isExpandedView = false),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: theme.colorScheme.onSurface,
                      size: 20.sp,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Text(
                  'I am interested in...',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          _buildSelectAllToggle(theme),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(top: 8.h),
              itemCount: _allGenders.length,
              itemBuilder: (context, index) => _buildGenderCheckbox(theme, _allGenders[index]),
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
        Text(
          'Lovz',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 40.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Step 2 of 3',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14.sp,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        SizedBox(height: 16.h),
        _buildProgressBar(theme, 2 / 3),
        SizedBox(height: 32.h),
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
            Icons.track_changes_rounded,
            color: theme.colorScheme.onPrimary,
            size: 40.sp,
          ),
        ),
        SizedBox(height: 20.h),
        Text(
          'Show me',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Who would you like to meet?',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 16.sp,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  // ============================================
  // PROGRESS BAR (NEW - MODERN DESIGN)
  // ============================================
  Widget _buildProgressBar(ThemeData theme, double progress) {
    return Container(
      height: 8.h,
      decoration: BoxDecoration(
        color: theme.dividerColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
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
      ),
    );
  }

  // ============================================
  // PREFERENCE OPTION (UPDATED - MODERN CARD)
  // ============================================
  Widget _buildPreferenceOption(ThemeData theme, String preference) {
    final bool isSelected = _selectedPreferences.contains(preference) && 
                           _selectedPreferences.length == 1;

    return InkWell(
      onTap: () => setState(() {
        _selectedPreferences.clear();
        _selectedPreferences.add(preference);
      }),
      borderRadius: BorderRadius.circular(16.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor,
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ]
              : [],
        ),
        child: Text(
          preference,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  // ============================================
  // SEE ALL OPTION (UPDATED - MODERN DESIGN)
  // ============================================
  Widget _buildSeeAllOption(ThemeData theme) {
    return InkWell(
      onTap: () => setState(() {
        _isExpandedView = true;
        _selectedPreferences.clear();
        _areAllSelected = false;
      }),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'See all',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: theme.colorScheme.primary,
              size: 18.sp,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // SELECT ALL TOGGLE (UPDATED - MODERN SWITCH)
  // ============================================
  Widget _buildSelectAllToggle(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 12.w),
            child: Text(
              'Select All',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Switch(
            value: _areAllSelected,
            onChanged: (bool value) {
              setState(() {
                _areAllSelected = value;
                if (_areAllSelected) {
                  _selectedPreferences = List.from(_allGenderTitles);
                } else {
                  _selectedPreferences.clear();
                }
              });
            },
            activeTrackColor: theme.colorScheme.primary.withOpacity(0.5),
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  // ============================================
  // GENDER CHECKBOX (UPDATED - MODERN CARD)
  // ============================================
  Widget _buildGenderCheckbox(ThemeData theme, Gender gender) {
    final bool isSelected = _selectedPreferences.contains(gender.title);

    return InkWell(
      onTap: () => setState(() {
        if (isSelected) {
          _selectedPreferences.remove(gender.title);
          if (_areAllSelected) _areAllSelected = false;
        } else {
          _selectedPreferences.add(gender.title);
          if (_selectedPreferences.length == _allGenders.length) {
            _areAllSelected = true;
          }
        }
      }),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.15)
                : theme.colorScheme.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gender.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      gender.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Container(
                width: 24.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.dividerColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: theme.colorScheme.onPrimary,
                        size: 16.sp,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // CONTINUE BUTTON (UPDATED - SAVE BUTTON RULE)
  // ============================================
  Widget _buildContinueButton(ThemeData theme, bool isActive) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: ElevatedButton(
          onPressed: isActive ? _onContinuePressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withOpacity(0.3),
            foregroundColor: theme.colorScheme.surface,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            elevation: isActive ? 4 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Continue'),
              SizedBox(width: 8.w),
              Icon(Icons.arrow_forward_rounded, size: 20.sp),
            ],
          ),
        ),
      ),
    );
  }
}