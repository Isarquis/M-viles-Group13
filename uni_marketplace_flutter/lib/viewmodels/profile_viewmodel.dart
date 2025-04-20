import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'package:uni_marketplace_flutter/models/product_model.dart';

class ProfileViewModel {
  final String userId;
  final FirestoreService _firestoreService = FirestoreService();

  String name = '';
  String email = '';
  String phone = '';
  String imagePath = '';

  List<Product> postedProducts = [];
  List<Product> rentedProducts = [];
  Product? lastSold;
  List<Product> boughtProducts = [];

  ProfileViewModel(this.userId);

  Future<void> loadUserData() async {
    final userData = await _firestoreService.getUser(userId);
    if (userData != null) {
      name = userData['name'] ?? '';
      email = userData['email'] ?? '';
      phone = userData['phone'] ?? '';
      imagePath = userData['image'] ?? '';
    }

    final allProducts = await _firestoreService.getAllProducts();
    postedProducts = allProducts.where((p) =>
      (p.ownerId?.toLowerCase() ?? '') == userId.toLowerCase() &&
      (p.status?.toLowerCase() == 'available') &&
      (p.type != null && p.type!.map((e) => e.toLowerCase()).contains('buy'))
    ).toList();
    print('Posted products: $postedProducts');

    rentedProducts = allProducts.where((p) =>
      (p.ownerId?.toLowerCase() ?? '') == userId.toLowerCase() &&
      (p.status?.toLowerCase() == 'available') &&
      (p.type != null && p.type!.map((e) => e.toLowerCase()).contains('rent'))
    ).toList();

    final sold = allProducts.where((p) =>
      (p.ownerId?.toLowerCase() ?? '') == userId.toLowerCase() &&
      (p.status?.toLowerCase() == 'sold') &&
      (p.type != null && p.type!.map((e) => e.toLowerCase()).contains('buy'))
    ).toList();
    if (sold.isNotEmpty) {
      lastSold = sold.first;
    }

    final transactions = await _firestoreService.getTransactionsByUser(userId);
    for (var t in transactions) {
      final product = await _firestoreService.getProductById(t['productId']);
      if (product != null) {
        boughtProducts.add(product);
      }
    }
  }
}
