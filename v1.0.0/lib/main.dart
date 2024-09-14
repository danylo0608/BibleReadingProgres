import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Для збереження налаштувань
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false; // Змінна для контролю теми

  @override
  void initState() {
    super.initState();
    _loadTheme(); // Завантажуємо тему при старті додатку
  }

  Future<void> _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  void _toggleTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = !isDarkMode;
      prefs.setBool('isDarkMode', isDarkMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkMode
          ? ThemeData.dark().copyWith(
              scaffoldBackgroundColor: Colors.black,
              primaryColor: Colors.white,
              textTheme:
                  const TextTheme(bodyLarge: TextStyle(color: Colors.white)),
            )
          : ThemeData.light(),
      home: HomePage(toggleTheme: _toggleTheme),
    );
  }
}

class HomePage extends StatefulWidget {
  final Function toggleTheme;

  const HomePage({super.key, required this.toggleTheme});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Database _database;
  List<Map<String, dynamic>> _readings = [];

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'bible_reading.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE readings(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT, passage TEXT)",
        );
      },
      version: 1,
    );
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    final List<Map<String, dynamic>> readings =
        await _database.query('readings', orderBy: 'id DESC');
    setState(() {
      _readings = readings;
    });
  }

  Future<void> _addReading(String date, String passage) async {
    await _database.insert(
      'readings',
      {'date': date, 'passage': passage},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _loadReadings(); // Оновлюємо список після додавання
  }

  Future<void> _deleteReading(int id) async {
    await _database.delete('readings', where: 'id = ?', whereArgs: [id]);
    _loadReadings(); // Оновлюємо список після видалення
  }

  void _showAddReadingDialog(BuildContext context) {
    final dateController = TextEditingController();
    final passageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Додати запис'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Дата'),
              ),
              TextField(
                controller: passageController,
                decoration: const InputDecoration(labelText: 'Місце'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Відмінити'),
            ),
            ElevatedButton(
              onPressed: () {
                _addReading(dateController.text, passageController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Додати'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(int id, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Підтвердження'),
          content: const Text('Ви впевнені, що хочете видалити цей запис?'),
          actions: [
            TextButton(
              child: const Text('Відмінити'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Видалити'),
              onPressed: () {
                _deleteReading(id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllReadings() async {
    await _database.delete('readings');
    _loadReadings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Прогрес читання Біблії'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showSettingsDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _readings.length,
              itemBuilder: (context, index) {
                final reading = _readings[index];
                return ListTile(
                  title: Text('${reading['date']} - ${reading['passage']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _showDeleteConfirmationDialog(reading['id'], context);
                    },
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  _showAddReadingDialog(context);
                },
                child: const Text('Додати запис'),
              ),
              ElevatedButton(
                onPressed: () {
                  _showConfirmationDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text('Очистити всі записи'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Налаштування'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Темна тема'),
                trailing: Switch(
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (value) {
                    widget.toggleTheme();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Підтвердження'),
          content: const Text('Ви впевнені, що хочете очистити всі записи?'),
          actions: [
            TextButton(
              child: const Text('Відмінити'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Очистити'),
              onPressed: () {
                _clearAllReadings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
