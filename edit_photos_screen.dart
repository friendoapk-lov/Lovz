// === START: Edit Photos Screen - Dark Theme Redesigned UI ===

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lovz/utils/app_colors.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class EditPhotosScreen extends StatefulWidget {
  final List<String> initialImageUrls;

  const EditPhotosScreen({
    Key? key,
    this.initialImageUrls = const [],
  }) : super(key: key);

  @override
  _EditPhotosScreenState createState() => _EditPhotosScreenState();
}

class _EditPhotosScreenState extends State<EditPhotosScreen> {
  final List<dynamic> _images = List.filled(5, null);

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.initialImageUrls.length && i < 5; i++) {
      _images[i] = widget.initialImageUrls[i];
    }
  }

  // === FUNCTIONS - BILKUL SAME HAIN, KOI CHANGE NAHI ===
  Future<void> _pickOrUpdateImage(int index) async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps != PermissionState.authorized && ps != PermissionState.limited) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo permission is required.')),
      );
      return;
    }

    final List<AssetEntity>? assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: const AssetPickerConfig(
        maxAssets: 1,
        requestType: RequestType.image,
        themeColor: AppColors.primaryPink,
      ),
    );

    if (assets != null && assets.isNotEmpty) {
      final file = await assets.first.file;
      if (file != null) {
        setState(() {
          _images[index] = file;
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images[index] = null;
    });
  }

  Future<void> _pickMultipleImages() async {
    final int availableSlots = _images.where((img) => img == null).length;
    if (availableSlots == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aap 5 se zyada photos nahi daal sakte.')),
      );
      return;
    }

    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps != PermissionState.authorized && ps != PermissionState.limited) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photos ke liye permission zaroori hai.')),
      );
      return;
    }

    final List<AssetEntity>? assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: availableSlots,
        requestType: RequestType.image,
        themeColor: AppColors.primaryPink,
      ),
    );

    if (assets != null && assets.isNotEmpty) {
      for (var asset in assets) {
        final file = await asset.file;
        if (file != null) {
          final int firstEmptyIndex = _images.indexWhere((img) => img == null);
          if (firstEmptyIndex != -1) {
            setState(() {
              _images[firstEmptyIndex] = file;
            });
          }
        }
      }
    }
  }

  // === UI WIDGETS - REDESIGNED WITH DARK THEME ===
  Widget _buildPlaceholderBox(int index) {
    return GestureDetector(
      onTap: _pickMultipleImages,
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A), // Dark grey background
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.2), // Light red accent
            width: 1.5,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add_a_photo_outlined,
            color: Color(0xFFFF453A), // Light red icon
            size: 40.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoBox(int index) {
    final image = _images[index];

    return GestureDetector(
      onTap: () => _pickOrUpdateImage(index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: image is String
                    ? Image.network(
                        'https://pub-20b75325021441f58867571ca62aa1aa.r2.dev/${image}_thumb.webp',
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        image as File,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
          Positioned(
            top: 8.h,
            right: 8.w,
            child: InkWell(
              onTap: () => _removeImage(index),
              child: Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: Color(0xFF0A0A0A).withOpacity(0.8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFFFF453A),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Color(0xFFFF453A),
                  size: 18.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A), // Pure dark black
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
                  'EDIT PHOTOS',
                  style: GoogleFonts.anton(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 1.5,
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
              child: Column(
                children: [
                  // Main large photo
                  SizedBox(
                    height: 0.65.sh,
                    width: double.infinity,
                    child: _images[0] == null
                        ? _buildPlaceholderBox(0)
                        : _buildPhotoBox(0),
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  // Grid of 4 smaller photos
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                    ),
                    itemBuilder: (context, index) {
                      final listIndex = index + 1;
                      return _images[listIndex] == null
                          ? _buildPlaceholderBox(listIndex)
                          : _buildPhotoBox(listIndex);
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Save Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(_images);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // White button
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Save',
                style: TextStyle(
                fontSize: 18.sp,
                color: Color(0xFF0A0A0A), // Dark text
               fontWeight: FontWeight.bold,
               ),
               ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// === END: Edit Photos Screen Redesigned ===