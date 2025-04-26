import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'package:uni_marketplace_flutter/models/product_model.dart';
import 'package:hive/hive.dart'; 



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

  Future<String> downloadAndSaveImage(String url, String filename) async {
    final response = await http.get(Uri.parse(url));
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }
  Future<List<Product>> downloadImagesForProducts(List<Product> products, String suffix) async {
    List<Product> updatedProducts = [];
    for (var p in products) {
      String imagePath = p.image ?? '';
      if (imagePath.isNotEmpty && !imagePath.startsWith('/')) {
        imagePath = await downloadAndSaveImage(imagePath, '${p.id}_$suffix.jpg');
      }
      updatedProducts.add(Product(
        id: p.id,
        title: p.title,
        description: p.description,
        price: p.price,
        image: imagePath,
        ownerId: p.ownerId,
        type: p.type,
        status: p.status,
        latitude: p.latitude,
        longitude: p.longitude,
        originalImageUrl: p.originalImageUrl,
      ));
    }
    return updatedProducts;
  }

  Future<void> loadUserData({bool offlineMode = false}) async {
    if (offlineMode) {
      var box = Hive.box('profile_data');

      postedProducts = (box.get('postedProducts', defaultValue: []) as List)
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      rentedProducts = (box.get('rentedProducts', defaultValue: []) as List)
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      boughtProducts = (box.get('boughtProducts', defaultValue: []) as List)
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      var profileInfo = box.get('profileInfo', defaultValue: {});
      name = profileInfo['name'] ?? '';
      email = profileInfo['email'] ?? '';
      phone = profileInfo['phone'] ?? '';
      imagePath = profileInfo['imagePath'] ?? '';

      return;
    }
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
      (p.status?.toLowerCase() == 'available') 
    ).toList();
    print('Posted products: $postedProducts');

    rentedProducts = allProducts.where((p) =>
      (p.ownerId?.toLowerCase() ?? '') == userId.toLowerCase() &&
      (p.status?.toLowerCase() == 'rented') &&
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

    postedProducts = postedProducts.map((p) => Product(
      id: p.id,
      title: p.title,
      description: p.description,
      price: p.price,
      image: p.image,
      ownerId: p.ownerId,
      type: p.type,
      status: p.status,
      latitude: p.latitude,
      longitude: p.longitude,
      originalImageUrl: p.image,
    )).toList();

    rentedProducts = rentedProducts.map((p) => Product(
      id: p.id,
      title: p.title,
      description: p.description,
      price: p.price,
      image: p.image,
      ownerId: p.ownerId,
      type: p.type,
      status: p.status,
      latitude: p.latitude,
      longitude: p.longitude,
      originalImageUrl: p.image,
    )).toList();

    if (lastSold != null) {
      lastSold = Product(
        id: lastSold!.id,
        title: lastSold!.title,
        description: lastSold!.description,
        price: lastSold!.price,
        image: lastSold!.image,
        ownerId: lastSold!.ownerId,
        type: lastSold!.type,
        status: lastSold!.status,
        latitude: lastSold!.latitude,
        longitude: lastSold!.longitude,
        originalImageUrl: lastSold!.image,
      );
    }

    postedProducts = await downloadImagesForProducts(postedProducts, 'posted');
    rentedProducts = await downloadImagesForProducts(rentedProducts, 'rented');
    boughtProducts = await downloadImagesForProducts(boughtProducts, 'bought');
    if (lastSold != null && lastSold!.image != null && lastSold!.image!.isNotEmpty && !lastSold!.image!.startsWith('/')) {
      String localImagePath = await downloadAndSaveImage(lastSold!.image!, '${lastSold!.id}_sold.jpg');
      lastSold = Product(
        id: lastSold!.id,
        title: lastSold!.title,
        description: lastSold!.description,
        price: lastSold!.price,
        image: localImagePath,
        ownerId: lastSold!.ownerId,
        type: lastSold!.type,
        status: lastSold!.status,
        latitude: lastSold!.latitude,
        longitude: lastSold!.longitude,
        originalImageUrl: lastSold!.originalImageUrl,
      );
    }

    final enrichedTransactions = await _firestoreService.getEnrichedSaleTransactionsByUser(userId);
    for (var t in enrichedTransactions) {
      String localImagePath = '';
      if (t['productImage'] != null && (t['productImage'] as String).isNotEmpty) {
        localImagePath = await downloadAndSaveImage(t['productImage'], '${t['productId']}.jpg');
      }
      final product = Product(
        id: t['productId'],
        title: t['productTitle'],
        image: localImagePath,
        price: (t['price'] as num).toDouble(),
      );
      boughtProducts.add(product);
    }
    var box = Hive.box('profile_data');

    if (imagePath.isNotEmpty && !imagePath.startsWith('/')) {
      imagePath = await downloadAndSaveImage(imagePath, 'profile_$userId.jpg');
    }

    await box.put('postedProducts', postedProducts.map((p) => p.toJson()).toList());
    await box.put('rentedProducts', rentedProducts.map((p) => p.toJson()).toList());
    await box.put('boughtProducts', boughtProducts.map((p) => p.toJson()).toList());
    await box.put('profileInfo', {
      'name': name,
      'email': email,
      'phone': phone,
      'imagePath': imagePath,
    });
  }
  FirestoreService get firestoreService => _firestoreService;
}
