import 'package:flutter/material.dart';
import 'package:uni_marketplace_flutter/models/product_model.dart';
import 'package:uni_marketplace_flutter/services/firestore_service.dart';
import 'package:uni_marketplace_flutter/services/search_service.dart';
import 'package:uni_marketplace_flutter/services/search_database_service.dart';
import 'package:uni_marketplace_flutter/services/search_file_service.dart';

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
  final SearchService _searchService = SearchService();
  final SearchDatabaseService _searchDbService = SearchDatabaseService();

  Future<void> _performSearch(String input) async {
    final lowerInput = input.toLowerCase();

    if (lowerInput.isEmpty) {
      widget.onSearchResult(widget.products);
      return;
    }

    await _searchService.incrementSearchTerm(lowerInput);
    await _searchDbService.insertSearchTerm(lowerInput);
    await SearchFileService.appendSearchTerm(lowerInput);
    _firestoreService.logFeatureUsage('search$lowerInput');

    final filtered =
        widget.products.where((p) {
          final title = p.title ?? '';
          return title.toLowerCase().contains(lowerInput);
        }).toList();

    widget.onSearchResult(filtered);
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
                  onChanged: (value) => _performSearch(value),
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
                  _performSearch(widget.controller.text);
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
      ],
    );
  }
}
