

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class PlaceRentOfferSection extends StatelessWidget {
  final Map<String, dynamic> product;
  final TextEditingController daysController;
  final TextEditingController priceController;
  final String productId;
  final Future<void> Function() loadProduct;
  final Future<void> Function() loadOffers;
  final void Function(bool) setShowRentOffer;
  final BuildContext context;

  const PlaceRentOfferSection({
    required this.product,
    required this.daysController,
    required this.priceController,
    required this.productId,
    required this.loadProduct,
    required this.loadOffers,
    required this.setShowRentOffer,
    required this.context,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => setShowRentOffer(false),
            ),
          ],
        ),
        const Text(
          'Make a Rent Offer',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            product['imageUrl'].toString().startsWith('http')
                ? Image.network(product['imageUrl'], width: 100)
                : Image.asset(product['imageUrl'], width: 100),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Number of days:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: daysController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: 'ej. 5',
                      hintStyle: const TextStyle(color: Colors.blueGrey),
                      filled: true,
                      fillColor: const Color(0xFFE1E5F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Price (COP):',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: 'ej. 35.000',
                      hintStyle: const TextStyle(color: Colors.blueGrey),
                      filled: true,
                      fillColor: const Color(0xFFE1E5F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            final days = int.tryParse(daysController.text) ?? 0;
            final price = int.tryParse(priceController.text.replaceAll('.', '')) ?? 0;

            if (days > 0 && price > 0) {
              final rentData = {
                'days': days,
                'price': price,
                'renter': '202113407',
                'productId': productId,
                'createdAt': Timestamp.now(),
              };
              await FirestoreService().placeRentOffer(rentData);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rent offer placed successfully')),
              );
              daysController.clear();
              priceController.clear();
              await loadProduct();
              await loadOffers();
              setShowRentOffer(false);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Días y precio deben ser mayores a 0')),
              );
            }
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text('Make Rent Offer', style: TextStyle(color: Colors.white)),
          ),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F7A8C)),
        ),
      ],
    );
  }
}