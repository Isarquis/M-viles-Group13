import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uni_marketplace_flutter/viewmodels/post_product_view_model.dart';
import 'package:uni_marketplace_flutter/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

class PostProductScreen extends StatefulWidget {
  final VoidCallback onProductPosted;

  const PostProductScreen({super.key, required this.onProductPosted});

  @override
  State<PostProductScreen> createState() => _PostProductScreenState();
}

class _PostProductScreenState extends State<PostProductScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _baseBidController = TextEditingController();
  String _selectedCategory = 'Math';
  final List<String> _transactionTypes = [];
  File? _image;
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;
  Timer? _debounceTimer;
  bool _isProcessing = false;
  late String _attemptId;

  late final PostProductViewModel _viewModel;
  final List<String> _categories = ['Math', 'Science', 'Tech'];

  late Box productBox;
  late Box imageBox;

  @override
  @override
  void initState() {
    super.initState();
    _viewModel = PostProductViewModel(FirestoreService());
    _getLocation();
    _initHive();

    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    _attemptId = const Uuid().v4(); // <-- muevelo a nivel de clase
    _viewModel.logPostStep(
      step: 'start_post',
      userId: userId,
      attemptId: _attemptId,
    );
  }

  Future<void> _initHive() {
    return Hive.openBox('pending_products')
        .then((box) {
          productBox = box;
          return Hive.openBox('product_images');
        })
        .then((box) {
          imageBox = box;
          print('Hive boxes initialized with .then() chaining');
        })
        .catchError((e) {
          print('Error initializing Hive boxes: $e');
        });
  }

  Future<void> _getLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
    }
  }

  Future<void> _pickImage(bool fromCamera) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );
    if (file != null) {
      setState(() => _image = File(file.path));

      // Log de paso: imagen seleccionada
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      await _viewModel.logPostStep(
        step: 'image_selected',
        userId: userId,
        attemptId: _attemptId,
      );
    }
  }

  Future<void> _postProduct() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _snack('No internet connection, product will be saved for later upload.');
      // El guardado local ya está implementado en tu ViewModel postProduct
      return;
    }

    if (_isProcessing || (_debounceTimer?.isActive ?? false)) {
      print('PostProductScreen: Intento en curso o debounce activo, ignorando');
      return;
    }
    _isProcessing = true;
    _debounceTimer = Timer(const Duration(seconds: 2), () {});
    setState(() => _isLoading = true);

    print('PostProductScreen: Iniciando _postProduct');

    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una imagen')),
      );
      _isProcessing = false;
      setState(() => _isLoading = false);
      return;
    }
    if (_transactionTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un tipo de transacción'),
        ),
      );
      _isProcessing = false;
      setState(() => _isLoading = false);
      return;
    }

    final attemptId = Uuid().v4();
    print('PostProductScreen: Generado attemptId: $attemptId');

    try {
      final user = FirebaseAuth.instance.currentUser;
      final ownerId = user?.uid ?? 'unknown_owner';

      await _viewModel.postProduct(
        title: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        selectedCategory: _selectedCategory,
        price: double.parse(_priceController.text),
        baseBid: double.tryParse(_baseBidController.text) ?? 0.0,
        transactionTypes: _transactionTypes,
        email: _emailController.text.trim(),
        imageFile: _image!,
        latitude: _latitude ?? 0.0,
        longitude: _longitude ?? 0.0,
        ownerId: ownerId,
        attemptId: attemptId,
      );
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      await _viewModel.logPostStep(
        step: 'post_success',
        userId: userId,
        attemptId: _attemptId,
      );
      await _viewModel.logProductPosting(
        category: _selectedCategory,
        transactionTypes: _transactionTypes,
        userId: ownerId,
      );

      _snack('Producto publicado exitosamente');
      widget.onProductPosted(); // Invoca el callback para cambiar a ProductList
    } catch (e) {
      if (e.toString() ==
          'Exception: No internet connection, product saved for later upload') {
        _snack('Producto guardado para subir después');
      } else if (e.toString().contains('Failed to save product locally')) {
        _snack('Error al guardar el producto localmente: $e');
      } else if (e.toString().contains('Invalid product data')) {
        _snack('Datos del producto inválidos, por favor verifica');
      } else if (e.toString().contains('Invalid email format')) {
        _snack('Email inválido');
      } else if (e.toString().contains('Invalid double')) {
        _snack('Precio o base de puja inválidos');
      } else {
        _snack('Error: $e');
      }
    } finally {
      _isProcessing = false;
      setState(() => _isLoading = false);
    }
  }

  Future<String> _saveImageLocally(File image) async {
    try {
      final localPath =
          '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await image.copy(localPath);
      return localPath;
    } catch (e) {
      throw Exception('Error al guardar la imagen localmente: $e');
    }
  }

  Future<void> _saveProductLocally(Map<String, dynamic> productData) async {
    await productBox.put(productData['attemptId'], productData);
    print(
      'Producto guardado localmente con attemptId: ${productData['attemptId']}',
    );
  }

  // Mostrar un snackbar con el mensaje
  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _removeImage() => setState(() => _image = null);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: null,
          title: const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Post a product',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ElevatedButton.icon(
                onPressed: () => _pickImage(false),
                icon: const Icon(Icons.photo_library),
                label: const Text('Select from Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F7A8C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Work Sans',
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _pickImage(true),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take a Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F7A8C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_image != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Stack(
                    children: [
                      Image.file(_image!, height: 150),
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
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                style: const TextStyle(fontFamily: 'Work Sans', fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                style: const TextStyle(fontFamily: 'Work Sans', fontSize: 16),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(fontFamily: 'Work Sans', fontSize: 16),
                ),
                items:
                    _categories.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(
                          c,
                          style: const TextStyle(fontFamily: 'Work Sans'),
                        ),
                      );
                    }).toList(),
                onChanged: (v) async {
                  setState(() => _selectedCategory = v!);
                  final userId =
                      FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
                  await _viewModel.logPostStep(
                    step: 'category_selected',
                    userId: userId,
                    attemptId: _attemptId,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (COP)'),
                style: const TextStyle(fontFamily: 'Work Sans', fontSize: 16),
                onEditingComplete: () async {
                  final userId =
                      FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
                  await _viewModel.logPostStep(
                    step: 'price_entered',
                    userId: userId,
                    attemptId: _attemptId,
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_transactionTypes.contains('Bidding')) ...[
                TextField(
                  controller: _baseBidController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Base Bid (COP)',
                  ),
                  style: const TextStyle(fontFamily: 'Work Sans', fontSize: 16),
                  onEditingComplete: () async {
                    final userId =
                        FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
                    await _viewModel.logPostStep(
                      step: 'base_bid_entered',
                      userId: userId,
                      attemptId: _attemptId,
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'Transaction Types:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              ...['Rent', 'Buy', 'Bidding'].map((type) {
                final label = type == 'Bidding' ? 'Bid' : type;
                return CheckboxListTile(
                  title: Text(label),
                  value: _transactionTypes.contains(type),
                  onChanged: (v) {
                    setState(() {
                      v!
                          ? _transactionTypes.add(type)
                          : _transactionTypes.remove(type);
                    });
                  },
                );
              }),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Contact Email'),
                style: const TextStyle(fontFamily: 'Work Sans', fontSize: 16),
                onEditingComplete: () async {
                  final userId =
                      FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
                  await _viewModel.logPostStep(
                    step: 'email_entered',
                    userId: userId,
                    attemptId: _attemptId,
                  );
                },
              ),
              const SizedBox(height: 20),
              Center(
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                          onPressed:
                              _isLoading || _isProcessing ? null : _postProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F7A8C),
                            foregroundColor: Colors.white,
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
      ),
    );
  }
}
