import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SearchHistoryDB {
  static final SearchHistoryDB _instance = SearchHistoryDB._internal();
  factory SearchHistoryDB() => _instance;
  SearchHistoryDB._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'search_history.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE search_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            term TEXT NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> insertTerm(String term) async {
    final db = await database;
    await db.insert('search_history', {
      'term': term,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<String>> getRecentTerms({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'search_history',
      columns: ['term'],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    // Extraemos solo los términos y eliminamos duplicados manteniendo orden
    final seen = <String>{};
    final terms = <String>[];
    for (var row in maps) {
      final term = row['term'] as String;
      if (!seen.contains(term)) {
        seen.add(term);
        terms.add(term);
      }
    }
    return terms;
  }
}
