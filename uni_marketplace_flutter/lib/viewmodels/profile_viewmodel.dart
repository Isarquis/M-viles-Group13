import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class ProfileViewModel {
  final String userId;
  final FirestoreService _firestoreService = FirestoreService();

  String name = '';
  String email = '';
  String phone = '';
  String imagePath = '';

  List<Map<String, dynamic>> postedProducts = [];
  List<Map<String, dynamic>> rentedProducts = [];
  Map<String, dynamic>? lastSold;
  List<Map<String, dynamic>> boughtProducts = [];

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
      (p['ownerId']?.toString() ?? '').toLowerCase() == userId.toLowerCase() &&
      (p['status']?.toString().toLowerCase() == 'available') &&
      (p['type'] != null && (p['type'] as List).map((e) => e.toString().toLowerCase()).contains('buy'))
    ).toList();
    print('Posted products: $postedProducts');

    rentedProducts = allProducts.where((p) =>
      (p['ownerId']?.toString() ?? '').toLowerCase() == userId.toLowerCase() &&
      (p['status']?.toString().toLowerCase() == 'available') &&
      (p['type'] != null && (p['type'] as List).map((e) => e.toString().toLowerCase()).contains('rent'))
    ).toList();

    final sold = allProducts.where((p) =>
      (p['ownerId']?.toString() ?? '').toLowerCase() == userId.toLowerCase() &&
      (p['status']?.toString().toLowerCase() == 'sold') &&
      (p['type'] != null && (p['type'] as List).map((e) => e.toString().toLowerCase()).contains('buy'))
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
