import 'package:flutter/material.dart';
import 'package:uni_marketplace_flutter/screens/product_detail.dart';
import 'package:uni_marketplace_flutter/services/firestore_service.dart';

class SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final List<Map<String, dynamic>> products;
  final Function(List<Map<String, dynamic>>) onSearchResult;

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

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> suggestions =
        widget.controller.text.isEmpty
            ? []
            : widget.products
                .where(
                  (p) => p["title"].toLowerCase().contains(
                    widget.controller.text.toLowerCase(),
                  ),
                )
                .toList();

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
                  onChanged: (value) => setState(() {}),
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
                  } else if (suggestions.isNotEmpty) {
                    _firestoreService.logFeatureUsage('search_${widget.controller.text}');
                    widget.onSearchResult([suggestions.first]);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F7A8C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Search',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...suggestions.map(
          (s) => ListTile(
            title: Text(s["title"]),
            onTap: () {
              widget.controller.text = s["title"];
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
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _allProducts = [];
  final List<String> _localImages = [
    "assets/images/ProbabilidadYEstadistica.jpg",
    "assets/images/calculadora.png",
    "assets/images/algoritmos.png",
    "assets/images/glasses.webp",
  ];

  @override
  void initState() {
    super.initState();
    _firestoreService.logFeatureUsage('screen_product_list');
    _loadProducts();
  }

  void _loadProducts() async {
    var fetchedProducts = await _firestoreService.getAllProducts();

    setState(() {
      _products = fetchedProducts;
      _allProducts = List<Map<String, dynamic>>.from(fetchedProducts);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {},
        ),
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
          _buildFilterAndSearch(),
          Expanded(child: _buildProductList()),
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
              ..._filterOptions.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    selectedColor: const Color(0xFF1F7A8C),
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: Color(0xFF1F7A8C)),
                    labelStyle: TextStyle(
                      color:
                          _selectedFilter == filter
                              ? Colors.white
                              : const Color(0xFF1F7A8C),
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
              }).toList(),
              const Spacer(),
              DropdownButton<String>(
                value: _selectedCategory,
                underline: Container(height: 1, color: const Color(0xFF1F7A8C)),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.black,
                ),
                items:
                    _categories.map((String value) {
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
              ),
            ],
          ),
          const SizedBox(height: 12),
          SearchBar(
            controller: _searchController,
            products: _allProducts,
            onSearchResult: (result) {
              setState(() {
                if (result.isEmpty) {
                  _products = List<Map<String, dynamic>>.from(_allProducts);
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

  Widget _buildProductList() {
    if (_products.isEmpty) {
      return Center(
        child: Image.asset(
          'assets/images/loading.gif',
          height: MediaQuery.of(context).size.height * 0.2,
        ),
      );
    }

    List<Map<String, dynamic>> filteredProducts =
        _products.where((product) {
          bool matchesCategory =
              _selectedCategory == "Select" ||
              product["category"] == _selectedCategory;
          bool matchesType =
              _selectedFilter == "All" ||
              product["type"].contains(_selectedFilter);
          return (_selectedFilter == "All" ? true : matchesType) &&
              matchesCategory;
        }).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.only(top: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(15),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          product["image"].startsWith('http')
                              ? Image.network(
                                product["image"],
                                fit: BoxFit.contain,
                                height: 200,
                              )
                              : Image.asset(
                                product["image"],
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
                        product["title"],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "\$${product["price"]} COP",
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
                                  builder:
                                      (context) => ProductDetail(
                                        productId: product["id"],
                                      ),
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
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
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
      },
    );
  }
}
