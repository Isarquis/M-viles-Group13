import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uni_marketplace_flutter/services/database_helper.dart';
import 'package:uni_marketplace_flutter/services/firestore_service.dart';
import 'dart:io';
import 'package:synchronized/synchronized.dart';

class OfflineSyncService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final FirestoreService _firestoreService;
  final Set<String> _processedAttemptIds = {};
  final _lock = Lock(); // Candado para evitar sincronizaciones concurrentes
  bool _isSyncing = false; // Flag para rastrear si ya está sincronizando

  OfflineSyncService(this._firestoreService) {
    _startListening();
  }

  void _startListening() {
    Connectivity().onConnectivityChanged.listen((
      ConnectivityResult result,
    ) async {
      if (result != ConnectivityResult.none && !_isSyncing) {
        await _syncPendingProducts();
      } else if (_isSyncing) {}
    });
  }

  Future<void> _syncPendingProducts() async {
    await _lock.synchronized(() async {
      if (_isSyncing) {
        print('OfflineSyncService: Sincronización ya en curso, omitiendo');
        return;
      }
      _isSyncing = true;

      try {
        final pendingProducts = await _databaseHelper.getPendingProducts();
        print(
          'OfflineSyncService: Encontrados ${pendingProducts.length} productos pendientes',
        );

        for (var product in pendingProducts) {
          final attemptId = product['attemptId'] as String?;
          if (attemptId == null) {
            print(
              'OfflineSyncService: Producto sin attemptId, omitiendo: ${product['id']}',
            );
            await _databaseHelper.deletePendingProduct(product['id']);
            continue;
          }

          if (_processedAttemptIds.contains(attemptId)) {
            print(
              'OfflineSyncService: Producto con attemptId $attemptId ya procesado, eliminando',
            );
            await _databaseHelper.deletePendingProduct(product['id']);
            continue;
          }

          print(
            'OfflineSyncService: Procesando producto con attemptId: $attemptId',
          );
          try {
            File imageFile = File(product['imagePath']);
            final imageUrl = await _firestoreService.uploadImageToS3(imageFile);

            final data = <String, dynamic>{
              'title': product['title'],
              'description': product['description'],
              'category': product['selectedCategory'],
              'price': product['price'],
              'baseBid': product['baseBid'],
              'type': (product['transactionTypes'] as String).split(','),
              'image': imageUrl,
              'contactEmail': product['email'],
              'latitude': product['latitude'],
              'longitude': product['longitude'],
              'status': 'Available',
              'createdAt': FieldValue.serverTimestamp(),
              'ownerId': product['ownerId'],
            };

            await _firestoreService.addProduct(data);
            print(
              'OfflineSyncService: Producto subido con éxito, attemptId: $attemptId',
            );

            _processedAttemptIds.add(attemptId);
            await _databaseHelper.deletePendingProduct(product['id']);
            print(
              'OfflineSyncService: Producto eliminado de pending_products, id: ${product['id']}',
            );
          } catch (e) {
            print(
              'OfflineSyncService: Error al sincronizar producto ${product['id']}: $e',
            );
          }
        }
      } finally {
        _isSyncing = false;
        _processedAttemptIds.clear();
        print('OfflineSyncService: Sincronización completada');
      }
    });
  }
}
