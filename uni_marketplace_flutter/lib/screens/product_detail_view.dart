import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../viewmodels/product_detail_viewmodel.dart';


class ProductDetailView extends StatelessWidget {
  final Product product;

  const ProductDetailView({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductDetailViewModel(product.id),
      child: _ProductDetailContent(product: product),
    );
  }
}

class _ProductDetailContent extends StatelessWidget {
  final Product product;

  const _ProductDetailContent({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ProductDetailViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.title ?? 'Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SizedBox(
                height: 150,
                child: Image.network(
                  product.image ?? '',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Biddings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (viewModel.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (viewModel.bidsWithUsers.isEmpty)
              const Text("No bids yet.")
            else
              Expanded(
                child: ListView.builder(
                  itemCount: viewModel.bidsWithUsers.length,
                  itemBuilder: (context, index) {
                    final bid = viewModel.bidsWithUsers[index]['bid'];
                    final user = viewModel.bidsWithUsers[index]['user'];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: user['image'] != null ? NetworkImage(user['image']) : null,
                              radius: 30,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Price: ${bid['amount']?.toString() ?? 'N/A'} COP'),
                                  Text(user['phone']?.toString() ?? ''),
                                  Text(user['email']?.toString() ?? '', style: const TextStyle(color: Colors.blue)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      ElevatedButton(
                                      onPressed: () async {
                                        await viewModel.deleteBid(bid);
                                      },
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        child: const Text(
                                          "Decline",
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 86, 186, 58)),
                                        child: const Text(
                                          "Accept",
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
          ],
        ),
      ),
    );
  }
}