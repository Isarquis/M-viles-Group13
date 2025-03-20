import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // USERS
  Future<void> createUser(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).set(data);
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    var doc = await _db.collection('users').doc(userId).get();
    return doc.exists ? doc.data() as Map<String, dynamic> : null;
  }

  // PRODUCTS
  Future<void> addProduct(Map<String, dynamic> data) async {
    await _db.collection('products').add(data);
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    var snapshot = await _db.collection('products').get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> getProductsByType(String type) async {
    var snapshot = await _db.collection('products').where('type', arrayContains: type).get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<void> updateProductStatus(String productId, String status) async {
    await _db.collection('products').doc(productId).update({'status': status});
  }

  // BIDS
  Future<void> placeBid(Map<String, dynamic> bidData) async {
    await _db.collection('bids').add(bidData);
  }

  Future<List<Map<String, dynamic>>> getBidsByProduct(String productId) async {
    var snapshot = await _db.collection('bids').where('productId', isEqualTo: productId).get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  // TRANSACTIONS
  Future<void> createTransaction(Map<String, dynamic> transactionData) async {
    await _db.collection('transactions').add(transactionData);
  }

  Future<List<Map<String, dynamic>>> getTransactionsByUser(String userId) async {
    var snapshot = await _db
        .collection('transactions')
        .where('buyerId', isEqualTo: userId)
        .get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }
}