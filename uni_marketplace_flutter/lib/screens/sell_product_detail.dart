import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
              owner['phone'] != ''
                  ? owner['phone']
                  : '+573243223541'; // Fallback from screenshot
          final email =
              owner['email'] != ''
                  ? owner['email']
                  : 'd.zamorac@uniandes.edu.co'; // Fallback from screenshot
          final ownerName =
              owner['name'] != 'Unknown Owner'
                  ? owner['name']
                  : 'David Zamora'; // Fallback from screenshot

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
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
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
                                ? Image.network(
                                  product['imageUrl'],
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(
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
                    // Product Title
                    Text(
                      product['name'].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Product Price
                    Text(
                      '\$${product['price']}',
                      style: const TextStyle(
                        color: Color(0xFF2B7B35),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Description Section
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
                    // Sell Button
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          FirestoreService().logFeatureUsage('button_sell');
                          _showFutureMessage();
                        },
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
                        child: const Text(
                          'Sell',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Owner Information
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
