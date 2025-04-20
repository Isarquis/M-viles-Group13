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
      appBar: AppBar(title: Text('My Profile')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      profile.imagePath.isNotEmpty
                          ? NetworkImage(profile.imagePath)
                          : null,
                  child: profile.imagePath.isEmpty ? Icon(Icons.person) : null,
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: TextStyle(
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
            SizedBox(height: 24),
            Text(
              'Posted Products',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            profile.postedProducts.isNotEmpty
                ? Row(
                  children:
                      profile.postedProducts.map((Product p) {
                        String imagePath = p.image ?? '';
                        return imagePath.isNotEmpty
                          ? ProductCard(
                              imagePath: imagePath,
                              title: p.title ?? '',
                            )
                          : Container();
                      }).toList(),
                )
                : CircularProgressIndicator(),
            SizedBox(height: 24),
            Text(
              'Last Sold',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            profile.lastSold != null
                ? ProductCard(
                    imagePath: lastSoldImage,
                    title: profile.lastSold?.title ?? '',
                  )
                : Text("No sales yet."),
            SizedBox(height: 24),
            Text(
              'Currently Rented',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            profile.rentedProducts.isNotEmpty
                ? Row(
                  children:
                      profile.rentedProducts.map((Product p) {
                        String imagePath = p.image ?? '';
                        return imagePath.isNotEmpty
                          ? ProductCard(
                              imagePath: imagePath,
                              title: p.title ?? '',
                            )
                          : Container();
                      }).toList(),
                )
                : CircularProgressIndicator(),
            SizedBox(height: 24),
            Text(
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
