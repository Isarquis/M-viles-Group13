import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:collection';
import '../services/firestore_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ProductDetailViewModel extends ChangeNotifier {
  static final _bidsCache = LinkedHashMap<String, List<Map<String, dynamic>>>(); // key: productId
  static final _rentOffersCache = LinkedHashMap<String, List<Map<String, dynamic>>>();
  static const int _cacheSizeLimit = 10;

  void _addToCache<K, V>(LinkedHashMap<K, V> cache, K key, V value) {
    if (cache.containsKey(key)) {
      cache.remove(key); // Move key to the end to mark it as recently used
    } else if (cache.length >= _cacheSizeLimit) {
      cache.remove(cache.keys.first); // Remove least recently used (first inserted)
    }
    cache[key] = value; // Insert as most recently used
  }
  final String productId;
  final FirestoreService _firestoreService = FirestoreService();

  bool _hasConnection = true;
  bool get hasConnection => _hasConnection;

  Map<String, dynamic>? _product;
  Map<String, dynamic>? get product => _product;

  List<Map<String, dynamic>> _bidsWithUsers = [];
  List<Map<String, dynamic>> get bidsWithUsers => _bidsWithUsers;

  int _highestBid = 0;
  int get highestBid => _highestBid;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  ProductDetailViewModel(this.productId) {
    loadProduct().then((_) {
      loadBids();
      loadRentOffers();
    });
  }

  Future<void> checkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _hasConnection = connectivityResult != ConnectivityResult.none;
  }

  Future<void> loadProduct() async {
    var productData = await _firestoreService.getProductById(productId);
    print('Product owner id: ${productData?.ownerId}');
    if (productData != null) {
      _product = {
        'ownerId': productData.ownerId,
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

    await checkConnection();
    if (!_hasConnection) {
      _bidsWithUsers = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (_bidsCache.containsKey(productId)) {
      _bidsWithUsers = _bidsCache[productId]!;
    } else {
      try {
        final combined = await _firestoreService.getBidsWithUsersByProduct(productId);
        _hasConnection = true;

        for (var item in combined) {
          final bid = item['bid'];
          if (bid['createdAt'] is Timestamp) {
            final ts = bid['createdAt'] as Timestamp;
            final date = ts.toDate();
            bid['createdAt'] =
                '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
          }
        }

        int maxBid = int.tryParse(_product?['baseBid']?.toString().replaceAll('.0', '') ?? '0') ?? 0;
        for (var item in combined) {
          int bidAmount = item['bid']['amount'] ?? 0;
          if (bidAmount >= maxBid) {
            maxBid = bidAmount;
            _highestBid = maxBid;
          }
        }

        _bidsWithUsers = combined;
        _addToCache(_bidsCache, productId, combined);
      } catch (e) {
        _hasConnection = false;
        _bidsWithUsers = [];
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  List<Map<String, dynamic>> _rentOffersWithUsers = [];
  List<Map<String, dynamic>> get rentOffersWithUsers => _rentOffersWithUsers;

  Future<void> loadRentOffers() async {
    _isLoading = true;
    notifyListeners();

    await checkConnection();
    if (!_hasConnection) {
      _rentOffersWithUsers = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (_rentOffersCache.containsKey(productId)) {  // Check if the data is already cached
      _rentOffersWithUsers = _rentOffersCache[productId]!;
    } else {
      try {
        final combined = await _firestoreService.getRentOffersWithUsersByProduct(productId); // get data from Firestore   
        _hasConnection = true;

        for (var item in combined) {   // PROCESS
          if (item['offer'] == null) {
            if (item['rentOffer'] != null) {
              item['offer'] = item['rentOffer'];
            } else if (item['rent'] != null) {
              item['offer'] = item['rent'];
            }
          }

          final offer = item['offer'];
          if (offer != null) {
            if (offer['amount'] == null && offer['price'] != null) {
              offer['amount'] = offer['price'];
            }

            if (offer['createdAt'] is Timestamp) {
              final ts = offer['createdAt'] as Timestamp;
              final d = ts.toDate();
              offer['createdAt'] =
                  '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
            }
          }
        }

        _rentOffersWithUsers = combined;  //Update UI data binding
        _addToCache(_rentOffersCache, productId, combined);  // Cache the data using LRU
      } catch (e) {
        _hasConnection = false;
        _rentOffersWithUsers = [];
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteBid(Map<String, dynamic> bid) async {
    final bidId = bid['id'];
    if (bidId != null) {
      try {
        await _firestoreService.deleteBidById(bidId);
        // success
        await loadBids();
      } catch (e) {
        // error
      }
    }
  }

  Future<void> deleteRentOffer(Map<String, dynamic> offer) async {
    final offerId = offer['id'];
    if (offerId != null) {
      try {
        await _firestoreService.deleteRentOfferById(offerId);
        await loadRentOffers();
      } catch (e) {
        // error
      }
    }
  }
}
