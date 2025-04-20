import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
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
    Future.microtask(() =>
        Provider.of<NearbyProductsViewModel>(context, listen: false).loadNearbyProducts());
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<NearbyProductsViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Products close to you')),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: viewModel.currentLocation != null
                  ? LatLng(viewModel.currentLocation!.latitude, viewModel.currentLocation!.longitude)
                  : const LatLng(4.7110, -74.0721),
              zoom: 15,
            ),
            markers: viewModel.markers,
            myLocationEnabled: true,
          ),
          if (viewModel.selectedProduct != null)
            FutureBuilder(
              future: FirestoreService().getUser(viewModel.selectedProduct!.ownerId ?? ''),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(viewModel.selectedProduct!.title ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(viewModel.selectedProduct!.description ?? ''),
                        const SizedBox(height: 8),
                        Text('Vendedor: ${userData['name'] ?? ''}'),
                        Text('Email: ${userData['email'] ?? ''}'),
                        Text('Teléfono: ${userData['phone'] ?? ''}'),
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