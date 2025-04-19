import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String imagePath;
  final String endDate;

  const ProductCard({
    Key? key,
    required this.imagePath,
    required this.endDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network(imagePath, height: 80, fit: BoxFit.contain),
          SizedBox(height: 8),
          Text(
            'End date: $endDate',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
