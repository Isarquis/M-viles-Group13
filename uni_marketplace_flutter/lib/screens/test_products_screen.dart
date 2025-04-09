import 'package:flutter/material.dart';
import 'package:uni_marketplace_flutter/services/firestore_service.dart';

class TestProductsScreen extends StatefulWidget {
  @override
  _TestProductsScreenState createState() => _TestProductsScreenState();
}

class _TestProductsScreenState extends State<TestProductsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> products = [];

  void fetchProducts() async {
    var result = await _firestoreService.getAllProducts();
    setState(() {
      products = result;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Productos')),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          var product = products[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              leading: product['imageUrl'] != null
                  ? Image.network(product['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                  : Icon(Icons.image_not_supported),
              title: Text(product['title']?.toString() ?? 'Sin título'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Precio: ${product['price']?.toString() ?? 'Sin precio'} COP'),
                  Text('Descripción: ${product['description'] ?? 'Sin descripción'}'),
                  Text('Estado: ${product['status'] ?? 'Sin estado'}'),
                  Text('Tipo: ${(product['type'] as List?)?.join(", ") ?? 'Sin tipo'}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}