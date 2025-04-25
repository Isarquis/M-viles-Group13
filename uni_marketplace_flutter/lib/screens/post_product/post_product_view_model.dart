import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uni_marketplace_flutter/services/firestore_service.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Para obtener el ownerId

class PostProductViewModel {
  final FirestoreService _firestoreService;

  PostProductViewModel(this._firestoreService);

  Future<bool> checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  Future<String> uploadImage(File imageFile) async {
    try {
      bool isConnected = await checkConnectivity();
      if (!isConnected) throw Exception('No internet connection');

      File resizedImage = await _resizeImage(imageFile);
      File compressedImage = await _compressImage(resizedImage);

      return await _firestoreService.uploadImageToS3(compressedImage);
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  Future<File> _resizeImage(File file) async {
    try {
      final img.Image image = img.decodeImage(await file.readAsBytes())!;
      img.Image resized = img.copyResize(image, width: 600);
      return File(file.path)..writeAsBytesSync(img.encodeJpg(resized));
    } catch (e) {
      throw Exception('Error resizing image: $e');
    }
  }

  Future<File> _compressImage(File file) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 600,
        minHeight: 600,
        quality: 80,
        rotate: 0,
      );

      if (result == null) throw Exception('Image compression failed');
      return File(file.path)..writeAsBytesSync(result);
    } catch (e) {
      throw Exception('Error compressing image: $e');
    }
  }

  bool isEmailValid(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');
    return regex.hasMatch(email);
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
    required String createdAt,
    required String ownerId,
  }) async {
    try {
      if (!_isValidData(
        title,
        description,
        selectedCategory,
        price,
        transactionTypes,
        email,
      )) {
        throw Exception('Invalid product data');
      }

      if (!isEmailValid(email)) {
        throw Exception('Invalid email format');
      }

      String imageUrl = await uploadImage(imageFile);

      // Obtener el ID del dueño (usuario autenticado)
      User? user = FirebaseAuth.instance.currentUser;
      String ownerId = user?.uid ?? "default_owner_id";

      // Obtener la fecha de creación
      DateTime createdAt = DateTime.now();

      // Convertir la fecha a formato string, si es necesario
      String formattedDate =
          "${createdAt.day}/${createdAt.month}/${createdAt.year}, ${createdAt.hour}:${createdAt.minute}:${createdAt.second}";

      Map<String, dynamic> data = {
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
        'createdAt': formattedDate, // Fecha de creación
        'ownerId': ownerId, // ID del dueño
      };

      await _firestoreService.addProduct(data);
    } catch (e) {
      print('Error al publicar el producto: $e');
      throw Exception('Error posting product: $e');
    }
  }

  bool _isValidData(
    String title,
    String description,
    String selectedCategory,
    double price,
    List<String> transactionTypes,
    String email,
  ) {
    return title.isNotEmpty &&
        description.isNotEmpty &&
        selectedCategory.isNotEmpty &&
        price > 0 &&
        transactionTypes.isNotEmpty &&
        isEmailValid(email);
  }
}
