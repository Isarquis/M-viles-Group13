import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add Product
  Future<void> addProduct(Map<String, dynamic> data) async {
    await _db.collection('products').add(data);
  }

  // Get Products
  Future<List<Map<String, dynamic>>> getProducts() async {
    var snapshot = await _db.collection('products').get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  // Place Bid
  Future<void> placeBid(Map<String, dynamic> bidData) async {
    await _db.collection('bids').add(bidData);
  }

  // Get Bids for a Product
  Future<List<Map<String, dynamic>>> getBids(String productId) async {
    var snapshot = await _db.collection('bids').where('productId', isEqualTo: productId).get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }
}