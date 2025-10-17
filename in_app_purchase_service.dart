import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- YEH ADD KIYA HAI
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- YEH ADD KIYA HAI

// Step 1: Play Console mein banayi gayi Product IDs yahan daalein.
const List<String> _kProductIds = <String>[
  '50_diamonds',  // <-- AAPKE PACKS KE ANUSAAR UPDATE KIYA
  '110_diamonds', // <-- AAPKE PACKS KE ANUSAAR UPDATE KIYA
];

class InAppPurchaseService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  final List<ProductDetails> _products = [];
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final StreamController<String> _purchaseSuccessController = StreamController.broadcast();

  List<ProductDetails> get products => _products;
  ValueNotifier<bool> get isLoading => _isLoading;
  Stream<String> get purchaseSuccessStream => _purchaseSuccessController.stream;

  Future<void> init() async {
    _isLoading.value = true;
    
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      _isLoading.value = false;
      return;
    }

    await _loadProducts();
    _isLoading.value = false;
    _listenToPurchaseUpdates();
  }

  Future<void> _loadProducts() async {
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_kProductIds.toSet());
    if (response.error == null) {
      _products.clear();
      _products.addAll(response.productDetails);
      _products.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    }
  }

  Future<void> buyProduct(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
  }

  void _listenToPurchaseUpdates() {
    _subscription = _inAppPurchase.purchaseStream.listen((List<PurchaseDetails> purchaseDetailsList) {
      _handlePurchaseUpdates(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      print("Purchase stream error: $error");
    });
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        print("Purchase successful for: ${purchaseDetails.productID}");
        
        // Ab diamonds dene ka kaam yahan se hoga
        _deliverDiamonds(purchaseDetails);

        _purchaseSuccessController.add(purchaseDetails.productID);

        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        print("Purchase Error: ${purchaseDetails.error?.message}");
      }
    }
  }
  
  // === YEH AAPKE CODE SE LIYA GAYA HAI ===
  // User ko diamonds dene ka function
  Future<void> _deliverDiamonds(PurchaseDetails purchaseDetails) async {
    int diamondsToAdd = 0;
    // Product ID ke hisaab se diamonds ki sankhya set karein
    switch (purchaseDetails.productID) {
      case '50_diamonds':
        diamondsToAdd = 50;
        break;
      case '110_diamonds':
        diamondsToAdd = 110;
        break;
    }

    if (diamondsToAdd > 0) {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'diamonds': FieldValue.increment(diamondsToAdd)});
          print('$diamondsToAdd Diamonds delivered to user $userId');
        } catch (e) {
          print("Error updating diamonds in Firestore: $e");
        }
      } else {
        print("Error: User not logged in. Cannot deliver diamonds.");
      }
    }
  }
  
  void dispose() {
    _subscription.cancel();
    _purchaseSuccessController.close();
  }
}