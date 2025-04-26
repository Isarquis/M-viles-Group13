import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uni_marketplace_flutter/services/firestore_service.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uni_marketplace_flutter/services/database_helper.dart';

class PostProductViewModel {
  final FirestoreService _firestoreService;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  PostProductViewModel(this._firestoreService);

  Future<bool> checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      print('PostProductViewModel: Conectividad verificada: $result');
      return result != ConnectivityResult.none;
    } catch (e) {
      print('PostProductViewModel: Error al verificar conectividad: $e');
      return false;
    }
  }

  Future<String> uploadImage(File file) async {
    print('PostProductViewModel: Comenzando compresión y subida de imagen');
    final img.Image image = img.decodeImage(await file.readAsBytes())!;
    final resized = img.copyResize(image, width: 600);
    final resizedFile = File(file.path)
      ..writeAsBytesSync(img.encodeJpg(resized));

    final compressedBytes = await FlutterImageCompress.compressWithFile(
      resizedFile.path,
      minWidth: 600,
      minHeight: 600,
      quality: 80,
    );
    if (compressedBytes == null) throw Exception('Compression failed');
    final compressedFile = File(file.path)..writeAsBytesSync(compressedBytes);

    final imageUrl = await _firestoreService.uploadImageToS3(compressedFile);
    print('PostProductViewModel: Imagen subida con éxito: $imageUrl');
    return imageUrl;
  }

  bool isEmailValid(String email) {
    final re = RegExp(r'^[\w\.\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z]{2,}$');
    return re.hasMatch(email);
  }

  Future<void> postProduct({
    required String title,
    required String description,
    required String selectedCategory,
    required double price,
    required double baseBid,
    required List<String> transactionTypes,
    required String email,
    required File imageFile,
    required double latitude,
    required double longitude,
    required String ownerId,
    required String attemptId,
  }) async {
    print(
      'PostProductViewModel: postProduct called with title: $title and attemptId: $attemptId',
    );

    if (title.isEmpty ||
        description.isEmpty ||
        selectedCategory.isEmpty ||
        price <= 0 ||
        transactionTypes.isEmpty ||
        !isEmailValid(email)) {
      print('PostProductViewModel: Datos inválidos del producto');
      throw Exception('Invalid product data');
    }

    bool isOnline = await checkConnectivity();
    if (!isOnline) {
      print(
        'PostProductViewModel: Modo offline, guardando producto localmente con attemptId: $attemptId',
      );
      try {
        String localImagePath = await _databaseHelper.saveImageLocally(
          imageFile,
        );
        await _databaseHelper.insertPendingProduct({
          'title': title,
          'description': description,
          'selectedCategory': selectedCategory,
          'price': price,
          'baseBid': baseBid,
          'transactionTypes': transactionTypes.join(','),
          'email': email,
          'imagePath': localImagePath,
          'latitude': latitude,
          'longitude': longitude,
          'ownerId': ownerId,
          'attemptId': attemptId,
        });
        await _databaseHelper.printPendingProducts();
        print('PostProductViewModel: Producto guardado localmente con éxito');
        throw Exception(
          'No internet connection, product saved for later upload',
        );
      } catch (e) {
        print('PostProductViewModel: Error al guardar producto localmente: $e');
        throw Exception('Failed to save product locally: $e');
      }
    }

    print('PostProductViewModel: Modo online, subiendo producto directamente');
    final imageUrl = await uploadImage(imageFile);

    final data = <String, dynamic>{
      'title': title,
      'description': description,
      'category': selectedCategory,
      'price': price,
      'baseBid': baseBid,
      'type': transactionTypes,
      'image': imageUrl,
      'contactEmail': email,
      'latitude': latitude,
      'longitude': longitude,
      'status': 'Available',
      'createdAt': FieldValue.serverTimestamp(),
      'ownerId': ownerId,
    };

    await _firestoreService.addProduct(data);
    print('PostProductViewModel: Producto subido a Firestore con éxito');
  }
}
