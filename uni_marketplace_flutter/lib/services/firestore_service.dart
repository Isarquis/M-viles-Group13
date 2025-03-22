import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // USERS
  Future<void> createUser(String userId, Map<String, dynamic> data) async {
    String imageUrl = await uploadImage('users');
    data['profileImage'] = imageUrl;
    await _db.collection('users').doc(userId).set(data);
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    var doc = await _db.collection('users').doc(userId).get();
    return doc.exists ? doc.data() as Map<String, dynamic> : null;
  }

  // PRODUCTS
  Future<void> addProduct(Map<String, dynamic> data) async {
    String imageUrl = await uploadImage('products');
    data['imageUrl'] = imageUrl;
    await _db.collection('products').add(data);
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    var snapshot = await _db.collection('products').get();
    return snapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getProductsByType(String type) async {
    var snapshot =
        await _db
            .collection('products')
            .where('type', arrayContains: type)
            .get();
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  Future<void> updateProductStatus(String productId, String status) async {
    await _db.collection('products').doc(productId).update({'status': status});
  }

  // BIDS
  Future<void> placeBid(Map<String, dynamic> bidData) async {
    await _db.collection('bids').add(bidData);
  }

  Future<List<Map<String, dynamic>>> getBidsByProduct(String productId) async {
    var snapshot =
        await _db
            .collection('bids')
            .where('productId', isEqualTo: productId)
            .get();
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  // TRANSACTIONS
  Future<void> createTransaction(Map<String, dynamic> transactionData) async {
    await _db.collection('transactions').add(transactionData);
  }

  Future<List<Map<String, dynamic>>> getTransactionsByUser(
    String userId,
  ) async {
    var snapshot =
        await _db
            .collection('transactions')
            .where('buyerId', isEqualTo: userId)
            .get();
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }
  Future<Map<String, dynamic>?> getProductById(String id) async {
  var doc = await FirebaseFirestore.instance.collection('products').doc(id).get();
  return doc.exists ? doc.data() : null;
}

  Future<List<Map<String, dynamic>>> getBiddersFromBids(
    List<Map<String, dynamic>> bids,
  ) async {
    List<Map<String, dynamic>> users = [];
    for (var bid in bids) {
      var bidderId = bid['bidder'];
      if (bidderId != null) {
        var userData = await getUser(bidderId);
        if (userData != null) {
          users.add(userData);
        }
      }
    }
    return users;
  }

  Future<List<Map<String, dynamic>>> getBidsWithUsersByProduct(
    String productId,
  ) async {
    var snapshot =
        await _db
            .collection('bids')
            .where('productId', isEqualTo: productId)
            .get();
    List<Map<String, dynamic>> combined = [];
    
    for (var doc in snapshot.docs) {
      var bid = doc.data();
      var bidderId = bid['bidder'];
      if (bidderId != null) {
        var userData = await getUser(bidderId);
        if (userData != null) {
          combined.add({'bid': bid, 'user': userData});
        }
      }
    }
    combined.sort((a, b) => (b['bid']['amount'] as int).compareTo(a['bid']['amount'] as int));
    return combined;
  }

  Future<String> uploadImage(String folder) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) throw 'No image selected';

    File file = File(image.path);
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    var ref = FirebaseStorage.instance.ref().child('$folder/$fileName.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> logFeatureUsage(String feature) async {
    await _db.collection('logs').add({
      'type': 'feature_usage',
      'feature': feature,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}