// lib/screens/filter_screen.dart (FULLY UPDATED - PROFESSIONAL, RESPONSIVE, THEME-BASED)

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lovz/widgets/location_search_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lovz/utils/theme.dart'; // THEME: Imported for CustomColors

// ============================================
// HELPER CLASS (NO CHANGE)
// ============================================
class SelectableOption {
  final String title;
  final String? description;
  SelectableOption(this.title, {this.description});
}

// ============================================
// FILTER SCREEN WIDGET
// ============================================
class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

// ============================================
// FILTER SCREEN STATE
// ============================================
class _FilterScreenState extends State<FilterScreen> {
  // ============================================
  // DEFAULT VALUES (NO CHANGE)
  // ============================================
  final RangeValues _defaultAgeRange = const RangeValues(22, 35);
  final double _defaultDistance = 50.0;
  final List<String> _defaultGenders = [];
  final List<String> _defaultOrientations = [];
  final List<String> _defaultIdentities = [];

  // ============================================
  // STATE VARIABLES FOR FILTERS (NO CHANGE)
  // ============================================
  late RangeValues _currentAgeRange;
  late double _currentDistance;
  late List<String> _selectedGenders;
  late List<String> _selectedOrientations;
  late List<String> _selectedIdentities;

  bool _isLoading = true;

  // ============================================
  // LOCATION STATE VARIABLES (NO CHANGE)
  // ============================================
  String _currentLocationName = "Anywhere";
  double? _currentLocationLat;
  double? _currentLocationLng;
  late String _originalLocationName;

  // ============================================
  // SEE ALL TOGGLE STATE (NO CHANGE)
  // ============================================
  bool _showAllGenders = false;
  bool _showAllOrientations = false;
  bool _showAllIdentities = false;

  // ============================================
  // INIT STATE (NO CHANGE)
  // ============================================
  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  // ============================================
  // LOAD FILTERS FROM STORAGE (NO CHANGE)
  // ============================================
  Future<void> _loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    String defaultLocationName = "Anywhere";
    if (currentUserUid != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .get();
      if (userDoc.exists) {
        defaultLocationName = userDoc.data()?['locationName'] ?? "Anywhere";
      }
    }

