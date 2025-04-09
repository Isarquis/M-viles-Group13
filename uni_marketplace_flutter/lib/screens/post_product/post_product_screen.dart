import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:uni_marketplace_flutter/screens/product_list.dart';
import 'package:uni_marketplace_flutter/services/firestore_service.dart';
import 'package:uni_marketplace_flutter/screens/post_product/post_product_view_model.dart'; // Importar ViewModel

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
  bool _isLoading = false;

  late PostProductViewModel _viewModel;

  final List<String> _categories = ['Math', 'Science', 'Tech'];

  @override
  void initState() {
    super.initState();
    _viewModel = PostProductViewModel(FirestoreService());
  }

  Future<void> _pickImage(bool isCamera) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: isCamera ? ImageSource.camera : ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _postProduct() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una imagen')),
      );
      return;
    }

    if (_transactionTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, selecciona al menos un tipo de transacción',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _viewModel.postProduct(
        title: _nameController.text,
        description: _descriptionController.text,
        selectedCategory: _selectedCategory,
        price: double.parse(_priceController.text),
        transactionTypes: _transactionTypes,
        email: _emailController.text,
        imageFile: _image!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto publicado exitosamente')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProductList()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al publicar el producto: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
    });
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
              onPressed: () => _pickImage(false),
              icon: const Icon(Icons.photo_library),
              label: const Text('Select from Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F7A8C),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _pickImage(true),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take a Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F7A8C),
              ),
            ),
            if (_image != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Stack(
                  children: [
                    Image.file(_image!, height: 100),
                    Positioned(
                      top: -5,
                      right: -5,
                      child: GestureDetector(
                        onTap: _removeImage,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F7A94).withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Resto de campos de formulario aquí (nombre, descripción, precio, etc.)
            const SizedBox(height: 20),
            Center(
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                        onPressed: _postProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F7A8C),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 15,
                          ),
                        ),
                        child: const Text(
                          'Post',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
