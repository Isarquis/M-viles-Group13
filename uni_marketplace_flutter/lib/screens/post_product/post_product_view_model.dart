import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart'; // Paquete de conectividad
import 'package:uni_marketplace_flutter/services/firestore_service.dart';
import 'package:image/image.dart'
    as img; // Importación de la librería 'image' para manipular imágenes
import 'package:flutter_image_compress/flutter_image_compress.dart'; // Importación para comprimir imágenes

class PostProductViewModel {
  final FirestoreService _firestoreService;

  PostProductViewModel(this._firestoreService);

  // Verificación de la conexión a internet
  Future<bool> checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  // Subir imagen después de redimensionar y comprimir
  Future<String> uploadImage(File imageFile) async {
    try {
      bool isConnected = await checkConnectivity();
      if (!isConnected) {
        throw Exception('No internet connection');
      }

      File resizedImage = await _resizeImage(imageFile);
      File compressedImage = await _compressImage(resizedImage);

      return await _firestoreService.uploadImageToS3(compressedImage);
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  // Redimensionar la imagen
  Future<File> _resizeImage(File file) async {
    try {
      final img.Image image = img.decodeImage(await file.readAsBytes())!;
      img.Image resized = img.copyResize(image, width: 600);
      final newFile = File(file.path)..writeAsBytesSync(img.encodeJpg(resized));
      return newFile;
    } catch (e) {
      throw Exception('Error resizing image: $e');
    }
  }

  // Comprimir la imagen
  Future<File> _compressImage(File file) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 600,
        minHeight: 600,
        quality: 80,
        rotate: 0,
      );

      if (result == null) {
        throw Exception('Image compression failed');
      }

      final compressedFile = File(file.path)..writeAsBytesSync(result);
      return compressedFile;
    } catch (e) {
      throw Exception('Error compressing image: $e');
    }
  }

  bool isEmailValid(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');
    return regex.hasMatch(email);
  }

  // Método para publicar el producto
  Future<void> postProduct({
    required String title,
    required String description,
    required String selectedCategory,
    required double price,
    required List<String> transactionTypes,
    required String email,
    required File imageFile,
  }) async {
    try {
      // Validar los datos antes de proceder
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

      // Subir la imagen a S3 o al servicio que uses
      String imageUrl = await uploadImage(imageFile);

      // Crear un mapa con los datos del producto para Firestore
      Map<String, dynamic> data = {
        'title': title,
        'description': description,
        'category': selectedCategory, // Guardamos la categoría seleccionada
        'price': price,
        'type':
            transactionTypes.isNotEmpty
                ? transactionTypes[0]
                : '', // Usamos el primer tipo de transacción
        'image': imageUrl, // URL de la imagen subida
        'contactEmail': email,
        'status': 'Available', // El estado predeterminado del producto
      };

      // Llamada al servicio de Firestore para agregar el producto
      await _firestoreService.addProduct(data);
      print('Producto publicado correctamente');
    } catch (e) {
      print('Error al publicar el producto: $e');
      throw Exception('Error posting product: $e');
    }
  }

  // Función para validar los datos antes de publicarlos
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
        isEmailValid(email); // Verifica si el correo es válido
  }
}
