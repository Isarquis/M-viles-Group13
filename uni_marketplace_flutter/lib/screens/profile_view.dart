import 'dart:io';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../components/product_card.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../models/product_model.dart';
import 'product_detail_view.dart';

class ProfileView extends StatefulWidget {
  final VoidCallback onDiscoverTapped;
  final String userId;

  ProfileView({required this.onDiscoverTapped, required this.userId, super.key}) {
    print('Creating ProfileView with userId: $userId');
  }

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late ProfileViewModel profile;
  bool _isLoading = true;
  bool hasConnection = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      bool previousConnection = hasConnection;
      setState(() {
        hasConnection = result != ConnectivityResult.none;
      });
      if (!previousConnection && hasConnection) {
        loadUserData();
      }
    });
  }

  Future<void> checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      hasConnection = connectivityResult != ConnectivityResult.none;
    });
  }

  void loadUserData() async {
    await checkConnectivity();
    print('Loading user data for userId: ${widget.userId}');
    profile = ProfileViewModel(widget.userId);
    await profile.loadUserData(offlineMode: !hasConnection);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String lastSoldImage = profile.lastSold?.image ?? '';
    String lastSoldOriginalImageUrl = profile.lastSold?.originalImageUrl ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!hasConnection)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.red,
                child: const Text(
                  'You are offline. Data may be outdated.',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: profile.imagePath.isNotEmpty
                      ? (profile.imagePath.startsWith('/') ? FileImage(File(profile.imagePath)) : NetworkImage(profile.imagePath)) as ImageProvider
                      : null,
                  child: profile.imagePath.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(profile.email),
                    Text(profile.phone),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Posted Products',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            profile.postedProducts.isNotEmpty
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: profile.postedProducts.map((Product p) {
                        String imagePath = p.image ?? '';
                        String originalImageUrl = p.originalImageUrl ?? '';
                        return imagePath.isNotEmpty
                            ? SizedBox(
                                height: 158,
                                child: ProductCard(
                                  imagePath: imagePath,
                                  originalImageUrl: originalImageUrl,
                                  title: p.title ?? '',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ProductDetailView(product: p),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : const SizedBox.shrink();
                      }).toList(),
                    ),
                  )
                : const Text("You haven't posted anything yet."),
            const SizedBox(height: 24),
            const Text(
              'Last Sold',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            profile.lastSold != null
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SizedBox(
                          height: 158,
                          child: ProductCard(
                            imagePath: lastSoldImage,
                            originalImageUrl: lastSoldOriginalImageUrl,
                            title: profile.lastSold?.title ?? '',
                          ),
                        ),
                      ],
                    ),
                  )
                : const Text("No sales yet."),
            const SizedBox(height: 24),
            const Text(
              'Currently Rented',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            profile.rentedProducts.isNotEmpty
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: profile.rentedProducts.map((Product p) {
                        String imagePath = p.image ?? '';
                        String originalImageUrl = p.originalImageUrl ?? '';
                        return imagePath.isNotEmpty
                            ? SizedBox(
                                height: 158,
                                child: ProductCard(
                                  imagePath: imagePath,
                                  originalImageUrl: originalImageUrl,
                                  title: p.title ?? '',
                                ),
                              )
                            : const SizedBox.shrink();
                      }).toList(),
                    ),
                  )
                : const Text("No rentals yet."),
            const SizedBox(height: 24),
            const Text(
              'Last Bought',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            profile.boughtProducts.isEmpty
                ? GestureDetector(
                    onTap: widget.onDiscoverTapped,
                    child: Text(
                      "You have not bought anything yet. Discover products",
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: profile.boughtProducts.map((Product p) {
                        String imagePath = p.image ?? '';
                        String originalImageUrl = p.originalImageUrl ?? '';
                        String title = p.title ?? '';
                        return imagePath.isNotEmpty
                            ? SizedBox(
                                height: 158,
                                child: ProductCard(
                                  imagePath: imagePath,
                                  originalImageUrl: originalImageUrl,
                                  title: title,
                                ),
                              )
                            : const SizedBox.shrink();
                      }).toList(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
