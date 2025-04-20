import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../viewmodels/nearby_products_viewmodel.dart';
import '../widgets/selected_product_preview.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../services/firestore_service.dart';

class NearbyProductsMap extends StatefulWidget {
  const NearbyProductsMap({super.key});

  @override
  State<NearbyProductsMap> createState() => _NearbyProductsMapState();
}

class _NearbyProductsMapState extends State<NearbyProductsMap> {
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          Provider.of<NearbyProductsViewModel>(
            context,
            listen: false,
          ).loadNearbyProducts(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<NearbyProductsViewModel>(context);
    if (viewModel.selectedProduct != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.getZoomLevel().then((zoom) {
          final adjustedDelta = 0.01 / pow(2, zoom - 14);
          _mapController.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(
                viewModel.selectedProduct!.latitude! - adjustedDelta,
                viewModel.selectedProduct!.longitude!,
              ),
            ),
          );
        });
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Products close to you')),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              if (viewModel.currentLocation != null) {
                _mapController.moveCamera(
                  CameraUpdate.newLatLng(
                    LatLng(
                      viewModel.currentLocation!.latitude - 0.008,
                      viewModel.currentLocation!.longitude,
                    ),
                  ),
                );
              }
            },
            initialCameraPosition: CameraPosition(
              target:
                  viewModel.currentLocation != null
                      ? LatLng(
                        viewModel.currentLocation!.latitude,
                        viewModel.currentLocation!.longitude,
                      )
                      : const LatLng(4.7110, -74.0721),
              zoom: 15,
            ),
            markers: viewModel.markers,
            myLocationEnabled: true,
          ),
          if (viewModel.selectedProduct != null)
            FutureBuilder(
              future: FirestoreService().getUser(
                viewModel.selectedProduct!.ownerId ?? '',
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: CircularProgressIndicator(),
                  );
                }

                final userData = snapshot.data! as Map<String, dynamic>;
                return Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sobre el producto',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    viewModel.selectedProduct!.title ?? '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    viewModel.selectedProduct!.description ?? '',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                viewModel.selectedProduct!.image ?? '',
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          'Sobre el vendedor',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                userData['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                userData['image'] ?? '',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
