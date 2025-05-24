import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uni_marketplace_flutter/services/firestore_service.dart';
import 'package:uni_marketplace_flutter/viewmodels/sell_product_detail_viewmodel.dart';

class SellProductDetail extends StatefulWidget {
  final String productId;
  const SellProductDetail({required this.productId, Key? key})
    : super(key: key);

  @override
  _SellProductDetailState createState() => _SellProductDetailState();
}

class _SellProductDetailState extends State<SellProductDetail> {
  bool _isSelling = false;

  @override
  void initState() {
    super.initState();
    FirestoreService().logFeatureUsage('screen_sell_product_detail');
  }

  void _showFutureMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selling feature will be implemented in the future'),
      ),
    );
  }

  void _shareProduct(Map<String, dynamic> product) {
    final title = product['name'] ?? 'Product';
    final price = product['price'] != null ? '\$${product['price']} COP' : '';
    Share.share('Check out this listing: $title for $price');
  }

  void _handleSellPressed() async {
    setState(() => _isSelling = true);
    FirestoreService().logFeatureUsage('button_sell');

    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isSelling = false);
    _showFutureMessage();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SellProductDetailViewModel(widget.productId),
      child: Consumer<SellProductDetailViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.product == null || viewModel.owner == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final product = viewModel.product!;
          final owner = viewModel.owner!;
          final phoneNumber =
              owner['phone'] != '' ? owner['phone'] : '+573243223541';
          final email =
              owner['email'] != ''
                  ? owner['email']
                  : 'd.zamorac@uniandes.edu.co';
          final ownerName =
              owner['name'] != 'Unknown Owner' ? owner['name'] : 'David Zamora';

          final imageUrl = product['imageUrl'];
          if (imageUrl != null && imageUrl.toString().startsWith('http')) {
            // Precache image to improve UX
            precacheImage(CachedNetworkImageProvider(imageUrl), context);
          }

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              leading: const BackButton(color: Colors.black),
              elevation: 0,
              backgroundColor: Colors.white,
              title: const Text(
                'Detail Producto',
                style: TextStyle(color: Colors.black),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share, color: Color(0xFF1F7A8C)),
                  onPressed: () => _shareProduct(product),
                  tooltip: 'Share Listing',
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child:
                            (product['imageUrl']?.toString().startsWith(
                                      'http',
                                    ) ??
                                    false)
                                ? CachedNetworkImage(
                                  imageUrl: product['imageUrl'],
                                  fit: BoxFit.contain,
                                  placeholder:
                                      (context, url) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                  errorWidget:
                                      (context, url, error) => const Icon(
                                        Icons.broken_image,
                                        size: 150,
                                        color: Colors.grey,
                                      ),
                                )
                                : Image.asset(
                                  'assets/images/placeholder.png',
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(
                                            Icons.broken_image,
                                            size: 150,
                                            color: Colors.grey,
                                          ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      product['name'].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${product['price']}',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 201, 56, 56),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'About the book',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product['description'],
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isSelling ? null : _handleSellPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F7A8C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 12,
                          ),
                        ),
                        child:
                            _isSelling
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text(
                                  'Sell',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        radius: 24,
                        child: Image.asset(
                          'assets/images/bidder1.jpg',
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.grey,
                              ),
                        ),
                      ),
                      title: Text(
                        ownerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _showFutureMessage,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  phoneNumber,
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _showFutureMessage,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.email,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  email,
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
