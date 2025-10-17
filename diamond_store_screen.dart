import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // RESPONSIVE: Added for responsive sizing
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/in_app_purchase_service.dart';

class DiamondStoreScreen extends StatefulWidget {
  const DiamondStoreScreen({super.key});

  @override
  State<DiamondStoreScreen> createState() => _DiamondStoreScreenState();
}

class _DiamondStoreScreenState extends State<DiamondStoreScreen> {
  // Service ka ek instance banayein
  final InAppPurchaseService _service = InAppPurchaseService();
  late StreamSubscription<String> _purchaseSuccessSubscription;

  @override
  void initState() {
    super.initState();
    // Service ko shuru karein
    _service.init();

    // Khareedaari safal hone par message dikhane ke liye listener lagayein
    _purchaseSuccessSubscription = _service.purchaseSuccessStream.listen((productId) {
      int diamondsAdded = 0;
      if (productId == '50_diamonds') diamondsAdded = 50;
      if (productId == '110_diamonds') diamondsAdded = 110;
      
      if (diamondsAdded > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$diamondsAdded Diamonds added successfully! ✨'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _service.dispose();
    _purchaseSuccessSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // THEME: Access theme data once at the start of build method
    final theme = Theme.of(context);

    return Scaffold(
      // UPDATED: Using scaffoldBackgroundColor from central theme
      backgroundColor: theme.scaffoldBackgroundColor,
      
      // UPDATED: Standard AppBar with theme-based styling (Anton font automatically applied)
      appBar: AppBar(
        title: const Text('GET DIAMONDS'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      
      // Loading state ko handle karne ke liye ValueListenableBuilder ka istemaal karein
      body: ValueListenableBuilder<bool>(
        valueListenable: _service.isLoading,
        builder: (context, isLoading, child) {
          if (isLoading) {
            return Center(
              // UPDATED: Using primary color for loading indicator
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          if (_service.products.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Text(
                  'No products found. Please try again later.',
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

          return _buildProductList(theme);
        },
      ),
    );
  }

  Widget _buildProductList(ThemeData theme) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _service.products.length,
      itemBuilder: (context, index) {
        final ProductDetails productDetails = _service.products[index];
        
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8.h),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          // UPDATED: Using surface color from theme for card background
          color: theme.colorScheme.surface,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Diamond Icon
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    // UPDATED: Using primary color with opacity for icon background
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.diamond_outlined,
                    // UPDATED: Using primary color for icon
                    color: theme.colorScheme.primary,
                    size: 32.sp,
                  ),
                ),
                
                SizedBox(width: 16.w),
                
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productDetails.title,
                        // UPDATED: Using theme text style
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        productDetails.description,
                        // UPDATED: Using theme text style with opacity
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14.sp,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(width: 12.w),
                
                // Buy Button
                ElevatedButton(
                  onPressed: () => _service.buyProduct(productDetails),
                  // UPDATED: Following Save Button Rule (white bg, dark text)
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.onSurface,
                    foregroundColor: theme.colorScheme.surface,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    elevation: 2,
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text(productDetails.price),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}