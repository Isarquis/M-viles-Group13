import 'package:flutter/material.dart';
import 'package:uni_marketplace_flutter/widgets/home_header.dart';
import 'package:uni_marketplace_flutter/widgets/search_bar.dart' as custom;
import 'package:uni_marketplace_flutter/models/product_model.dart';
import 'package:uni_marketplace_flutter/services/firestore_service.dart';
import 'package:uni_marketplace_flutter/widgets/product_card.dart';
import 'package:uni_marketplace_flutter/services/search_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SearchService _searchService = SearchService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  bool _isOffline = false;
  late final StreamSubscription<ConnectivityResult> _connectivitySubscription;
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Product> _recommendedProducts = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';

  @override
void initState() {
  super.initState();
  _loadProducts();

  _connectivitySubscription = Connectivity()
      .onConnectivityChanged
      .listen((ConnectivityResult result) {
    if (result != ConnectivityResult.none) {
      _loadProducts();
    } else {
      setState(() {
        _isOffline = true;
      });
    }
  });
    }
    @override
    void dispose() {
      _connectivitySubscription.cancel();
      _searchController.dispose();
      super.dispose();
    }

    

Future<void> _updateRecommended() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  final topSearches = await _searchService.getTopUserSearchTerms(userId, limit: 3);
  final recommended = _allProducts.where((product) {
    final title = product.title?.toLowerCase() ?? '';
    return topSearches.any((term) => title.contains(term));
  }).toList();

  setState(() {
    _recommendedProducts = recommended;
  });
}


  Future<void> _loadProducts() async {
  final connectivityResult = await Connectivity().checkConnectivity();
  final isOnline = connectivityResult != ConnectivityResult.none;
  final box = await Hive.openBox('offline_products');

  if (isOnline) {
    try {
      List<Product> products = await _firestoreService.getAllProducts();
      products.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

      await box.put('products', products.map((p) => p.toMap()).toList());

      final categories = <String>{'All'};
      for (final product in products) {
        if (product.category?.isNotEmpty == true) categories.add(product.category!);
      }

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      final topSearches = await _searchService.getTopUserSearchTerms(userId, limit: 3);
      final recommended = products.where((product) {
        final title = product.title?.toLowerCase() ?? '';
        return topSearches.any((term) => title.contains(term));
      }).toList();

      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _categories = categories.toList();
        _recommendedProducts = recommended;
        _isOffline = false;
      });
    } catch (e) {
      await _loadCachedProducts();
    }
  } else {
    await _loadCachedProducts();
  }
}

Future<void> _loadCachedProducts() async {
  final box = await Hive.openBox('offline_products');
  final cachedList = box.get('products') as List<dynamic>?;

  if (cachedList != null && cachedList.isNotEmpty) {
    final cachedProducts = cachedList.map((e) => Product.fromMap(Map<String, dynamic>.from(e), e['id'] ?? '')).toList();

    final categories = <String>{'All'};
    for (final product in cachedProducts) {
      if (product.category?.isNotEmpty == true) categories.add(product.category!);
    }

    setState(() {
      _allProducts = cachedProducts;
      _filteredProducts = cachedProducts;
      _categories = categories.toList();
      _recommendedProducts = [];
      _isOffline = true;
    });
  } else {
    setState(() {
      _allProducts = [];
      _filteredProducts = [];
      _categories = ['All'];
      _recommendedProducts = [];
      _isOffline = true;
    });
  }
}


  void _filterProducts(String query) {
    final filtered = _allProducts.where((product) {
      final titleLower = (product.title ?? '').toLowerCase();
      final searchLower = query.toLowerCase();
      final matchesCategory =
          _selectedCategory == 'All' || product.category == _selectedCategory;
      return titleLower.contains(searchLower) && matchesCategory;
    }).toList();

    setState(() {
      _filteredProducts = filtered;
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterProducts(_searchController.text);
  }


  @override
  Widget build(BuildContext context) {
    final bool isSearching = _searchController.text.isNotEmpty;
    final bool isFilteringCategory = _selectedCategory != 'All';

    return Scaffold(
      appBar: HomeHeader(
        onCategorySelected: _onCategorySelected,
        categories: _categories,
        selectedCategory: _selectedCategory,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  Intro
            const Text(
              'Welcome to UNIMARKET',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
             if (_isOffline) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'You are offline. Showing data storage.',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 4),
            const Text(
              'Buy, sell, and discover items from your university community.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            // Search Bar
            custom.SearchBar(
              controller: _searchController,
              products: _allProducts,
              onSearchResult: (result) {
                setState(() {
                  _filteredProducts = result.isEmpty ? _allProducts : result;
                });
              },
            ),
            const SizedBox(height: 16),

            // Recommended
            if (_recommendedProducts.isNotEmpty &&
                !isSearching &&
                !isFilteringCategory) ...[
              const Text(
                'Recommended',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recommendedProducts.length,
                  itemBuilder: (context, index) {
                    final product = _recommendedProducts[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: ProductCard(
                        title: product.title ?? '',
                        price: product.price ?? 0.0,
                        imageUrl: product.image ?? '',
                        productId: product.id,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Recently Added
            if (_allProducts.isNotEmpty &&
                !isSearching &&
                !isFilteringCategory) ...[
              const Text(
                'Recently Added',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    final product = _allProducts.reversed.toList()[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: ProductCard(
                        title: product.title ?? '',
                        price: product.price ?? 0.0,
                        imageUrl: product.image ?? '',
                        productId: product.id,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Search or Filtered Results
            if (_filteredProducts.isNotEmpty &&
                (isSearching || isFilteringCategory)) ...[
              const Text(
                'Search Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ProductCard(
                      title: product.title ?? '',
                      price: product.price ?? 0.0,
                      imageUrl: product.image ?? '',
                      productId: product.id,
                    ),
                  );
                },
              ),
            ],

            if (_isOffline && _allProducts.isEmpty) ...[
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'No store products found.\nReconnect to view listings.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ]

          ],
        ),
      ),
    );
  }
}