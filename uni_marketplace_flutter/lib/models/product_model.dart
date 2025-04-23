import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String? title;
  final String? description;
  final String? image;
  final String? category;
  final String? ownerId;
  final String? status;
  final double? price;
  final double? baseBid;
  final double? latitude;
  final double? longitude;
  final List<String>? type;
  final DateTime? createdAt;

  Product({
    required this.id,
    this.title,
    this.description,
    this.image,
    this.category,
    this.ownerId,
    this.status,
    this.price,
    this.baseBid,
    this.latitude,
    this.longitude,
    this.type,
    this.createdAt,
  });

  factory Product.fromMap(Map<String, dynamic> data, String documentId) {
    return Product(
      id: documentId,
      title: data['title'],
      description: data['description'],
      image: data['image'],
      category: data['category'],
      ownerId: data['ownerId']?.toString(),
      status: data['status'],
      price: (data['price'] != null) ? (data['price'] as num).toDouble() : null,
      baseBid: (data['baseBid'] != null) ? (data['baseBid'] as num).toDouble() : null,
      latitude: (data['latitude'] != null) ? (data['latitude'] as num).toDouble() : null,
      longitude: (data['longitude'] != null) ? (data['longitude'] as num).toDouble() : null,
      type: (data['type'] != null) ? List<String>.from(data['type']) : null,
      createdAt: data['createdAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'image': image,
      'category': category,
      'ownerId': ownerId,
      'status': status,
      'price': price,
      'baseBid': baseBid,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'createdAt': createdAt,
    };
  }
    factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product.fromMap(data, doc.id);
  }
}
