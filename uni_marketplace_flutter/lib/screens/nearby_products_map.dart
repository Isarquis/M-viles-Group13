import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../viewmodels/nearby_products_viewmodel.dart';
import '../widgets/selected_product_preview.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../services/firestore_service.dart';
import './product_detail.dart';

class NearbyProductsMap extends StatefulWidget {
  const NearbyProductsMap({super.key});

  @override
  State<NearbyProductsMap> createState() => _NearbyProductsMapState();
}

class _NearbyProductsMapState extends State<NearbyProductsMap> with AutomaticKeepAliveClientMixin {
  GoogleMapController? _mapController;

  bool mapLoaded = false;
  bool hasConnection = true;

  @override
  bool get wantKeepAlive => true;

  void monitorConnection() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        hasConnection = result != ConnectivityResult.none;
      });
    });
  }

  void checkInitialConnection() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      hasConnection = result != ConnectivityResult.none;
    });
  }

  @override
  void initState() {
    super.initState();
    checkInitialConnection();
    monitorConnection();
    Future.microtask(() async {
      await Provider.of<NearbyProductsViewModel>(
        context,
        listen: false,
      ).loadNearbyProducts();
      if (mounted) {
        setState(() {
          mapLoaded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!hasConnection && !mapLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Products close to you')),
        body: const Center(
          child: Text(
            "🔌 To access the map and nearby products, please connect to the internet.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final viewModel = Provider.of<NearbyProductsViewModel>(context);
    if (viewModel.selectedProduct != null && _mapController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController!.getZoomLevel().then((zoom) {
          final adjustedDelta = 0.01 / pow(2, zoom - 14);
          _mapController!.animateCamera(
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
      body:
          viewModel.markers.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (controller) {
                      setState(() {
                        _mapController = controller;
                      });
                      if (viewModel.currentLocation != null) {
                        _mapController!.moveCamera(
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
                        if (!hasConnection) {
                          return Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "🌐 No internet connection.\nCan't load product details.",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
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
                                  'About the product',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            viewModel.selectedProduct!.title ??
                                                '',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            viewModel
                                                    .selectedProduct!
                                                    .description ??
                                                '',
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
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
                                const SizedBox(height: 5),

                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => ProductDetail(
                                                productId:
                                                    viewModel
                                                        .selectedProduct!
                                                        .id,
                                              ),
                                        ),
                                      );
                                    },
                                    child: const Text('View product details'),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Divider(),
                                const SizedBox(height: 2),
                                const Text(
                                  'About the seller',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        userData['name'] ?? '',
                                        style: const TextStyle(fontSize: 16),
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
