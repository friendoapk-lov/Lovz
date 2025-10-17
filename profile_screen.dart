import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovz/screens/edit_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lovz/models/user_profile_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lovz/screens/premium_plans_screen.dart';
import 'package:lovz/screens/boost_purchase_screen.dart';
import 'package:lovz/utils/theme.dart'; // THEME: Custom theme file import kiya gaya

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- STATE & LOGIC (No Changes) ---
  UserProfileModel? _userProfile;
  bool _isLoading = true;

  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  
  final String r2BaseUrl = 'https://pub-20b75325021441f58867571ca62aa1aa.r2.dev';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (docSnapshot.exists) {
        if (mounted) {
          setState(() {
            _userProfile = UserProfileModel.fromMap(docSnapshot.data()!);
            _isLoading = false;
          });
        }
      } else {
        throw Exception("User profile not found in database");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading profile: $e")),
        );
      }
    }
  }
  
  double _calculateProfileCompletion() {
    if (_userProfile == null) return 0.0;
    
    int totalFields = 11;
    int filledFields = 0;

    if (_userProfile!.profileImageUrls.isNotEmpty) filledFields++;
    if (_userProfile!.aboutMe.isNotEmpty) filledFields++;
    if (_userProfile!.basicGender.isNotEmpty) filledFields++;
    if (_userProfile!.basicOrientation.isNotEmpty) filledFields++;
    if (_userProfile!.basicIdentity.isNotEmpty || _userProfile!.basicIdentityPreferNotToSay) filledFields++;
    if (_userProfile!.basicRelationshipData != null) filledFields++;
    if (_userProfile!.heightFeet.isNotEmpty) filledFields++;
    if (_userProfile!.selectedInterests.isNotEmpty) filledFields++;
    if (_userProfile!.jobTitle.isNotEmpty) filledFields++;
    if (_userProfile!.selectedLanguages.isNotEmpty) filledFields++;
    if (_userProfile!.drinkingHabit.isNotEmpty) filledFields++;

    return filledFields / totalFields;
  }
  
  // --- UI WIDGETS START FROM HERE ---

  @override
  Widget build(BuildContext context) {
    // THEME: Theme data aur custom colors ko ek baar build method me access karna.
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
       backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(
              "Could not load profile. Please try again later.",
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    final double profileCompletion = _calculateProfileCompletion();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Hide back button
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: const Text('PROFILE'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: theme.colorScheme.onSurface, size: 26.sp),
            onPressed: () {
              print('Settings tapped!');
            },
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Column(
        children: [
          // UPDATED: Ab dividerColor aam theme se aa raha hai.
          Container(height: 1.h, color: theme.dividerColor),
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageCarousel(),
                  
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNameAndLocation(),
                        SizedBox(height: 20.h),
                        
                        _buildProfileCompletionBar(profileCompletion),
                        SizedBox(height: 28.h),
                        
                        if (_userProfile!.aboutMe.isNotEmpty) ...[
                          _buildSectionTitle('ABOUT ME'),
                          SizedBox(height: 8.h),
                          _buildAboutMeCard(),
                          SizedBox(height: 28.h),
                        ],
                        
                        _buildSectionTitle('MY BASICS'),
                        SizedBox(height: 8.h),
                        _buildMyBasicsGrid(),
                        SizedBox(height: 28.h),
                        
                        if (_userProfile!.jobTitle.isNotEmpty) ...[
                          _buildSectionTitle('MY WORK'),
                          SizedBox(height: 8.h),
                          _buildWorkCard(),
                          SizedBox(height: 28.h),
                        ],
                        
                        if (_userProfile!.selectedInterests.isNotEmpty) ...[
                          _buildSectionTitle('MY INTERESTS'),
                          SizedBox(height: 8.h),
                          _buildInterestsGrid(),
                          SizedBox(height: 28.h),
                        ],
                        
                        if (_userProfile!.drinkingHabit.isNotEmpty || 
                            _userProfile!.smokingHabit.isNotEmpty || 
                            _userProfile!.marijuanaHabit.isNotEmpty) ...[
                          _buildSectionTitle('MY HABITS'),
                          SizedBox(height: 8.h),
                          _buildMyHabitsGrid(),
                          SizedBox(height: 28.h),
                        ],
                        
                        _buildActionCard(
                          title: 'Boost My Profile', 
                          subtitle: 'Reach the top spot in your area.', 
                          icon: Icons.rocket_launch_rounded,
                          color: const Color(0xFFFF6B00), // Feature-specific color
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BoostPurchaseScreen(),
                              ),
                            );
                          }
                        ),
                        SizedBox(height: 16.h),
                        
                        _buildActionCard(
                          title: 'Premium Subscription', 
                          subtitle: 'Unlock perks & find more matches!', 
                          icon: Icons.auto_awesome,
                          color: const Color.fromARGB(255, 172, 29, 255), // Feature-specific color
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PremiumPlansScreen(),
                              ),
                            );
                          }
                        ),
                        SizedBox(height: 16.h),

                        _buildActionCard(
                          title: 'Dating & Safety Hub', 
                          subtitle: 'Your essential guide to safe connections.', 
                          icon: Icons.shield_outlined,
                          color: const Color(0xFF0D9488), // Feature-specific color
                          onTap: () {
                            print('Dating & Safety Hub tapped!');
                          }
                        ),
                        SizedBox(height: 30.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // HELPER WIDGETS - Refactored for Theme
  // ============================================
  
  Widget _buildImageCarousel() {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;
    final imageNames = _userProfile!.profileImageUrls;

    if (imageNames.isEmpty) {
      return Container(
        height: 450.h,
        color: customColors.surface_2, // UPDATED
        child: Center(
          child: Icon(Icons.person, size: 100.sp, color: Colors.grey.shade700), // UPDATED
        ),
      );
    }

    return SizedBox(
      height: 450.h,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: imageNames.length,
            onPageChanged: (int newIndex) {
              setState(() => _currentImageIndex = newIndex);
            },
            itemBuilder: (context, index) {
              final imageUrl = '$r2BaseUrl/${imageNames[index]}_medium.webp';
              
              return CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(color: theme.colorScheme.primary), // UPDATED
                ),
                errorWidget: (context, url, error) {
                  return Icon(Icons.error, color: theme.colorScheme.error, size: 50.sp); // UPDATED
                },
              );
            },
          ),
          
          Positioned(
            bottom: 16.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imageNames.length, 
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  height: 4.h,
                  width: _currentImageIndex == index ? 32.w : 16.w,
                  decoration: BoxDecoration(
                    // UPDATED
                    color: _currentImageIndex == index 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameAndLocation() {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // UPDATED: Using a single Text with RichText for better alignment
              RichText(
                text: TextSpan(
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 30.sp, 
                    fontWeight: FontWeight.w400,
                  ),
                  children: [
                    TextSpan(text: _userProfile!.currentName),
                    const TextSpan(text: ', '),
                    TextSpan(
                      text: '${_userProfile!.currentAge}',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontSize: 24.sp, 
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              
              Row(
                children: [
                  Icon(
                    Icons.location_on, 
                    color: customColors.locationSkyBlue, // UPDATED
                    size: 18.sp
                  ),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: Text(
                      _userProfile!.currentLocationName,
                      // UPDATED
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontSize: 15.sp,
                        color: customColors.locationSkyBlue,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // UPDATED: Edit button now uses theme colors
        ElevatedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfileScreen(initialData: _userProfile!),
              ),
            );
            _loadUserData();
          },
          icon: Icon(Icons.edit, size: 18.sp),
          label: Text('Edit', style: TextStyle(fontSize: 15.sp)),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.onSurface, // White
            foregroundColor: theme.colorScheme.surface,   // Dark Grey
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCompletionBar(double value) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Profile Completion', style: theme.textTheme.bodyMedium), // UPDATED
            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), // UPDATED
            ),
          ],
        ),
        SizedBox(height: 8.h),
        
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8.h,
            backgroundColor: customColors.surface_2, // UPDATED
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary), // UPDATED
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    // UPDATED: Using a style from theme instead of GoogleFonts directly
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
        fontSize: 15.sp,
        fontWeight: FontWeight.normal,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildAboutMeCard() {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: customColors.surface_2, // UPDATED
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        _userProfile!.aboutMe,
        // UPDATED
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: 15.sp,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildMyBasicsGrid() {
    // Logic remains same, only the UI builder `_buildInfoTile` is updated
    // ... (code omitted for brevity, no changes needed here) ...
    List<Map<String, dynamic>> tiles = [];
    
    if (_userProfile!.basicGender.isNotEmpty) {
      tiles.add({'icon': Icons.wc_outlined, 'text': _userProfile!.basicGender.join(', ')});
    }
    if (_userProfile!.basicOrientation.isNotEmpty) {
      tiles.add({'icon': Icons.favorite_border, 'text': _userProfile!.basicOrientation.join(', ')});
    }
    if (_userProfile!.basicIdentity.isNotEmpty || _userProfile!.basicIdentityPreferNotToSay) {
      tiles.add({'icon': Icons.face_retouching_natural_outlined, 'text': _getIdentityText()});
    }
    if (_userProfile!.basicRelationshipData != null) {
      tiles.add({'icon': Icons.people_outline, 'text': _getRelationshipText()});
    }
    if (_userProfile!.heightFeet.isNotEmpty) {
      tiles.add({'icon': Icons.height, 'text': "${_userProfile!.heightFeet}'${_userProfile!.heightInches}\""});
    }
    if (_userProfile!.weightKg.isNotEmpty) {
      tiles.add({'icon': Icons.monitor_weight_outlined, 'text': "${_userProfile!.weightKg} kg"});
    }

    if (tiles.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, index) {
        return _buildInfoTile(
          icon: tiles[index]['icon'],
          text: tiles[index]['text'],
        );
      },
    );
  }
  
  Widget _buildInfoTile({required IconData icon, required String text}) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: customColors.surface_2, // UPDATED
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary, // UPDATED
            size: 20.sp
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14.sp), // UPDATED
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkCard() {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: customColors.surface_2, // UPDATED
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.work_outline,
            color: theme.colorScheme.primary, // UPDATED
            size: 24.sp
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              '${_userProfile!.jobTitle}${_userProfile!.jobCompany.isNotEmpty ? " at ${_userProfile!.jobCompany}" : ""}',
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15.sp), // UPDATED
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsGrid() {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: _userProfile!.selectedInterests.map((interest) {
        // ... (logic remains same)
        IconData? icon;
        switch (interest.toLowerCase()) {
          case 'painting': icon = Icons.palette_outlined; break;
          case 'cooking': icon = Icons.restaurant_outlined; break;
          case 'yoga': icon = Icons.self_improvement_outlined; break;
          default: icon = null;
        }
        
        return _buildInterestChip(interest, icon);
      }).toList(),
    );
  }

  Widget _buildInterestChip(String label, IconData? icon) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: customColors.surface_2, // UPDATED
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: theme.colorScheme.primary, size: 18.sp), // UPDATED
            SizedBox(width: 8.w),
          ],
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14.sp), // UPDATED
          ),
        ],
      ),
    );
  }

  Widget _buildMyHabitsGrid() {
    // ... (logic remains same, uses updated `_buildInfoTile`)
    List<Map<String, dynamic>> habits = [];
    
    if (_userProfile!.drinkingHabit.isNotEmpty) {
      habits.add({'icon': Icons.local_bar_outlined, 'text': _userProfile!.drinkingHabit});
    }
    if (_userProfile!.smokingHabit.isNotEmpty) {
      habits.add({'icon': Icons.smoking_rooms_outlined, 'text': _userProfile!.smokingHabit});
    }
    if (_userProfile!.marijuanaHabit.isNotEmpty) {
      habits.add({'icon': Icons.grass_outlined, 'text': _userProfile!.marijuanaHabit});
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
      ),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        return _buildInfoTile(
          icon: habits[index]['icon'],
          text: habits[index]['text'],
        );
      },
    );
  }

  // --- LOGIC HELPER FUNCTIONS (No Changes) ---
  String _getIdentityText() {
    if (_userProfile!.basicIdentityPreferNotToSay) return "Prefer not to say";
    return _userProfile!.basicIdentity.isEmpty 
        ? "Not specified" 
        : _userProfile!.basicIdentity.join(', ');
  }

  String _getRelationshipText() {
    if (_userProfile!.basicRelationshipData == null) return "Not specified";
    
    RelationshipType? type;
    if (_userProfile!.basicRelationshipData!['type'] is String) {
      type = RelationshipType.values.firstWhere(
        (e) => e.toString() == _userProfile!.basicRelationshipData!['type']
      );
    } else {
      type = _userProfile!.basicRelationshipData!['type'];
    }

    NonMonogamousStatus? status;
    if(_userProfile!.basicRelationshipData!['status'] != null) {
      if (_userProfile!.basicRelationshipData!['status'] is String) {
        status = NonMonogamousStatus.values.firstWhere(
          (e) => e.toString() == _userProfile!.basicRelationshipData!['status']
        );
      } else {
        status = _userProfile!.basicRelationshipData!['status'];
      }
    }

    switch (type) {
      case RelationshipType.monogamous: return 'Monogamous';
      case RelationshipType.openToEither: return 'Open to either';
      case RelationshipType.nonMonogamous:
        if (status != null) {
          String statusName = status.toString().split('.').last;
          return statusName[0].toUpperCase() + statusName.substring(1);
        }
        return 'Non-monogamous';
      default: return 'Not specified';
    }
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: color, // Feature-specific color remains
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), // Kept for contrast on dynamic color
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, size: 28.sp, color: theme.colorScheme.onPrimary), // UPDATED
                ),
                SizedBox(width: 16.w),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(fontSize: 17.sp, fontWeight: FontWeight.bold), // UPDATED
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13.sp,
                          color: theme.colorScheme.onPrimary.withOpacity(0.9), // UPDATED
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                
                Icon(
                  Icons.arrow_forward_ios, 
                  color: theme.colorScheme.onPrimary, // UPDATED
                  size: 18.sp
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}