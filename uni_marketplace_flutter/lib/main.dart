import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/auth/login_page.dart';
import 'screens/auth/register_page.dart';
import 'screens/home_page.dart';
import 'screens/product_list.dart';
import 'screens/product_detail.dart';
import 'screens/post_product/post_product_screen.dart';
import 'screens/nearby_products_map.dart';
import 'screens/profile_view.dart';

import 'widgets/custom_navbar.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/nearby_products_viewmodel.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NearbyProductsViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;

    return MaterialApp(
      title: 'Uni Marketplace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.grey,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: Colors.green,
        ),
      ),
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => const HomeScreen(),
      },
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

  final List<Widget> _screens = [
    const HomePage(),
    const ProductList(),
    const ProductDetail(productId: '60J3pS3bRnFjrksPd8hL'),
    const PostProductScreen(),
    const NearbyProductsMap(),
    ProfileView(onDiscoverTapped: () {}),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      Center(child: Text('Home')),
      ProductList(),
      ProductDetail(productId: '60J3pS3bRnFjrksPd8hL'),
      PostProductScreen(),
      NearbyProductsMap(),
      ProfileView(onDiscoverTapped: () => setState(() => currentIndex = 1)),
    ];

    return Scaffold(
    body: _screens[currentIndex],
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
