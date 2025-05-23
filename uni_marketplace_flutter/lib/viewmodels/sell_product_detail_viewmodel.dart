import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SellProductDetailViewModel with ChangeNotifier {
  final String productId;
  Map<String, dynamic>? _product;
  Map<String, dynamic>? _owner;

  SellProductDetailViewModel(this.productId) {
    loadProduct();
  }

  Map<String, dynamic>? get product => _product;
  Map<String, dynamic>? get owner => _owner;

  Future<void> loadProduct() async {
    try {
      // Fetch product
      DocumentSnapshot productDoc =
          await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .get();

      if (productDoc.exists) {
        final productData = productDoc.data() as Map<String, dynamic>?;
        if (productData != null) {
          // Map fields to match the expected structure
          _product = {
            'name': productData['title'] ?? 'Unknown Product',
            'price': productData['price']?.toString() ?? '0',
            'description':
                productData['description'] ?? 'No description available',
            'imageUrl': productData['image'] ?? 'assets/images/placeholder.png',
            'ownerId': productData['ownerId'] ?? 'unknown_owner',
          };

          // Fetch owner
          String ownerId = _product!['ownerId'];
          DocumentSnapshot ownerDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(ownerId)
                  .get();

          if (ownerDoc.exists) {
            final ownerData = ownerDoc.data() as Map<String, dynamic>?;
            _owner = {
              'name': ownerData?['name'] ?? 'Unknown Owner',
              'email': ownerData?['email'] ?? '',
              'phone': ownerData?['phone'] ?? '',
            };
          } else {
            _owner = {'name': 'Unknown Owner', 'email': '', 'phone': ''};
          }
        } else {
          _product = {
            'name': 'Product Not Found',
            'price': '0',
            'description': 'No description available',
            'imageUrl': 'assets/images/placeholder.png',
          };
          _owner = {'name': 'Unknown Owner', 'email': '', 'phone': ''};
        }
      } else {
        _product = {
          'name': 'Product Not Found',
          'price': '0',
          'description': 'No description available',
          'imageUrl': 'assets/images/placeholder.png',
        };
        _owner = {'name': 'Unknown Owner', 'email': '', 'phone': ''};
      }
    } catch (e) {
      _product = {
        'name': 'Error Loading Product',
        'price': '0',
        'description': 'Error: $e',
        'imageUrl': 'assets/images/placeholder.png',
      };
      _owner = {'name': 'Unknown Owner', 'email': '', 'phone': ''};
    }
    notifyListeners();
  }
}
