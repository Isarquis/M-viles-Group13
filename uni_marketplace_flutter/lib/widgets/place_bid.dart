import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class PlaceBidSection extends StatelessWidget {
  final Map<String, dynamic> product;
  final TextEditingController bidController;
  final String? bidError;
  final int Function() getMinimumBid;
  final int? highestBid;
  final String productId;
  final Future<void> Function() loadProduct;
  final Future<void> Function() loadBids;
  final void Function(bool) setShowPlaceBid;
  final void Function(bool) setShowBidders;
  final BuildContext context;

  const PlaceBidSection({
    required this.product,
    required this.bidController,
    required this.bidError,
    required this.getMinimumBid,
    required this.highestBid,
    required this.productId,
    required this.loadProduct,
    required this.loadBids,
    required this.setShowPlaceBid,
    required this.setShowBidders,
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
              onPressed: () => setShowPlaceBid(false),
            ),
          ],
        ),
        Text(
          'Make a Bid',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            product['imageUrl'].toString().startsWith('http')
                ? Image.network(product['imageUrl'], width: 100)
                : Image.asset(product['imageUrl'], width: 100),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'Minimum bidding price:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' ${getMinimumBid()} COP'),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Set your Price:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: bidController,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      hintText: 'ej. 35.000',
                      hintStyle: TextStyle(color: Colors.blueGrey),
                      filled: true,
                      fillColor: Color(0xFFE1E5F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (bidError != null) ...[
                    SizedBox(height: 4),
                    Text(
                      bidError!,
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            final bidValue = int.tryParse(
                    bidController.text.replaceAll('.', '')) ??
                0;
            final baseBid = highestBid ??
                int.tryParse(product['baseBid']
                        .toString()
                        .replaceAll('.', '')) ??
                0;
            if (bidValue < baseBid) {
              setShowPlaceBid(true);
            } else {
              final bidData = {
                'amount': bidValue,
                'bidder': '202113407',
                'productId': productId,
                'createdAt': Timestamp.now(),
              };
              await FirestoreService().placeBid(bidData);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Bid placed successfully')),
              );
              bidController.clear();
              await loadProduct();
              await loadBids();
              setShowPlaceBid(false);
              setShowBidders(true);
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text('Make Bid', style: TextStyle(color: Colors.white)),
          ),
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1F7A8C)),
        ),
      ],
    );
  }
}

