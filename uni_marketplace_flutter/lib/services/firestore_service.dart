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
    String imageUrl = await uploadImage('users');
    data['profileImage'] = imageUrl;
    await _db.collection('users').doc(userId).set(data);
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      var doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
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
    await FirebaseFirestore.instance.collection('products').add(data);
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
    return snapshot.docs
        .map((doc) => Product.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<Product>> getProductsByType(String type) async {
    var snapshot =
        await _db
            .collection('products')
            .where('type', arrayContains: type)
            .get();
    return snapshot.docs
        .map((doc) => Product.fromMap(doc.data(), doc.id))
        .toList();
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
    await _db.collection('bids').doc(bidId).delete();
  }

  Future<void> deleteRentOfferById(String offerId) async {
    await _db.collection('rents').doc(offerId).delete();
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

      'createdAt': FieldValue.serverTimestamp()
    });
  }

  Future<void> logResponseTime(DateTime requestedAt, DateTime receivedAt, DateTime showedAt) async {

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

