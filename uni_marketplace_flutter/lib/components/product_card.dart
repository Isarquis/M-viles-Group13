import 'dart:io';

import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String imagePath;
  final String originalImageUrl;
  final String title;
  final VoidCallback? onTap;

  const ProductCard({
    Key? key,
    required this.imagePath,
    required this.originalImageUrl,
    required this.title,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
          SizedBox(
            height: 100,
            child: Builder(
              builder: (_) {
                if (imagePath.startsWith('/') && File(imagePath).existsSync()) {
                  return Image.file(File(imagePath), fit: BoxFit.contain);
                } else if (originalImageUrl.isNotEmpty) {
                  return Image.network(originalImageUrl, fit: BoxFit.contain);
                } else {
                  return Icon(Icons.image_not_supported);
                }
              },
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ));
  }
}
