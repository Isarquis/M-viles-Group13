import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uni_marketplace_flutter/services/firestore_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostProductScreen extends StatefulWidget {
  const PostProductScreen({super.key});

  @override
  _PostProductScreenState createState() => _PostProductScreenState();
}

class _PostProductScreenState extends State<PostProductScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedCategory = 'Math';
  List<String> _transactionTypes = [];
  File? _image;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  final List<String> _categories = ['Math', 'Science', 'Tech'];

Future<void> _pickImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    setState(() {
      _image = File(pickedFile.path);
      print('Imagen seleccionada: ${_image!.path}');
    });
  } else {
    print('No se seleccionó ninguna imagen');
  }
}

  // Función para publicar el producto
Future<void> _postProduct() async {
  if (_image == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Por favor, selecciona una imagen')),
    );
    return;
  }
  if (_transactionTypes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Por favor, selecciona al menos un tipo de transacción')),
    );
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    if (!_image!.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La imagen seleccionada no es válida')),
      );
      return;
    }

    String imageUrl = await _firestoreService.uploadImageWithFile(_image!, 'products');
    print('URL de la imagen: $imageUrl');

    Map<String, dynamic> data = {
      'title': _nameController.text,
      'description': _descriptionController.text,
      'category': _selectedCategory,
      'price': double.parse(_priceController.text),
      'type': _transactionTypes,
      'image': imageUrl,
      'contactEmail': _emailController.text,
      'status': 'Available',
    };

    await _firestoreService.addProduct(data);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Producto publicado exitosamente')),
    );
    Navigator.pop(context);
  } catch (e) {
    print('Error en _postProduct: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al publicar el producto: $e')),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Product'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Add Photos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F7A8C),
                foregroundColor: Colors.white,
              ),
            ),
            if (_image != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.file(_image!, height: 100),
              ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price (COP)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            const Text('Transaction Types:', style: TextStyle(fontWeight: FontWeight.bold)),
            CheckboxListTile(
              title: const Text('Rental'),
              value: _transactionTypes.contains('Rent'),
              onChanged: (value) {
                setState(() {
                  if (value!) {
                    _transactionTypes.add('Rent');
                  } else {
                    _transactionTypes.remove('Rent');
                  }
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Buy'),
              value: _transactionTypes.contains('Buy'),
              onChanged: (value) {
                setState(() {
                  if (value!) {
                    _transactionTypes.add('Buy');
                  } else {
                    _transactionTypes.remove('Buy');
                  }
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Bid'),
              value: _transactionTypes.contains('Bidding'),
              onChanged: (value) {
                setState(() {
                  if (value!) {
                    _transactionTypes.add('Bidding');
                  } else {
                    _transactionTypes.remove('Bidding');
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Contact Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _postProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F7A8C),
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      ),
                      child: const Text(
                        'Post',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}