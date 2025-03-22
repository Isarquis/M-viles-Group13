import 'package:flutter/material.dart';
import 'screens/product_detail.dart';
import 'screens/product_list.dart';
import 'screens/test_products_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/custom_navbar.dart';
import '../services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uni Marketplace',
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();

  final List<Widget> screens = [
    Center(child: Text('Home')), 
    ProductList(),
    ProductDetail(productId: '60J3pS3bRnFjrksPd8hL'),
    TestProductsScreen(),
    Center(child: Text('Map')),
    Center(child: Text('Profile')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: CustomNavBar(
        selectedIndex: currentIndex,
        onItemTapped: (index) {
          setState(() {
            currentIndex = index;
          });
          _firestoreService.logFeatureUsage('screen_$index');
        },
      ),
    );
  }
}
