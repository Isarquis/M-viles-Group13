import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirestoreService() {
    _db.settings = const Settings(
      persistenceEnabled: true, //  Offline caching
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // USERS
  Future<void> createUser(String userId, Map<String, dynamic> data) async {
    String imageUrl = await uploadImage('users');
    data['profileImage'] = imageUrl;
    await _db.collection('users').doc(userId).set(data);
  }

  Future<void> registerUserWithGender(
    String userId,
    Map<String, dynamic> data,
    String gender,
  ) async {
    try {
      String imageUrl;

      if (gender.toLowerCase() == 'hombre') {
        imageUrl =
            'https://unimarketimagesbucket.s3.us-west-1.amazonaws.com/bidder2.jpg';
      } else {
        imageUrl =
            'https://unimarketimagesbucket.s3.us-west-1.amazonaws.com/bidder1.jpg';
      }

      final userData = {
        'email': data['email'] ?? '',
        'name': data['name'] ?? '',
        'phone': data['phone'] ?? '',
        'image': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _db.collection('users').doc(userId).set(userData);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logPurchase(String productId, int price, String category) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    await _db.collection('buy-logs').add({
      'type': 'purchase',
      'productId': productId,
      'price': price,
      'category': category,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      var doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        return data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // PRODUCTS

  Future<void> addProduct(Map<String, dynamic> data) async {
    try {
      await _db.collection('products').add(data);
    } catch (e) {
      throw Exception('Error adding product: $e');
    }
  }

  Future<String> uploadImageToS3(File imageFile) async {
    try {
      // Generar un nombre único para el archivo
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      // URL del bucket S3
      final uri = Uri.parse(
        'https://unimarketimagesbucket.s3.amazonaws.com/$fileName',
      );

      // Realizar la solicitud PUT para subir la imagen
      final request =
          http.Request('PUT', uri)
            ..headers['Content-Type'] = 'image/jpeg'
            ..bodyBytes =
                imageFile.readAsBytesSync(); // Asignar la lista de bytes

      final response = await request.send();

      // Verificar el código de estado de la respuesta
      if (response.statusCode == 200) {
        return uri.toString(); // Devuelve la URL de la imagen cargada
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      rethrow; // Volver a lanzar el error si ocurre un problema
    }
  }

  Future<List<Product>> getAllProducts() async {
    var snapshot = await _db.collection('products').get();
    return snapshot.docs.map((doc) {
      return Product.fromMap(doc.data(), doc.id);
    }).toList();
  }

  Future<List<Product>> getProductsByType(String type) async {
    var snapshot =
        await _db
            .collection('products')
            .where('type', arrayContains: type)
            .get();
    return snapshot.docs.map((doc) {
      return Product.fromMap(doc.data(), doc.id);
    }).toList();
  }

  Future<void> updateProductStatus(String productId, String status) async {
    await _db.collection('products').doc(productId).update({'status': status});
  }

  // BIDS
  Future<void> placeBid(Map<String, dynamic> bidData) async {
    print('Placing bidd: $bidData');
    try {
      var docRef = await _db.collection('bids').add(bidData);
      print('Bid placed with ID: ${docRef.id}');
    } catch (e) {
      print('Error placing bid: $e');
      rethrow;
    }
  }

  Future<void> deleteBidById(String bidId) async {
    try {
      await _db.collection('bids').doc(bidId).delete();
    } catch (e) {
      throw Exception('Error deleting bid: $e');
    }
  }

  Future<void> deleteRentOfferById(String offerId) async {
    try {
      await _db.collection('rents').doc(offerId).delete();
    } catch (e) {
      throw Exception('Error deleting rent offer: $e');
    }
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

  Future<void> createSaleTransaction({
    required String buyerId,
    required String sellerId,
    required String productId,
    required int price,
  }) async {
    final docRef = FirebaseFirestore.instance
        .collection('products')
        .doc(productId);
    final productSnapshot = await docRef.get();

    if (!productSnapshot.exists) {
      throw Exception('Producto no encontrado');
    }

    final productData = productSnapshot.data();
    if (productData?['status'] == 'Sold') {
      throw Exception('Este producto ya fue vendido');
    }

    // Marcar producto como vendido
    await docRef.update({'status': 'Sold'});

    // Crear transacción
    await FirebaseFirestore.instance.collection('transactions').add({
      'buyerId': buyerId,
      'sellerId': sellerId,
      'productId': productId,
      'price': price,
      'type': 'Sale',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getSaleTransactionsByUser(
    String userId,
  ) async {
    var snapshot =
        await _db
            .collection('transactions')
            .where('buyerId', isEqualTo: userId)
            .where('type', isEqualTo: 'Sale')
            .get();

    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getSaleTransactionsBySeller(String sellerId) async {
    var snapshot = await _db
        .collection('transactions')
        .where('sellerId', isEqualTo: sellerId)
        .where('type', isEqualTo: 'Sale')
        .get();

    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getEnrichedSaleTransactionsByUser(
    String userId,
  ) async {
    var snapshot =
        await _db
            .collection('transactions')
            .where('buyerId', isEqualTo: userId)
            .where('type', isEqualTo: 'Sale')
            .get();

    print('Snapshot de transacciones encontradas: ${snapshot.docs.length}');
    for (var doc in snapshot.docs) {
      print('Transacción encontrada: ${doc.data()}');
    }

    List<Map<String, dynamic>> enrichedTransactions = [];

    for (var doc in snapshot.docs) {
      var transactionData = doc.data() as Map<String, dynamic>;
      String? productId = transactionData['productId'];
      if (productId != null) {
        var productDoc = await _db.collection('products').doc(productId).get();
        if (productDoc.exists) {
          var productData = productDoc.data() as Map<String, dynamic>;
          transactionData['productTitle'] = productData['title'] ?? '';
          transactionData['productImage'] = productData['image'] ?? '';
        }
      }
      enrichedTransactions.add(transactionData);
    }

    return enrichedTransactions;
  }

  Future<Product?> getProductById(String id) async {
    var doc = await _db.collection('products').doc(id).get();
    return doc.exists ? Product.fromMap(doc.data()!, doc.id) : null;
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
      bid['id'] = doc.id;
      var bidderId = bid['bidder'];
      if (bidderId != null) {
        var userData = await getUser(bidderId);
        if (userData != null) {
          combined.add({'bid': bid, 'user': userData});
        }
      }
    }

    combined.sort(
      (a, b) =>
          (b['bid']['amount'] as int).compareTo(a['bid']['amount'] as int),
    );

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

  Future<void> logFeatureUsage(String feature, {DateTime? startedAt}) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    await _db.collection('logs').add({
      'type': 'feature_usage',
      'feature': feature,
      'userId': userId,
      if (startedAt != null) 'startedAt': startedAt.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> logResponseTime(
    DateTime requestedAt,
    DateTime receivedAt,
    DateTime showedAt,
  ) async {
    await _db.collection('logs').add({
      'type': 'response_time',
      'requested_at': requestedAt.millisecondsSinceEpoch,
      'received_at': receivedAt.millisecondsSinceEpoch,
      'showed_at': showedAt.millisecondsSinceEpoch,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> placeRentOffer(Map<String, dynamic> rentData) async {
    await _db.collection('rents').add(rentData);
  }

  Future<List<Map<String, dynamic>>> getRentOffersWithUsersByProduct(
    String productId,
  ) async {
    var snapshot =
        await _db
            .collection('rents')
            .where('productId', isEqualTo: productId)
            .get();

    List<Map<String, dynamic>> combined = [];

    for (var doc in snapshot.docs) {
      var rent = doc.data();
      rent['id'] = doc.id;
      var renterId = rent['renter'];
      if (renterId != null) {
        var userData = await getUser(renterId);
        if (userData != null) {
          combined.add({'rent': rent, 'user': userData});
        }
      }
    }

    combined.sort(
      (a, b) =>
          (b['rent']['price'] as int).compareTo(a['rent']['price'] as int),
    );

    return combined;
  }
}

Future<List<Product>> getProductsMatchingTerms(List<String> terms) async {
  print(
    'FirestoreService: Buscando productos que coincidan con los términos: $terms',
  );
  Set<Product> results = {};

  for (final term in terms) {
    final query =
        await FirebaseFirestore.instance
            .collection('products')
            .where('title', isGreaterThanOrEqualTo: term)
            .where('title', isLessThanOrEqualTo: term + '\uf8ff')
            .get();

    results.addAll(query.docs.map((doc) => Product.fromFirestore(doc)));
  }

  return results.toList();
}
