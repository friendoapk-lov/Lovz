import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lovz/screens/splash_screen.dart';
import 'package:lovz/utils/theme.dart';

class BlockedScreen extends StatefulWidget {
  const BlockedScreen({super.key});

  @override
  State<BlockedScreen> createState() => _BlockedScreenState();
}

class _BlockedScreenState extends State<BlockedScreen> {
  final TextEditingController _appealController = TextEditingController();
  bool _isSubmitting = false;

  // === YEH AAPKA PURANA, WORKING SUBMIT APPEAL LOGIC HAI ===
  void _submitAppeal() async {
    if (_appealController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a reason for your appeal.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('appeals').add({
        'userId': userId,
        'appealMessage': _appealController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (mounted) Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Your appeal has been submitted and will be reviewed."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Appeal submission error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to submit appeal. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // === YEH AAPKA PURANA, WORKING DIALOG LOGIC HAI (Now with theme styling) ===
  void _showAppealDialog() {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: customColors.surface_2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          "Appeal Decision",
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: _appealController,
          maxLines: 4,
          style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15.sp),
          decoration: InputDecoration(
            hintText: "Why do you believe this block was a mistake?",
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 14.sp,
            ),
            filled: true,
            fillColor: theme.scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            child: Text(
              "Cancel",
              style: theme.textTheme.labelLarge?.copyWith(fontSize: 15.sp),
            ),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitAppeal,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: _isSubmitting
                ? SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : Text(
                    "Submit Appeal",
                    style: theme.textTheme.labelLarge?.copyWith(fontSize: 15.sp),
                  ),
          ),
        ],
      ),
    );
  }

  // === YEH NAYA, WORKING LOGOUT FUNCTION HAI ===
  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SplashScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>()!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // === BLOCKED ICON WITH DECORATIVE CONTAINER ===
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.block_rounded,
                    size: 80.sp,
                    color: theme.colorScheme.error,
                  ),
                ),
                SizedBox(height: 32.h),

                // === MAIN CONTENT CARD ===
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: customColors.surface_2,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      // === TITLE ===
                      Text(
                        "Account Blocked",
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),

                      // === DIVIDER ===
                      Container(
                        height: 1.h,
                        color: theme.dividerColor,
                      ),
                      SizedBox(height: 16.h),

                      // === DESCRIPTION ===
                      Text(
                        "Your account has been permanently blocked for repeated violations of our community guidelines.",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 16.sp,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32.h),

                      // === APPEAL BUTTON ===
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showAppealDialog,
                          icon: Icon(Icons.flag_outlined, size: 20.sp),
                          label: Text(
                            "Appeal This Decision",
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontSize: 16.sp,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // === LOGOUT BUTTON ===
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: _handleLogout,
                          icon: Icon(
                            Icons.logout_rounded,
                            size: 20.sp,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          label: Text(
                            "Logout",
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontSize: 16.sp,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // === FOOTER TEXT ===
                Text(
                  "If you believe this was a mistake, please submit an appeal and our team will review your case.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}