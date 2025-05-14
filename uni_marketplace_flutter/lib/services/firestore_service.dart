import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

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
    try {
      String imageUrl = '';

      // Si existe imagen, se sube
      if (data.containsKey('imageFile') && data['imageFile'] is File) {
        imageUrl = await uploadImageToS3(data['imageFile']);
      } else {
        // Asignar imagen predeterminada
        imageUrl =
            'https://unimarketimagesbucket.s3.us-west-1.amazonaws.com/default-user.jpg';
      }

      data['profileImage'] = imageUrl;

      await _db.collection('users').doc(userId).set(data);
      print('Usuario creado con imagen: $imageUrl');
    } catch (e) {
      print('Error en createUser: $e');
      rethrow;
    }
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

  Future<void> registerUserWithGender(
    String userId,
    Map<String, dynamic> data,
    String gender, {
    File? profileImageFile, // <-- Nuevo parámetro opcional
  }) async {
    try {
      print('Registrando usuario con género: $gender');

      String imageUrl = '';

      // Si el usuario ha subido una imagen, se sube a S3
      if (profileImageFile != null) {
        imageUrl = await uploadImageToS3(profileImageFile);
        print('Imagen personalizada subida a S3: $imageUrl');
      } else {
        // Asignar imagen predeterminada según género
        imageUrl =
            gender.toLowerCase() == 'male'
                ? 'https://unimarketimagesbucket.s3.us-west-1.amazonaws.com/bidder2.jpg'
                : 'https://unimarketimagesbucket.s3.us-west-1.amazonaws.com/bidder1.jpg';

        print('Imagen predeterminada asignada: $imageUrl');
      }

      final userData = {
        'email': data['email'] ?? '',
        'name': data['name'] ?? '',
        'phone': data['phone'] ?? '',
        'image': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _db.collection('users').doc(userId).set(userData);
      print('Usuario registrado: $userData');
    } catch (e) {
      print('Error en registerUserWithGender: $e');
      rethrow;
    }
  }

  Future<String> uploadImageToS3(File imageFile) async {
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      final uri = Uri.parse(
        'https://unimarketimagesbucket.s3.us-west-1.amazonaws.com/$fileName',
      );

      final request =
          http.Request('PUT', uri)
            ..headers['Content-Type'] = 'image/jpeg'
            ..bodyBytes = imageFile.readAsBytesSync();

      final response = await request.send();

      if (response.statusCode == 200) {
        print('Imagen subida a S3: $uri');
        return uri.toString();
      } else {
        throw Exception('Error subiendo imagen: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en uploadImageToS3: $e');
      rethrow;
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
    await _db.collection('transactions').add({
      'buyerId': buyerId,
      'sellerId': sellerId,
      'productId': productId,
      'price': price,
      'type': 'Sale',
      'createdAt': FieldValue.serverTimestamp(),
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

  Future<List<Map<String, dynamic>>> getEnrichedSaleTransactionsByUser(
    String userId,
  ) async {
    var snapshot =
        await _db
            .collection('transactions')
            .where('buyerId', isEqualTo: userId)
            .where('type', isEqualTo: 'Sale')
            .get();

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

  Future<void> logFeatureUsage(String feature) async {
    await _db.collection('logs').add({
      'type': 'feature_usage',
      'feature': feature,

      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logPostStep({
    required String step,
    required String userId,
    required String attemptId,
  }) async {
    try {
      await _db.collection('logs').add({
        'type': 'post_step',
        'step': step,
        'user_id': userId,
        'attempt_id': attemptId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Log de paso guardado: $step');
    } catch (e) {
      print('Error al guardar log de paso: $e');
    }
  }

  Future<void> logProductPosting({
    required String category,
    required List<String> transactionTypes,
    required String userId,
  }) async {
    final timestamp = FieldValue.serverTimestamp();
    for (final type in transactionTypes) {
      await _db.collection('logs').add({
        'type': 'posting_log',
        'category': category,
        'transactionType': type,
        'userId': userId,
        'timestamp': timestamp,
      });
    }
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
