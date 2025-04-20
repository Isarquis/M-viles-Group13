import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class ProductDetailViewModel extends ChangeNotifier {
  final String productId;
  final FirestoreService _firestoreService = FirestoreService();

  Map<String, dynamic>? _product;
  Map<String, dynamic>? get product => _product;

  List<Map<String, dynamic>> _bidsWithUsers = [];
  List<Map<String, dynamic>> get bidsWithUsers => _bidsWithUsers;

  int _highestBid = 0;
  int get highestBid => _highestBid;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  ProductDetailViewModel(this.productId) {
    loadProduct();
    loadBids();
  }

  Future<void> loadProduct() async {
    var productData = await _firestoreService.getProductById(productId);
    if (productData != null) {
      _product = {
        'name': productData.title ?? 'No Name',
        'price': (productData.price ?? 0).toString(),
        'description': productData.description ?? 'No description',
        'imageUrl': productData.image ?? 'assets/images/loading.gif',
        'baseBid': productData.baseBid ?? '50.000',
        'type': productData.type ?? [],
      };
      notifyListeners();
    }
  }

  @override
  Future<void> loadBids() async {
    _isLoading = true;
    notifyListeners();

    final combined = await _firestoreService.getBidsWithUsersByProduct(productId);

    for (var item in combined) {
      final bid = item['bid'];
      if (bid['createdAt'] is Timestamp) {
        final ts = bid['createdAt'] as Timestamp;
        final date = ts.toDate();
        bid['createdAt'] = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
      }
    }

    int maxBid = int.tryParse(_product?['baseBid']?.toString().replaceAll('.', '') ?? '0') ?? 0;
    for (var item in combined) {
      int bidAmount = item['bid']['amount'] ?? 0;
      if (bidAmount > maxBid) maxBid = bidAmount;
    }
    _highestBid = maxBid;
    _bidsWithUsers = combined;

    _isLoading = false;
    notifyListeners();
  }

  List<Map<String, dynamic>> _rentOffersWithUsers = [];
  List<Map<String, dynamic>> get rentOffersWithUsers => _rentOffersWithUsers;

  Future<void> loadRentOffers() async {
    _isLoading = true;
    notifyListeners();

    _rentOffersWithUsers = await _firestoreService.getRentOffersWithUsersByProduct(productId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteBid(Map<String, dynamic> bid) async {
    final bidId = bid['id'];
    if (bidId != null) {
      try {
        await _firestoreService.deleteBidById(bidId);
        print('Bid $bidId deleted successfully');
        await loadBids();
      } catch (e) {
        print('Failed to delete bid $bidId: $e');
      }
    }
  }
}
