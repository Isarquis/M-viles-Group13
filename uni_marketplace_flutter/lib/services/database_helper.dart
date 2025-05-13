import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:synchronized/synchronized.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  final _lock = Lock();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'marketplace.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pending_products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            description TEXT,
            selectedCategory TEXT,
            price REAL,
            baseBid REAL,
            transactionTypes TEXT,
            email TEXT,
            imagePath TEXT,
            latitude REAL,
            longitude REAL,
            ownerId TEXT,
            attemptId TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            title TEXT,
            price TEXT,
            description TEXT,
            imageUrl TEXT,
            ownerName TEXT,
            ownerEmail TEXT,
            ownerPhone TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE pending_products ADD COLUMN attemptId TEXT',
          );
        }
      },
    );
  }

  Future<String> saveImageLocally(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String newPath = join(
        directory.path,
        'images',
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await Directory(join(directory.path, 'images')).create(recursive: true);
      final File newImage = await imageFile.copy(newPath);
      return newImage.path;
    } catch (e) {
      throw Exception('Failed to save image locally: $e');
    }
  }

  Future<bool> productExistsByAttemptId(String attemptId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pending_products',
      where: 'attemptId = ?',
      whereArgs: [attemptId],
    );
    return maps.isNotEmpty;
  }

  Future<void> insertPendingProduct(Map<String, dynamic> product) async {
    await _lock.synchronized(() async {
      print(
        'DatabaseHelper: insertPendingProduct called with attemptId: ${product['attemptId']}',
      );

      if (await productExistsByAttemptId(product['attemptId'])) {
        print(
          'DatabaseHelper: Product with attemptId ${product['attemptId']} already exists, skipping insertion',
        );
        return;
      }

      final db = await database;
      await db.insert(
        'pending_products',
        product,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print(
        'DatabaseHelper: Product inserted into pending_products with attemptId: ${product['attemptId']}',
      );
    });
  }

  Future<List<Map<String, dynamic>>> getPendingProducts() async {
    final db = await database;
    return await db.query('pending_products');
  }

  Future<void> deletePendingProduct(int id) async {
    final db = await database;
    await db.delete('pending_products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    await db.insert(
      'products',
      product,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getProduct(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<void> printPendingProducts() async {
    final pending = await getPendingProducts();
    print('DatabaseHelper: Pending products: $pending');
  }
}
