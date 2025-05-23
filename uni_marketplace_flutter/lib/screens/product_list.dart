import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uni_marketplace_flutter/screens/product_detail.dart';
import 'package:uni_marketplace_flutter/services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uni_marketplace_flutter/models/product_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; 


class SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final List<Product> products;
  final Function(List<Product>) onSearchResult;

  const SearchBar({
    required this.controller,
    required this.products,
    required this.onSearchResult,
    super.key,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final FirestoreService _firestoreService = FirestoreService();
  Timer? _debounce;
  List<Product> _suggestions = [];

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final results = widget.products.where(
        (p) => (p.title ?? '').toLowerCase().contains(query.toLowerCase()),
      ).toList();

      setState(() {
        _suggestions = results;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _suggestions = [];
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE1E5F2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'What are you looking for?',
                    hintStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (widget.controller.text.isEmpty) {
                    widget.onSearchResult([]);
                  } else if (_suggestions.isNotEmpty) {
                    _firestoreService.logFeatureUsage('search${widget.controller.text}');
                    widget.onSearchResult([_suggestions.first]);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F7A8C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text(
                  'Search',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ..._suggestions.map(
          (s) => ListTile(
            title: Text(s.title ?? ''),
            onTap: () {
              widget.controller.text = s.title ?? '';
              setState(() {});
            },
          ),
        ),
      ],
    );
  }
}
class ProductList extends StatefulWidget {
  const ProductList({super.key});

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = "All";
  String _selectedCategory = "Select";

  final List<String> _filterOptions = ["All", "Buy", "Rent"];
  final List<String> _categories = ["Select", "Math", "Science", "Tech"];

  final FirestoreService _firestoreService = FirestoreService();
  List<Product> _products = [];
  List<Product> _allProducts = [];
  bool _isOffline = false; // NEW

  @override
  void initState() {
    super.initState();
    _firestoreService.logFeatureUsage('screen_product_list');
    _checkConnectionAndLoad();

  }

  Future<void> _checkConnectionAndLoad() async {
  var connectivityResult = await (Connectivity().checkConnectivity());

  if (connectivityResult == ConnectivityResult.none) {
    setState(() {
      _isOffline = true;
    });
  }
  
  _loadProducts();
}



  void _loadProducts() async {
    DateTime requestedAt = DateTime.now();
    var fetchedProducts = await _firestoreService.getAllProducts();
    DateTime receivedAt = DateTime.now();

    setState(() {
      final available = fetchedProducts.where(
        (p) => (p.status ?? '').toLowerCase() == 'available',
      ).toList();
      _products = available;
      _allProducts = List<Product>.from(available);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      DateTime showedAt = DateTime.now();
      _firestoreService.logResponseTime(requestedAt, receivedAt, showedAt);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Discover',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isOffline) _buildOfflineBanner(), // NEW
          _buildFilterAndSearch(),
          Expanded(child: _buildProductList()),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      color: Colors.red,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: const [
          Icon(Icons.wifi_off, color: Colors.white),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are offline. Showing stored products.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ..._filterOptions.map((filter) => _buildChoiceChip(filter)),
              const Spacer(),
              _buildCategoryDropdown(),
            ],
          ),
          const SizedBox(height: 12),
          SearchBar(
            controller: _searchController,
            products: _allProducts,
            onSearchResult: (result) {
              setState(() {
                if (result.isEmpty) {
                  _products = List<Product>.from(_allProducts);
                } else {
                  _products = result;
                }
              });
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String filter) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(filter),
        selected: _selectedFilter == filter,
        selectedColor: const Color(0xFF1F7A8C),
        backgroundColor: Colors.transparent,
        side: const BorderSide(color: Color(0xFF1F7A8C)),
        labelStyle: TextStyle(
          color: _selectedFilter == filter ? Colors.white : const Color(0xFF1F7A8C),
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        onSelected: (selected) {
          setState(() {
            _selectedFilter = filter;
          });
        },
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButton<String>(
      value: _selectedCategory,
      underline: Container(height: 1, color: const Color(0xFF1F7A8C)),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
      items: _categories.map((value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedCategory = newValue!;
        });
      },
    );
  }

  Widget _buildProductList() {
    if (_products.isEmpty) {
      return Center(
        child: Image.asset(
          'assets/images/loading.gif',
          height: MediaQuery.of(context).size.height * 0.2,
        ),
      );
    }

    List<Product> filteredProducts = _products.where((product) {
      bool matchesCategory = _selectedCategory == "Select" || product.category == _selectedCategory;
      bool matchesType = _selectedFilter == "All" || (product.type != null && product.type!.contains(_selectedFilter));
      return (_selectedFilter == "All" ? true : matchesType) && matchesCategory;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.only(top: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.82,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(15),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (product.image ?? '').startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: product.image ?? '',
                          fit: BoxFit.contain,
                          height: 200,
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        )
                      : Image.asset(
                          product.image ?? '',
                          fit: BoxFit.contain,
                          height: 200,
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "\$${product.price} COP",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2B7B35),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetail(productId: product.id),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F7A8C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Details",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

