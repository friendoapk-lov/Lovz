// lib/screens/edit_basics_hub_screen.dart - THEME REFACTORED & PERFECTED

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovz/screens/edit_gender_screen.dart';
import 'package:lovz/screens/edit_orientation_screen.dart';
import 'package:lovz/screens/edit_identity_screen.dart';
import 'package:lovz/screens/edit_relationship_screen.dart';
import 'package:lovz/models/user_profile_model.dart';

// ========================================
// CLASS DEFINITION - KOI BADLAV NAHI
// ========================================
class EditBasicsHubScreen extends StatefulWidget {
  final List<String> initialGender;
  final List<String> initialOrientation;
  final List<String> initialIdentity;
  final bool initialIdentityPreferNotToSay;
  final Map<String, dynamic>? initialRelationshipData;

  const EditBasicsHubScreen({
    Key? key,
    required this.initialGender,
    required this.initialOrientation,
    required this.initialIdentity,
    required this.initialIdentityPreferNotToSay,
    this.initialRelationshipData,
  }) : super(key: key);

  @override
  State<EditBasicsHubScreen> createState() => _EditBasicsHubScreenState();
}

// ========================================
// STATE CLASS - KOI BADLAV NAHI
// ========================================
class _EditBasicsHubScreenState extends State<EditBasicsHubScreen> {
  // --- STATE & LOGIC (No Changes) ---
  late List<String> _gender;
  late List<String> _orientation;
  late List<String> _identity;
  late bool _identityPreferNotToSay;
  late Map<String, dynamic> _relationshipData;

  @override
  void initState() {
    super.initState();
    _gender = List.from(widget.initialGender);
    _orientation = List.from(widget.initialOrientation);
    _identity = List.from(widget.initialIdentity);
    _identityPreferNotToSay = widget.initialIdentityPreferNotToSay;
    
    _relationshipData = widget.initialRelationshipData ?? {
      'type': RelationshipType.monogamous,
      'status': null,
    };
  }

  // --- LOGIC HELPER FUNCTIONS (No Changes) ---
  String _getRelationshipDisplayString() {
    RelationshipType type = _relationshipData['type'];
    NonMonogamousStatus? status = _relationshipData['status'];
    
    switch (type) {
      case RelationshipType.monogamous:
        return 'Monogamous';
      case RelationshipType.openToEither:
        return 'Open to either';
      case RelationshipType.nonMonogamous:
        if (status != null) {
          String statusName = status.toString().split('.').last;
          return statusName[0].toUpperCase() + statusName.substring(1);
        }
        return 'Non-monogamous';
      default:
        return 'Not specified';
    }
  }

  void _saveAndExit() {
    Navigator.of(context).pop({
      'gender': _gender,
      'orientation': _orientation,
      'identity': _identity,
      'identityPreferNotToSay': _identityPreferNotToSay,
      'relationshipData': _relationshipData,
    });
  }

  // ========================================
  // BUILD METHOD - UI REFACTORED
  // ========================================
  @override
  Widget build(BuildContext context) {
    // THEME: Theme data ko ek baar build method me access karna.
    final theme = Theme.of(context);
    // NOTE: 'customColors' variable ki zaroorat yahan nahi hai kyunki is screen
    // par koi special custom color istemal nahi ho raha hai.

    return Scaffold(
      // UPDATED: Background color ab theme se aa raha hai.
      backgroundColor: theme.scaffoldBackgroundColor,
      
      // UPDATED: Custom header ko standard AppBar se replace kiya gaya hai.
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: const Text('MY BASICS'),
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
              padding: EdgeInsets.all(20.w),
              children: [
                // === GENDER OPTION ===
                _buildBasicsOptionRow(
                  icon: Icons.wc_outlined,
                  title: "Gender",
                  value: _gender.join(', '),
                  onTap: () async {
                    final result = await Navigator.push<List<String>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditGenderScreen(
                          initialGenders: _gender,
                        ),
                      ),
                    );
                    if (result != null) setState(() => _gender = result);
                  },
                ),
                
                // UPDATED: Divider ab theme se style ho raha hai.
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Container(height: 1.h, color: theme.dividerColor),
                ),

                // === ORIENTATION OPTION ===
                _buildBasicsOptionRow(
                  icon: Icons.favorite_border_rounded,
                  title: "Sexual Orientation",
                  value: _orientation.isEmpty 
                      ? 'Not specified' 
                      : _orientation.join(', '),
                  onTap: () async {
                    final result = await Navigator.push<List<String>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditOrientationScreen(
                          initialOrientations: _orientation,
                        ),
                      ),
                    );
                    if (result != null) setState(() => _orientation = result);
                  },
                ),
                
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Container(height: 1.h, color: theme.dividerColor),
                ),

                // === IDENTITY OPTION ===
                _buildBasicsOptionRow(
                  icon: Icons.face_retouching_natural_outlined,
                  title: "Identity",
                  value: _identityPreferNotToSay 
                      ? "Prefer not to say" 
                      : (_identity.isEmpty ? 'Not specified' : _identity.join(', ')),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditIdentityScreen(
                          initialIdentities: _identity,
                          initialPreferNotToSay: _identityPreferNotToSay,
                        ),
                      ),
                    );
                    if (result != null && result is Map) {
                      setState(() {
                        _identity = List<String>.from(result['identities']);
                        _identityPreferNotToSay = result['preferNotToSay'];
                      });
                    }
                  },
                ),
                
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Container(height: 1.h, color: theme.dividerColor),
                ),

                // === RELATIONSHIP OPTION ===
                _buildBasicsOptionRow(
                  icon: Icons.people_outline_rounded,
                  title: "Relationship Type",
                  value: _getRelationshipDisplayString(),
                  onTap: () async {
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditRelationshipScreen(
                          initialRelationshipData: _relationshipData,
                        ),
                      ),
                    );
                    if (result != null) setState(() => _relationshipData = result);
                  },
                ),
              ],
            ),
          ),
          
           // === SAVE BUTTON (UPDATED) ===
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAndExit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface, // White
                  foregroundColor: theme.colorScheme.surface,   // Dark Grey/Black for text
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  // CORRECTED #2: textStyle ko button ki style me hi define karna behtar hai.
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 18.sp,
                  ), 
                ),
                child: const Text(
                  'Save',
                  // CORRECTED #2: Yahan se style hata di gayi hai taaki foregroundColor kaam kar sake.
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // HELPER WIDGET - UI REFACTORED
  // ========================================
  Widget _buildBasicsOptionRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    // THEME: Theme ko yahan access karna behtar practice hai.
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      // THEME: InkWell ke splash/highlight colors theme se aayenge.
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            // UPDATED: Icon ka color theme ka primary color hai.
            Icon(
              icon,
              color: theme.colorScheme.primary, 
              size: 24.sp,
            ),
            
            SizedBox(width: 16.w),
            
            // UPDATED: Title ka style ab theme se aa raha hai.
            Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16.sp,
              ),
            ),
            
            const Spacer(),
            
            // UPDATED: Value text ka style bhi theme se aa raha hai.
            Expanded(
              child: Text(
                value.isEmpty ? "Not specified" : value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15.sp,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            
            SizedBox(width: 8.w),
            
            // UPDATED: Arrow icon ka color bhi theme se control ho raha hai.
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}