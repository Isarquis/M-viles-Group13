import 'package:flutter/material.dart';
import 'package:uni_marketplace_flutter/widgets/home_header.dart';
import 'package:uni_marketplace_flutter/widgets/search_bar.dart' as custom;
import 'package:uni_marketplace_flutter/models/product_model.dart';
import 'package:uni_marketplace_flutter/services/firestore_service.dart';
import 'package:uni_marketplace_flutter/widgets/product_card.dart';
import 'package:uni_marketplace_flutter/services/search_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SearchService _searchService = SearchService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Product> _recommendedProducts = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';

  @override
    void initState() {
      super.initState();
      _loadProducts();

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
  List<Product> products = await _firestoreService.getAllProducts();
  products.sort((a, b) {
    final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  });

  final extractedCategories = <String>{'All'};
  for (var product in products) {
    if (product.category != null && product.category!.isNotEmpty) {
      extractedCategories.add(product.category!);
    }
  }

  setState(() {
    _allProducts = products;
    _filteredProducts = products;
    _categories = extractedCategories.toList();
  });

  await _updateRecommended(); 
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
            const SizedBox(height: 4),
            const Text(
              'Buy, sell, and discover items from your university community.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            // 🔍 Search Bar
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
          ],
        ),
      ),
    );
  }
}
