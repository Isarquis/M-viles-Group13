import 'package:flutter/material.dart';
import '../components/product_card.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../models/product_model.dart';

class ProfileView extends StatefulWidget {
  final VoidCallback onDiscoverTapped;

  ProfileView({required this.onDiscoverTapped});

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late ProfileViewModel profile;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() async {
    profile = ProfileViewModel('202113407');
    await profile.loadUserData();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    String lastSoldImage = profile.lastSold?.image ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: profile.imagePath.isNotEmpty
                      ? NetworkImage(profile.imagePath)
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
                        return imagePath.isNotEmpty
                            ? SizedBox(
                                height: 158,
                                child: ProductCard(
                                  imagePath: imagePath,
                                  title: p.title ?? '',
                                ),
                              )
                            : const SizedBox.shrink();
                      }).toList(),
                    ),
                  )
                : const CircularProgressIndicator(),
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
                        return imagePath.isNotEmpty
                            ? SizedBox(
                                height: 158,
                                child: ProductCard(
                                  imagePath: imagePath,
                                  title: p.title ?? '',
                                ),
                              )
                            : const SizedBox.shrink();
                      }).toList(),
                    ),
                  )
                : const CircularProgressIndicator(),
            const SizedBox(height: 24),
            const Text(
              'Last Bought',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: widget.onDiscoverTapped,
              child: Text(
                "You have not bought anything yet. Discover products",
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
