import 'package:flutter/material.dart';
import 'package:uni_marketplace_flutter/screens/product_detail.dart';

class ProductList extends StatefulWidget {
  const ProductList({super.key});

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = "Buy";
  String _selectedCategory = "Math";

  final List<String> _filterOptions = ["Buy", "Rent"];
  final List<String> _categories = ["Math", "Science", "Tech"];

  final List<Map<String, dynamic>> _products = [
    {
      "title": "Probabilidad y estadística para ingeniería y ciencias",
      "price": "35",
      "image": "assets/images/ProbabilidadYEstadistica.jpg",
    },
    {
      "title": "Calculator",
      "price": "40",
      "image": "assets/images/calculadora.png",
    },
    {
      "title": "Análisis y diseño de algoritmos",
      "price": "45",
      "image": "assets/images/algoritmos.png",
    },
    {
      "title": "Chemical Safety Goggles",
      "price": "15",
      "image": "assets/images/glasses.webp",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Discover',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildFilterAndSearch(),
          Expanded(
            child: _buildProductList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSearch() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              ..._filterOptions.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    selectedColor: const Color(0xFF1F7A8C).withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _selectedFilter == filter
                          ? const Color(0xFF1F7A8C)
                          : Colors.black,
                      fontWeight: _selectedFilter == filter
                          ? FontWeight.bold
                          : FontWeight.normal,
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
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down),
                items: _categories.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'What are you looking for?',
                    fillColor: Colors.grey[200],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F7A94), // color cerulean
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Search',
                  style: TextStyle(
                    color: Colors.white, // <- Aquí forzamos blanco
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
          ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          child: Container(
            color: Colors.grey[200],
            height: 160,
            width: double.infinity,
            child: Center(
              child: Image.asset(
                product["image"],
                fit: BoxFit.contain,
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.image, size: 60, color: Colors.grey[600]);
                },
              ),
            ),
          ),
        ),



              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product["title"],
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (product["price"].isNotEmpty)
                      Text(
                        "\$${product["price"]}.000",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF2B7B35),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: product["title"] == "Probabilidad y estadística para ingeniería y ciencias"
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetail(productId: '60J3pS3bRnFjrksPd8hL'),
                                  ),
                                );
                              }
                            : () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F7A8C),
                          padding: const EdgeInsets.symmetric(vertical: 8),
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
