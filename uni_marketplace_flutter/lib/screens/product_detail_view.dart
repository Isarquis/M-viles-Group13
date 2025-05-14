import 'dart:io';
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

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

class _ProductDetailContent extends StatefulWidget {
  final Product product;
  const _ProductDetailContent({Key? key, required this.product}) : super(key: key);

  @override
  State<_ProductDetailContent> createState() => _ProductDetailContentState();
}

class _ProductDetailContentState extends State<_ProductDetailContent> {
  bool showAllBids = false;
  bool showAllRentOffers = false;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool hasConnection = true;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      setState(() {
        hasConnection = result != ConnectivityResult.none;
      });
    });
  }

  Future<void> _checkInitialConnection() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      hasConnection = result != ConnectivityResult.none;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ProductDetailViewModel>(context);
    final vmHasConnection = viewModel.hasConnection;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.product.title ?? 'Product'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!hasConnection || !vmHasConnection)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.red,
                child: const Text(
                  'You are offline. Data may be outdated.',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: SizedBox(
                          height: 150,
                          child: widget.product.image != null && widget.product.image!.startsWith('/')
                              ? Image.file(
                                  File(widget.product.image!),
                                  fit: BoxFit.contain,
                                )
                              : Image.network(
                                  widget.product.image ?? '',
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
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: showAllBids
                              ? viewModel.bidsWithUsers.length
                              : (viewModel.bidsWithUsers.length > 2
                                  ? 2
                                  : viewModel.bidsWithUsers.length),
                          itemBuilder: (context, index) {
                            final bid = viewModel.bidsWithUsers[index]['bid'];
                            final user = viewModel.bidsWithUsers[index]['user'];
                            return _BidCard(bid: bid, user: user, viewModel: viewModel);
                          },
                        ),
                      if (viewModel.bidsWithUsers.length > 2)
                        TextButton(
                          onPressed: () => setState(() => showAllBids = !showAllBids),
                          child: Text(showAllBids ? 'Show less' : 'Show all'),
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'Rent offers',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (viewModel.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (viewModel.rentOffersWithUsers.isEmpty)
                        const Text("No rent offers yet.")
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: showAllRentOffers
                              ? viewModel.rentOffersWithUsers.length
                              : (viewModel.rentOffersWithUsers.length > 2
                                  ? 2
                                  : viewModel.rentOffersWithUsers.length),
                          itemBuilder: (context, index) {
                            final offer = viewModel.rentOffersWithUsers[index]['offer'];
                            final user = viewModel.rentOffersWithUsers[index]['user'];
                            return _RentCard(offer: offer, user: user);
                          },
                        ),
                      if (viewModel.rentOffersWithUsers.length > 2)
                        TextButton(
                          onPressed: () => setState(() => showAllRentOffers = !showAllRentOffers),
                          child: Text(showAllRentOffers ? 'Show less' : 'Show all'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BidCard extends StatelessWidget {
  final Map<String, dynamic> bid;
  final Map<String, dynamic> user;
  final ProductDetailViewModel viewModel;

  const _BidCard({required this.bid, required this.user, required this.viewModel, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                        onPressed: () async => await viewModel.deleteBid(bid),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Decline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 86, 186, 58)),
                        child: const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
  }
}

class _RentCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  final Map<String, dynamic> user;

  const _RentCard({required this.offer, required this.user, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  Text('Amount: ${offer['amount']?.toString() ?? 'N/A'} COP'),
                  Text('Days: ${offer['days']?.toString() ?? ''}'),
                  Text(user['phone']?.toString() ?? ''),
                  Text(user['email']?.toString() ?? '', style: const TextStyle(color: Colors.blue)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final viewModel = Provider.of<ProductDetailViewModel>(context, listen: false);
                          await viewModel.deleteRentOffer(offer);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Decline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 86, 186, 58)),
                        child: const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
  }
}