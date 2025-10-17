// lib/screens/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovz/screens/edit_personal_info_screen.dart';
import 'package:lovz/screens/edit_basics_hub_screen.dart';
import 'package:lovz/screens/edit_height_weight_screen.dart';
import 'package:lovz/screens/edit_interests_screen.dart';
import 'package:lovz/screens/edit_profession_screen.dart';
import 'package:lovz/screens/edit_languages_screen.dart';
import 'package:lovz/screens/edit_habits_screen.dart';
import 'package:lovz/screens/edit_photos_screen.dart';
import 'package:lovz/models/user_profile_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:lovz/services/image_processor.dart';
import 'dart:async';
import 'package:lovz/utils/theme.dart'; // THEME: Custom theme file import kiya gaya

class EditProfileScreen extends StatefulWidget {
  final UserProfileModel initialData;

  const EditProfileScreen({
    Key? key,
    required this.initialData,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // === STATE VARIABLES (No Change in Logic) ===
  bool _isUploading = false;
  bool _isCompressing = false;
  List<ProcessedImage> _processedImages = [];
  late UserProfileModel _data;
  late TextEditingController _aboutMeController;
  final _aboutMeFocusNode = FocusNode();
  bool _isAboutMeFocused = false;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;
    _aboutMeController = TextEditingController(text: _data.aboutMe);

    _aboutMeFocusNode.addListener(() {
      setState(() {
        _isAboutMeFocused = _aboutMeFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _aboutMeController.dispose();
    _aboutMeFocusNode.dispose();
    super.dispose();
  }

  // ============================================
  // LOGIC & DATA FUNCTIONS (No UI Changes Here)
  // Saare functions jaise _startImageProcessing aur _uploadImagesAndSaveProfile
  // pehle jaise hi hain. Inme koi badlav nahi kiya gaya hai.
  // ============================================
  Future<void> _startImageProcessing(List<File?> imageFiles) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isCompressing = false);
      return;
    }

    List<Future<ProcessedImage>> processingTasks = [];
    for (var file in imageFiles) {
      if (file != null) {
        final String baseName = '${user.uid}-${const Uuid().v4()}';
        processingTasks.add(processImageForUpload(file.path, baseName));
      }
    }

    try {
      final results = await Future.wait(processingTasks);
      _processedImages = results;
    } catch (e, st) {
      debugPrint('ERROR during image processing: $e\n$st');
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error preparing images: ${e.toString()}'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if(mounted) setState(() => _isCompressing = false);
    }
  }

  Future<void> _uploadImagesAndSaveProfile() async {
    final bool hasNewImagesToProcess = _data.profileImages.any((file) => file != null);

    if (hasNewImagesToProcess && _processedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please wait, images are being prepared...'),
          backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isUploading = true);

    final workerUrl = Uri.parse("https://lovz-image-uploader.friendo-apk.workers.dev");
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Error: User not logged in.'), backgroundColor: Colors.red));
      }
      setState(() => _isUploading = false);
      return;
    }

    try {
      List<String> uploadedImageBaseNames = [];
      if (_processedImages.isNotEmpty) {
        List<Future<void>> uploadTasks = [];

        for (var imageBundle in _processedImages) {
          uploadTasks.add(http.post(workerUrl,
              headers: {'X-Custom-Filename': imageBundle.mediumFileName},
              body: imageBundle.mediumBytes));

          uploadTasks.add(http.post(workerUrl,
              headers: {'X-Custom-Filename': imageBundle.thumbFileName},
              body: imageBundle.thumbBytes));
              
          uploadedImageBaseNames.add(imageBundle.baseName);
        }
        
        await Future.wait(uploadTasks);
      }

      _data.aboutMe = _aboutMeController.text.trim();
      List<String> finalImageNames = List.from(_data.profileImageUrls)..addAll(uploadedImageBaseNames);
      _data.profileImageUrls = finalImageNames;
      final updatedDataMap = _data.toJson();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updatedDataMap);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('An error occurred during update: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ============================================
  // MAIN BUILD (Refactored for Theme)
  // ============================================
  @override
  Widget build(BuildContext context) {
    // THEME: Theme data aur custom colors ko ek baar build method me access karna.
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        // UPDATED: Ab scaffoldBackgroundColor aam theme se aa raha hai.
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 24.sp),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('EDIT PROFILE'),
          centerTitle: true,
          // NOTE: backgroundColor aur titleTextStyle ab theme se automatically aa rahe hain
        ),
        body: Column(
          children: [
            // UPDATED: Ab dividerColor aam theme se aa raha hai.
            Container(height: 1.h, color: theme.dividerColor),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhotoSection(context),
                    SizedBox(height: 8.h),
                    
                    Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoSection(context),
                          SizedBox(height: 24.h),
                          
                          _buildSectionTitle('ABOUT ME'),
                          SizedBox(height: 8.h),
                          
                          _buildAboutMeCard(),
                          SizedBox(height: 16.h),
                          
                          _buildInfoCard(
                            title: 'MY BASICS',
                            children: [
                              _buildMyBasicsRow(),
                              Divider(height: 1.h, color: theme.dividerColor),
                              _buildHeightWeightRow(),
                            ]
                          ),
                          SizedBox(height: 16.h),
                          
                          _buildInfoCard(
                            title: 'MY INTERESTS',
                            children: [ _buildMyInterestsRow() ]
                          ),
                          SizedBox(height: 16.h),
                          
                          _buildInfoCard(
                            title: 'MY WORK & EDUCATION',
                            children: [
                              _buildProfessionRow(),
                              Divider(height: 1.h, color: theme.dividerColor),
                              _buildLanguagesRow(),
                            ]
                          ),
                          SizedBox(height: 16.h),
                          
                          _buildInfoCard(
                            title: 'HABITS',
                            children: [
                              _buildHabitRow(
                                icon: Icons.local_bar_outlined,
                                title: 'Drinking',
                                currentValue: _data.drinkingHabit,
                              ),
                              Divider(height: 1.h, color: theme.dividerColor),
                              _buildHabitRow(
                                icon: Icons.smoking_rooms_outlined,
                                title: 'Smoking',
                                currentValue: _data.smokingHabit,
                              ),
                              Divider(height: 1.h, color: theme.dividerColor),
                              _buildHabitRow(
                                icon: Icons.grass_outlined,
                                title: 'Marijuana',
                                currentValue: _data.marijuanaHabit,
                              ),
                            ],
                          ),
                          SizedBox(height: 40.h),
                          
                          _buildSaveButton(context),
                          SizedBox(height: 30.h),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // UI WIDGETS (Refactored for Theme)
  // ============================================
  
  Widget _buildPhotoSection(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 0.50.sh,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Builder(
            builder: (context) {
              if (_data.profileImages.isNotEmpty && _data.profileImages[0] != null) {
                return Image.file(_data.profileImages[0]!, fit: BoxFit.cover);
              }
              else if (_data.profileImageUrls.isNotEmpty) {
                final imageUrl = 'https://pub-20b75325021441f58867571ca62aa1aa.r2.dev/${_data.profileImageUrls[0]}_medium.webp';
                return Image.network(imageUrl, fit: BoxFit.cover);
              }
              else {
                // UPDATED: Placeholder
                return Container(color: theme.colorScheme.surface);
              }
            },
          ),
          
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.center,
              )
            ),
          ),
          
          Positioned(
            bottom: 16.h,
            right: 16.w,
            // UPDATED: Edit Photos button ab theme colors istemal karta hai
            child: ElevatedButton.icon(
              onPressed: () async {
                if (_isCompressing) return;

                final result = await Navigator.push<List<dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPhotosScreen(
                      initialImageUrls: _data.profileImageUrls,
                    ),
                  ),
                );

                if (result != null) {
                  _processedImages.clear();
                  List<File?> newLocalFiles = List.filled(5, null);
                  List<String> oldImageUrls = [];
                  List<File> filesToProcess = [];

                  for (int i = 0; i < result.length; i++) {
                    if (result[i] is File) {
                      newLocalFiles[i] = result[i] as File;
                      filesToProcess.add(result[i] as File);
                    } else if (result[i] is String) {
                      oldImageUrls.add(result[i] as String);
                    }
                  }

                  setState(() {
                    _data.profileImages = newLocalFiles;
                    _data.profileImageUrls = oldImageUrls;
                    if (filesToProcess.isNotEmpty) _isCompressing = true;
                  });

                  if (filesToProcess.isNotEmpty) {
                    _startImageProcessing(filesToProcess);
                  }
                }
              },
              icon: Icon(Icons.photo_camera_outlined, size: 18.sp),
              label: Text('Edit Photos', style: TextStyle(fontSize: 15.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.onSurface,
                foregroundColor: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // UPDATED: RichText behtar alignment ke liye
              RichText(
                text: TextSpan(
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 30.sp, 
                    fontWeight: FontWeight.w400,
                  ),
                  children: [
                    TextSpan(text: _data.currentName),
                    const TextSpan(text: ', '),
                    TextSpan(
                      text: '${_data.currentAge}',
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
                  Icon(Icons.location_on, color: customColors.locationSkyBlue, size: 18.sp),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: Text(
                      _data.currentLocationName,
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
        
        ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditPersonalInfoScreen(
                  initialName: _data.currentName,
                  initialAge: _data.currentAge,
                  initialLocation: _data.currentLocationName,
                ),
              ),
            );

            if (result != null && result is Map<String, String>) {
              setState(() {
                _data.currentName = result['name']!;
                _data.currentAge = result['age']!;
              });
            }
          },
          icon: Icon(Icons.edit, size: 18.sp),
          label: Text('Edit', style: TextStyle(fontSize: 15.sp)),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.onSurface,
            foregroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutMeCard() {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: customColors.surface_2, // UPDATED
        borderRadius: BorderRadius.circular(16.r),
        border: _isAboutMeFocused
            ? Border.all(color: theme.colorScheme.primary, width: 1.5) // UPDATED
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.edit_note_outlined, color: theme.colorScheme.primary, size: 24.sp), // UPDATED
          SizedBox(width: 12.w),
          Expanded(
            child: TextFormField(
              controller: _aboutMeController,
              focusNode: _aboutMeFocusNode,
              maxLines: 3,
              maxLength: 150,
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15.sp), // UPDATED
              decoration: InputDecoration(
                hintText: 'My quick intro...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5)
                ), // UPDATED
                border: InputBorder.none,
                counterText: "",
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED: Re-usable section title
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
        fontSize: 15.sp,
        fontWeight: FontWeight.normal,
        letterSpacing: 1.5,
      ),
    );
  }

  // UPDATED: Re-usable card wrapper
  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    final customColors = Theme.of(context).extension<CustomColors>()!;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: customColors.surface_2, // UPDATED
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title),
          SizedBox(height: 12.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMyBasicsRow() {
    final theme = Theme.of(context);

    Color getTextColor(bool isSet) {
      return isSet ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.7);
    }
    String getValueText(List<String> list, String placeholder) {
      return list.isEmpty ? placeholder : list.join(', ');
    }
    String getIdentityText() {
      if (_data.basicIdentityPreferNotToSay) return "Prefer not to say";
      return _data.basicIdentity.isEmpty ? "Identity" : _data.basicIdentity.join(', ');
    }
    String getRelationshipText() {
      if (_data.basicRelationshipData == null) return "Relationship Type";
      RelationshipType type = _data.basicRelationshipData!['type'];
      NonMonogamousStatus? status = _data.basicRelationshipData!['status'];
      switch (type) {
        case RelationshipType.monogamous: return 'Monogamous';
        case RelationshipType.openToEither: return 'Open to either';
        case RelationshipType.nonMonogamous:
          if (status != null) {
            String statusName = status.toString().split('.').last;
            return statusName[0].toUpperCase() + statusName.substring(1);
          }
          return 'Non-monogamous';
        default: return 'Relationship Type';
      }
    }

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EditBasicsHubScreen(
            initialGender: _data.basicGender,
            initialOrientation: _data.basicOrientation,
            initialIdentity: _data.basicIdentity,
            initialIdentityPreferNotToSay: _data.basicIdentityPreferNotToSay,
            initialRelationshipData: _data.basicRelationshipData,
          )),
        );
        if (result != null && result is Map<String, dynamic>) {
          setState(() {
            _data.basicGender = result['gender'];
            _data.basicOrientation = result['orientation'];
            _data.basicIdentity = result['identity'];
            _data.basicIdentityPreferNotToSay = result['identityPreferNotToSay'];
            _data.basicRelationshipData = result['relationshipData'];
          });
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.wc_outlined, color: theme.colorScheme.primary, size: 24.sp),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_data.basicGender.join(', '), style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16.sp)),
                  SizedBox(height: 4.h),
                  Text(getValueText(_data.basicOrientation, "Orientation"), style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15.sp, color: getTextColor(_data.basicOrientation.isNotEmpty))),
                  SizedBox(height: 4.h),
                  Text(getIdentityText(), style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15.sp, color: getTextColor(_data.basicIdentity.isNotEmpty || _data.basicIdentityPreferNotToSay))),
                  SizedBox(height: 4.h),
                  Text(getRelationshipText(), style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15.sp, color: getTextColor(_data.basicRelationshipData != null))),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(Icons.arrow_forward_ios, size: 14.sp, color: theme.iconTheme.color)
          ],
        ),
      ),
    );
  }

  Widget _buildHeightWeightRow() {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () async {
        final result = await Navigator.push<Map<String, String>>(context, MaterialPageRoute(builder: (context) => EditHeightWeightScreen(initialFeet: _data.heightFeet, initialInches: _data.heightInches, initialWeight: _data.weightKg)));
        if (result != null) setState(() {_data.heightFeet = result['feet'] ?? ''; _data.heightInches = result['inches'] ?? ''; _data.weightKg = result['weight'] ?? '';});
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Icon(Icons.height, color: theme.colorScheme.primary, size: 24.sp),
            SizedBox(width: 16.w),
            Text("Height & Weight", style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16.sp)),
            const Spacer(),
            Text(
              (_data.heightFeet.isEmpty && _data.weightKg.isEmpty) ? "Add" : "${_data.heightFeet}'${_data.heightInches}\", ${_data.weightKg} kg",
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16.sp),
            ),
            SizedBox(width: 8.w),
            Icon(Icons.arrow_forward_ios, size: 14.sp, color: theme.iconTheme.color)
          ],
        ),
      ),
    );
  }

  Widget _buildMyInterestsRow() {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () async {
        final result = await Navigator.push<List<String>>(context, MaterialPageRoute(builder: (context) => EditInterestsScreen(initialInterests: _data.selectedInterests)));
        if (result != null) setState(() => _data.selectedInterests = result);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.palette_outlined, color: theme.colorScheme.primary, size: 24.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: _data.selectedInterests.isEmpty
                ? Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text('Add your interests', style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16.sp)),
                  )
                : Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: _data.selectedInterests.map((interest) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface, // UPDATED
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(interest, style: theme.textTheme.bodySmall?.copyWith(fontSize: 13.sp, color: theme.colorScheme.onSurface)), // UPDATED
                    )).toList(),
                  ),
          ),
          SizedBox(width: 8.w),
          Icon(Icons.arrow_forward_ios, size: 14.sp, color: theme.iconTheme.color)
        ],
      ),
    );
  }

  Widget _buildProfessionRow() {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () async {
        final result = await Navigator.push<Map<String, String>>(context, MaterialPageRoute(builder: (context) => EditProfessionScreen(initialTitle: _data.jobTitle, initialCompany: _data.jobCompany)));
        if (result != null) setState(() { _data.jobTitle = result['title'] ?? ''; _data.jobCompany = result['company'] ?? ''; });
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, color: theme.colorScheme.primary, size: 24.sp),
            SizedBox(width: 16.w),
            Expanded(
              child: (_data.jobTitle.isEmpty && _data.jobCompany.isEmpty)
                  ? Text("Profession", style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16.sp))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_data.jobTitle, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16.sp)),
                        if (_data.jobCompany.isNotEmpty)
                          Text(_data.jobCompany, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14.sp)),
                      ],
                    ),
            ),
            if (_data.jobTitle.isEmpty && _data.jobCompany.isEmpty)
              Text("Add", style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16.sp)),
            SizedBox(width: 8.w),
            Icon(Icons.arrow_forward_ios, size: 14.sp, color: theme.iconTheme.color),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagesRow() {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () async {
        final result = await Navigator.push<List<String>>(context, MaterialPageRoute(builder: (context) => EditLanguagesScreen(initialLanguages: _data.selectedLanguages)));
        if (result != null) setState(() => _data.selectedLanguages = result);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.translate, color: theme.colorScheme.primary, size: 24.sp),
            SizedBox(width: 16.w),
            Expanded(
              child: _data.selectedLanguages.isEmpty
                  ? Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Text("Languages", style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16.sp)),
                    )
                  : Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: _data.selectedLanguages.map((lang) => Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface, // UPDATED
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(lang, style: theme.textTheme.labelSmall?.copyWith(fontSize: 12.sp, color: theme.colorScheme.onSurface)), // UPDATED
                      )).toList(),
                    ),
            ),
            if (_data.selectedLanguages.isEmpty)
              Text("Add", style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16.sp)),
            SizedBox(width: 8.w),
            Icon(Icons.arrow_forward_ios, size: 14.sp, color: theme.iconTheme.color),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitRow({ required IconData icon, required String title, required String currentValue }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: _navigateToHabitsScreen,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 24.sp),
            SizedBox(width: 16.w),
            Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16.sp)),
            const Spacer(),
            Text(
              currentValue.isEmpty ? 'Add' : currentValue,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16.sp),
            ),
            SizedBox(width: 8.w),
            Icon(Icons.arrow_forward_ios, size: 14.sp, color: theme.iconTheme.color),
          ],
        ),
      ),
    );
  }

  void _navigateToHabitsScreen() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (context) => EditHabitsScreen(initialHabits: {'drinking': _data.drinkingHabit, 'smoking': _data.smokingHabit, 'marijuana': _data.marijuanaHabit})),
    );
    if (result != null) {
      setState(() { _data.drinkingHabit = result['drinking'] ?? ''; _data.smokingHabit = result['smoking'] ?? ''; _data.marijuanaHabit = result['marijuana'] ?? ''; });
    }
  }

  Widget _buildSaveButton(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDisabled = _isUploading || _isCompressing;
    
    String buttonText = 'Save & Update Profile';
    if (_isCompressing) buttonText = 'Preparing images...';
    else if (_isUploading) buttonText = 'Uploading...';

    // UPDATED: Ab ye ek proper ElevatedButton hai
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isDisabled ? null : _uploadImagesAndSaveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.onSurface, // White background
          foregroundColor: theme.colorScheme.surface, // Black text
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          disabledBackgroundColor: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        child: _isUploading || _isCompressing
            ? SizedBox(
                height: 24.h,
                width: 24.w,
                child: CircularProgressIndicator(
                  color: theme.colorScheme.surface, // Black spinner
                  strokeWidth: 3,
                ),
              )
            : Text(
                buttonText,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.surface, // Black text
                ),
              ),
      ),
    );
  }
}