    setState(() {
      _originalLocationName = defaultLocationName;

      final minAge = prefs.getDouble('filter_min_age') ?? _defaultAgeRange.start;
      final maxAge = prefs.getDouble('filter_max_age') ?? _defaultAgeRange.end;
      _currentAgeRange = RangeValues(minAge, maxAge);

      _currentDistance = prefs.getDouble('filter_distance') ?? _defaultDistance;
      _selectedGenders = prefs.getStringList('filter_genders') ?? List.from(_defaultGenders);
      _selectedOrientations = prefs.getStringList('filter_orientations') ?? List.from(_defaultOrientations);
      _selectedIdentities = prefs.getStringList('filter_identities') ?? List.from(_defaultIdentities);

      _currentLocationName = prefs.getString('filter_location_name') ?? _originalLocationName;
      _currentLocationLat = prefs.getDouble('filter_location_lat');
      _currentLocationLng = prefs.getDouble('filter_location_lng');

      _isLoading = false;
    });
  }

  // ============================================
  // SAVE FILTERS TO STORAGE (NO CHANGE)
  // ============================================
  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setDouble('filter_min_age', _currentAgeRange.start);
    await prefs.setDouble('filter_max_age', _currentAgeRange.end);
    await prefs.setDouble('filter_distance', _currentDistance);
    await prefs.setStringList('filter_genders', _selectedGenders);
    await prefs.setStringList('filter_orientations', _selectedOrientations);
    await prefs.setStringList('filter_identities', _selectedIdentities);

    if (_currentLocationLat != null && _currentLocationLng != null) {
      await prefs.setString('filter_location_name', _currentLocationName);
      await prefs.setDouble('filter_location_lat', _currentLocationLat!);
      await prefs.setDouble('filter_location_lng', _currentLocationLng!);
    } else {
      await prefs.remove('filter_location_name');
      await prefs.remove('filter_location_lat');
      await prefs.remove('filter_location_lng');
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // ============================================
  // RESET FILTERS (NO CHANGE)
  // ============================================
  Future<void> _resetFilters() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove('filter_min_age');
    await prefs.remove('filter_max_age');
    await prefs.remove('filter_distance');
    await prefs.remove('filter_genders');
    await prefs.remove('filter_orientations');
    await prefs.remove('filter_identities');
    await prefs.remove('filter_location_name');
    await prefs.remove('filter_location_lat');
    await prefs.remove('filter_location_lng');

    setState(() {
      _currentAgeRange = _defaultAgeRange;
      _currentDistance = _defaultDistance;
      _selectedGenders = List.from(_defaultGenders);
      _selectedOrientations = List.from(_defaultOrientations);
      _selectedIdentities = List.from(_defaultIdentities);
      _currentLocationName = _originalLocationName;
      _currentLocationLat = null;
      _currentLocationLng = null;
    });
  }

  // ============================================
  // MAIN BUILD METHOD (UPDATED - THEME-BASED & RESPONSIVE)
  // ============================================
  @override
  Widget build(BuildContext context) {
    // THEME: Access theme and custom colors
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;

    // ============================================
    // DATA LISTS (NO CHANGE)
    // ============================================
    final List<SelectableOption> primaryGenders = [
      SelectableOption('Man', description: 'An adult male human being.'),
      SelectableOption('Woman', description: 'An adult female human being.'),
    ];
    
    final List<SelectableOption> allGenders = [
      SelectableOption('Man', description: 'An adult male human being.'),
      SelectableOption('Woman', description: 'An adult female human being.'),
      SelectableOption('Agender', description: 'Individuals with no gender identity or a neutral gender identity.'),
      SelectableOption('Androgynous', description: 'Individuals with both male and female presentation or nature.'),
      SelectableOption('Bigender', description: 'Individuals who identify as multiple genders or identities, either simultaneously or at different times.'),
      SelectableOption('Cis Man', description: 'Individuals whose gender identity matches the male sex they were assigned at birth.'),
      SelectableOption('Cis Woman', description: 'Individuals whose gender identity matches the female sex they were assigned at birth.'),
      SelectableOption('Genderfluid', description: 'Individuals who do not have a fixed gender identity.'),
      SelectableOption('Genderqueer', description: 'Individuals who do not identify with binary gender identity norms.'),
      SelectableOption('Gender Nonconforming', description: 'Individuals whose gender expressions do not match masculine and feminine gender norms.'),
      SelectableOption('Hijra', description: 'A third gender identity, largely used in the Indian subcontinent, which typically reflects people who were assigned male at birth, who identify as neither male nor female.'),
      SelectableOption('Intersex', description: 'Individuals born with a reproductive or sexual anatomy that does not fit the typical definitions of female or male.'),
      SelectableOption('Non-binary', description: 'A term covering any gender identity or expression that does not fit within the gender binary.'),
      SelectableOption('Other gender', description: 'Individuals who identify with any other gender expressions.'),
      SelectableOption('Pangender', description: 'Individuals who identify with a wide multiplicity of gender identities.'),
      SelectableOption('Transgender', description: 'Individuals whose gender identity differs from their assigned sex. This is an umbrella term.'),
      SelectableOption('Trans Man', description: 'Individuals who were assigned female at birth (AFAB) but have a male gender identity.'),
      SelectableOption('Transmasculine', description: 'Transgender individuals whose gender expression is more masculine presenting.'),
      SelectableOption('Transsexual', description: 'This term is sometimes used to describe trans individuals (who do not identify with the sex they were assigned at birth) who wish to align their gender identity and sex through medical intervention.'),
      SelectableOption('Trans Woman', description: 'Individuals who were assigned male at birth (AMAB) but have a female gender identity.'),
      SelectableOption('Two-Spirit', description: 'Term largely used in Indigenous, Native American, and First Nation cultures, reflecting individuals who identify with multiple genders or identities that are neither male nor female.'),
    ];
    
    final List<SelectableOption> primaryOrientations = [
      SelectableOption('Straight', description: 'Attracted mostly to people of the opposite sex or gender.'),
      SelectableOption('Gay', description: 'Attracted mostly to people of the same sex or gender.'),
      SelectableOption('Lesbian', description: 'A woman who is attracted mostly to other women.'),
      SelectableOption('Bisexual', description: 'Attracted to more than one sex or gender.'),
    ];
    
    final List<SelectableOption> allOrientations = [
      SelectableOption('Straight', description: 'Attracted mostly to people of the opposite sex or gender.'),
      SelectableOption('Gay', description: 'Attracted mostly to people of the same sex or gender.'),
      SelectableOption('Bisexual', description: 'Attracted to more than one sex or gender.'),
      SelectableOption('Asexual', description: 'Not sexually attracted to anyone and/or has no desire for sexual relationships.'),
      SelectableOption('Demisexual', description: 'Experiences sexual attraction only after forming a strong emotional bond.'),
      SelectableOption('Homoflexible', description: 'Primarily attracted to the same sex but with some flexibility for attraction to other sexes.'),
      SelectableOption('Heteroflexible', description: 'Primarily attracted to the opposite sex but with some flexibility for attraction to other sexes.'),
      SelectableOption('Lesbian', description: 'A woman who is attracted mostly to other women.'),
      SelectableOption('Pansexual', description: 'Attracted to people regardless of their sex or gender identity.'),
      SelectableOption('Queer', description: 'An umbrella term for those who are not straight and/or not cisgender.'),
      SelectableOption('Questioning', description: 'In the process of exploring one\'s own sexual orientation.'),
      SelectableOption('Gray-asexual', description: 'Experiences sexual attraction very rarely or with very low intensity.'),
      SelectableOption('Reciprosexual', description: 'Experiences sexual attraction only when they know the other person is attracted to them first.'),
      SelectableOption('Akiosexual', description: 'Experiences sexual attraction but does not want it to be reciprocated.'),
      SelectableOption('Aceflux', description: 'Sexual orientation fluctuates on the asexual spectrum.'),
      SelectableOption('Grayromantic', description: 'Experiences romantic attraction very rarely or with very low intensity.'),
      SelectableOption('Demiromantic', description: 'Experiences romantic attraction only after forming a strong emotional bond.'),
      SelectableOption('Recipromantic', description: 'Experiences romantic attraction only when they know the other person is attracted to them first.'),
      SelectableOption('Akioromantic', description: 'Experiences romantic attraction but does not want it to be reciprocated.'),
      SelectableOption('Aroflux', description: 'Romantic orientation fluctuates on the aromantic spectrum.'),
    ];
    
    final List<SelectableOption> primaryIdentities = [
      SelectableOption('Top'),
      SelectableOption('Bottom'),
      SelectableOption('Versatile')
    ];
    
    final List<SelectableOption> allIdentities = [
      SelectableOption('Top'), SelectableOption('Bottom'), SelectableOption('Versatile'),
      SelectableOption('Bear'), SelectableOption('Bio'), SelectableOption('Butch'),
      SelectableOption('Drag king'), SelectableOption('Drag queen'), SelectableOption('Femme'),
      SelectableOption('Hard femme'), SelectableOption('High femme'), SelectableOption('Leather'),
      SelectableOption('Otter'), SelectableOption('Soft butch'), SelectableOption('Stone butch'),
      SelectableOption('Stone femme'), SelectableOption('Stud'), SelectableOption('Switch'),
      SelectableOption('Twink')
    ];

    // ============================================
    // LOADING STATE CHECK (UPDATED - THEME BASED)
    // ============================================
    if (_isLoading) {
      return Scaffold(
        // UPDATED: Using scaffoldBackgroundColor from theme
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            // UPDATED: Using primary color from theme
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    // ============================================
    // MAIN SCAFFOLD (UPDATED - STANDARD APPBAR)
    // ============================================
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        // UPDATED: Using scaffoldBackgroundColor from theme
        backgroundColor: theme.scaffoldBackgroundColor,
        
        // UPDATED: Standard AppBar (Anton font automatically applied)
        appBar: AppBar(
          title: const Text('PREFERENCES'),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        
        body: Column(
          children: [
            // UPDATED: Using Container instead of Divider widget
            Container(height: 1.h, color: theme.dividerColor),
            
            // === SCROLLABLE CONTENT ===
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(20.w),
                children: [
                  // === AGE RANGE SECTION ===
                  _buildSectionTitle(theme, 'AGE RANGE: ${_currentAgeRange.start.round()} - ${_currentAgeRange.end.round()}'),
                  SizedBox(height: 8.h),
                  _buildAgeRangeSlider(theme),
                  SizedBox(height: 24.h),

                  // === DISTANCE SECTION ===
                  _buildSectionTitle(theme, 'DISTANCE: ${_currentDistance.round()} KM'),
                  SizedBox(height: 8.h),
                  _buildDistanceSlider(theme),
                  SizedBox(height: 24.h),

                  // === LOCATION SECTION ===
                  _buildSectionTitle(theme, 'LOCATION'),
                  SizedBox(height: 8.h),
                  _buildLocationSelector(theme, customColors),
                  SizedBox(height: 32.h),

                  // === DIVIDER ===
                  Container(height: 1.h, color: theme.dividerColor),
                  SizedBox(height: 32.h),

                  // === INTERESTED IN SECTION ===
                  _buildExpandableCheckboxSection(
                    theme: theme,
                    title: "I'M INTERESTED IN",
                    primaryOptions: primaryGenders,
                    allOptions: allGenders,
                    selectedOptions: _selectedGenders,
                    isExpanded: _showAllGenders,
                    onToggle: () => setState(() => _showAllGenders = !_showAllGenders),
                  ),
                  SizedBox(height: 32.h),

                  // === DIVIDER ===
                  Container(height: 1.h, color: theme.dividerColor),
                  SizedBox(height: 32.h),

                  // === SEXUAL ORIENTATION SECTION ===
                  _buildExpandableCheckboxSection(
                    theme: theme,
                    title: "SEXUAL ORIENTATION",
                    primaryOptions: primaryOrientations,
                    allOptions: allOrientations,
                    selectedOptions: _selectedOrientations,
                    isExpanded: _showAllOrientations,
                    onToggle: () => setState(() => _showAllOrientations = !_showAllOrientations),
                  ),
                  SizedBox(height: 32.h),

                  // === DIVIDER ===
                  Container(height: 1.h, color: theme.dividerColor),
                  SizedBox(height: 32.h),

                  // === IDENTITY SECTION ===
                  _buildExpandableCheckboxSection(
                    theme: theme,
                    title: "IDENTITY",
                    primaryOptions: primaryIdentities,
                    allOptions: allIdentities,
                    selectedOptions: _selectedIdentities,
                    isExpanded: _showAllIdentities,
                    onToggle: () => setState(() => _showAllIdentities = !_showAllIdentities),
                  ),
                  SizedBox(height: 40.h),

                  // === ACTION BUTTONS ===
                  _buildActionButtons(theme),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // SECTION TITLE (UPDATED - THEME BASED)
  // ============================================
  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      // UPDATED: Using headlineLarge for Anton font (automatically applied)
      style: theme.textTheme.headlineLarge?.copyWith(
        fontSize: 15.sp,
        letterSpacing: 1.5,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  // ============================================
  // AGE RANGE SLIDER (UPDATED - THEME BASED)
  // ============================================
  Widget _buildAgeRangeSlider(ThemeData theme) {
    return SliderTheme(
      data: SliderThemeData(
        // UPDATED: Using primary color from theme
        activeTrackColor: theme.colorScheme.primary,
        // UPDATED: Using dividerColor from theme
        inactiveTrackColor: theme.dividerColor,
        // UPDATED: Using onSurface color
        thumbColor: theme.colorScheme.onSurface,
        overlayColor: theme.colorScheme.primary.withOpacity(0.2),
        valueIndicatorColor: theme.colorScheme.primary,
        valueIndicatorTextStyle: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
        ),
        trackHeight: 4.h,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.r),
        rangeThumbShape: RoundRangeSliderThumbShape(enabledThumbRadius: 10.r),
      ),
      child: RangeSlider(
        values: _currentAgeRange,
        min: 18,
        max: 80,
        divisions: 62,
        labels: RangeLabels(
          _currentAgeRange.start.round().toString(),
          _currentAgeRange.end.round().toString(),
        ),
        onChanged: (v) => setState(() => _currentAgeRange = v),
      ),
    );
  }

  // ============================================
  // DISTANCE SLIDER (UPDATED - THEME BASED)
  // ============================================
  Widget _buildDistanceSlider(ThemeData theme) {
    return SliderTheme(
      data: SliderThemeData(
        // UPDATED: Using primary color from theme
        activeTrackColor: theme.colorScheme.primary,
        inactiveTrackColor: theme.dividerColor,
        thumbColor: theme.colorScheme.onSurface,
        overlayColor: theme.colorScheme.primary.withOpacity(0.2),
        valueIndicatorColor: theme.colorScheme.primary,
        valueIndicatorTextStyle: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
        ),
        trackHeight: 4.h,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.r),
      ),
      child: Slider(
        value: _currentDistance,
        min: 1,
        max: 100,
        divisions: 99,
        label: '${_currentDistance.round()} km',
        onChanged: (v) => setState(() => _currentDistance = v),
      ),
    );
  }

  // ============================================
  // LOCATION SELECTOR (UPDATED - THEME BASED)
  // ============================================
  Widget _buildLocationSelector(ThemeData theme, CustomColors customColors) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        // UPDATED: Using custom surface_2 color
        color: customColors.surface_2,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: InkWell(
        onTap: () async {
          final result = await showModalBottomSheet<Map<String, dynamic>>(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext context) {
              return const LocationSearchSheet();
            },
          );

          if (result != null && result.containsKey('lat')) {
            setState(() {
              _currentLocationName = result['name'];
              _currentLocationLat = result['lat'];
              _currentLocationLng = result['lng'];
            });
          }
        },
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              // UPDATED: Using primary color
              color: theme.colorScheme.primary,
              size: 24.sp,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                _currentLocationName,
                // UPDATED: Using theme text style
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 16.sp,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14.sp,
              // UPDATED: Using onSurface with opacity
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // EXPANDABLE CHECKBOX SECTION (UPDATED - THEME BASED)
  // ============================================
  Widget _buildExpandableCheckboxSection({
    required ThemeData theme,
    required String title,
    required List<SelectableOption> primaryOptions,
    required List<SelectableOption> allOptions,
    required List<String> selectedOptions,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    List<SelectableOption> visibleOptions = primaryOptions;
    List<SelectableOption> hiddenOptions = allOptions
        .where((opt) => !primaryOptions.any((p) => p.title == opt.title))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(theme, title),
        SizedBox(height: 12.h),
        
        // Primary Options
        ...visibleOptions.map((option) => _buildCheckbox(theme, option, selectedOptions)),
        
        // Hidden Options (if expanded)
        if (isExpanded)
          ...hiddenOptions.map((option) => _buildCheckbox(theme, option, selectedOptions)),
        
        // See All / See Less Button
        if (hiddenOptions.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: TextButton(
              onPressed: onToggle,
              style: TextButton.styleFrom(
                // UPDATED: Using primary color
                foregroundColor: theme.colorScheme.primary,
                padding: EdgeInsets.zero,
              ),
              child: Text(
                isExpanded ? 'See less' : 'See all',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================
  // CHECKBOX (UPDATED - THEME BASED)
  // ============================================
  Widget _buildCheckbox(ThemeData theme, SelectableOption option, List<String> selectedOptions) {
    return CheckboxListTile(
      title: Text(
        option.title,
        // UPDATED: Using theme text style
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: 16.sp,
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: option.description != null
          ? Text(
              option.description!,
              // UPDATED: Using theme text style with opacity
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            )
          : null,
      value: selectedOptions.contains(option.title),
      onChanged: (bool? value) {
        setState(() {
          if (value == true) {
            selectedOptions.add(option.title);
          } else {
            selectedOptions.remove(option.title);
          }
        });
      },
      // UPDATED: Using primary color
      activeColor: theme.colorScheme.primary,
      checkColor: theme.colorScheme.onPrimary,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.symmetric(vertical: 4.h),
      dense: true,
    );
  }

  // ============================================
  // ACTION BUTTONS (UPDATED - SAVE BUTTON RULE)
  // ============================================
  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        // === APPLY BUTTON (Following Save Button Rule) ===
        Expanded(
          child: ElevatedButton(
            onPressed: _saveFilters,
            // UPDATED: Following Save Button Rule
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.onSurface, // White
              foregroundColor: theme.colorScheme.surface,   // Dark
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('Apply'),
          ),
        ),
        
        SizedBox(width: 16.w),
        
        // === RESET BUTTON (Outlined) ===
        Expanded(
          child: OutlinedButton(
            onPressed: _resetFilters,
            style: OutlinedButton.styleFrom(
              // UPDATED: Using onSurface with opacity for border
              side: BorderSide(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                width: 1.5,
              ),
              // UPDATED: Using onSurface color for text
              foregroundColor: theme.colorScheme.onSurface,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('Reset'),
          ),
        ),
      ],
    );
  }
}