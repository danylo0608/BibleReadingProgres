import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class BibleReadingDatabase {
  static final BibleReadingDatabase instance = BibleReadingDatabase._init();
  static Database? _database;

  BibleReadingDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bible_readings.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE readings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      passage TEXT NOT NULL
    )
    ''');
  }

  Future<List<Map<String, dynamic>>> getReadings() async {
    final db = await instance.database;
    return await db.query('readings');
  }

  Future<int> addReading(String date, String passage) async {
    final db = await instance.database;
    return await db.insert('readings', {'date': date, 'passage': passage});
  }

  Future<void> clearReadings() async { // Метод для очищення таблиці
    final db = await instance.database;
    await db.delete('readings');
  }
}
