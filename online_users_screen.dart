import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // RESPONSIVE: Added for responsive sizing
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart'; // UPDATED: Better image handling

import 'package:lovz/models/user_profile_data.dart';
import 'package:lovz/providers/online_status_provider.dart';

class OnlineUsersScreen extends StatefulWidget {
  // Filters from HomeScreen
  final double minAge;
  final double maxAge;
  final double maxDistance;
  final List<String> genders;
  final List<String> orientations;
  final List<String> identities;

  const OnlineUsersScreen({
    super.key,
    required this.minAge,
    required this.maxAge,
    required this.maxDistance,
    required this.genders,
    required this.orientations,
    required this.identities,
  });

  @override
  State<OnlineUsersScreen> createState() => _OnlineUsersScreenState();
}

class _OnlineUsersScreenState extends State<OnlineUsersScreen> {
  final String r2PublicUrlBase = "https://pub-20b75325021441f58867571ca62aa1aa.r2.dev";

  // YEH FUNCTION AB SIRF FIRESTORE SE DATA LAAYEGA
  // ISE BUILD METHOD MEIN FUTUREBUILDER USE KAREGA
  Future<List<UserProfileData>> _fetchProfilesFromIds(List<String> userIds) async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (userIds.isEmpty || currentUserUid == null) {
      return []; // Return an empty list if there's nothing to fetch
    }

    try {
      final currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserUid).get();
      if (!currentUserDoc.exists) return [];

      final currentUserLocation = currentUserDoc.data()?['location'] as GeoPoint?;
      final myBlockedList = List<String>.from(currentUserDoc.data()?['blockedUsers'] ?? []);

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      final filteredList = snapshot.docs
          .map((doc) => UserProfileData.fromFirestore(doc))
          .where((user) {
        // Apply blocking and filtering logic
        final isBlocked = myBlockedList.contains(user.uid) || user.blockedUsers.contains(currentUserUid);
        if (isBlocked) return false;

        final ageMatch = user.age >= widget.minAge && user.age <= widget.maxAge;
        final genderMatch = widget.genders.isEmpty || user.basicGender.any((g) => widget.genders.contains(g));
        final orientationMatch = widget.orientations.isEmpty || user.basicOrientation.any((o) => widget.orientations.contains(o));
        final identityMatch = widget.identities.isEmpty || user.basicIdentity.any((i) => widget.identities.contains(i));

        bool distanceMatch = true;
        if (widget.maxDistance < 100.0) {
          if (currentUserLocation != null && user.location != null) {
            final distanceInMeters = Geolocator.distanceBetween(currentUserLocation.latitude, currentUserLocation.longitude, user.location!.latitude, user.location!.longitude);
            distanceMatch = (distanceInMeters / 1000) <= widget.maxDistance;
          } else {
            distanceMatch = false;
          }
        }
        return ageMatch && genderMatch && orientationMatch && identityMatch && distanceMatch;
      }).toList();
      
      return filteredList;
    } catch (e) {
      debugPrint("Error fetching profiles from IDs: $e");
      return []; // Return empty list on error
    }
  }

  @override
  Widget build(BuildContext context) {
    // THEME: Access theme data
    final theme = Theme.of(context);
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      // UPDATED: Using scaffoldBackgroundColor from theme
      backgroundColor: theme.scaffoldBackgroundColor,
      
      // UPDATED: Standard AppBar with theme-based styling (Anton font automatically applied)
      appBar: AppBar(
        title: const Text('ONLINE USERS'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      
      // Consumer ka kaam hai OnlineStatusProvider ko hamesha sunna
      body: Consumer<OnlineStatusProvider>(
        builder: (context, onlineStatusProvider, child) {
          // Hum hamesha provider se latest online users ki list lenge
          final otherOnlineUserIds = onlineStatusProvider.onlineUsers
              .where((id) => id != currentUserUid)
              .toList();

          // CASE 1: Agar koi bhi dusra user online nahi hai
          if (otherOnlineUserIds.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  'No other users are currently online.',
                  textAlign: TextAlign.center,
                  // UPDATED: Using theme text style and color
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 18.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            );
          }

          // CASE 2: Agar online users hain, to unke profiles fetch karo
          return FutureBuilder<List<UserProfileData>>(
            // FutureBuilder online IDs ke basis par profiles fetch karega
            future: _fetchProfilesFromIds(otherOnlineUserIds),
            builder: (context, snapshot) {
              // Jab tak data aa raha hai, loader dikhao
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    // UPDATED: Using primary color
                    color: theme.colorScheme.primary,
                  ),
                );
              }

              // Agar data laane mein error aaye
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Something went wrong!",
                    // UPDATED: Using theme text style
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 18.sp,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                );
              }

              // Agar data aa gaya hai, lekin filter ke baad list khaali hai
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Text(
                      'No online users found that match your current filters.',
                      textAlign: TextAlign.center,
                      // UPDATED: Using theme text style
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 18.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                );
              }

              // Finally, agar sab theek hai, to users ki list (Grid) dikhao
              final onlineUsers = snapshot.data!;
              return GridView.builder(
                padding: EdgeInsets.all(12.w),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 0.7,
                ),
                itemCount: onlineUsers.length,
                itemBuilder: (context, index) {
                  final user = onlineUsers[index];
                  return _buildOnlineUserCard(theme, user);
                },
              );
            },
          );
        },
      ),
    );
  }

  // ============================================
  // ONLINE USER CARD (UPDATED - THEME BASED & RESPONSIVE)
  // ============================================
  Widget _buildOnlineUserCard(ThemeData theme, UserProfileData user) {
    final imageUrl = user.profileImageUrls.isNotEmpty
        ? '$r2PublicUrlBase/${user.profileImageUrls.first}_medium.webp'
        : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      // UPDATED: Using surface color from theme
      color: theme.colorScheme.surface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Profile Image
          if (imageUrl != null)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: theme.colorScheme.primary,
                ),
              ),
              errorWidget: (context, url, error) => Center(
                child: Icon(
                  Icons.person,
                  size: 80.sp,
                  // UPDATED: Using onSurface with opacity
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
            )
          else
            Container(
              // UPDATED: Using surface color
              color: theme.colorScheme.surface,
              child: Center(
                child: Icon(
                  Icons.person,
                  size: 80.sp,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
            ),

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // User Info (Bottom)
          Positioned(
            bottom: 8.h,
            left: 8.w,
            right: 8.w,
            child: Text(
              '${user.name}, ${user.age}',
              // UPDATED: Using theme text style
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16.sp,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(
                    blurRadius: 2.0,
                    color: Colors.black54,
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Online Indicator (Top Right)
          Positioned(
            top: 8.h,
            right: 8.w,
            child: Container(
              width: 12.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: Colors.green, // Green for online status
                shape: BoxShape.circle,
                border: Border.all(
                  // UPDATED: Using onSurface color for border
                  color: theme.colorScheme.onSurface,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}