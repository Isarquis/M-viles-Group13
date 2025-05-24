import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uni_marketplace_flutter/models/product_model.dart';
import 'package:uni_marketplace_flutter/screens/sell_product_detail.dart';
import 'package:uni_marketplace_flutter/services/firestore_service.dart';

enum SortOption { priceAsc, priceDesc, dateAsc, dateDesc }

class EarnScreen extends StatefulWidget {
  const EarnScreen({Key? key}) : super(key: key);

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> {
  // servicios y controladores
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // datos y estados
  List<Product> _allProducts = [];
  List<Product> _filtered = [];
  List<Product> _page = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _lastIndex = 0;
  final int _perPage = 20;

  String _selectedCategory = 'All';
  SortOption? _selectedSort;
  final List<String> _categories = ['All', 'Math', 'Science', 'Tech'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _allProducts.clear();
      _filtered.clear();
      _page.clear();
      _lastIndex = 0;
      _hasMore = true;
    });

    final fetched = await _firestoreService.getAllProducts();
    // sólo disponibles
    _allProducts =
        fetched
            .where((p) => (p.status ?? '').toLowerCase() == 'available')
            .toList();

    _applyFilterSort();
    setState(() => _isLoading = false);
  }

  void _applyFilterSort() {
    // filtrar por categoría
    _filtered =
        (_selectedCategory == 'All')
            ? List.from(_allProducts)
            : _allProducts
                .where((p) => p.category == _selectedCategory)
                .toList();

    // filtrar por texto
    final term = _searchController.text.trim().toLowerCase();
    if (term.isNotEmpty) {
      _filtered =
          _filtered
              .where(
                (p) => p.title != null && p.title!.toLowerCase().contains(term),
              )
              .toList();
    }

    // ordenar
    if (_selectedSort != null) {
      switch (_selectedSort!) {
        case SortOption.priceAsc:
          _filtered.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
          break;
        case SortOption.priceDesc:
          _filtered.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
          break;
        case SortOption.dateAsc:
          _filtered.sort(
            (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
              b.createdAt ?? DateTime.now(),
            ),
          );
          break;
        case SortOption.dateDesc:
          _filtered.sort(
            (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
              a.createdAt ?? DateTime.now(),
            ),
          );
          break;
      }
    }

    // reiniciar paginación
    _page.clear();
    _lastIndex = 0;
    _hasMore = true;
    _loadMore();
  }

  void _loadMore() {
    if (!_hasMore) return;
    setState(() => _isLoadingMore = true);

    final nextIndex = min(_lastIndex + _perPage, _filtered.length);
    final slice = _filtered.sublist(_lastIndex, nextIndex);

    setState(() {
      _page.addAll(slice);
      _lastIndex = nextIndex;
      _hasMore = _lastIndex < _filtered.length;
      _isLoadingMore = false;
    });
  }

  void _onSearchOrCategoryChanged() {
    // limpiar búsqueda si cambio categoría
    _searchController.clear();
    _applyFilterSort();
  }

  void _onSortSelected(SortOption opt) {
    setState(() => _selectedSort = opt);
    _applyFilterSort();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earn'),
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            onSelected: _onSortSelected,
            itemBuilder:
                (_) => const [
                  PopupMenuItem(
                    value: SortOption.priceAsc,
                    child: Text('Price: Low → High'),
                  ),
                  PopupMenuItem(
                    value: SortOption.priceDesc,
                    child: Text('Price: High → Low'),
                  ),
                  PopupMenuItem(
                    value: SortOption.dateAsc,
                    child: Text('Date: Old → New'),
                  ),
                  PopupMenuItem(
                    value: SortOption.dateDesc,
                    child: Text('Date: New → Old'),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          // filtros
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _selectedCategory,
                  items:
                      _categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                  onChanged: (v) {
                    _selectedCategory = v!;
                    _onSearchOrCategoryChanged();
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search…',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _applyFilterSort(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _applyFilterSort,
                  child: const Text('Go'),
                ),
              ],
            ),
          ),
          // lista
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      controller: _scrollController,
                      itemCount: _page.length + (_hasMore ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i == _page.length) {
                          return const Padding(
                            padding: EdgeInsets.all(8),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final p = _page[i];
                        return ListTile(
                          leading:
                              p.image != null && p.image!.startsWith('http')
                                  ? CachedNetworkImage(
                                    imageUrl: p.image!,
                                    width: 50,
                                    placeholder:
                                        (_, __) =>
                                            const CircularProgressIndicator(),
                                    errorWidget:
                                        (_, __, ___) => const Icon(Icons.error),
                                  )
                                  : const Icon(Icons.image),
                          title: Text(p.title ?? ''),
                          subtitle: Text(
                            "\$${p.price?.toStringAsFixed(0) ?? '0'} COP",
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.share),
                            onPressed: () {
                              Share.share(
                                'Check out this listing: ${p.title} for \$${p.price?.toStringAsFixed(0)} COP',
                              );
                            },
                          ),
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => SellProductDetail(productId: p.id),
                                ),
                              ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
