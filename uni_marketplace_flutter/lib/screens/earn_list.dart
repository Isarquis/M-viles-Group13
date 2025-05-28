import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uni_marketplace_flutter/models/product_model.dart';
import 'package:uni_marketplace_flutter/screens/sell_product_detail.dart';
import 'package:uni_marketplace_flutter/services/firestore_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:uni_marketplace_flutter/services/search_history_db.dart';

enum SortOption { priceAsc, priceDesc, dateAsc, dateDesc }

class EarnScreen extends StatefulWidget {
  const EarnScreen({Key? key}) : super(key: key);

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Product> _allProducts = [];
  List<Product> _filtered = [];
  final ValueNotifier<List<Product>> _pageNotifier = ValueNotifier([]);
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _lastIndex = 0;
  bool _showOfflineBanner = false;
  late Box _productsBox;
  final int _perPage = 20;

  String _selectedCategory = 'All';
  SortOption? _selectedSort;
  final List<String> _categories = ['All', 'Math', 'Science', 'Tech'];

  // Search History
  final SearchHistoryDB _searchHistoryDB = SearchHistoryDB();
  List<String> _searchSuggestions = [];

  // Debounce timer
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _onScroll();
      _hideSearchSuggestionsOnScroll();
    });
    // Arrancamos todo después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _setup());
  }

  Future<void> _setup() async {
    await _initHive();
    await _loadInitial();
  }

  Future<void> _initHive() async {
    _productsBox = await Hive.openBox('cached_products');
  }

  Future<void> _loadSearchSuggestions() async {
    final terms = await _searchHistoryDB.getRecentTerms();
    setState(() => _searchSuggestions = terms);
  }

  Future<void> _saveSearchTerm(String term) async {
    if (term.trim().isEmpty) return;
    await _searchHistoryDB.insertTerm(term.trim());
    await _loadSearchSuggestions();
  }

  void _hideSearchSuggestionsOnScroll() {
    if (_searchSuggestions.isNotEmpty) {
      setState(() => _searchSuggestions = []);
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _showOfflineBanner = false;
      _allProducts.clear();
      _filtered.clear();
      _pageNotifier.value = [];
      _lastIndex = 0;
      _hasMore = true;
    });

    try {
      final conn = await Connectivity().checkConnectivity();
      if (conn == ConnectivityResult.none) {
        throw Exception('offline');
      }
      // Intento online
      final fetched = await _firestoreService.getAllProducts();
      _allProducts =
          fetched
              .where((p) => (p.status ?? '').toLowerCase() == 'available')
              .toList();
      await _saveProductsToHive(_allProducts);
    } catch (_) {
      // OFFLINE o fallo de red
      final cached = await _loadProductsFromHive();
      _allProducts = cached;
      _showOfflineBanner = true;
    } finally {
      setState(() => _isLoading = false);
      _applyFilterSort();
    }
  }

  Future<void> _saveProductsToHive(List<Product> products) async {
    await _productsBox.put('products', products.map((p) => p.toMap()).toList());
  }

  Future<List<Product>> _loadProductsFromHive() async {
    final cached = _productsBox.get('products', defaultValue: []);
    return (cached as List)
        .map((e) => Product.fromMap(e as Map<String, dynamic>, ''))
        .toList();
  }

  void _applyFilterSort() {
    final term = _searchController.text.trim().toLowerCase();
    if (term.isNotEmpty) _saveSearchTerm(term);

    _filtered =
        _selectedCategory == 'All'
            ? List.from(_allProducts)
            : _allProducts
                .where((p) => p.category == _selectedCategory)
                .toList();

    if (term.isNotEmpty) {
      _filtered =
          _filtered
              .where(
                (p) => p.title != null && p.title!.toLowerCase().contains(term),
              )
              .toList();
    }

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

    _pageNotifier.value = [];
    _lastIndex = 0;
    _hasMore = true;
    _loadMore();
  }

  void _loadMore() {
    if (!_hasMore) return;
    setState(() => _isLoadingMore = true);

    final next = min(_lastIndex + _perPage, _filtered.length);
    final slice = _filtered.sublist(_lastIndex, next);
    _pageNotifier.value = [..._pageNotifier.value, ...slice];
    _lastIndex = next;
    _hasMore = _lastIndex < _filtered.length;

    setState(() => _isLoadingMore = false);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  void _onSearchOrCategoryChanged() {
    _searchController.clear();
    _applyFilterSort();
  }

  void _onSortSelected(SortOption opt) {
    setState(() => _selectedSort = opt);
    _applyFilterSort();
  }

  Widget _buildSearchSuggestions() {
    if (_searchSuggestions.isEmpty || _searchController.text.isNotEmpty)
      return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 3)],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchSuggestions.length,
        itemBuilder: (context, i) {
          final s = _searchSuggestions[i];
          return ListTile(
            title: Text(s),
            onTap: () {
              _searchController.text = s;
              _applyFilterSort();
              setState(() => _searchSuggestions = []);
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _productsBox.close();
    _debounce?.cancel();
    _pageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Earn',
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
          if (_showOfflineBanner)
            Container(
              color: Colors.red,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: const [
                  Icon(Icons.wifi_off, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You are offline. Showing cached products.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Filtros + búsqueda
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: DropdownButtonFormField<String>(
                        isDense: true,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 15,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1F7A8C),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1F7A8C),
                              width: 2,
                            ),
                          ),
                        ),
                        value: _selectedCategory,
                        items:
                            _categories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          _selectedCategory = v!;
                          _onSearchOrCategoryChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onTap: _loadSearchSuggestions,
                        decoration: InputDecoration(
                          hintText: 'Search…',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 15,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1F7A8C),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1F7A8C),
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (text) {
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce = Timer(
                            const Duration(milliseconds: 300),
                            _applyFilterSort,
                          );
                        },
                        onSubmitted: (_) => _applyFilterSort(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _applyFilterSort,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F7A8C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 17,
                        ),
                      ),
                      child: const Text(
                        'Go',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                _buildSearchSuggestions(),
              ],
            ),
          ),

          // Lista paginada
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ValueListenableBuilder<List<Product>>(
                      valueListenable: _pageNotifier,
                      builder:
                          (_, page, __) => ListView.builder(
                            controller: _scrollController,
                            itemCount: page.length + (_hasMore ? 1 : 0),
                            itemBuilder: (ctx, i) {
                              if (i == page.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final product = page[i];
                              return _buildProductCard(product);
                            },
                          ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child:
                    (product.image ?? '').startsWith('http')
                        ? CachedNetworkImage(
                          imageUrl: product.image!,
                          fit: BoxFit.contain,
                          height: 200,
                          placeholder:
                              (_, __) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          errorWidget: (_, __, ___) => const Icon(Icons.error),
                        )
                        : Image.asset(
                          product.image!,
                          fit: BoxFit.contain,
                          height: 200,
                        ),
              ),
            ),
            // Título / precio / acciones
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title ?? '',
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
                        "\$${product.price?.toStringAsFixed(1) ?? '0'} COP",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color.fromARGB(255, 183, 53, 53),
                        ),
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => SellProductDetail(
                                          productId: product.id,
                                        ),
                                  ),
                                ),
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
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.share),
                            onPressed:
                                () => Share.share(
                                  'Check out this listing: ${product.title} for \$${product.price?.toStringAsFixed(1)} COP',
                                ),
                          ),
                        ],
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
