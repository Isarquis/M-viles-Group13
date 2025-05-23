import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/product_model.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class NearbyProductsViewModel extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();

  List<Product> nearbyProducts = [];
  Product? selectedProduct;
  Position? currentLocation;
  Set<Marker> markers = {};

  Future<void> loadNearbyProducts() async {
    currentLocation = await _locationService.getCurrentLocation();
    if (currentLocation == null) return;

    List<Product> allProducts = await _firestoreService.getAllProducts();

    nearbyProducts =
        allProducts.where((product) {
          if (product.latitude == null || product.longitude == null)
            return false;
          double distance = _locationService.calculateDistance(
            currentLocation!.latitude,
            currentLocation!.longitude,
            product.latitude!,
            product.longitude!,
          );
          return distance <= 10000; // 10 km
        }).toList();

    markers.clear(); // Clear previous markers
    for (var product in nearbyProducts) {
      if (product.image != null) {
        BitmapDescriptor icon = await _getProductMarkerIcon(product.image!);
        markers.add(
          Marker(
            markerId: MarkerId(product.id),
            position: LatLng(product.latitude!, product.longitude!),
            icon: icon,
            onTap: () {
              selectProduct(product);
 
            },
          ),
        );
      }
    }

    notifyListeners();
  }

  Future<BitmapDescriptor> _getProductMarkerIcon(String imageUrl) async {
    final file = await DefaultCacheManager().getSingleFile(imageUrl);
    final Uint8List bytes = await file.readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 150,
    );
    ui.FrameInfo? frameInfo;
    try {
      frameInfo = await codec.getNextFrame();
    } catch (e) {
      print('Error obteniendo frame del icono del producto: $e');
      return BitmapDescriptor.defaultMarker;
    }
    if (frameInfo == null) return BitmapDescriptor.defaultMarker;
    final ui.Image image = frameInfo.image;
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List pngBytes = byteData!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(pngBytes);
  }

  void selectProduct(Product product) {
    selectedProduct = product;
    notifyListeners();
  }

  void clearSelectedProduct() {
    selectedProduct = null;
    notifyListeners();
  }
}
