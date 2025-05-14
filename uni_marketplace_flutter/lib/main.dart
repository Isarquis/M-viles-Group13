import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uni_marketplace_flutter/screens/earn_list.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/register_page.dart';
import 'screens/home_page.dart';
import 'screens/product_list.dart';
import 'screens/product_detail.dart';
import 'screens/post_product_screen.dart';
import 'screens/nearby_products_map.dart';
import 'screens/profile_view.dart';
import 'widgets/custom_navbar.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/nearby_products_viewmodel.dart';
import 'services/firestore_service.dart';
import 'services/offline_sync_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();

  final firestoreService = FirestoreService();
  OfflineSyncService(firestoreService);

  await Hive.openBox('profile_data');

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
        '/home': (context) {
          final user = FirebaseAuth.instance.currentUser;
          return HomeScreen(userId: user!.uid);
        },
        '/profile': (context) {
          final user = FirebaseAuth.instance.currentUser;
          return ProfileView(
            userId: user!.uid,
            onDiscoverTapped: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          );
        },
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({required this.userId, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();
  late String userId;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    userId = widget.userId;

    _screens = [
      const HomePage(),
      const ProductList(),
      const EarnScreen(),
      PostProductScreen(
        onProductPosted: () {
          setState(() {
            currentIndex = 1; // Cambia a ProductList
          });
        },
      ),
      const NearbyProductsMap(),
      ProfileView(
        onDiscoverTapped: () {
          setState(() {
            currentIndex = 0; // Cambia a HomePage
          });
        },
        userId: userId,
      ),
    ];
  }


  @override
  Widget build(BuildContext context) {
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
